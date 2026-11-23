class_name GuardianBoss
extends Node3D

## Interactive World-Finale Puzzle-Platformer Boss (Stages 20, 40, 60, 80, 100, 120):
## - Hovering Guardian/Echo Sentinel watching the arena with orbiting seal rings
## - Emits telegraphed expanding 3D floor shockwave rings that the player can jump over to dodge
## - Tracks remaining puzzle seals (keys/switches) and shatters dramatically when the exit unlocks

signal boss_spoke(message_key: String)
signal player_hit_by_shockwave

@export var world_index: int = 1
@export var is_echo_boss: bool = false

var player_ref: PlayerController = null
var arena_floor_y: float = 0.0

var _core: Node3D
var _ring_a: MeshInstance3D
var _ring_b: MeshInstance3D
var _light: OmniLight3D
var _t: float = 0.0
var _attack_timer: float = 2.6
var _defeated: bool = false
var _accent: Color = Color(0.84, 0.42, 0.92)


func _ready() -> void:
	_build_visuals()


func _build_visuals() -> void:
	_accent = Color(0.26, 0.88, 1.0) if is_echo_boss else Color(0.84, 0.42, 0.92)
	if world_index == 6:
		_accent = Color(1.0, 0.78, 0.34)
	var body_mat := LowPolyMeshLibrary.make_flat_material(Color(0.10, 0.09, 0.18), 0.75)
	var glow_mat := LowPolyMeshLibrary.make_flat_material(_accent, 0.15, _accent, 2.0)

	_core = Node3D.new()
	add_child(_core)

	var robe := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.85
	cm.height = 2.4
	cm.radial_segments = 8
	robe.mesh = cm
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
	_light.light_color = _accent
	_light.light_energy = 2.0
	_light.omni_range = 10.0
	_light.shadow_enabled = false
	_core.add_child(_light)


func _get_attack_interval() -> float:
	match SaveManager.get_difficulty():
		"story":
			return 6.0
		"master":
			return 3.4
		_:
			return 4.6


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

	# Periodic telegraphed shockwave pulse when player is nearby
	if player_ref != null and is_instance_valid(player_ref) and not player_ref.movement_locked:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = _get_attack_interval()
			_emit_shockwave_ring()


func _emit_shockwave_ring() -> void:
	if get_parent() == null:
		return
	# Brief visual telegraph on boss core before launching ground ring
	var charge_tw := create_tween()
	charge_tw.tween_property(_core, "scale", Vector3(1.22, 1.22, 1.22), 0.35).set_trans(Tween.TRANS_SINE)
	charge_tw.tween_property(_core, "scale", Vector3.ONE, 0.25)
	charge_tw.tween_callback(_spawn_expanding_ring)


func _spawn_expanding_ring() -> void:
	if _defeated or get_parent() == null:
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.88
	torus.outer_radius = 1.0
	torus.rings = 28
	torus.ring_segments = 6
	ring.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(_accent.r, _accent.g, _accent.b, 0.72)
	mat.emission_enabled = true
	mat.emission = _accent
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat

	var origin := Vector3(global_position.x, arena_floor_y + 0.22, global_position.z)
	ring.position = origin
	ring.scale = Vector3(0.4, 0.4, 0.4)
	get_parent().add_child(ring)

	var hit_state := {"hit": false}
	var max_r := 13.5
	var dur := 2.4
	var tw := create_tween()
	tw.tween_method(func(r: float) -> void:
		if not is_instance_valid(ring):
			return
		ring.scale = Vector3(r, 0.55, r)
		mat.albedo_color.a = clampf(1.0 - (r / max_r), 0.0, 0.75)
		if not hit_state["hit"] and player_ref != null and is_instance_valid(player_ref) and not player_ref.movement_locked:
			var p := player_ref.global_position
			var dist_xz := Vector2(p.x - origin.x, p.z - origin.z).length()
			var dy := p.y - arena_floor_y
			# Player can cleanly jump over the ring (dy >= 0.60m dodges it!)
			if absf(dist_xz - r) < 0.45 and dy < 0.58 and dy > -0.8:
				hit_state["hit"] = true
				player_hit_by_shockwave.emit()
	, 0.5, max_r, dur).set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)


func react_to_progress() -> void:
	if _defeated or _core == null:
		return
	var tw := create_tween()
	tw.tween_property(_core, "scale", Vector3(1.20, 1.20, 1.20), 0.16).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_core, "scale", Vector3.ONE, 0.26).set_trans(Tween.TRANS_SINE)


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
