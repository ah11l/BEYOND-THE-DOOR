class_name GuardianBoss
extends Node3D

## 6 Distinct World Boss Archetypes (Stages 5, 20, 40, 60, 80, 100, 120):
## - World 1: Forgotten Sentinel (single cyan-violet shockwave ring)
## - World 2: Whispering Warden (twin staggered emerald-cyan rings)
## - World 3: Clockwork Arbiter (orbiting gear crown + fast bronze shockwave)
## - World 4: Abyss Watcher (obsidian twin-pillar aura + wide dark-teal wave)
## - World 5: Echo of Fear (translucent cyan mirror doppelganger + rapid double pulse)
## - World 6: The Final Architect Echo (radiant golden crown + triple harmonic seal)

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
var _attack_timer: float = 3.2
var _defeated: bool = false
var _accent: Color = Color(0.84, 0.42, 0.92)


func _ready() -> void:
	_build_visuals()


func _build_visuals() -> void:
	var accents := {
		1: Color(0.76, 0.42, 0.94),
		2: Color(0.24, 0.86, 0.78),
		3: Color(0.92, 0.66, 0.34),
		4: Color(0.28, 0.76, 0.94),
		5: Color(0.32, 0.92, 1.0),
		6: Color(1.0, 0.80, 0.34),
	}
	_accent = accents.get(clampi(world_index, 1, 6), Color(0.84, 0.42, 0.92)) as Color

	var body_mat: Material
	if is_echo_boss or world_index == 5:
		var sh_mat := ShaderMaterial.new()
		var sh := load("res://assets/shaders/echo_ghost.gdshader")
		if sh != null:
			sh_mat.shader = sh
		body_mat = sh_mat
	else:
		body_mat = LowPolyMeshLibrary.make_flat_material(Color(0.10, 0.09, 0.18), 0.72)

	var glow_mat := LowPolyMeshLibrary.make_flat_material(_accent, 0.15, _accent, 2.1)

	_core = Node3D.new()
	add_child(_core)

	var robe := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.90
	cm.height = 2.6
	cm.radial_segments = 8
	robe.mesh = cm
	robe.material_override = body_mat
	_core.add_child(robe)

	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.54
	hm.height = 1.06
	hm.radial_segments = 8
	hm.rings = 4
	head.mesh = hm
	head.position = Vector3(0.0, 1.55, 0.0)
	head.material_override = body_mat
	_core.add_child(head)

	# World-specific crown / silhouette distinction
	var crown_spokes := 3 if world_index <= 2 else (6 if world_index <= 4 else 8)
	for i in range(crown_spokes):
		var a := float(i) * (TAU / float(crown_spokes))
		var shard := MeshInstance3D.new()
		var sc := CylinderMesh.new()
		sc.top_radius = 0.02
		sc.bottom_radius = 0.12
		sc.height = 0.85
		sc.radial_segments = 4
		shard.mesh = sc
		shard.position = Vector3(cos(a) * 0.72, 2.25, sin(a) * 0.72)
		shard.rotation = Vector3(sin(a) * 0.35, a, -cos(a) * 0.35)
		shard.material_override = glow_mat
		_core.add_child(shard)

	for ex in [-0.16, 0.16]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.095
		em.height = 0.19
		eye.mesh = em
		eye.position = Vector3(ex, 1.58, 0.46)
		eye.material_override = glow_mat
		_core.add_child(eye)

	_ring_a = MeshInstance3D.new()
	var ta := TorusMesh.new()
	ta.inner_radius = 1.40
	ta.outer_radius = 1.54
	ta.rings = 24
	ta.ring_segments = 6
	_ring_a.mesh = ta
	_ring_a.material_override = glow_mat
	_core.add_child(_ring_a)

	_ring_b = MeshInstance3D.new()
	var tb := TorusMesh.new()
	tb.inner_radius = 1.85
	tb.outer_radius = 1.96
	tb.rings = 24
	tb.ring_segments = 6
	_ring_b.mesh = tb
	tb.rings = 24
	_ring_b.rotation_degrees = Vector3(65.0, 20.0, 0.0)
	_ring_b.material_override = glow_mat
	_core.add_child(_ring_b)

	_light = OmniLight3D.new()
	_light.light_color = _accent
	_light.light_energy = 2.2
	_light.omni_range = 11.0
	_light.shadow_enabled = false
	_core.add_child(_light)


