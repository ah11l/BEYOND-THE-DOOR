class_name CheckpointPad
extends Node3D

## Glowing floor checkpoint sigil that updates respawn point and persists locally.

signal checkpoint_reached(checkpoint_id: String, spawn_pos: Vector3)

@export var checkpoint_id: String = "cp_1"
var activated: bool = false
var _ring_mat: StandardMaterial3D


func _ready() -> void:
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.72
	cyl.bottom_radius = 0.78
	cyl.height = 0.06
	cyl.radial_segments = 8
	disc.mesh = cyl
	disc.position = Vector3(0.0, 0.03, 0.0)
	_ring_mat = LowPolyMeshLibrary.make_flat_material(Color(0.32, 0.56, 0.78), 0.4, Color(0.28, 0.78, 1.0), 0.5)
	disc.material_override = _ring_mat
	add_child(disc)

	var sym := Label3D.new()
	sym.text = "✦"
	sym.font_size = 52
	sym.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	sym.position = Vector3(0.0, 0.08, 0.0)
	sym.modulate = Color(0.85, 0.96, 1.0)
	add_child(sym)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.9
	shape.shape = sph
	shape.position = Vector3(0.0, 0.5, 0.0)
	area.add_child(shape)
	area.body_entered.connect(_on_player_entered)
	add_child(area)


func _on_player_entered(_body: Node) -> void:
	if activated:
		return
	activated = true
	if _ring_mat != null:
		_ring_mat.emission_energy_multiplier = 2.2
	AudioManager.play_sfx("checkpoint")
	checkpoint_reached.emit(checkpoint_id, global_position + Vector3(0.0, 0.2, 0.0))
