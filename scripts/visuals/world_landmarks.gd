class_name WorldLandmarks
extends Node3D

## Builds visually unmistakable, animated 3D architectural landmarks framed directly inside
## the isometric camera's visible background (-X, -Z quadrant at 7.5m-13.5m) for all 6 worlds:
## - World 1 (Forgotten Islands): Ancient glowing-rune ruin pillars & broken archways
## - World 2 (Whispering Forest): Towering misty emerald pines & dense glowing fireflies
## - World 3 (City of Stopped Clocks): Giant rotating antique-gold clockwork gears right behind the islands
## - World 4 (The Silent Abyss): Towering obsidian monoliths & rising luminous turquoise energy beams
## - World 5 (Sea of Mirrors): Giant floating silver-blue mirror slabs & drifting crystal shards
## - World 6 (Beyond the Door): Giant orbiting golden astral rings & sunlit marble sanctuary pillars

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
	arena_span = clampf(span, 10.0, 22.0)
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
	var stone_mat := LowPolyMeshLibrary.make_preloaded_material(LowPolyMeshLibrary.PRELOAD_WORLD_CLIFF[1], Color(0.86, 0.88, 0.98), 0.88, Vector3(0.25, 0.25, 0.25), true)
	var rune_mat := LowPolyMeshLibrary.make_flat_material(Color(0.28, 0.88, 1.0), 0.2, Color(0.24, 0.86, 1.0), 1.6)
	var d := arena_span * 0.45 + 4.5

	var positions: Array[Vector3] = [
		Vector3(-d * 0.9, -2.5, -d * 0.9),
		Vector3(d * 0.2, -3.0, -d * 1.05),
		Vector3(-d * 1.05, -2.0, d * 0.15),
		Vector3(-d * 0.35, -3.5, -d * 1.1),
	]
	for i in range(positions.size()):
		var ob := Node3D.new()
		ob.position = positions[i]
		var m := MeshInstance3D.new()
		var mb := BoxMesh.new()
		mb.size = Vector3(1.15, 7.5 + float(i % 2) * 2.5, 1.15)
		m.mesh = mb
		m.position.y = mb.size.y * 0.5
		m.material_override = stone_mat
		ob.add_child(m)
		var band := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(1.28, 0.38, 1.28)
		band.mesh = rbox
		band.position.y = mb.size.y * 0.72
		band.material_override = rune_mat
		ob.add_child(band)
		add_child(ob)
		_floaters.append(ob)


func _build_world_2_whispering_forest() -> void:
	## Distant rocky floating islets topped with deep-emerald pine trees + delicate tiny golden-cyan fireflies
	var d := arena_span * 0.48 + 5.2
	var spots: Array[Vector3] = [
		Vector3(-d * 0.95, -1.2, -d * 0.85),
		Vector3(-d * 0.20, -0.8, -d * 1.08),
		Vector3(d * 0.55, -1.4, -d * 0.95),
		Vector3(-d * 1.10, -1.0, d * 0.22),
	]
	for i in range(spots.size()):
		var p: Vector3 = spots[i]
		var holder := Node3D.new()
		holder.position = p
		var islet := MeshInstance3D.new()
		islet.mesh = LowPolyMeshLibrary.create_floating_island_mesh(Vector3(3.4, 2.4, 3.4), Color(0.84, 0.96, 0.90), Color(0.78, 0.90, 0.88), 200 + i, Color(0.14, 0.40, 0.28), 2)
		holder.add_child(islet)
		var tr := LowPolyMeshLibrary.create_low_poly_tree(Color(0.05, 0.22, 0.14), 1.45, true, 2)
		tr.position = Vector3(0.0, 0.0, 0.0)
		holder.add_child(tr)
		add_child(holder)
		_floaters.append(holder)

	var count := 36
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sph := SphereMesh.new()
	sph.radius = 0.032
	sph.height = 0.064
	sph.radial_segments = 5
	sph.rings = 3
	mm.mesh = sph
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in range(count):
		var p := Vector3(rng.randf_range(-10.0, 10.0), rng.randf_range(0.5, 4.4), rng.randf_range(-10.0, 10.0))
		_firefly_base.append(p)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
	_fireflies = MultiMeshInstance3D.new()
	_fireflies.multimesh = mm
	_fireflies.material_override = LowPolyMeshLibrary.make_flat_material(Color(0.65, 0.98, 0.88), 0.1, Color(0.45, 0.95, 0.84), 1.45)
	add_child(_fireflies)