func _get_attack_interval() -> float:
	var base := 5.0 - float(clampi(world_index, 1, 6)) * 0.25
	match SaveManager.get_difficulty():
		"story":
			return base + 1.8
		"master":
			return maxf(2.6, base - 1.1)
		_:
			return base


func _process(delta: float) -> void:
	if _defeated or _core == null:
		return
	_t += delta
	_core.position.y = sin(_t * 1.45) * 0.36
	if _ring_a != null:
		_ring_a.rotation.y += delta * (1.0 + float(world_index) * 0.15)
		_ring_a.rotation.x = sin(_t * 0.8) * 0.25
	if _ring_b != null:
		_ring_b.rotation.z -= delta * 0.95

	if player_ref != null and is_instance_valid(player_ref) and not player_ref.movement_locked:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = _get_attack_interval()
			_emit_boss_pattern()


func _emit_boss_pattern() -> void:
	if get_parent() == null:
		return
	var charge_tw := create_tween()
	charge_tw.tween_property(_core, "scale", Vector3(1.24, 1.24, 1.24), 0.35).set_trans(Tween.TRANS_SINE)
	charge_tw.tween_property(_core, "scale", Vector3.ONE, 0.25)
	charge_tw.tween_callback(_spawn_expanding_ring)
	# Worlds 2, 5, 6 emit a dramatic staggered second harmonic ring!
	if world_index in [2, 5, 6]:
		charge_tw.tween_interval(0.55)
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
	mat.albedo_color = Color(_accent.r, _accent.g, _accent.b, 0.76)
	mat.emission_enabled = true
	mat.emission = _accent
	mat.emission_energy_multiplier = 1.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat

	var origin := Vector3(global_position.x, arena_floor_y + 0.20, global_position.z)
	ring.position = origin
	ring.scale = Vector3(0.4, 0.4, 0.4)
	get_parent().add_child(ring)

	var hit_state := {"hit": false}
	var max_r := 13.5
	var dur := 2.5 - float(clampi(world_index, 1, 6)) * 0.08
	var tw := create_tween()
	tw.tween_method(func(r: float) -> void:
		if not is_instance_valid(ring):
			return
		ring.scale = Vector3(r, 0.55, r)
		mat.albedo_color.a = clampf(1.0 - (r / max_r), 0.0, 0.78)
		if not hit_state["hit"] and player_ref != null and is_instance_valid(player_ref) and not player_ref.movement_locked:
			var p := player_ref.global_position
			var dist_xz := Vector2(p.x - origin.x, p.z - origin.z).length()
			var dy := p.y - arena_floor_y
			if absf(dist_xz - r) < 0.42 and dy < 0.46 and dy > -0.8:
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
	AudioManager.play_sfx("key_pickup")
	var tw := create_tween()
	tw.tween_property(_core, "scale", Vector3(1.25, 1.25, 1.25), 0.16).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_core, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_SINE)


func on_door_unlocked() -> void:
	if _defeated:
		return
	_defeated = true
	AudioManager.play_sfx("door_open")
	boss_spoke.emit("boss_w%d_defeated" % clampi(world_index, 1, 6))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.6, 1.6, 1.6), 0.25).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_property(self, "scale", Vector3(0.02, 0.02, 0.02), 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if _light != null:
		tw.parallel().tween_property(_light, "light_energy", 0.0, 0.95)
	tw.chain().tween_callback(queue_free)
