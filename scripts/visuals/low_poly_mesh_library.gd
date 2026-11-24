class_name LowPolyMeshLibrary
extends RefCounted

## V26 6-World Procedural Low-Poly 3D Mesh & Painted Material Library:
## - 6 distinct cohesive world palettes, seamless painted ground & cliff textures, and tree silhouettes:
##   1. الجزر المنسية (Emerald blossom trees + slate flagstones)
##   2. غابة الهمس (Deep pine trees + hanging lanterns + bioluminescent mushrooms)
##   3. مدينة الساعات المتوقفة (Olive cypress trees + bronze-inlaid clockwork stone)
##   4. الهاوية الصامتة (Twisted abyssal cypress + glowing teal cracks & crystal buds)
##   5. بحر المرايا (Teal-emerald crystal trees + rose blossoms + reflective indigo-silver tiles)
##   6. ما وراء الباب (Sanctuary emerald trees + golden lanterns + ivory-gold marble)
## - Carved glowing rune pushable block material, layer-32 camera occlusion fade, and hooded protagonist.

const WORLD_PALETTES := {
	1: { # الجزر المنسية — The Forgotten Islands
		"name_key": "world_1_name",
		"top": Color(0.88, 0.94, 0.92),
		"grass": Color(0.18, 0.46, 0.32),
		"side": Color(0.84, 0.84, 0.94),
		"accent": Color(0.16, 0.46, 0.30),      # Natural emerald canopy
		"accent_alt": Color(0.12, 0.36, 0.28),  # Deep forest pine
		"blossom": Color(0.94, 0.58, 0.74),     # Subtle pink blossom highlights
		"rune_glow": Color(0.32, 0.88, 1.0),
		"sky_top": Color(0.03, 0.05, 0.12),
		"sky_horizon": Color(0.12, 0.14, 0.28),
		"fog": Color(0.09, 0.11, 0.22),
		"light": Color(0.88, 0.90, 0.98),
		"fill_warm": Color(0.82, 0.62, 0.54),
		"rim_cool": Color(0.28, 0.72, 0.92),
		"metallic": 0.04,
		"roughness": 0.86,
	},
	2: { # غابة الهمس — The Whispering Forest
		"name_key": "world_2_name",
		"top": Color(0.84, 0.96, 0.90),
		"grass": Color(0.14, 0.44, 0.32),
		"side": Color(0.78, 0.90, 0.88),
		"accent": Color(0.11, 0.40, 0.28),      # Deep whispering pine
		"accent_alt": Color(0.10, 0.34, 0.32),  # Mossy emerald-teal
		"blossom": Color(0.42, 0.96, 0.86),     # Bioluminescent mist glow
		"rune_glow": Color(0.34, 0.96, 0.84),
		"sky_top": Color(0.02, 0.06, 0.10),
		"sky_horizon": Color(0.07, 0.22, 0.24),
		"fog": Color(0.06, 0.18, 0.20),
		"light": Color(0.76, 0.94, 0.92),
		"fill_warm": Color(0.96, 0.78, 0.44),
		"rim_cool": Color(0.24, 0.88, 0.80),
		"metallic": 0.04,
		"roughness": 0.88,
	},
	3: { # مدينة الساعات المتوقفة — City of Stopped Clocks
		"name_key": "world_3_name",
		"top": Color(0.92, 0.88, 0.94),
		"grass": Color(0.24, 0.40, 0.26),
		"side": Color(0.88, 0.82, 0.88),
		"accent": Color(0.24, 0.42, 0.25),      # Olive-cypress green
		"accent_alt": Color(0.18, 0.34, 0.24),  # Deep cypress
		"blossom": Color(0.94, 0.74, 0.36),     # Antique bronze-gold trim
		"rune_glow": Color(0.98, 0.76, 0.34),
		"sky_top": Color(0.06, 0.04, 0.12),
		"sky_horizon": Color(0.24, 0.15, 0.22),
		"fog": Color(0.18, 0.12, 0.19),
		"light": Color(0.96, 0.86, 0.74),
		"fill_warm": Color(0.95, 0.68, 0.36),
		"rim_cool": Color(0.56, 0.44, 0.82),
		"metallic": 0.12,
		"roughness": 0.78,
	},
	4: { # الهاوية الصامتة — The Silent Abyss
		"name_key": "world_4_name",
		"top": Color(0.82, 0.92, 0.96),
		"grass": Color(0.10, 0.32, 0.36),
		"side": Color(0.74, 0.84, 0.92),
		"accent": Color(0.09, 0.26, 0.32),      # Dark blue-green abyssal cypress
		"accent_alt": Color(0.07, 0.20, 0.28),  # Deep obsidian pine
		"blossom": Color(0.76, 0.64, 0.98),     # Pale violet-pink crystal buds
		"rune_glow": Color(0.24, 0.92, 0.96),
		"sky_top": Color(0.015, 0.035, 0.06),
		"sky_horizon": Color(0.05, 0.16, 0.22),
		"fog": Color(0.04, 0.14, 0.19),
		"light": Color(0.68, 0.88, 0.94),
		"fill_warm": Color(0.46, 0.38, 0.68),
		"rim_cool": Color(0.18, 0.84, 0.92),
		"metallic": 0.10,
		"roughness": 0.80,
	},
	5: { # بحر المرايا — Sea of Mirrors
		"name_key": "world_5_name",
		"top": Color(0.92, 0.94, 1.0),
		"grass": Color(0.14, 0.42, 0.40),
		"side": Color(0.88, 0.92, 1.0),
		"accent": Color(0.12, 0.44, 0.38),      # Deep teal-emerald canopy
		"accent_alt": Color(0.16, 0.48, 0.46),  # Silver-teal
		"blossom": Color(0.96, 0.64, 0.76),     # Delicate rose-pink blossoms
		"rune_glow": Color(0.72, 0.78, 1.0),
		"sky_top": Color(0.05, 0.04, 0.14),
		"sky_horizon": Color(0.22, 0.16, 0.36),
		"fog": Color(0.16, 0.13, 0.28),
		"light": Color(0.90, 0.92, 1.0),
		"fill_warm": Color(0.84, 0.64, 0.88),
		"rim_cool": Color(0.54, 0.82, 1.0),
		"metallic": 0.32,
		"roughness": 0.34,
	},
	6: { # ما وراء الباب — Beyond the Door
		"name_key": "world_6_name",
		"top": Color(1.0, 0.97, 0.92),
		"grass": Color(0.14, 0.44, 0.28),
		"side": Color(0.96, 0.90, 0.82),
		"accent": Color(0.12, 0.42, 0.26),      # Majestic sanctuary emerald
		"accent_alt": Color(0.16, 0.48, 0.30),  # Sunlit emerald
		"blossom": Color(0.98, 0.74, 0.56),     # Warm golden-pink sanctuary blossoms
		"rune_glow": Color(1.0, 0.82, 0.36),
		"sky_top": Color(0.05, 0.04, 0.11),
		"sky_horizon": Color(0.46, 0.28, 0.12),
		"fog": Color(0.28, 0.19, 0.12),
		"light": Color(1.0, 0.90, 0.72),
		"fill_warm": Color(1.0, 0.74, 0.34),
		"rim_cool": Color(0.48, 0.72, 0.96),
		"metallic": 0.14,
		"roughness": 0.62,
	},
}