func _build_world_3_clockwork_city() -> void:
	var bronze_mat := LowPolyMeshLibrary.make_flat_material(Color(0.84, 0.62, 0.28), 0.32, Color(0.82, 0.58, 0.22), 0.42)
	bronze_mat.metallic = 0.60
	var glow_mat := LowPolyMeshLibrary.make_flat_material(Color(1.0, 0.82, 0.38), 0.18, Color(1.0, 0.78, 0.32), 1.75)
	var d := arena_span * 0.44 + 4.5

	var gear_specs := [
		{"pos": Vector3(-d * 0.85, 2.2, -d * 0.85), "rad": 4.2, "rot": Vector3(58.0, 42.0, 0.0)},
		{"pos": Vector3(d * 0.25, 3.0, -d * 1.0), "rad": 3.4, "rot": Vector3(62.0, -28.0, 0.0)},
		{"pos": Vector3(-d * 1.05, 1.4, d * 0.15), "rad": 3.8, "rot": Vector3(68.0, 75.0, 0.0)},
	]
	for gs in gear_specs:
		var gear := Node3D.new()
		gear.position = gs["pos"] as Vector3
		gear.rotation_degrees = gs["rot"] as Vector3
		var rad := float(gs["rad"])

		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = rad * 0.74
		torus.outer_radius = rad
		torus.rings = 22
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = bronze_mat
		gear.add_child(ring)

		for t_i in range(10):
			var a := float(t_i) * (TAU / 10.0)
			var tooth := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(rad * 0.18, 0.45, rad * 0.30)
			tooth.mesh = tb
			tooth.position = Vector3(cos(a) * rad * 1.06, 0.0, sin(a) * rad * 1.06)
			tooth.rotation.y = -a
			tooth.material_override = bronze_mat
			gear.add_child(tooth)

		var hub := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = rad * 0.22
		hs.height = rad * 0.44
		hub.mesh = hs
		hub.material_override = glow_mat
		gear.add_child(hub)

		add_child(gear)
		_spinners.append(gear)


func _build_world_4_silent_abyss() -> void:
	var obs_mat := LowPolyMeshLibrary.make_preloaded_material(LowPolyMeshLibrary.PRELOAD_WORLD_CLIFF[4], Color(0.68, 0.80, 0.88), 0.72, Vector3(0.25, 0.25, 0.25), true)
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(0.18, 0.86, 0.92, 0.28)
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(0.16, 0.86, 0.94)
	beam_mat.emission_energy_multiplier = 1.65
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var d := arena_span * 0.44 + 4.4

	var spots: Array[Vector3] = [
		Vector3(-d * 0.9, -6.5, -d * 0.85),
		Vector3(-d * 0.1, -6.5, -d * 1.05),
		Vector3(d * 0.55, -6.5, -d * 0.90),
		Vector3(-d * 1.05, -6.5, d * 0.20),
	]
	for i in range(spots.size()):
		var spire := Node3D.new()
		spire.position = spots[i]
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.5, 16.0, 1.5)
		m.mesh = b
		m.position.y = 8.0
		m.material_override = obs_mat
		spire.add_child(m)

		var beam := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = 0.28
		bc.bottom_radius = 0.52
		bc.height = 24.0
		bc.radial_segments = 8
		beam.mesh = bc
		beam.position = Vector3(1.4 if i % 2 == 0 else -1.4, 10.0, 0.0)
		beam.material_override = beam_mat
		spire.add_child(beam)
		add_child(spire)
		_floaters.append(spire)


