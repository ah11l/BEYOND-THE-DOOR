class_name CheckpointPad
extends Node3D

## Sleek glowing torus-ring floor checkpoint sigil (no overexposed white disc) matching world accent.

signal checkpoint_reached(checkpoint_id: String, spawn_pos: Vector3)

@export var checkpoint_id: String = "cp_1"
@export var world_index: int = 1
var activated: bool = false
var _outer_mat: StandardMaterial3D
var _inner_mat: StandardMaterial3D
var _spark: MeshInstance3D = null
var _t: float = 0.0


func _ready() -> void:
	var pal := LowPolyMeshLibrary.get_world_palette(world_index)
	var glow_col: Color = pal.get("rune_glow", Color(0.32, 0.88, 1.0))

	# Subtle dark stone inset ring base
	var base := MeshInstance3D.new()
	var b_cyl := CylinderMesh.new()
	b_cyl.top_radius = 0.66
	b_cyl.bottom_radius = 0.72
	b_cyl.height = 0.03
	b_cyl.radial_segments = 16
	base.mesh = b_cyl
	base.position = Vector3(0.0, 0.015, 0.0)
	base.material_override = LowPolyMeshLibrary.make_flat_material(Color(0.10, 0.13, 0.20), 0.78)
	add_child(base)

	# Sleek glowing outer rune torus ring
	var outer := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.54
	tor.outer_radius = 0.68
	tor.rings = 24
	tor.ring_segments = 8
	outer.mesh = tor
	outer.position = Vector3(0.0, 0.05, 0.0)
	_outer_mat = LowPolyMeshLibrary.make_flat_material(glow_col, 0.25, glow_col, 0.85)
	outer.material_override = _outer_mat
	add_child(outer)

	# Inner delicate halo ring
	var inner := MeshInstance3D.new()
	var itor := TorusMesh.new()
	itor.inner_radius = 0.34
	itor.outer_radius = 0.40
	itor.rings = 20
	itor.ring_segments = 6
	inner.mesh = itor
	inner.position = Vector3(0.0, 0.045, 0.0)
	_inner_mat = LowPolyMeshLibrary.make_flat_material(glow_col.lightened(0.25), 0.25, glow_col, 0.45)
	inner.material_override = _inner_mat
	add_child(inner)

	# Tiny floating center crystal spark
	_spark = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.08
	sph.height = 0.16
	sph.radial_segments = 6
	sph.rings = 3
	_spark.mesh = sph
	_spark.position = Vector3(0.0, 0.22, 0.0)
	_spark.material_override = LowPolyMeshLibrary.make_flat_material(glow_col.lightened(0.35), 0.15, glow_col, 1.35)
	add_child(_spark)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sph_col := SphereShape3D.new()
	sph_col.radius = 0.9
	shape.shape = sph_col
	shape.position = Vector3(0.0, 0.5, 0.0)
	area.add_child(shape)
	area.body_entered.connect(_on_player_entered)
	add_child(area)


func _process(delta: float) -> void:
	_t += delta
	if _spark != null:
		_spark.position.y = 0.22 + sin(_t * 2.6) * 0.05
		_spark.rotation.y += delta * 1.4


func _on_player_entered(_body: Node) -> void:
	if activated:
		return
	activated = true
	if _outer_mat != null:
		_outer_mat.emission_energy_multiplier = 1.85
	if _inner_mat != null:
		_inner_mat.emission_energy_multiplier = 1.45
	AudioManager.play_sfx("checkpoint")
	checkpoint_reached.emit(checkpoint_id, global_position + Vector3(0.0, 0.2, 0.0))
