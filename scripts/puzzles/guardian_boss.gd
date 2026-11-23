class_name GuardianBoss
extends Node3D

## World-Finale Puzzle Boss Sentinel (Stages 20, 40, 60, 80, 100, 120):
## Hovering hooded/crystalline Guardian or Echo Boss watching the arena.
## Reacts dynamically as the player solves locks/keys/plates and disperses when the exit opens.

signal boss_spoke(message_key: String)

@export var world_index: int = 1
@export var is_echo_boss: bool = false

var _core: Node3D
var _ring_a: MeshInstance3D
var _ring_b: MeshInstance3D
var _light: OmniLight3D
var _t: float = 0.0
var _defeated: bool = false


func _ready() -> void:
	_build_visuals()


func _build_visuals() -> void:
	var accent := Color(0.26, 0.88, 1.0) if is_echo_boss else Color(0.84, 0.42, 0.92)
	if world_index == 6:
		accent = Color(1.0, 0.78, 0.34)
	var body_mat := LowPolyMeshLibrary.make_flat_material(Color(0.10, 0.09, 0.18), 0.75)
	var glow_mat := LowPolyMeshLibrary.make_flat_material(accent, 0.15, accent, 2.2)

	_core = Node3D.new()
	add_child(_core)

	# Tall hovering cloaked sentinel silhouette
	var robe := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.85
	cm.height = 2.4
	cm.radial_segments = 8
	robe.mesh = cm
	robe.position = Vector3(0.0, 0.0, 0.0)
	robe.material_override = body_mat
	_core.add_child(robe)

	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.52
	hm.height = 1.02
	hm.radial_segments = 8
	hm.rings = 4
	head.mesh = hm
	head.position = Vector3(0.0, 1.45, 0.0)
	head.material_override = body_mat
	_core.add_child(head)

	for ex in [-0.15, 0.15]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.09
		em.height = 0.18
		eye.mesh = em
		eye.position = Vector3(ex, 1.48, 0.44)
		eye.material_override = glow_mat
		_core.add_child(eye)

	# Orbiting energy seal rings
	_ring_a = MeshInstance3D.new()
	var ta := TorusMesh.new()
	ta.inner_radius = 1.35
	ta.outer_radius = 1.48
	ta.rings = 24
	ta.ring_segments = 6
	_ring_a.mesh = ta
	_ring_a.material_override = glow_mat
	_core.add_child(_ring_a)

	_ring_b = MeshInstance3D.new()
	var tb := TorusMesh.new()
	tb.inner_radius = 1.75
	tb.outer_radius = 1.84
	tb.rings = 24
	tb.ring_segments = 6
	_ring_b.mesh = tb
	_ring_b.rotation_degrees = Vector3(65.0, 20.0, 0.0)
	_ring_b.material_override = glow_mat
	_core.add_child(_ring_b)

	_light = OmniLight3D.new()
	_light.light_color = accent
	_light.light_energy = 2.2
	_light.omni_range = 10.0
	_light.shadow_enabled = false
	_core.add_child(_light)


func _process(delta: float) -> void:
	if _defeated or _core == null:
		return
	_t += delta
	_core.position.y = sin(_t * 1.4) * 0.35
	if _ring_a != null:
		_ring_a.rotation.y += delta * 1.1
		_ring_a.rotation.x = sin(_t * 0.8) * 0.25
	if _ring_b != null:
		_ring_b.rotation.z -= delta * 0.85


func react_to_progress() -> void:
	if _defeated or _core == null:
		return
	var tw := create_tween()
	tw.tween_property(_core, "scale", Vector3(1.18, 1.18, 1.18), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_core, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_SINE)


func on_door_unlocked() -> void:
	if _defeated:
		return
	_defeated = true
	boss_spoke.emit("boss_w%d_defeated" % clampi(world_index, 1, 6))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if _light != null:
		tw.tween_property(_light, "light_energy", 0.0, 0.85)
	tw.chain().tween_callback(queue_free)