const TEX_ISLAND_TOP := "res://assets/textures/island_top.png"
const TEX_CLIFF_ROCK := "res://assets/textures/cliff_rock.png"
const TEX_WOOD_PLANKS := "res://assets/textures/wood_planks.png"
const TEX_COSMIC_SKY := "res://assets/textures/cosmic_sky.png"
const TEX_RUNE_BLOCK_ALBEDO := "res://assets/textures/rune_block_albedo.png"
const TEX_RUNE_BLOCK_EMISSION := "res://assets/textures/rune_block_emission.png"

## Explicit preloads guarantee Godot 4.5 Android APK export packs & loads ALL 6 world textures!
const PRELOAD_WORLD_TOP := {
	1: preload("res://assets/textures/world_1_top.png"),
	2: preload("res://assets/textures/world_2_top.png"),
	3: preload("res://assets/textures/world_3_top.png"),
	4: preload("res://assets/textures/world_4_top.png"),
	5: preload("res://assets/textures/world_5_top.png"),
	6: preload("res://assets/textures/world_6_top.png"),
}
const PRELOAD_WORLD_CLIFF := {
	1: preload("res://assets/textures/world_1_cliff.png"),
	2: preload("res://assets/textures/world_2_cliff.png"),
	3: preload("res://assets/textures/world_3_cliff.png"),
	4: preload("res://assets/textures/world_4_cliff.png"),
	5: preload("res://assets/textures/world_5_cliff.png"),
	6: preload("res://assets/textures/world_6_cliff.png"),
}
const PRELOAD_W4_TOP_EMISSION: Texture2D = preload("res://assets/textures/world_4_top_emission.png")
const PRELOAD_WORLD_TOP_NORMAL := {
	1: preload("res://assets/textures/world_1_top_normal.png"),
	2: preload("res://assets/textures/world_2_top_normal.png"),
	3: preload("res://assets/textures/world_3_top_normal.png"),
	4: preload("res://assets/textures/world_4_top_normal.png"),
	5: preload("res://assets/textures/world_5_top_normal.png"),
	6: preload("res://assets/textures/world_6_top_normal.png"),
}
const PRELOAD_RUNE_ALBEDO: Texture2D = preload("res://assets/textures/rune_block_albedo.png")
const PRELOAD_RUNE_EMISSION: Texture2D = preload("res://assets/textures/rune_block_emission.png")
const PRELOAD_RUNE_NORMAL: Texture2D = preload("res://assets/textures/rune_block_normal.png")
const PRELOAD_WOOD_NORMAL: Texture2D = preload("res://assets/textures/wood_planks_normal.png")


