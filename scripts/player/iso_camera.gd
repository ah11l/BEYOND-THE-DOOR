class_name IsoCameraRig
extends Node3D

## Dramatic, intelligent dynamic camera rig:
## - Closer, lower heroic 3/4 perspective (8.6, 7.6, 8.6, FOV 38)
## - Smooth velocity lookahead + subtle adaptive corner yaw (±6 deg)
## - Automatic wide framing when starting a stage + subtle suspense camera shake
## - Layer-32 prop occlusion fade + 3D cinematic shot support

@export var follow_speed: float = 5.4
@export var base_offset: Vector3 = Vector3(8.6, 7.6, 8.6)
@export var look_offset: Vector3 = Vector3(0.0, 0.95, 0.0)
@export var base_fov: float = 38.0

var target: Node3D = null
var camera: Camera3D = null
var cinematic_mode: bool = false

var _current_offset: Vector3 = Vector3(8.6, 7.6, 8.6)
var _desired_zoom: float = 1.0
var _lookahead: Vector3 = Vector3.ZERO
var _dynamic_yaw: float = 0.0
var _stage_center: Vector3 = Vector3.ZERO
var _stage_span: float = 12.0
var _occluded_nodes: Array[Node3D] = []
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_duration: float = 0.01
var _shake_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_shake_rng.randomize()
	_current_offset = base_offset
	camera = Camera3D.new()
	camera.name = "IsoCamera3D"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = base_fov
	camera.near = 0.2
	camera.far = 240.0
	add_child(camera)
	camera.position = _current_offset
	camera.look_at(look_offset, Vector3.UP)


func trigger_shake(strength: float = 0.20, duration: float = 0.65) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(duration, 0.05)
	_shake_time = _shake_duration


func set_target(node: Node3D, snap: bool = true) -> void:
	target = node
	if snap and target != null:
		global_position = target.global_position
		_lookahead = Vector3.ZERO
		_dynamic_yaw = 0.0
		if camera != null:
			camera.position = base_offset
			camera.look_at(global_position + look_offset, Vector3.UP)


func configure_stage_framing(center: Vector3, span: float, play_intro_glide: bool = true) -> void:
	_stage_center = center
	_stage_span = clampf(span, 8.0, 34.0)
	if not play_intro_glide or target == null or camera == null:
		return
	var wide_mult := clampf(1.38 + (_stage_span - 12.0) * 0.018, 1.38, 1.72)
	var start_focus := target.global_position.lerp(_stage_center, 0.48)
	cinematic_mode = true
	global_position = start_focus
	camera.position = base_offset * wide_mult
	camera.fov = base_fov + 4.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", target.global_position, 1.45)
	tw.tween_property(camera, "position", base_offset, 1.45)
	tw.tween_property(camera, "fov", base_fov, 1.45)
	tw.chain().tween_callback(func() -> void: cinematic_mode = false)


func snap_to_target() -> void:
	if target != null and is_instance_valid(target):
		global_position = target.global_position
		_lookahead = Vector3.ZERO
		_desired_zoom = 1.0
		_dynamic_yaw = 0.0


func reset_view() -> void:
	cinematic_mode = false
	_desired_zoom = 1.0
	_lookahead = Vector3.ZERO
	_dynamic_yaw = 0.0
	if camera != null:
		camera.fov = base_fov
		camera.position = base_offset


func play_door_zoom_in(door_pos: Vector3, duration: float = 1.15) -> void:
	if camera == null:
		return
	cinematic_mode = true
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_position", door_pos + Vector3(0.0, 1.1, 0.0), duration)
	tw.tween_property(camera, "position", base_offset * 0.42, duration)
	tw.tween_property(camera, "fov", 26.0, duration)


func play_cinematic_shot(from_focus: Vector3, to_focus: Vector3, from_offset: Vector3, to_offset: Vector3, duration: float) -> Tween:
	cinematic_mode = true
	global_position = from_focus
	if camera != null:
		camera.position = from_offset
		camera.look_at(global_position + look_offset, Vector3.UP)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_position", to_focus, duration)
	if camera != null:
		tw.tween_property(camera, "position", to_offset, duration)
	return tw


func _physics_process(delta: float) -> void:
	if cinematic_mode:
		if camera != null:
			camera.look_at(global_position + Vector3(0.0, 0.75, 0.0), Vector3.UP)
		return
	if target == null or not is_instance_valid(target):
		return

	var target_vel := Vector3.ZERO
	if target is CharacterBody3D:
		target_vel = (target as CharacterBody3D).velocity
	var horiz_vel := Vector3(target_vel.x, 0.0, target_vel.z)

	var desired_lookahead := horiz_vel * 0.46
	if desired_lookahead.length() > 3.0:
		desired_lookahead = desired_lookahead.normalized() * 3.0
	_lookahead = _lookahead.lerp(desired_lookahead, minf(1.0, 3.6 * delta))

	var target_yaw := clampf((target.global_position.x - _stage_center.x) * 0.008, -0.11, 0.11)
	_dynamic_yaw = lerpf(_dynamic_yaw, target_yaw, minf(1.0, 2.2 * delta))

	var speed_ratio := clampf(horiz_vel.length() / 5.8, 0.0, 1.0)
	var elev_boost := clampf(target.global_position.y * 0.045, 0.0, 0.28)
	var air_boost := 0.08 if (target is CharacterBody3D and not (target as CharacterBody3D).is_on_floor()) else 0.0
	var span_bonus := clampf((_stage_span - 16.0) * 0.010, 0.0, 0.16)
	_desired_zoom = 1.0 + speed_ratio * 0.14 + elev_boost + air_boost + span_bonus

	var desired_focus := target.global_position + _lookahead
	global_position = global_position.lerp(desired_focus, minf(1.0, follow_speed * delta))

	var rotated_base := base_offset.rotated(Vector3.UP, _dynamic_yaw)
	var target_offset := rotated_base * _desired_zoom
	_current_offset = _current_offset.lerp(target_offset, minf(1.0, 3.0 * delta))

	var shake_off := Vector3.ZERO
	if _shake_time > 0.0:
		_shake_time = maxf(0.0, _shake_time - delta)
		var decay := _shake_time / _shake_duration
		var amp := _shake_strength * decay
		shake_off = Vector3(
			_shake_rng.randf_range(-amp, amp),
			_shake_rng.randf_range(-amp * 0.6, amp * 0.6),
			_shake_rng.randf_range(-amp, amp)
		)
		if _shake_time <= 0.0:
			_shake_strength = 0.0

	if camera != null:
		camera.position = _current_offset + shake_off
		camera.look_at(global_position + look_offset + shake_off * 0.35, Vector3.UP)

	_update_occlusion_fade()


func _update_occlusion_fade() -> void:
	for n in _occluded_nodes:
		if is_instance_valid(n):
			n.visible = true
	_occluded_nodes.clear()

	if camera == null or target == null or not is_instance_valid(target):
		return
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var from_pt := camera.global_position
	var to_pt := target.global_position + Vector3(0.0, 0.85, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from_pt, to_pt, 32)
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var col := hit.get("collider") as Node
		if col != null and col.get_parent() is Node3D:
			var prop_root := col.get_parent() as Node3D
			prop_root.visible = false
			_occluded_nodes.append(prop_root)
