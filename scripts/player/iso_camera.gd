class_name IsoCameraRig
extends Node3D

## Smooth tilted top-down / isometric camera matching the reference framing.

@export var follow_speed: float = 5.5
@export var camera_offset: Vector3 = Vector3(11.5, 11.2, 11.5)
@export var look_offset: Vector3 = Vector3(0.0, 0.6, 0.0)
@export var fov_degrees: float = 34.0

var target: Node3D = null
var camera: Camera3D = null


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "IsoCamera3D"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = fov_degrees
	camera.near = 0.2
	camera.far = 160.0
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


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var desired := target.global_position
	global_position = global_position.lerp(desired, minf(1.0, follow_speed * delta))
	if camera != null:
		camera.look_at(global_position + look_offset, Vector3.UP)