static func get_world_top_texture_path(world_index: int) -> String:
	return "res://assets/textures/world_%d_top.png" % clampi(world_index, 1, 6)


static func get_world_cliff_texture_path(world_index: int) -> String:
	return "res://assets/textures/world_%d_cliff.png" % clampi(world_index, 1, 6)


static func make_preloaded_material(tex: Texture2D, tint: Color = Color.WHITE, roughness: float = 0.84, uv_scale: Vector3 = Vector3(1.0, 1.0, 1.0), triplanar: bool = true, metallic: float = 0.04, normal_tex: Texture2D = null, normal_strength: float = 1.15) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = roughness
	mat.metallic = metallic
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if tex != null:
		mat.albedo_texture = tex
		mat.uv1_triplanar = triplanar
		mat.uv1_scale = uv_scale
	if normal_tex != null:
		mat.normal_enabled = true
		mat.normal_texture = normal_tex
		mat.normal_scale = normal_strength
	return mat


static func make_textured_material(tex_path: String, tint: Color = Color.WHITE, roughness: float = 0.84, uv_scale: Vector3 = Vector3(1.0, 1.0, 1.0), triplanar: bool = true, metallic: float = 0.04) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = roughness
	mat.metallic = metallic
	var tex := load(tex_path) as Texture2D
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if tex != null:
		mat.albedo_texture = tex
		mat.uv1_triplanar = triplanar
		mat.uv1_scale = uv_scale
	if tex_path == TEX_WOOD_PLANKS:
		mat.normal_enabled = true
		mat.normal_texture = PRELOAD_WOOD_NORMAL
		mat.normal_scale = 1.10
	return mat


static func make_rune_block_material(world_index: int = 1) -> StandardMaterial3D:
	var pal := get_world_palette(world_index)
	var rune_col: Color = pal.get("rune_glow", Color(0.32, 0.88, 1.0))
	var mat := StandardMaterial3D.new()
	if world_index == 6:
		mat.albedo_color = Color(0.95, 0.90, 0.82)
		mat.roughness = 0.55
		mat.metallic = 0.18
	elif world_index == 5:
		mat.albedo_color = Color(0.74, 0.80, 0.98)
		mat.roughness = 0.32
		mat.metallic = 0.34
	elif world_index == 4:
		mat.albedo_color = Color(0.42, 0.48, 0.56)
		mat.roughness = 0.72
		mat.metallic = 0.12
	else:
		mat.albedo_color = Color(0.76, 0.78, 0.88)
		mat.roughness = 0.74
		mat.metallic = 0.10

	mat.albedo_texture = PRELOAD_RUNE_ALBEDO
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.normal_enabled = true
	mat.normal_texture = PRELOAD_RUNE_NORMAL
	mat.normal_scale = 1.35
	mat.emission_enabled = true
	mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	mat.emission = rune_col
	mat.emission_texture = PRELOAD_RUNE_EMISSION
	mat.emission_energy_multiplier = 2.10
	return mat


