class_name LowPolyMeshLibrary
extends RefCounted

## Reference-aligned procedural low-poly 3D mesh & material library:
## - Restrained cosmic palettes (deep navy, muted indigo, dark natural greens, subdued turquoise)
## - Multi-tiered faceted floating islands with mossy grass ledges & rocky undersides
## - Layered stylized trees (with layer-32 camera occlusion fade), wooden cabins, glowing waterfalls,
##   ancient stone arches, crystal clusters, Guardian Boss Sentinels, and the approved hooded protagonist.

const WORLD_PALETTES := {
	1: { # الجزر المنسية — The Forgotten Islands
		"name_key": "world_1_name",
		"top": Color(0.28, 0.34, 0.42),
		"grass": Color(0.20, 0.38, 0.34),
		"side": Color(0.20, 0.18, 0.30),
		"accent": Color(0.56, 0.24, 0.48), # Restrained plum-magenta canopy
		"accent_alt": Color(0.22, 0.38, 0.56), # Muted indigo canopy
		"sky_top": Color(0.03, 0.04, 0.11),
		"sky_horizon": Color(0.14, 0.10, 0.24),
		"fog": Color(0.10, 0.09, 0.20),
		"light": Color(0.86, 0.86, 0.96),
	},
	2: { # غابة الهمس — The Whispering Forest
		"name_key": "world_2_name",
		"top": Color(0.22, 0.34, 0.38),
		"grass": Color(0.16, 0.36, 0.30),
		"side": Color(0.14, 0.20, 0.30),
		"accent": Color(0.20, 0.52, 0.62), # Subdued turquoise-pine
		"accent_alt": Color(0.18, 0.38, 0.34),
		"sky_top": Color(0.02, 0.05, 0.12),
		"sky_horizon": Color(0.09, 0.18, 0.28),
		"fog": Color(0.08, 0.14, 0.24),
		"light": Color(0.72, 0.88, 0.96),
	},
	3: { # مدينة الساعات المتوقفة — City of Stopped Clocks
		"name_key": "world_3_name",
		"top": Color(0.34, 0.28, 0.44),
		"grass": Color(0.24, 0.26, 0.38),
		"side": Color(0.20, 0.14, 0.28),
		"accent": Color(0.52, 0.32, 0.64), # Muted twilight violet
		"accent_alt": Color(0.68, 0.54, 0.34), # Antique bronze-gold
		"sky_top": Color(0.05, 0.03, 0.12),
		"sky_horizon": Color(0.20, 0.11, 0.28),
		"fog": Color(0.14, 0.09, 0.22),
		"light": Color(0.86, 0.78, 0.94),
	},
	4: { # الهاوية الصامتة — The Silent Abyss
		"name_key": "world_4_name",
		"top": Color(0.24, 0.27, 0.36),
		"grass": Color(0.16, 0.28, 0.32),
		"side": Color(0.11, 0.13, 0.21),
		"accent": Color(0.26, 0.48, 0.52), # Deep mist teal
		"accent_alt": Color(0.28, 0.32, 0.48),
		"sky_top": Color(0.018, 0.024, 0.06),
		"sky_horizon": Color(0.09, 0.11, 0.19),
		"fog": Color(0.07, 0.09, 0.16),
		"light": Color(0.72, 0.80, 0.90),
	},
	5: { # بحر المرايا — Sea of Mirrors
		"name_key": "world_5_name",
		"top": Color(0.34, 0.28, 0.42),
		"grass": Color(0.24, 0.32, 0.40),
		"side": Color(0.18, 0.14, 0.28),
		"accent": Color(0.66, 0.38, 0.44), # Muted rose-amber
		"accent_alt": Color(0.32, 0.48, 0.66),
		"sky_top": Color(0.04, 0.03, 0.10),
		"sky_horizon": Color(0.22, 0.13, 0.24),
		"fog": Color(0.14, 0.10, 0.20),
		"light": Color(0.92, 0.82, 0.86),
	},
	6: { # ما وراء الباب — Beyond the Door
		"name_key": "world_6_name",
		"top": Color(0.30, 0.30, 0.46),
		"grass": Color(0.22, 0.36, 0.42),
		"side": Color(0.15, 0.15, 0.28),
		"accent": Color(0.78, 0.62, 0.32), # Astral antique gold
		"accent_alt": Color(0.28, 0.52, 0.66),
		"sky_top": Color(0.022, 0.032, 0.10),
		"sky_horizon": Color(0.18, 0.15, 0.32),
		"fog": Color(0.12, 0.11, 0.24),
		"light": Color(0.96, 0.88, 0.76),
	},
}


