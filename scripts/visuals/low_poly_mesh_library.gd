class_name LowPolyMeshLibrary
extends RefCounted

## Reusable procedural low-poly 3D mesh and material builder matching the visual reference:
## faceted floating islands, stylized geometric trees, benches, glowing lanterns, crystals,
## wooden bridges, rocks, and the hooded protagonist carrying a cyan lantern.

const WORLD_PALETTES := {
	1: {
		"name_key": "world_1_name",
		"top": Color(0.72, 0.65, 0.86),
		"side": Color(0.26, 0.20, 0.42),
		"accent": Color(0.84, 0.34, 0.68), # Magenta-pink tree crown
		"sky_top": Color(0.035, 0.055, 0.145),
		"sky_horizon": Color(0.24, 0.14, 0.36),
		"sky_bottom": Color(0.11, 0.08, 0.24),
		"fog": Color(0.16, 0.12, 0.28),
		"light": Color(0.92, 0.88, 1.0),
	},
	2: {
		"name_key": "world_2_name",
		"top": Color(0.36, 0.46, 0.74),
		"side": Color(0.16, 0.23, 0.46),
		"accent": Color(0.30, 0.78, 0.95), # Cyan-blue sky foliage
		"sky_top": Color(0.025, 0.065, 0.18),
		"sky_horizon": Color(0.11, 0.24, 0.42),
		"sky_bottom": Color(0.06, 0.11, 0.26),
		"fog": Color(0.10, 0.18, 0.34),
		"light": Color(0.68, 0.86, 1.0),
	},
	3: {
		"name_key": "world_3_name",
		"top": Color(0.55, 0.38, 0.68),
		"side": Color(0.28, 0.16, 0.40),
		"accent": Color(0.78, 0.42, 0.92), # Violet dual-state crown
		"sky_top": Color(0.07, 0.035, 0.16),
		"sky_horizon": Color(0.30, 0.14, 0.38),
		"sky_bottom": Color(0.14, 0.06, 0.24),
		"fog": Color(0.22, 0.11, 0.30),
		"light": Color(0.88, 0.72, 1.0),
	},
	4: {
		"name_key": "world_4_name",
		"top": Color(0.34, 0.36, 0.50),
		"side": Color(0.14, 0.15, 0.25),
		"accent": Color(0.42, 0.76, 0.72), # Pale teal-silver crown
		"sky_top": Color(0.02, 0.025, 0.065),
		"sky_horizon": Color(0.12, 0.14, 0.24),
		"sky_bottom": Color(0.04, 0.05, 0.11),
		"fog": Color(0.09, 0.11, 0.19),
		"light": Color(0.70, 0.80, 0.92),
	},
	5: {
		"name_key": "world_5_name",
		"top": Color(0.50, 0.39, 0.60),
		"side": Color(0.23, 0.17, 0.34),
		"accent": Color(0.92, 0.56, 0.42), # Warm fractured amber-rose
		"sky_top": Color(0.055, 0.035, 0.13),
		"sky_horizon": Color(0.32, 0.16, 0.30),
		"sky_bottom": Color(0.13, 0.07, 0.20),
		"fog": Color(0.20, 0.12, 0.24),
		"light": Color(0.95, 0.80, 0.82),
	},
	6: {
		"name_key": "world_6_name",
		"top": Color(0.46, 0.44, 0.68),
		"side": Color(0.18, 0.18, 0.36),
		"accent": Color(0.96, 0.78, 0.38), # Astral gold crown
		"sky_top": Color(0.025, 0.035, 0.12),
		"sky_horizon": Color(0.26, 0.20, 0.42),
		"sky_bottom": Color(0.09, 0.08, 0.22),
		"fog": Color(0.16, 0.14, 0.30),
		"light": Color(1.0, 0.90, 0.74),
	},
}


static func get_world_palette(world_index: int) -> Dictionary:
	return WORLD_PALETTES.get(clampi(world_index, 1, 6), WORLD_PALETTES[1])