static func build_cosmic_sky(world_index: int = 1) -> Sky:
	## 6 unmistakably distinct world skies (high-contrast horizon & atmosphere per world)
	var w := clampi(world_index, 1, 6)
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	match w:
		1: # World 1: Starry Indigo-Navy Night (Forgotten Islands)
			psm.sky_top_color = Color(0.03, 0.05, 0.15)
			psm.sky_horizon_color = Color(0.14, 0.22, 0.44)
			psm.ground_bottom_color = Color(0.02, 0.04, 0.10)
			psm.ground_horizon_color = Color(0.10, 0.16, 0.34)
		2: # World 2: Vivid Emerald-Teal Forest Mist (Whispering Forest)
			psm.sky_top_color = Color(0.02, 0.14, 0.13)
			psm.sky_horizon_color = Color(0.10, 0.46, 0.38)
			psm.ground_bottom_color = Color(0.01, 0.08, 0.08)
			psm.ground_horizon_color = Color(0.06, 0.32, 0.28)
		3: # World 3: Warm Amber-Sunset & Twilight Violet (City of Stopped Clocks)
			psm.sky_top_color = Color(0.16, 0.07, 0.22)
			psm.sky_horizon_color = Color(0.76, 0.40, 0.20)
			psm.ground_bottom_color = Color(0.10, 0.05, 0.14)
			psm.ground_horizon_color = Color(0.52, 0.26, 0.16)
		4: # World 4: Eerie Deep Black-Cyan Abyss (The Silent Abyss)
			psm.sky_top_color = Color(0.01, 0.04, 0.07)
			psm.sky_horizon_color = Color(0.05, 0.34, 0.42)
			psm.ground_bottom_color = Color(0.01, 0.02, 0.04)
			psm.ground_horizon_color = Color(0.03, 0.22, 0.28)
		5: # World 5: Luminous Lavender & Silver-Indigo Nebula (Sea of Mirrors)
			psm.sky_top_color = Color(0.12, 0.07, 0.28)
			psm.sky_horizon_color = Color(0.48, 0.36, 0.78)
			psm.ground_bottom_color = Color(0.08, 0.06, 0.20)
			psm.ground_horizon_color = Color(0.34, 0.28, 0.62)
		6: # World 6: Radiant Golden Sunrise Celestial Sanctuary (Beyond the Door)
			psm.sky_top_color = Color(0.10, 0.07, 0.20)
			psm.sky_horizon_color = Color(0.94, 0.62, 0.24)
			psm.ground_bottom_color = Color(0.14, 0.09, 0.16)
			psm.ground_horizon_color = Color(0.76, 0.48, 0.20)
	psm.sky_curve = 0.28
	psm.ground_curve = 0.22
	sky.sky_material = psm
	return sky


static func get_world_fog_density(world_index: int) -> float:
	match clampi(world_index, 1, 6):
		1:
			return 0.009
		2:
			return 0.018
		3:
			return 0.015
		4:
			return 0.022
		5:
			return 0.014
		6:
			return 0.012
		_:
			return 0.012


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


