class_name WorldLandmarks
extends Node3D

## Builds visually distinct, animated giant 3D architectural landmarks for each of the 6 worlds:
## - World 1 (Forgotten Islands): Towering broken ruin archways & drifting monoliths
## - World 2 (Whispering Forest): Colossal glowing spirit trees & animated cyan firefly swarm
## - World 3 (City of Stopped Clocks): Giant rotating clockwork gears & bronze pendulums
## - World 4 (The Silent Abyss): Abyssal obsidian spires & rising dark-teal energy columns
## - World 5 (Sea of Mirrors): Floating rotating crystal mirror monoliths & drifting glass shards
## - World 6 (Beyond the Door): Giant orbiting golden astral rings & Architect's sky sanctuary

@export var world_index: int = 1
@export var arena_center: Vector3 = Vector3.ZERO
@export var arena_span: float = 16.0

var _spinners: Array[Node3D] = []
var _floaters: Array[Node3D] = []
var _fireflies: MultiMeshInstance3D = null
var _firefly_base: Array[Vector3] = []
var _t: float = 0.0


func build_for_world(w_idx: int, center: Vector3, span: float) -> void:
	world_index = clampi(w_idx, 1, 6)
	arena_center = center
	arena_span = maxf(span, 12.0)
	position = arena_center

	match world_index:
		1:
			_build_world_1_ruins()
		2:
			_build_world_2_whispering_forest()
		3:
			_build_world_3_clockwork_city()
		4:
			_build_world_4_silent_abyss()
		5:
			_build_world_5_sea_of_mirrors()
		6:
			_build_world_6_beyond_the_door()


func _build_world_1_ruins() -> void:
	## Colossal broken ancient ruin archway framing the horizon + drifting stone obelisks
	var stone_mat := LowPolyMeshLibrary.make_textured_material(LowPolyMeshLibrary.TEX_CLIFF_ROCK, Color(0.75, 0.72, 0.90), 0.88, Vector3(0.22, 0.22, 0.22), true)
	var rune_mat := LowPolyMeshLibrary.make_flat_material(Color(0.28, 0.86, 1.0), 0.2, Color(0.24, 0.84, 1.0), 1.4)
	var r := arena_span * 0.72 + 7.5

	var arch := Node3D.new()
	arch.position = Vector3(-r * 0.55, -2.5, -r * 0.75)
	arch.rotation_degrees.y = 32.0
	add_child(arch)
	for sx in [-4.2, 4.2]:
		var col := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.6, 14.0, 1.6)
		col.mesh = b
		col.position = Vector3(sx, 7.0, 0.0)
		col.material_override = stone_mat
		arch.add_child(col)
	var beam := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(11.2, 1.5, 2.0)
	beam.mesh = bb
	beam.position = Vector3(0.0, 14.2, 0.0)
	beam.material_override = stone_mat
	arch.add_child(beam)

	for i in range(4):
		var ang := float(i) * (TAU / 4.0) + 0.5
		var ob := Node3D.new()
		ob.position = Vector3(cos(ang) * (r + 3.0), -1.0 + float(i % 2) * 3.0, sin(ang) * (r + 3.0))
		var m := MeshInstance3D.new()
		var mb := BoxMesh.new()
		mb.size = Vector3(1.2, 5.2, 1.2)
		m.mesh = mb
		m.material_override = stone_mat
		ob.add_child(m)
		var band := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(1.32, 0.35, 1.32)
		band.mesh = rbox
		band.position.y = 0.8
		band.material_override = rune_mat
		ob.add_child(band)
		add_child(ob)
		_floaters.append(ob)


func _build_world_2_whispering_forest() -> void:
	## Colossal distant glowing spirit trees + animated floating cyan firefly swarm
	var r := arena_span * 0.70 + 8.0
	for i in range(5):
		var ang := float(i) * (TAU / 5.0) - 0.6
		var tr := LowPolyMeshLibrary.create_low_poly_tree(Color(0.20, 0.60, 0.70), 3.4, (i % 2 == 0))
		tr.position = Vector3(cos(ang) * r, -4.5, sin(ang) * r)
		add_child(tr)

	# Animated cyan fireflies hovering across the stage
	var count := 28
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sph := SphereMesh.new()
	sph.radius = 0.09
	sph.height = 0.18
	sph.radial_segments = 5
	sph.rings = 3
	mm.mesh = sph
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in range(count):
		var p := Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(0.8, 6.2), rng.randf_range(-12.0, 12.0))
		_firefly_base.append(p)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
	_fireflies = MultiMeshInstance3D.new()
	_fireflies.multimesh = mm
	_fireflies.material_override = LowPolyMeshLibrary.make_flat_material(Color(0.45, 0.96, 1.0), 0.1, Color(0.32, 0.94, 1.0), 2.4)
	add_child(_fireflies)


