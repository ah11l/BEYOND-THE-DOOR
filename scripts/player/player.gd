class_name PlayerController
extends CharacterBody3D

## Responsive hooded protagonist controller with smooth analog isometric movement,
## coyote time, jump buffering, subtle movement lean, multi-zone gravity support, and Echo integration.

signal interaction_target_changed(target: Node)
signal interacted(target: Node)
signal fell_into_void

@export var move_speed: float = 5.8
@export var acceleration: float = 28.0
@export var air_acceleration: float = 16.0
@export var deceleration: float = 30.0
@export var jump_velocity: float = 6.8
@export var base_gravity: float = 18.5
@export var void_y_threshold: float = -10.0

const COYOTE_TIME := 0.14
const JUMP_BUFFER_TIME := 0.14

var gravity_scale: float = 1.0
var upward_lift: float = 0.0
var current_world_side: int = 0
var active_room_state: int = 0
var movement_locked: bool = false

var _rig: Node3D
var _lantern_holder: Node3D
var _interact_area: Area3D
var _nearby_interactables: Array[Node] = []
var _current_target: Node = null
var _bob_time: float = 0.0
var _camera_ref: Camera3D = null
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _active_gravity_zones: Dictionary = {} # zone_id -> {"scale": float, "lift": float}


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 16

	_rig = LowPolyMeshLibrary.build_hooded_character(false)
	add_child(_rig)
	_lantern_holder = _rig.get_node_or_null("LanternHolder")

	_interact_area = get_node_or_null("InteractArea") as Area3D
	if _interact_area != null:
		_interact_area.area_entered.connect(_on_interact_area_entered)
		_interact_area.area_exited.connect(_on_interact_area_exited)
		_interact_area.body_entered.connect(_on_interact_area_entered)
		_interact_area.body_exited.connect(_on_interact_area_exited)

	GameState.touch_jump_pressed.connect(_queue_jump)
	GameState.touch_interact_pressed.connect(_try_interact)


func set_camera_reference(cam: Camera3D) -> void:
	_camera_ref = cam


func enter_gravity_zone(zone_id: String, scale_val: float, lift_val: float) -> void:
	_active_gravity_zones[zone_id] = {"scale": scale_val, "lift": lift_val}
	_recompute_gravity_zone()


func exit_gravity_zone(zone_id: String) -> void:
	_active_gravity_zones.erase(zone_id)
	_recompute_gravity_zone()


func set_gravity_zone(scale_val: float, lift_val: float) -> void:
	enter_gravity_zone("_direct", scale_val, lift_val)


func reset_gravity_zone() -> void:
	_active_gravity_zones.clear()
	_recompute_gravity_zone()


func _recompute_gravity_zone() -> void:
	if _active_gravity_zones.is_empty():
		gravity_scale = 1.0
		upward_lift = 0.0
		return
	var best_scale := 1.0
	var best_lift := 0.0
	for zdata in _active_gravity_zones.values():
		var d := zdata as Dictionary
		best_scale = minf(best_scale, float(d.get("scale", 1.0)))
		best_lift = maxf(best_lift, float(d.get("lift", 0.0)))
	gravity_scale = best_scale
	upward_lift = best_lift


func _queue_jump() -> void:
	if movement_locked:
		return
	_jump_buffer_timer = JUMP_BUFFER_TIME