static func create_floating_island_mesh(size: Vector3, top_color: Color, side_color: Color, seed_val: int = 1, grass_color: Color = Color(0.20, 0.38, 0.34), world_index: int = 1) -> ArrayMesh:
	## 2-Surface World-Themed Painted Floating Island:
	## Surface 0: World-specific seamless hand-painted top surface (world_X_top.png)
	## Surface 1: World-specific faceted cliff rock & tapered underside (world_X_cliff.png)
	var pal := get_world_palette(world_index)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var thickness := maxf(size.y, 1.8)
	var sub_x := clampi(int(round(size.x / 1.45)), 3, 8)
	var sub_z := clampi(int(round(size.z / 1.45)), 3, 8)

	var st_top := SurfaceTool.new()
	st_top.begin(Mesh.PRIMITIVE_TRIANGLES)

	var grid: Array = []
	for ix in range(sub_x + 1):
		var col: Array = []
		var u := float(ix) / float(sub_x)
		var x := lerpf(-hx, hx, u)
		for iz in range(sub_z + 1):
			var v := float(iz) / float(sub_z)
			var z := lerpf(-hz, hz, v)
			var is_edge := (ix == 0 or ix == sub_x or iz == 0 or iz == sub_z)
			var y_jitter := 0.0 if is_edge else rng.randf_range(-0.018, 0.018)
			col.append(Vector3(x, y_jitter, z))
		grid.append(col)

	for ix in range(sub_x):
		for iz in range(sub_z):
			var p00: Vector3 = grid[ix][iz]
			var p10: Vector3 = grid[ix + 1][iz]
			var p11: Vector3 = grid[ix + 1][iz + 1]
			var p01: Vector3 = grid[ix][iz + 1]
			_add_flat_tri(st_top, p00, p10, p11, Color.WHITE)
			_add_flat_tri(st_top, p00, p11, p01, Color.WHITE)

	var mesh := st_top.commit()
	var w_clamped := clampi(world_index, 1, 6)
	var top_tex: Texture2D = PRELOAD_WORLD_TOP[w_clamped]
	var top_rough := float(pal.get("roughness", 0.84))
	var top_metal := float(pal.get("metallic", 0.04))
	var top_tint := Color.WHITE.lerp(top_color, 0.22)
	var top_norm: Texture2D = PRELOAD_WORLD_TOP_NORMAL[w_clamped]
	var top_mat := make_preloaded_material(top_tex, top_tint, top_rough, Vector3(0.24, 0.24, 0.24), true, top_metal, top_norm, 1.25)
	if w_clamped == 4:
		top_mat.emission_enabled = true
		top_mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		top_mat.emission = Color(0.24, 0.96, 1.0)
		top_mat.emission_texture = PRELOAD_W4_TOP_EMISSION
		top_mat.emission_energy_multiplier = 2.20
	mesh.surface_set_material(0, top_mat)

	# Surface 1: Faceted Cliff Rock Sides & Tapered Underside
	var st_cliff := SurfaceTool.new()
	st_cliff.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lip_y := -0.26
	var mid_y := -thickness * 0.58
	var bottom_tip := Vector3(rng.randf_range(-hx * 0.18, hx * 0.18), -thickness * 1.62, rng.randf_range(-hz * 0.18, hz * 0.18))

	var top_ring: Array[Vector3] = [
		Vector3(-hx, 0.0, -hz), Vector3(0.0, 0.0, -hz), Vector3(hx, 0.0, -hz),
		Vector3(hx, 0.0, 0.0), Vector3(hx, 0.0, hz), Vector3(0.0, 0.0, hz),
		Vector3(-hx, 0.0, hz), Vector3(-hx, 0.0, 0.0),
	]
	var lip_ring: Array[Vector3] = []
	var mid_ring: Array[Vector3] = []
	for p3: Vector3 in top_ring:
		var j_lip := rng.randf_range(0.95, 1.03)
		var j_mid := rng.randf_range(0.76, 0.90)
		lip_ring.append(Vector3(p3.x * j_lip, lip_y + rng.randf_range(-0.05, 0.04), p3.z * j_lip))
		mid_ring.append(Vector3(p3.x * j_mid, mid_y + rng.randf_range(-0.18, 0.18), p3.z * j_mid))

	var n := top_ring.size()
	for i in range(n):
		var ni := (i + 1) % n
		_add_flat_tri(st_cliff, top_ring[i], lip_ring[i], lip_ring[ni], Color.WHITE)
		_add_flat_tri(st_cliff, top_ring[i], lip_ring[ni], top_ring[ni], Color.WHITE)
		_add_flat_tri(st_cliff, lip_ring[i], mid_ring[i], mid_ring[ni], Color.WHITE)
		_add_flat_tri(st_cliff, lip_ring[i], mid_ring[ni], lip_ring[ni], Color.WHITE)
		_add_flat_tri(st_cliff, mid_ring[i], bottom_tip, mid_ring[ni], Color.WHITE)

	st_cliff.commit(mesh)
	var cliff_tex: Texture2D = PRELOAD_WORLD_CLIFF[w_clamped]
	var cliff_tint := Color.WHITE.lerp(side_color, 0.22)
	mesh.surface_set_material(1, make_preloaded_material(cliff_tex, cliff_tint, 0.86, Vector3(0.28, 0.28, 0.28), true, top_metal * 0.5))
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


