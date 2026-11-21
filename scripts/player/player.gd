class_name PlayerController
extends CharacterBody3D

## Hooded protagonist controller with isometric camera-relative movement,
## optional jump, local gravity field support, interaction detection, and Echo integration.

signal interaction_target_changed(target: Node)
signal interacted(target: Node)
signal fell_into_void

@export var move_speed: float = 5.4
@export var acceleration: float = 22.0
@export var deceleration: float = 26.0
@export var jump_velocity: float = 6.4
@export var base_gravity: float = 18.0
@export var void_y_threshold: float = -10.0

var gravity_scale: float = 1.0
var upward_lift: float = 0.0
var current_world_side: int = 0 # 0 = Primary, 1 = Alternate (Black Door)
var active_room_state: int = 0  # 0 = State A, 1 = State B (Purple Door)
var movement_locked: bool = false

var _rig: Node3D
var _lantern_holder: Node3D
var _interact_area: Area3D
var _nearby_interactables: Array[Node] = []
var _current_target: Node = null
var _bob_time: float = 0.0
var _camera_ref: Camera3D = null


func _ready() -> void:
	collision_layer = 2 # Layer 2: Player
	collision_mask = 1 | 16 # Layer 1: World, Layer 5: Pushable

	_rig = LowPolyMeshLibrary.build_hooded_character(false)
	add_child(_rig)
	_lantern_holder = _rig.get_node_or_null("LanternHolder")

	_interact_area = get_node_or_null("InteractArea") as Area3D
	if _interact_area != null:
		_interact_area.area_entered.connect(_on_interact_area_entered)
		_interact_area.area_exited.connect(_on_interact_area_exited)
		_interact_area.body_entered.connect(_on_interact_area_entered)
		_interact_area.body_exited.connect(_on_interact_area_exited)

	GameState.touch_jump_pressed.connect(_try_jump)
	GameState.touch_interact_pressed.connect(_try_interact)


func set_camera_reference(cam: Camera3D) -> void:
	_camera_ref = cam


func set_gravity_zone(scale_val: float, lift_val: float) -> void:
	gravity_scale = scale_val
	upward_lift = lift_val


func reset_gravity_zone() -> void:
	gravity_scale = 1.0
	upward_lift = 0.0


func _physics_process(delta: float) -> void:
	if movement_locked:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Gravity / Blue Door low-gravity or upward lift
	if upward_lift > 0.0:
		velocity.y = move_toward(velocity.y, upward_lift, base_gravity * 0.7 * delta)
	elif not is_on_floor():
		velocity.y -= base_gravity * gravity_scale * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	# Read combined keyboard + mobile touch joystick input
	var input_vec := _get_move_input()
	var move_dir := _to_isometric_direction(input_vec)

	if move_dir.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, move_dir.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * move_speed, acceleration * delta)
		var target_yaw := atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, 12.0 * delta))
		_bob_time += delta * 10.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		_bob_time += delta * 2.0

	if Input.is_action_just_pressed("jump"):
		_try_jump()
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	move_and_slide()
	_handle_pushable_collisions()
	_animate_character()
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
	# Fallback 45-degree isometric basis
	var angle := deg_to_rad(45.0)
	var cos_a := cos(angle)
	var sin_a := sin(angle)
	var wx := input_vec.x * cos_a - input_vec.y * sin_a
	var wz := input_vec.x * sin_a + input_vec.y * cos_a
	return Vector3(wx, 0.0, wz)


func _try_jump() -> void:
	if movement_locked:
		return
	if is_on_floor():
		var mult := 1.45 if gravity_scale < 0.7 else 1.0
		velocity.y = jump_velocity * mult


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


func _animate_character() -> void:
	if _rig == null:
		return
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	var bob_amp := 0.045 if horiz_speed > 0.3 else 0.015
	_rig.position.y = absf(sin(_bob_time)) * bob_amp
	if _lantern_holder != null:
		_lantern_holder.rotation.z = sin(_bob_time * 0.7) * 0.10


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