static func get_world_palette(world_index: int) -> Dictionary:
	return WORLD_PALETTES.get(clampi(world_index, 1, 6), WORLD_PALETTES[1])


static func make_flat_material(color: Color, roughness: float = 0.82, emission: Color = Color.BLACK, emission_energy: float = 0.0, use_vertex_color: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE if use_vertex_color else color
	mat.vertex_color_use_as_albedo = use_vertex_color
	mat.roughness = roughness
	mat.metallic = 0.04
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


static func create_floating_island_mesh(size: Vector3, top_color: Color, side_color: Color, seed_val: int = 1, grass_color: Color = Color(0.20, 0.38, 0.34)) -> ArrayMesh:
	## Faceted floating island with mossy grass perimeter rim, stone interior plateau,
	## and multi-faceted tapered rock cliff underside (playable top sits cleanly at y = 0).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var thickness := maxf(size.y, 1.8)
	var sub_x := clampi(int(round(size.x / 1.45)), 3, 8)
	var sub_z := clampi(int(round(size.z / 1.45)), 3, 8)

	var grid: Array = []
	for ix in range(sub_x + 1):
		var col: Array = []
		var u := float(ix) / float(sub_x)
		var x := lerpf(-hx, hx, u)
		for iz in range(sub_z + 1):
			var v := float(iz) / float(sub_z)
			var z := lerpf(-hz, hz, v)
			var is_edge := (ix == 0 or ix == sub_x or iz == 0 or iz == sub_z)
			var y_jitter := 0.0 if is_edge else rng.randf_range(-0.02, 0.02)
			col.append(Vector3(x, y_jitter, z))
		grid.append(col)

	for ix in range(sub_x):
		for iz in range(sub_z):
			var p00: Vector3 = grid[ix][iz]
			var p10: Vector3 = grid[ix + 1][iz]
			var p11: Vector3 = grid[ix + 1][iz + 1]
			var p01: Vector3 = grid[ix][iz + 1]
			var is_border := (ix == 0 or ix == sub_x - 1 or iz == 0 or iz == sub_z - 1)
			var base_c := grass_color if is_border else top_color
			var c1 := base_c.lightened(rng.randf_range(-0.05, 0.06))
			var c2 := base_c.lightened(rng.randf_range(-0.05, 0.06))
			_add_flat_tri(st, p00, p10, p11, c1)
			_add_flat_tri(st, p00, p11, p01, c2)

	# Stepped cliff lip + tapered craggy underside (3 vertical tiers for rich silhouette)
	var lip_y := -0.26
	var mid_y := -thickness * 0.58
	var bottom_tip := Vector3(rng.randf_range(-hx * 0.18, hx * 0.18), -thickness * 1.62, rng.randf_range(-hz * 0.18, hz * 0.18))

	var top_ring := [
		Vector3(-hx, 0.0, -hz), Vector3(0.0, 0.0, -hz), Vector3(hx, 0.0, -hz),
		Vector3(hx, 0.0, 0.0), Vector3(hx, 0.0, hz), Vector3(0.0, 0.0, hz),
		Vector3(-hx, 0.0, hz), Vector3(-hx, 0.0, 0.0),
	]
	var lip_ring: Array[Vector3] = []
	var mid_ring: Array[Vector3] = []
	for pt in top_ring:
		var p3 := pt as Vector3
		var j_lip := rng.randf_range(0.95, 1.03)
		var j_mid := rng.randf_range(0.76, 0.90)
		lip_ring.append(Vector3(p3.x * j_lip, lip_y + rng.randf_range(-0.05, 0.04), p3.z * j_lip))
		mid_ring.append(Vector3(p3.x * j_mid, mid_y + rng.randf_range(-0.18, 0.18), p3.z * j_mid))

	var n := top_ring.size()
	for i in range(n):
		var ni := (i + 1) % n
		var lip_c := grass_color.darkened(rng.randf_range(0.18, 0.28))
		var cliff_c := side_color.lightened(rng.randf_range(-0.05, 0.07))
		var deep_c := side_color.darkened(rng.randf_range(0.16, 0.30))
		_add_flat_tri(st, top_ring[i], lip_ring[i], lip_ring[ni], lip_c)
		_add_flat_tri(st, top_ring[i], lip_ring[ni], top_ring[ni], lip_c.lightened(0.04))
		_add_flat_tri(st, lip_ring[i], mid_ring[i], mid_ring[ni], cliff_c)
		_add_flat_tri(st, lip_ring[i], mid_ring[ni], lip_ring[ni], cliff_c.lightened(0.05))
		_add_flat_tri(st, mid_ring[i], bottom_tip, mid_ring[ni], deep_c)

	var mesh := st.commit()
	mesh.surface_set_material(0, make_flat_material(Color.WHITE, 0.88, Color.BLACK, 0.0, true))
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


static func create_low_poly_tree(crown_color: Color, scale_factor: float = 1.0, pine_style: bool = false) -> Node3D:
	## Rich layered canopy or tiered pine tree matching 254211.png silhouette,
	## with an invisible layer-32 occluder so the dynamic camera fades it if blocking the player.
	var root := Node3D.new()
	root.name = "LowPolyTree"

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.11 * scale_factor
	trunk_mesh.bottom_radius = 0.22 * scale_factor
	trunk_mesh.height = 1.55 * scale_factor
	trunk_mesh.radial_segments = 6
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0.0, 0.77 * scale_factor, 0.0)
	trunk.material_override = make_flat_material(Color(0.24, 0.16, 0.20), 0.92)
	root.add_child(trunk)

	if pine_style:
		var tiers := [
			{"y": 1.15, "r": 0.92, "h": 1.05, "c": crown_color.darkened(0.14)},
			{"y": 1.85, "r": 0.72, "h": 0.95, "c": crown_color},
			{"y": 2.45, "r": 0.48, "h": 0.85, "c": crown_color.lightened(0.08)},
		]
		for t in tiers:
			var cone := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.02 * scale_factor
			cm.bottom_radius = float(t["r"]) * scale_factor
			cm.height = float(t["h"]) * scale_factor
			cm.radial_segments = 7
			cone.mesh = cm
			cone.position = Vector3(0.0, float(t["y"]) * scale_factor, 0.0)
			cone.material_override = make_flat_material(t["c"] as Color, 0.84)
			root.add_child(cone)
	else:
		var puffs := [
			{"pos": Vector3(0.0, 1.95, 0.0), "r": 0.96, "h": 0.72, "c": crown_color},
			{"pos": Vector3(-0.68, 1.62, 0.26), "r": 0.66, "h": 0.56, "c": crown_color.darkened(0.12)},
			{"pos": Vector3(0.64, 1.68, -0.20), "r": 0.62, "h": 0.52, "c": crown_color.lightened(0.08)},
			{"pos": Vector3(0.10, 2.38, 0.08), "r": 0.58, "h": 0.44, "c": crown_color.lightened(0.12)},
		]
		for p in puffs:
			var crown := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = float(p["r"]) * scale_factor
			sphere.height = float(p["h"]) * 2.0 * scale_factor
			sphere.radial_segments = 7
			sphere.rings = 3
			crown.mesh = sphere
			crown.position = (p["pos"] as Vector3) * scale_factor
			crown.material_override = make_flat_material(p["c"] as Color, 0.82)
			root.add_child(crown)

	# Camera-only occluder on layer 32 (zero physical collision with player!)
	var occ := StaticBody3D.new()
	occ.collision_layer = 32
	occ.collision_mask = 0
	var occ_sh := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.85 * scale_factor
	cyl.height = 2.6 * scale_factor
	occ_sh.shape = cyl
	occ_sh.position = Vector3(0.0, 1.4 * scale_factor, 0.0)
	occ.add_child(occ_sh)
	root.add_child(occ)

	return root