static func create_low_poly_tree(crown_color: Color, scale_factor: float = 1.0, pine_style: bool = false, world_index: int = 1) -> Node3D:
	## 6 World-Distinct Stylized Low-Poly Trees (natural emerald/pine/olive/abyssal/teal foliage
	## with subtle world-themed blossom, lantern, mushroom, or crystal accents — no pink blobs!).
	var root := Node3D.new()
	root.name = "LowPolyTree_W%d" % world_index
	var pal := get_world_palette(world_index)
	var accent_col: Color = pal.get("blossom", Color(0.94, 0.58, 0.74))
	var glow_col: Color = pal.get("rune_glow", Color(0.32, 0.88, 1.0))

	# Shared sculptural trunk
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.09 * scale_factor
	trunk_mesh.bottom_radius = 0.20 * scale_factor
	trunk_mesh.height = 1.55 * scale_factor
	trunk_mesh.radial_segments = 6
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0.0, 0.77 * scale_factor, 0.0)
	var bark_col := Color(0.26, 0.18, 0.14) if world_index != 4 else Color(0.14, 0.15, 0.20)
	trunk.material_override = make_flat_material(bark_col, 0.92)
	root.add_child(trunk)

	match clampi(world_index, 1, 6):
		1:
			# World 1: Layered natural emerald canopy + subtle pink blossom clusters
			if pine_style:
				_add_cone_tiers(root, crown_color, scale_factor, [
					{"y": 1.20, "r": 0.86, "h": 0.98, "d": -0.10},
					{"y": 1.85, "r": 0.66, "h": 0.90, "d": 0.0},
					{"y": 2.42, "r": 0.44, "h": 0.78, "d": 0.08},
				])
			else:
				_add_faceted_canopy(root, crown_color, scale_factor)
			_add_blossom_dots(root, accent_col, scale_factor, [
				Vector3(-0.56, 1.86, 0.34), Vector3(0.52, 1.98, 0.22),
				Vector3(0.12, 2.48, -0.24), Vector3(-0.22, 1.66, -0.46),
			], 0.11, false)
		2:
			# World 2: Deep whispering pine + hanging warm mini-lantern + glowing forest mushrooms
			_add_cone_tiers(root, crown_color, scale_factor, [
				{"y": 1.18, "r": 0.96, "h": 1.04, "d": -0.12},
				{"y": 1.86, "r": 0.74, "h": 0.94, "d": 0.0},
				{"y": 2.48, "r": 0.50, "h": 0.84, "d": 0.08},
				{"y": 2.98, "r": 0.28, "h": 0.64, "d": 0.14},
			])
			_add_hanging_mini_lantern(root, Vector3(0.56, 1.24, 0.26) * scale_factor, Color(1.0, 0.80, 0.38), scale_factor)
			_add_blossom_dots(root, glow_col, scale_factor, [
				Vector3(-0.34, 0.14, 0.28), Vector3(-0.18, 0.10, 0.38), Vector3(0.28, 0.12, -0.24),
			], 0.09, true)
		3:
			# World 3: Tall slender olive-green cypress spire + subtle antique bronze base ring
			_add_cone_tiers(root, crown_color, scale_factor, [
				{"y": 1.22, "r": 0.64, "h": 1.15, "d": -0.10},
				{"y": 1.98, "r": 0.50, "h": 1.10, "d": 0.0},
				{"y": 2.68, "r": 0.34, "h": 1.00, "d": 0.08},
				{"y": 3.28, "r": 0.18, "h": 0.78, "d": 0.14},
			])
			var ring := MeshInstance3D.new()
			var tor := TorusMesh.new()
			tor.inner_radius = 0.24 * scale_factor
			tor.outer_radius = 0.32 * scale_factor
			tor.rings = 10
			tor.ring_segments = 5
			ring.mesh = tor
			ring.position = Vector3(0.0, 0.10 * scale_factor, 0.0)
			ring.material_override = make_flat_material(accent_col, 0.45, accent_col, 0.35)
			root.add_child(ring)
		4:
			# World 4: Twisted dark blue-green abyssal cypress + violet-pink glowing crystal buds
			var offsets: Array[Vector3] = [
				Vector3(0.0, 1.18, 0.0), Vector3(0.08, 1.76, -0.05),
				Vector3(-0.07, 2.30, 0.06), Vector3(0.04, 2.82, -0.03),
			]
			var radii := [0.74, 0.56, 0.40, 0.24]
			for i in range(4):
				var cone := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.04 * scale_factor
				cm.bottom_radius = float(radii[i]) * scale_factor
				cm.height = 0.92 * scale_factor
				cm.radial_segments = 6
				cone.mesh = cm
				cone.position = offsets[i] * scale_factor
				cone.rotation_degrees = Vector3(float(i % 2) * 5.0 - 2.5, float(i) * 32.0, float((i + 1) % 2) * 5.0 - 2.5)
				cone.material_override = make_flat_material(crown_color.lightened(float(i) * 0.04), 0.78)
				root.add_child(cone)
			_add_blossom_dots(root, accent_col, scale_factor, [
				Vector3(-0.46, 1.48, 0.22), Vector3(0.42, 1.98, 0.18),
				Vector3(-0.26, 2.48, -0.18), Vector3(0.24, 1.05, 0.28),
			], 0.095, true)
		5:
			# World 5: Elegant tiered teal-emerald crystal tree + rose-pink blossoms & floating prisms
			_add_cone_tiers(root, crown_color, scale_factor, [
				{"y": 1.24, "r": 0.88, "h": 0.82, "d": -0.08},
				{"y": 1.88, "r": 0.68, "h": 0.76, "d": 0.02},
				{"y": 2.46, "r": 0.46, "h": 0.68, "d": 0.10},
			])
			_add_blossom_dots(root, accent_col, scale_factor, [
				Vector3(-0.58, 1.38, 0.30), Vector3(0.54, 1.46, -0.20),
				Vector3(-0.34, 2.04, 0.28), Vector3(0.36, 2.10, 0.22),
			], 0.11, false)
			_add_blossom_dots(root, glow_col, scale_factor, [
				Vector3(-0.72, 0.96, 0.44), Vector3(0.68, 1.12, 0.36),
			], 0.075, true)
		6:
			# World 6: Majestic sanctuary emerald canopy + warm golden-pink blossoms + 2 hanging golden lanterns
			_add_faceted_canopy(root, crown_color, scale_factor)
			_add_blossom_dots(root, accent_col, scale_factor, [
				Vector3(-0.56, 1.90, 0.34), Vector3(0.54, 1.96, 0.24),
				Vector3(0.08, 2.50, -0.22), Vector3(-0.32, 2.26, -0.34),
			], 0.105, true)
			_add_hanging_mini_lantern(root, Vector3(-0.54, 1.26, 0.32) * scale_factor, Color(1.0, 0.84, 0.40), scale_factor)
			_add_hanging_mini_lantern(root, Vector3(0.50, 1.30, -0.22) * scale_factor, Color(1.0, 0.84, 0.40), scale_factor)

	# Camera-only occluder on layer 32 (zero physical collision with player!)
	var occ := StaticBody3D.new()
	occ.collision_layer = 32
	occ.collision_mask = 0
	var occ_sh := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.82 * scale_factor
	cyl.height = 2.6 * scale_factor
	occ_sh.shape = cyl
	occ_sh.position = Vector3(0.0, 1.4 * scale_factor, 0.0)
	occ.add_child(occ_sh)
	root.add_child(occ)

	return root