static func make_flat_material(color: Color, roughness: float = 0.82, emission: Color = Color.BLACK, emission_energy: float = 0.0, use_vertex_color: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE if use_vertex_color else color
	mat.vertex_color_use_as_albedo = use_vertex_color
	mat.roughness = roughness
	mat.metallic = 0.05
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


static func create_floating_island_mesh(size: Vector3, top_color: Color, side_color: Color, seed_val: int = 1) -> ArrayMesh:
	## Builds a faceted low-poly floating island with triangulated quilted top
	## and a tapered crystalline stone underside (top surface sits at y = 0).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var thickness := maxf(size.y, 1.4)
	var sub_x := clampi(int(round(size.x / 1.4)), 2, 8)
	var sub_z := clampi(int(round(size.z / 1.4)), 2, 8)

	# Build top quilted grid at y = 0 (subtle micro-relief <= 0.03 for flat-shaded facets without affecting physics)
	var grid: Array = []
	for ix in range(sub_x + 1):
		var col: Array = []
		var u := float(ix) / float(sub_x)
		var x := lerpf(-hx, hx, u)
		for iz in range(sub_z + 1):
			var v := float(iz) / float(sub_z)
			var z := lerpf(-hz, hz, v)
			var is_edge := (ix == 0 or ix == sub_x or iz == 0 or iz == sub_z)
			var y_jitter := 0.0 if is_edge else rng.randf_range(-0.025, 0.025)
			col.append(Vector3(x, y_jitter, z))
		grid.append(col)

	for ix in range(sub_x):
		for iz in range(sub_z):
			var p00: Vector3 = grid[ix][iz]
			var p10: Vector3 = grid[ix + 1][iz]
			var p11: Vector3 = grid[ix + 1][iz + 1]
			var p01: Vector3 = grid[ix][iz + 1]
			var c1 := top_color.lightened(rng.randf_range(-0.06, 0.08))
			var c2 := top_color.lightened(rng.randf_range(-0.06, 0.08))
			_add_flat_tri(st, p00, p10, p11, c1)
			_add_flat_tri(st, p00, p11, p01, c2)

	# Upper rim + tapered underside
	var rim_y := -thickness * 0.42
	var bottom_tip := Vector3(rng.randf_range(-hx * 0.15, hx * 0.15), -thickness * 1.45, rng.randf_range(-hz * 0.15, hz * 0.15))

	var top_corners := [
		Vector3(-hx, 0.0, -hz),
		Vector3(hx, 0.0, -hz),
		Vector3(hx, 0.0, hz),
		Vector3(-hx, 0.0, hz),
	]
	var rim_corners := [
		Vector3(-hx * 0.90, rim_y, -hz * 0.90),
		Vector3(hx * 0.90, rim_y, -hz * 0.90),
		Vector3(hx * 0.90, rim_y, hz * 0.90),
		Vector3(-hx * 0.90, rim_y, hz * 0.90),
	]

	for i in range(4):
		var ni := (i + 1) % 4
		var shade := side_color.lightened(rng.randf_range(-0.05, 0.07))
		var deep_shade := side_color.darkened(rng.randf_range(0.12, 0.28))
		_add_flat_tri(st, top_corners[i], rim_corners[i], rim_corners[ni], shade)
		_add_flat_tri(st, top_corners[i], rim_corners[ni], top_corners[ni], shade.lightened(0.04))
		_add_flat_tri(st, rim_corners[i], bottom_tip, rim_corners[ni], deep_shade)

	var mesh := st.commit()
	mesh.surface_set_material(0, make_flat_material(Color.WHITE, 0.86, Color.BLACK, 0.0, true))
	return mesh


static func _add_flat_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.length_squared() < 0.0001:
		normal = Vector3.UP
	st.set_color(color)
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_color(color)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_color(color)
	st.set_normal(normal)
	st.add_vertex(c)


static func create_low_poly_tree(crown_color: Color, scale_factor: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "LowPolyTree"

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.14 * scale_factor
	trunk_mesh.bottom_radius = 0.24 * scale_factor
	trunk_mesh.height = 1.35 * scale_factor
	trunk_mesh.radial_segments = 6
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0.0, 0.67 * scale_factor, 0.0)
	trunk.material_override = make_flat_material(Color(0.32, 0.20, 0.22), 0.9)
	root.add_child(trunk)

	var puffs := [
		{"pos": Vector3(0.0, 1.75, 0.0), "r": 0.95, "c": crown_color},
		{"pos": Vector3(-0.68, 1.52, 0.24), "r": 0.64, "c": crown_color.darkened(0.10)},
		{"pos": Vector3(0.62, 1.55, -0.18), "r": 0.60, "c": crown_color.lightened(0.10)},
	]
	for p in puffs:
		var crown := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = float(p["r"]) * scale_factor
		sphere.height = float(p["r"]) * 1.65 * scale_factor
		sphere.radial_segments = 7
		sphere.rings = 3
		crown.mesh = sphere
		crown.position = (p["pos"] as Vector3) * scale_factor
		crown.material_override = make_flat_material(p["c"] as Color, 0.78)
		root.add_child(crown)

	return root


static func create_bench() -> Node3D:
	var root := Node3D.new()
	root.name = "Bench"
	var wood_mat := make_flat_material(Color(0.34, 0.22, 0.20), 0.85)

	var seat := MeshInstance3D.new()
	var seat_box := BoxMesh.new()
	seat_box.size = Vector3(1.5, 0.12, 0.48)
	seat.mesh = seat_box
	seat.position = Vector3(0.0, 0.42, 0.0)
	seat.material_override = wood_mat
	root.add_child(seat)

	for lx in [-0.58, 0.58]:
		var leg := MeshInstance3D.new()
		var leg_box := BoxMesh.new()
		leg_box.size = Vector3(0.12, 0.42, 0.40)
		leg.mesh = leg_box
		leg.position = Vector3(lx, 0.21, 0.0)
		leg.material_override = wood_mat.duplicate()
		root.add_child(leg)
	return root


static func create_lantern_prop(glow_color: Color = Color(1.0, 0.78, 0.32), add_light: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "StoneLantern"
	var dark_mat := make_flat_material(Color(0.22, 0.17, 0.28), 0.75)
	var glow_mat := make_flat_material(glow_color, 0.2, glow_color, 2.2)

	var base := MeshInstance3D.new()
	var base_box := BoxMesh.new()
	base_box.size = Vector3(0.42, 0.10, 0.42)
	base.mesh = base_box
	base.position = Vector3(0.0, 0.05, 0.0)
	base.material_override = dark_mat
	root.add_child(base)

	var core := MeshInstance3D.new()
	var core_box := BoxMesh.new()
	core_box.size = Vector3(0.28, 0.36, 0.28)
	core.mesh = core_box
	core.position = Vector3(0.0, 0.28, 0.0)
	core.material_override = glow_mat
	root.add_child(core)

	var cap := MeshInstance3D.new()
	var cap_box := BoxMesh.new()
	cap_box.size = Vector3(0.44, 0.08, 0.44)
	cap.mesh = cap_box
	cap.position = Vector3(0.0, 0.50, 0.0)
	cap.material_override = dark_mat
	root.add_child(cap)

	if add_light:
		var light := OmniLight3D.new()
		light.light_color = glow_color
		light.light_energy = 1.4
		light.omni_range = 4.5
		light.position = Vector3(0.0, 0.42, 0.0)
		root.add_child(light)

	return root


static func create_crystal_cluster(color: Color = Color(0.25, 0.84, 1.0)) -> Node3D:
	var root := Node3D.new()
	root.name = "CrystalCluster"
	var mat := make_flat_material(color, 0.22, color, 1.55)
	var specs := [
		{"pos": Vector3(0.0, 0.55, 0.0), "r": 0.22, "h": 1.15, "rot": Vector3(0.0, 0.0, 0.0)},
		{"pos": Vector3(-0.24, 0.36, 0.12), "r": 0.14, "h": 0.72, "rot": Vector3(0.18, 0.4, 0.25)},
		{"pos": Vector3(0.22, 0.30, -0.10), "r": 0.13, "h": 0.62, "rot": Vector3(-0.15, 0.2, -0.28)},
	]
	for sp in specs:
		var m := MeshInstance3D.new()
		var prism := CylinderMesh.new()
		prism.top_radius = 0.01
		prism.bottom_radius = float(sp["r"])
		prism.height = float(sp["h"])
		prism.radial_segments = 5
		m.mesh = prism
		m.position = sp["pos"] as Vector3
		m.rotation = sp["rot"] as Vector3
		m.material_override = mat
		root.add_child(m)
	return root


static func create_rock(color: Color, scale_factor: float = 1.0) -> MeshInstance3D:
	var rock := MeshInstance3D.new()
	rock.name = "LowPolyRock"
	var sphere := SphereMesh.new()
	sphere.radius = 0.38 * scale_factor
	sphere.height = 0.54 * scale_factor
	sphere.radial_segments = 6
	sphere.rings = 2
	rock.mesh = sphere
	rock.position = Vector3(0.0, 0.18 * scale_factor, 0.0)
	rock.material_override = make_flat_material(color, 0.90)
	return rock


static func build_hooded_character(is_ghost: bool = false) -> Node3D:
	## Builds the small hooded/masked protagonist with dark cloak and cyan glowing lantern.
	var rig := Node3D.new()
	rig.name = "CharacterRig"

	var cloak_mat: Material
	var eye_mat: Material
	var lantern_mat: Material

	if is_ghost:
		var sh_mat := ShaderMaterial.new()
		var sh := load("res://assets/shaders/echo_ghost.gdshader")
		if sh != null:
			sh_mat.shader = sh
		cloak_mat = sh_mat
		eye_mat = make_flat_material(Color(0.75, 0.98, 1.0), 0.1, Color(0.55, 0.96, 1.0), 2.8)
		lantern_mat = make_flat_material(Color(0.55, 0.96, 1.0), 0.1, Color(0.45, 0.95, 1.0), 3.2)
	else:
		cloak_mat = make_flat_material(Color(0.11, 0.11, 0.18), 0.85)
		eye_mat = make_flat_material(Color(1.0, 0.84, 0.45), 0.1, Color(1.0, 0.78, 0.30), 2.6)
		lantern_mat = make_flat_material(Color(0.28, 0.92, 1.0), 0.1, Color(0.24, 0.88, 1.0), 3.2)

	# Cloak body
	var cloak := MeshInstance3D.new()
	var cloak_mesh := CylinderMesh.new()
	cloak_mesh.top_radius = 0.18
	cloak_mesh.bottom_radius = 0.36
	cloak_mesh.height = 0.82
	cloak_mesh.radial_segments = 8
	cloak.mesh = cloak_mesh
	cloak.position = Vector3(0.0, 0.52, 0.0)
	cloak.material_override = cloak_mat
	rig.add_child(cloak)

	# Hood
	var hood := MeshInstance3D.new()
	var hood_mesh := SphereMesh.new()
	hood_mesh.radius = 0.29
	hood_mesh.height = 0.56
	hood_mesh.radial_segments = 8
	hood_mesh.rings = 4
	hood.mesh = hood_mesh
	hood.position = Vector3(0.0, 1.04, 0.0)
	hood.material_override = cloak_mat
	rig.add_child(hood)

	# Glowing mask / eyes facing -Z (forward)
	for ex in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.048
		eye_mesh.height = 0.096
		eye_mesh.radial_segments = 6
		eye_mesh.rings = 3
		eye.mesh = eye_mesh
		eye.position = Vector3(ex, 1.05, -0.25)
		eye.material_override = eye_mat
		rig.add_child(eye)

	# Feet
	if not is_ghost:
		for fx in [-0.11, 0.11]:
			var foot := MeshInstance3D.new()
			var foot_mesh := CylinderMesh.new()
			foot_mesh.top_radius = 0.045
			foot_mesh.bottom_radius = 0.055
			foot_mesh.height = 0.16
			foot_mesh.radial_segments = 6
			foot.mesh = foot_mesh
			foot.position = Vector3(fx, 0.08, 0.0)
			foot.material_override = cloak_mat
			rig.add_child(foot)

	# Cyan lantern held at right side
	var lantern_holder := Node3D.new()
	lantern_holder.name = "LanternHolder"
	lantern_holder.position = Vector3(0.36, 0.54, -0.18)
	rig.add_child(lantern_holder)

	var lantern := MeshInstance3D.new()
	var l_box := BoxMesh.new()
	l_box.size = Vector3(0.16, 0.24, 0.16)
	lantern.mesh = l_box
	lantern.material_override = lantern_mat
	lantern_holder.add_child(lantern)

	var lantern_light := OmniLight3D.new()
	lantern_light.light_color = Color(0.26, 0.88, 1.0)
	lantern_light.light_energy = 1.6 if not is_ghost else 1.1
	lantern_light.omni_range = 4.6 if not is_ghost else 3.4
	lantern_holder.add_child(lantern_light)

	return rig


static func create_grass_tuft(color: Color = Color(0.36, 0.30, 0.54)) -> Node3D:
	var root := Node3D.new()
	root.name = "GrassTuft"
	var mat := make_flat_material(color, 0.88)
	for i in range(4):
		var blade := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.008
		cyl.bottom_radius = 0.045
		cyl.height = 0.28 + float(i % 2) * 0.10
		cyl.radial_segments = 4
		blade.mesh = cyl
		var ang := float(i) * (TAU / 4.0) + 0.3
		blade.position = Vector3(cos(ang) * 0.08, cyl.height * 0.45, sin(ang) * 0.08)
		blade.rotation = Vector3(sin(ang) * 0.28, ang, -cos(ang) * 0.28)
		blade.material_override = mat
		root.add_child(blade)
	return root