static func create_wooden_cabin(scale_factor: float = 1.0) -> Node3D:
	## Dark-timber atmospheric cabin matching 254211.png landmarks.
	var root := Node3D.new()
	root.name = "WoodenCabin"
	var wall_mat := make_flat_material(Color(0.24, 0.19, 0.26), 0.90)
	var roof_mat := make_flat_material(Color(0.16, 0.14, 0.22), 0.86)
	var win_mat := make_flat_material(Color(0.96, 0.78, 0.42), 0.2, Color(0.95, 0.72, 0.30), 1.3)

	var body := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.5, 1.0, 1.3) * scale_factor
	body.mesh = b
	body.position = Vector3(0.0, 0.5 * scale_factor, 0.0)
	body.material_override = wall_mat
	root.add_child(body)

	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(1.75, 0.85, 1.52) * scale_factor
	roof.mesh = prism
	roof.position = Vector3(0.0, 1.42 * scale_factor, 0.0)
	roof.material_override = roof_mat
	root.add_child(roof)

	var win := MeshInstance3D.new()
	var wb := BoxMesh.new()
	wb.size = Vector3(0.32, 0.32, 0.06) * scale_factor
	win.mesh = wb
	win.position = Vector3(0.0, 0.56 * scale_factor, 0.66 * scale_factor)
	win.material_override = win_mat
	root.add_child(win)
	return root