static func _add_faceted_canopy(root: Node3D, crown_color: Color, scale_factor: float) -> void:
	var puffs := [
		{"pos": Vector3(0.0, 1.96, 0.0), "r": 0.92, "h": 0.68, "c": crown_color},
		{"pos": Vector3(-0.64, 1.64, 0.24), "r": 0.62, "h": 0.52, "c": crown_color.darkened(0.12)},
		{"pos": Vector3(0.60, 1.70, -0.20), "r": 0.58, "h": 0.48, "c": crown_color.lightened(0.08)},
		{"pos": Vector3(0.08, 2.40, 0.06), "r": 0.54, "h": 0.42, "c": crown_color.lightened(0.12)},
	]
	for p in puffs:
		var crown := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = float(p["r"]) * scale_factor
		sphere.height = float(p["h"]) * 2.0 * scale_factor
		sphere.radial_segments = 6
		sphere.rings = 3
		crown.mesh = sphere
		crown.position = (p["pos"] as Vector3) * scale_factor
		crown.material_override = make_flat_material(p["c"] as Color, 0.84)
		root.add_child(crown)


static func _add_cone_tiers(root: Node3D, crown_color: Color, scale_factor: float, tiers: Array) -> void:
	for t in tiers:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02 * scale_factor
		cm.bottom_radius = float(t["r"]) * scale_factor
		cm.height = float(t["h"]) * scale_factor
		cm.radial_segments = 7
		cone.mesh = cm
		cone.position = Vector3(0.0, float(t["y"]) * scale_factor, 0.0)
		var d := float(t["d"])
		var col := crown_color.lightened(d) if d >= 0.0 else crown_color.darkened(-d)
		cone.material_override = make_flat_material(col, 0.84)
		root.add_child(cone)


static func _add_blossom_dots(root: Node3D, col: Color, scale_factor: float, positions: Array[Vector3], radius: float, glowing: bool) -> void:
	var mat := make_flat_material(col, 0.35, col, 1.25 if glowing else 0.25)
	var sph := SphereMesh.new()
	sph.radius = radius * scale_factor
	sph.height = radius * 2.0 * scale_factor
	sph.radial_segments = 5
	sph.rings = 2
	for pt: Vector3 in positions:
		var m := MeshInstance3D.new()
		m.mesh = sph
		m.position = pt * scale_factor
		m.material_override = mat
		root.add_child(m)


