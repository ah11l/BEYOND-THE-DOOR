class_name PushableBlock
extends CharacterBody3D

## Carved ancient rune-stone pushable cube that adapts its glowing runes to each of the 6 worlds.

@export var push_speed: float = 2.8
@export var world_index: int = 1
var initial_position: Vector3 = Vector3.ZERO
var _push_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	initial_position = global_position
	collision_layer = 16 # Layer 5: Pushable
	collision_mask = 1 | 16

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.05, 1.05, 1.05)
	shape.shape = box
	shape.position = Vector3(0.0, 0.525, 0.0)
	add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var m_box := BoxMesh.new()
	m_box.size = Vector3(1.05, 1.05, 1.05)
	mesh_inst.mesh = m_box
	mesh_inst.position = Vector3(0.0, 0.525, 0.0)
	mesh_inst.material_override = LowPolyMeshLibrary.make_rune_block_material(world_index)
	add_child(mesh_inst)


func apply_push(dir: Vector3) -> void:
	_push_velocity = dir * push_speed


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.1
	velocity.x = _push_velocity.x
	velocity.z = _push_velocity.z
	move_and_slide()
	_push_velocity = _push_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	if global_position.y < -10.0:
		reset_block()


func reset_block() -> void:
	global_position = initial_position
	velocity = Vector3.ZERO
	_push_velocity = Vector3.ZERO