static func create_luminous_waterfall(height: float = 3.8, width: float = 0.85) -> Node3D:
	## Restrained cascading turquoise water ribbon hanging from an island edge.
	var root := Node3D.new()
	root.name = "LuminousWaterfall"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.76, 0.92, 0.48)
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.72, 0.90)
	mat.emission_energy_multiplier = 0.75
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var strip := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, height, 0.08)
	strip.mesh = box
	strip.position = Vector3(0.0, -height * 0.5, 0.0)
	strip.material_override = mat
	root.add_child(strip)
	return root


static func create_bench() -> Node3D:
	var root := Node3D.new()
	root.name = "Bench"
	var wood_mat := make_flat_material(Color(0.30, 0.20, 0.20), 0.88)

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
		leg.material_override = wood_mat
		root.add_child(leg)
	return root


static func create_lantern_prop(glow_color: Color = Color(1.0, 0.78, 0.34), add_light: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "StoneLantern"
	var dark_mat := make_flat_material(Color(0.20, 0.17, 0.26), 0.78)
	var glow_mat := make_flat_material(glow_color, 0.2, glow_color, 1.8)

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
		light.light_energy = 1.15
		light.omni_range = 4.2
		light.position = Vector3(0.0, 0.42, 0.0)
		root.add_child(light)

	return root


static func create_crystal_cluster(color: Color = Color(0.24, 0.78, 0.94)) -> Node3D:
	var root := Node3D.new()
	root.name = "CrystalCluster"
	var mat := make_flat_material(color, 0.24, color, 1.15)
	var specs := [
		{"pos": Vector3(0.0, 0.52, 0.0), "r": 0.20, "h": 1.08, "rot": Vector3(0.0, 0.0, 0.0)},
		{"pos": Vector3(-0.22, 0.34, 0.12), "r": 0.13, "h": 0.68, "rot": Vector3(0.18, 0.4, 0.25)},
		{"pos": Vector3(0.20, 0.28, -0.10), "r": 0.12, "h": 0.58, "rot": Vector3(-0.15, 0.2, -0.28)},
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
	rock.material_override = make_flat_material(color, 0.92)
	return rock


static func build_hooded_character(is_ghost: bool = false, skin_id: String = "wanderer") -> Node3D:
	## Preserves the approved hooded protagonist silhouette, proportions, glowing eyes, and lantern,
	## while applying optional crystal-unlocked cloak & lantern themes.
	var rig := Node3D.new()
	rig.name = "CharacterRig"

	var cloak_mat: Material
	var eye_mat: Material
	var lantern_mat: Material
	var lantern_col := Color(0.26, 0.88, 1.0)

	if is_ghost:
		var sh_mat := ShaderMaterial.new()
		var sh := load("res://assets/shaders/echo_ghost.gdshader")
		if sh != null:
			sh_mat.shader = sh
		cloak_mat = sh_mat
		eye_mat = make_flat_material(Color(0.75, 0.98, 1.0), 0.1, Color(0.55, 0.96, 1.0), 2.4)
		lantern_mat = make_flat_material(Color(0.55, 0.96, 1.0), 0.1, Color(0.45, 0.95, 1.0), 2.8)
	else:
		var cfg := GameState.get_skin_config(skin_id)
		var c_col: Color = cfg.get("cloak", Color(0.11, 0.12, 0.20))
		var e_col: Color = cfg.get("eye", Color(1.0, 0.84, 0.45))
		lantern_col = cfg.get("lantern", Color(0.24, 0.88, 1.0))
		cloak_mat = make_flat_material(c_col, 0.85)
		eye_mat = make_flat_material(e_col, 0.1, e_col, 2.2)
		lantern_mat = make_flat_material(lantern_col, 0.1, lantern_col, 2.6)

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
	lantern_light.light_color = lantern_col
	lantern_light.light_energy = 1.45 if not is_ghost else 1.0
	lantern_light.omni_range = 4.6 if not is_ghost else 3.2
	lantern_holder.add_child(lantern_light)

	return rig


static func create_grass_tuft(color: Color = Color(0.20, 0.42, 0.34)) -> Node3D:
	var root := Node3D.new()
	root.name = "GrassTuft"
	var mat := make_flat_material(color, 0.88)
	for i in range(5):
		var blade := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.008
		cyl.bottom_radius = 0.042
		cyl.height = 0.26 + float(i % 3) * 0.08
		cyl.radial_segments = 4
		blade.mesh = cyl
		var ang := float(i) * (TAU / 5.0) + 0.3
		blade.position = Vector3(cos(ang) * 0.09, cyl.height * 0.45, sin(ang) * 0.09)
		blade.rotation = Vector3(sin(ang) * 0.26, ang, -cos(ang) * 0.26)
		blade.material_override = mat
		root.add_child(blade)
	return root


static func create_scenic_arch(stone_color: Color, glow_color: Color) -> Node3D:
	var root := Node3D.new()
	var s_mat := make_flat_material(stone_color, 0.84)
	var g_mat := make_flat_material(glow_color, 0.2, glow_color, 1.35)
	for sx in [-1.05, 1.05]:
		var col := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.32, 2.4, 0.32)
		col.mesh = b
		col.position = Vector3(sx, 1.2, 0.0)
		col.material_override = s_mat
		root.add_child(col)
	var top := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(2.55, 0.30, 0.38)
	top.mesh = tb
	top.position = Vector3(0.0, 2.48, 0.0)
	top.material_override = s_mat
	root.add_child(top)
	var gem := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.20
	sph.height = 0.40
	sph.radial_segments = 6
	sph.rings = 3
	gem.mesh = sph
	gem.position = Vector3(0.0, 2.86, 0.0)
	gem.material_override = g_mat
	root.add_child(gem)
	return root


static func create_crystal_spire(color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := make_flat_material(color, 0.20, color, 1.25)
	var main := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.34
	cyl.height = 2.35
	cyl.radial_segments = 5
	main.mesh = cyl
	main.position = Vector3(0.0, 1.18, 0.0)
	main.material_override = mat
	root.add_child(main)
	return root


static func create_floating_monolith(stone_color: Color, rune_color: Color) -> Node3D:
	var root := Node3D.new()
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.58, 2.1, 0.58)
	m.mesh = b
	m.position = Vector3(0.0, 1.35, 0.0)
	m.material_override = make_flat_material(stone_color, 0.85)
	root.add_child(m)
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.64, 0.18, 0.64)
	band.mesh = bb
	band.position = Vector3(0.0, 1.45, 0.0)
	band.material_override = make_flat_material(rune_color, 0.2, rune_color, 1.55)
	root.add_child(band)
	return root


static func create_celestial_ring(radius: float, color: Color) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.18
	torus.outer_radius = radius + 0.18
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = make_flat_material(color, 0.2, color, 1.0)
	return ring


static func create_hanging_vines(color: Color = Color(0.18, 0.44, 0.36), count: int = 4) -> Node3D:
	## Lush hanging moss & vine strands draping over floating island cliff edges (matching 254211.png).
	var root := Node3D.new()
	root.name = "HangingVines"
	var mat := make_flat_material(color, 0.85, color.lightened(0.2), 0.12)
	for i in range(count):
		var strand := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		var h := 0.85 + float(i % 3) * 0.45
		cyl.top_radius = 0.055
		cyl.bottom_radius = 0.015
		cyl.height = h
		cyl.radial_segments = 4
		strand.mesh = cyl
		strand.position = Vector3((float(i) - float(count - 1) * 0.5) * 0.24, -h * 0.5, 0.0)
		strand.material_override = mat
		root.add_child(strand)
	return root