static func _add_hanging_mini_lantern(root: Node3D, pos: Vector3, glow_col: Color, scale_factor: float) -> void:
	var cord := MeshInstance3D.new()
	var c_cyl := CylinderMesh.new()
	c_cyl.top_radius = 0.012 * scale_factor
	c_cyl.bottom_radius = 0.012 * scale_factor
	c_cyl.height = 0.28 * scale_factor
	c_cyl.radial_segments = 4
	cord.mesh = c_cyl
	cord.position = pos + Vector3(0.0, 0.14 * scale_factor, 0.0)
	cord.material_override = make_flat_material(Color(0.18, 0.15, 0.20), 0.9)
	root.add_child(cord)

	var orb := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.13, 0.18, 0.13) * scale_factor
	orb.mesh = b
	orb.position = pos
	orb.material_override = make_flat_material(glow_col, 0.15, glow_col, 2.0)
	root.add_child(orb)


static func create_wooden_cabin(scale_factor: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "WoodenCabin"
	var wall_mat := make_textured_material(TEX_WOOD_PLANKS, Color(0.88, 0.85, 0.92), 0.88, Vector3(0.65, 0.65, 0.65), true)
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

	var plinth := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(1.66, 0.18, 1.46) * scale_factor
	plinth.mesh = pb
	plinth.position = Vector3(0.0, 0.09 * scale_factor, 0.0)
	plinth.material_override = make_flat_material(Color(0.24, 0.25, 0.32), 0.88)
	root.add_child(plinth)

	var frame := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.42, 0.42, 0.04) * scale_factor
	frame.mesh = fb
	frame.position = Vector3(0.0, 0.56 * scale_factor, 0.64 * scale_factor)
	frame.material_override = roof_mat
	root.add_child(frame)
	return root


static func create_luminous_waterfall(height: float = 3.8, width: float = 0.85) -> Node3D:
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
	var wood_mat := make_textured_material(TEX_WOOD_PLANKS, Color(0.95, 0.90, 0.88), 0.86, Vector3(0.8, 0.8, 0.8), true)

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


static func create_rock(color: Color, scale_factor: float = 1.0, world_index: int = 1) -> MeshInstance3D:
	var rock := MeshInstance3D.new()
	rock.name = "LowPolyRock"
	var sphere := SphereMesh.new()
	sphere.radius = 0.38 * scale_factor
	sphere.height = 0.54 * scale_factor
	sphere.radial_segments = 6
	sphere.rings = 2
	rock.mesh = sphere
	rock.position = Vector3(0.0, 0.18 * scale_factor, 0.0)
	rock.material_override = make_textured_material(get_world_cliff_texture_path(world_index), Color.WHITE.lerp(color, 0.30), 0.90, Vector3(0.6, 0.6, 0.6), true)
	return rock


static func build_hooded_character(is_ghost: bool = false, skin_id: String = "wanderer") -> Node3D:
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
		var skin_map := {
			"wanderer": {"cloak": Color(0.11, 0.12, 0.20), "eye": Color(1.0, 0.84, 0.45), "lantern": Color(0.24, 0.88, 1.0)},
			"dawn_cloak": {"cloak": Color(0.16, 0.18, 0.34), "eye": Color(1.0, 0.90, 0.55), "lantern": Color(1.0, 0.78, 0.32)},
			"clockwork_keeper": {"cloak": Color(0.22, 0.13, 0.32), "eye": Color(0.84, 0.68, 1.0), "lantern": Color(0.76, 0.45, 0.98)},
			"abyss_walker": {"cloak": Color(0.18, 0.08, 0.14), "eye": Color(1.0, 0.56, 0.62), "lantern": Color(0.95, 0.42, 0.58)},
			"starlight_architect": {"cloak": Color(0.14, 0.22, 0.32), "eye": Color(0.78, 0.98, 1.0), "lantern": Color(0.32, 0.96, 0.88)},
		}
		var cfg: Dictionary = skin_map.get(skin_id, skin_map["wanderer"])
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


static func create_scenic_arch(stone_color: Color, glow_color: Color, world_index: int = 1) -> Node3D:
	var root := Node3D.new()
	var s_mat := make_textured_material(get_world_cliff_texture_path(world_index), Color.WHITE.lerp(stone_color, 0.30), 0.86, Vector3(0.45, 0.45, 0.45), true)
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