func _physics_process(delta: float) -> void:
	if movement_locked:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Coyote time & jump buffer timers for crisp, forgiving platforming
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	if Input.is_action_just_pressed("jump"):
		_queue_jump()
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	# Gravity / Blue Door upward lift
	if upward_lift > 0.0:
		velocity.y = move_toward(velocity.y, upward_lift, base_gravity * 0.75 * delta)
	elif not is_on_floor():
		velocity.y -= base_gravity * gravity_scale * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	# Execute buffered jump if grounded or within coyote window
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		var mult := 1.45 if gravity_scale < 0.7 else 1.0
		velocity.y = jump_velocity * mult
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	# Combined keyboard + floating touchpad analog input
	var input_vec := _get_move_input()
	var move_dir := _to_isometric_direction(input_vec)
	var accel := acceleration if is_on_floor() else air_acceleration

	if move_dir.length_squared() > 0.004:
		var desired := move_dir * (move_speed * GameState.get_move_speed_multiplier())
		velocity.x = move_toward(velocity.x, desired.x, accel * delta)
		velocity.z = move_toward(velocity.z, desired.z, accel * delta)
		var target_yaw := atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, 15.0 * delta))
		_bob_time += delta * (7.0 + move_dir.length() * 5.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		_bob_time += delta * 2.0

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	move_and_slide()
	_handle_pushable_collisions()
	_animate_character(delta)
	_refresh_closest_interactable()

	if global_position.y < void_y_threshold:
		fell_into_void.emit()


func _get_move_input() -> Vector2:
	var kb := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	var combined := kb + GameState.touch_move_vector
	if combined.length() > 1.0:
		combined = combined.normalized()
	return combined


func _to_isometric_direction(input_vec: Vector2) -> Vector3:
	if input_vec.length_squared() < 0.001:
		return Vector3.ZERO
	if _camera_ref != null:
		var forward := -_camera_ref.global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := _camera_ref.global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		return (right * input_vec.x - forward * input_vec.y).normalized() * input_vec.length()
	var angle := deg_to_rad(45.0)
	var cos_a := cos(angle)
	var sin_a := sin(angle)
	var wx := input_vec.x * cos_a - input_vec.y * sin_a
	var wz := input_vec.x * sin_a + input_vec.y * cos_a
	return Vector3(wx, 0.0, wz)


func _try_interact() -> void:
	if movement_locked:
		return
	_refresh_closest_interactable()
	if _current_target != null and is_instance_valid(_current_target):
		if _current_target.has_method("interact"):
			_current_target.interact(self)
			interacted.emit(_current_target)


func _handle_pushable_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider != null and collider.has_method("apply_push"):
			var push_dir := -col.get_normal()
			push_dir.y = 0.0
			if push_dir.length_squared() > 0.01:
				collider.apply_push(push_dir.normalized())


func _animate_character(delta: float) -> void:
	if _rig == null:
		return
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clampf(horiz_speed / move_speed, 0.0, 1.0)
	var bob_amp := lerpf(0.015, 0.055, speed_ratio)
	_rig.position.y = absf(sin(_bob_time)) * bob_amp
	# Gentle forward lean when moving for lively, responsive feel
	_rig.rotation.x = lerpf(_rig.rotation.x, -0.11 * speed_ratio, minf(1.0, 10.0 * delta))
	if _lantern_holder != null:
		_lantern_holder.rotation.z = sin(_bob_time * 0.75) * (0.08 + 0.08 * speed_ratio)


func _on_interact_area_entered(node: Node) -> void:
	var candidate := _find_interactable_owner(node)
	if candidate != null and not (candidate in _nearby_interactables):
		_nearby_interactables.append(candidate)
		_refresh_closest_interactable()


func _on_interact_area_exited(node: Node) -> void:
	var candidate := _find_interactable_owner(node)
	if candidate != null and candidate in _nearby_interactables:
		_nearby_interactables.erase(candidate)
		_refresh_closest_interactable()


func _find_interactable_owner(node: Node) -> Node:
	var cur := node
	while cur != null:
		if cur.has_method("interact"):
			return cur
		cur = cur.get_parent()
	return null


func _refresh_closest_interactable() -> void:
	var best: Node = null
	var best_dist := INF
	var valid_list: Array[Node] = []
	for item in _nearby_interactables:
		if not is_instance_valid(item) or not (item is Node3D):
			continue
		if item.has_method("can_interact") and not item.can_interact(self):
			valid_list.append(item)
			continue
		valid_list.append(item)
		var d := global_position.distance_squared_to((item as Node3D).global_position)
		if d < best_dist:
			best_dist = d
			best = item
	_nearby_interactables = valid_list
	if best != _current_target:
		_current_target = best
		interaction_target_changed.emit(_current_target)


func get_current_target() -> Node:
	return _current_target


func _exit_tree() -> void:
	if GameState.touch_jump_pressed.is_connected(_queue_jump):
		GameState.touch_jump_pressed.disconnect(_queue_jump)
	if GameState.touch_interact_pressed.is_connected(_try_interact):
		GameState.touch_interact_pressed.disconnect(_try_interact)
