class_name IsoCameraRig
extends Node3D

## Smooth tilted top-down / isometric camera with cinematic zoom-to-door transition support.

@export var follow_speed: float = 5.5
@export var camera_offset: Vector3 = Vector3(11.5, 11.2, 11.5)
@export var look_offset: Vector3 = Vector3(0.0, 0.6, 0.0)
@export var fov_degrees: float = 34.0

var target: Node3D = null
var camera: Camera3D = null
var cinematic_mode: bool = false


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "IsoCamera3D"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = fov_degrees
	camera.near = 0.2
	camera.far = 180.0
	add_child(camera)
	camera.position = camera_offset
	camera.look_at(look_offset, Vector3.UP)


func set_target(node: Node3D, snap: bool = true) -> void:
	target = node
	if snap and target != null:
		global_position = target.global_position
		if camera != null:
			camera.look_at(global_position + look_offset, Vector3.UP)


func snap_to_target() -> void:
	if target != null and is_instance_valid(target):
		global_position = target.global_position


func play_door_zoom_in(door_pos: Vector3, duration: float = 1.15) -> void:
	## Smoothly glides and zooms the camera into the glowing Golden Door for automatic stage transition.
	if camera == null:
		return
	cinematic_mode = true
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_position", door_pos + Vector3(0.0, 1.0, 0.0), duration)
	tw.tween_property(camera, "position", camera_offset * 0.34, duration)
	tw.tween_property(camera, "fov", 24.0, duration)


func _physics_process(delta: float) -> void:
	if cinematic_mode:
		if camera != null:
			camera.look_at(global_position + Vector3(0.0, 0.4, 0.0), Vector3.UP)
		return
	if target == null or not is_instance_valid(target):
		return
	var desired := target.global_position
	global_position = global_position.lerp(desired, minf(1.0, follow_speed * delta))
	if camera != null:
		camera.look_at(global_position + look_offset, Vector3.UP)