func _build_world_5_sea_of_mirrors() -> void:
	var frame_mat := LowPolyMeshLibrary.make_flat_material(Color(0.68, 0.76, 0.96), 0.25)
	frame_mat.metallic = 0.65
	var mirror_mat := LowPolyMeshLibrary.make_flat_material(Color(0.84, 0.92, 1.0), 0.05, Color(0.58, 0.78, 1.0), 0.95)
	mirror_mat.metallic = 0.85
	var shard_mat := LowPolyMeshLibrary.make_flat_material(Color(0.78, 0.94, 1.0), 0.12, Color(0.66, 0.88, 1.0), 1.35)
	var d := arena_span * 0.44 + 4.4

	var spots: Array[Vector3] = [
		Vector3(-d * 0.95, 2.0, -d * 0.75),
		Vector3(-d * 0.15, 2.8, -d * 1.02),
		Vector3(d * 0.55, 2.2, -d * 0.88),
		Vector3(-d * 1.05, 1.8, d * 0.25),
	]
	for i in range(spots.size()):
		var slab := Node3D.new()
		slab.position = spots[i]
		slab.rotation.y = atan2(-spots[i].x, -spots[i].z)

		var frame := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(2.8, 6.4, 0.28)
		frame.mesh = fb
		frame.material_override = frame_mat
		slab.add_child(frame)

		var glass := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(2.35, 5.9, 0.34)
		glass.mesh = gb
		glass.material_override = mirror_mat
		slab.add_child(glass)

		var shard := MeshInstance3D.new()
		var sc := CylinderMesh.new()
		sc.top_radius = 0.02
		sc.bottom_radius = 0.22
		sc.height = 2.2
		sc.radial_segments = 4
		shard.mesh = sc
		shard.position = Vector3(2.1, -0.8, 0.4)
		shard.material_override = shard_mat
		slab.add_child(shard)

		add_child(slab)
		_floaters.append(slab)


func _build_world_6_beyond_the_door() -> void:
	var gold_mat := LowPolyMeshLibrary.make_flat_material(Color(1.0, 0.84, 0.38), 0.18, Color(1.0, 0.78, 0.30), 1.60)
	gold_mat.metallic = 0.70
	var marble_mat := LowPolyMeshLibrary.make_preloaded_material(LowPolyMeshLibrary.PRELOAD_WORLD_TOP[6], Color(1.0, 0.98, 0.94), 0.55, Vector3(0.32, 0.32, 0.32), true)
	var d := arena_span * 0.44 + 4.4

	# Giant golden astral rings visible right behind the sanctuary islands
	var ring_specs := [
		{"pos": Vector3(-d * 0.85, 3.6, -d * 0.85), "r": 4.8, "rot": Vector3(68.0, 42.0, 0.0)},
		{"pos": Vector3(d * 0.30, 4.4, -d * 0.95), "r": 5.6, "rot": Vector3(72.0, -32.0, 0.0)},
	]
	for rs in ring_specs:
		var holder := Node3D.new()
		holder.position = rs["pos"] as Vector3
		holder.rotation_degrees = rs["rot"] as Vector3
		var rad := float(rs["r"])
		var m := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = rad - 0.24
		t.outer_radius = rad + 0.24
		t.rings = 36
		t.ring_segments = 6
		m.mesh = t
		m.material_override = gold_mat
		holder.add_child(m)
		add_child(holder)
		_spinners.append(holder)

	# White marble sanctuary pillars with gold trim
	var pil_spots: Array[Vector3] = [
		Vector3(-d * 1.05, -4.0, d * 0.15),
		Vector3(d * 0.55, -4.0, -d * 0.95),
		Vector3(-d * 0.30, -4.0, -d * 1.15),
	]
	for p: Vector3 in pil_spots:
		var pil := Node3D.new()
		pil.position = p
		var col := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.4, 14.0, 1.4)
		col.mesh = b
		col.position.y = 7.0
		col.material_override = marble_mat
		pil.add_child(col)
		var band := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(1.56, 0.45, 1.56)
		band.mesh = gb
		band.position.y = 9.5
		band.material_override = gold_mat
		pil.add_child(band)
		add_child(pil)
		_floaters.append(pil)


func _process(delta: float) -> void:
	_t += delta
	for i in range(_spinners.size()):
		var sp := _spinners[i]
		if is_instance_valid(sp):
			var dir := 1.0 if (i % 2 == 0) else -1.0
			sp.rotation.y += delta * 0.24 * dir

	for i in range(_floaters.size()):
		var fl := _floaters[i]
		if is_instance_valid(fl):
			fl.position.y += sin(_t * 0.9 + float(i) * 1.3) * delta * 0.24

	if _fireflies != null and _fireflies.multimesh != null:
		var mm := _fireflies.multimesh
		for i in range(_firefly_base.size()):
			var b := _firefly_base[i]
			var p := b + Vector3(sin(_t * 0.8 + float(i)) * 0.8, sin(_t * 1.4 + float(i) * 0.7) * 0.45, cos(_t * 0.7 + float(i)) * 0.8)
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