func _build_world_3_clockwork_city() -> void:
	## Giant rotating clockwork gears & bronze rims in the twilight sky
	var bronze_mat := LowPolyMeshLibrary.make_flat_material(Color(0.56, 0.42, 0.28), 0.55)
	var glow_mat := LowPolyMeshLibrary.make_flat_material(Color(0.76, 0.46, 0.96), 0.2, Color(0.76, 0.46, 0.96), 1.4)
	var r := arena_span * 0.68 + 8.5

	var gear_specs := [
		{"pos": Vector3(-r * 0.6, 2.5, -r * 0.75), "rad": 5.5, "rot": Vector3(18.0, 28.0, 0.0)},
		{"pos": Vector3(r * 0.65, 4.0, -r * 0.65), "rad": 4.2, "rot": Vector3(-12.0, -35.0, 0.0)},
		{"pos": Vector3(0.0, -5.5, -r * 0.90), "rad": 7.2, "rot": Vector3(72.0, 0.0, 0.0)},
	]
	for gs in gear_specs:
		var gear := Node3D.new()
		gear.position = gs["pos"] as Vector3
		gear.rotation_degrees = gs["rot"] as Vector3
		var rad := float(gs["rad"])

		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = rad * 0.76
		torus.outer_radius = rad
		torus.rings = 20
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = bronze_mat
		gear.add_child(ring)

		# Gear teeth & inner spokes
		for t_i in range(8):
			var a := float(t_i) * (TAU / 8.0)
			var tooth := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(rad * 0.22, 0.55, rad * 0.35)
			tooth.mesh = tb
			tooth.position = Vector3(cos(a) * rad * 1.05, 0.0, sin(a) * rad * 1.05)
			tooth.rotation.y = -a
			tooth.material_override = bronze_mat
			gear.add_child(tooth)

		var hub := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = rad * 0.20
		hs.height = rad * 0.40
		hub.mesh = hs
		hub.material_override = glow_mat
		gear.add_child(hub)

		add_child(gear)
		_spinners.append(gear)


func _build_world_4_silent_abyss() -> void:
	## Tall obsidian abyssal needles & rising luminous teal energy columns
	var obs_mat := LowPolyMeshLibrary.make_flat_material(Color(0.09, 0.11, 0.19), 0.72)
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(0.18, 0.68, 0.76, 0.24)
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(0.16, 0.66, 0.78)
	beam_mat.emission_energy_multiplier = 1.1
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var r := arena_span * 0.68 + 8.0

	for i in range(6):
		var ang := float(i) * (TAU / 6.0) + 0.3
		var spire := Node3D.new()
		spire.position = Vector3(cos(ang) * r, -6.0, sin(ang) * r)
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 1.4
		cyl.height = 18.0
		cyl.radial_segments = 5
		m.mesh = cyl
		m.position.y = 9.0
		m.material_override = obs_mat
		spire.add_child(m)

		if i % 2 == 0:
			var beam := MeshInstance3D.new()
			var bc := CylinderMesh.new()
			bc.top_radius = 0.35
			bc.bottom_radius = 0.55
			bc.height = 24.0
			bc.radial_segments = 8
			beam.mesh = bc
			beam.position.y = 12.0
			beam.material_override = beam_mat
			spire.add_child(beam)
		add_child(spire)
		_floaters.append(spire)


func _build_world_5_sea_of_mirrors() -> void:
	## Giant floating reflective/luminous crystal mirror slabs orbiting slowly around the arena
	var frame_mat := LowPolyMeshLibrary.make_flat_material(Color(0.24, 0.18, 0.34), 0.65)
	var mirror_mat := LowPolyMeshLibrary.make_flat_material(Color(0.58, 0.82, 0.98), 0.08, Color(0.45, 0.72, 0.96), 0.85)
	var r := arena_span * 0.66 + 7.5

	for i in range(6):
		var ang := float(i) * (TAU / 6.0)
		var slab := Node3D.new()
		slab.position = Vector3(cos(ang) * r, 1.5 + float(i % 2) * 2.5, sin(ang) * r)
		slab.rotation.y = -ang + PI * 0.5

		var frame := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(3.4, 7.6, 0.32)
		frame.mesh = fb
		frame.material_override = frame_mat
		slab.add_child(frame)

		var glass := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(2.85, 7.0, 0.38)
		glass.mesh = gb
		glass.material_override = mirror_mat
		slab.add_child(glass)

		add_child(slab)
		_floaters.append(slab)


func _build_world_6_beyond_the_door() -> void:
	## Colossal orbiting golden astral rings & Architect's sky sanctuary pillars
	var gold_mat := LowPolyMeshLibrary.make_flat_material(Color(0.95, 0.78, 0.36), 0.22, Color(0.95, 0.74, 0.30), 1.35)
	var cyan_mat := LowPolyMeshLibrary.make_flat_material(Color(0.30, 0.88, 1.0), 0.20, Color(0.26, 0.84, 1.0), 1.45)

	var ring_r := arena_span * 0.75 + 9.0
	for idx in range(2):
		var holder := Node3D.new()
		holder.position = Vector3(0.0, 4.0, -4.0)
		holder.rotation_degrees = Vector3(26.0 if idx == 0 else -32.0, 0.0, 18.0 if idx == 0 else -22.0)
		var m := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = ring_r + float(idx) * 3.5 - 0.25
		t.outer_radius = ring_r + float(idx) * 3.5 + 0.25
		t.rings = 40
		t.ring_segments = 6
		m.mesh = t
		m.material_override = gold_mat if idx == 0 else cyan_mat
		holder.add_child(m)
		add_child(holder)
		_spinners.append(holder)


func _process(delta: float) -> void:
	_t += delta
	for i in range(_spinners.size()):
		var sp := _spinners[i]
		if is_instance_valid(sp):
			var dir := 1.0 if (i % 2 == 0) else -1.0
			sp.rotation.y += delta * 0.22 * dir

	for i in range(_floaters.size()):
		var fl := _floaters[i]
		if is_instance_valid(fl):
			fl.position.y += sin(_t * 0.9 + float(i) * 1.3) * delta * 0.28

	if _fireflies != null and _fireflies.multimesh != null:
		var mm := _fireflies.multimesh
		for i in range(_firefly_base.size()):
			var b := _firefly_base[i]
			var p := b + Vector3(sin(_t * 0.8 + float(i)) * 0.8, sin(_t * 1.4 + float(i) * 0.7) * 0.45, cos(_t * 0.7 + float(i)) * 0.8)
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
