class_name StageBuilder
extends Node3D

## Runtime 3D stage builder & gameplay controller for all 120 stages across 6 worlds.
## Features reference-aligned restrained cosmic environments, intelligent dynamic camera,
## subtle ground-embedded puzzle guides, Guardian/Echo Boss encounters on stages 20/40/60/80/100/120,
## 3D Opening Cinematic on Stage 1, and contextual circular interaction UI.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")

var stage_id: int = 1
var stage_def: Dictionary = {}
var world_palette: Dictionary = {}

var _world_root: Node3D
var _player: PlayerController
var _camera_rig: IsoCameraRig
var _echo_recorder: EchoRecorder
var _hud: GameHUD
var _boss: GuardianBoss = null

var _golden_door: GoldenDoor = null
var _purple_doors: Array[PurpleDoor] = []
var _gravity_zones: Dictionary = {}
var _state_nodes: Array[Dictionary] = []
var _plate_bridges: Dictionary = {}
var _plates: Dictionary = {}
var _pushable_blocks: Array[PushableBlock] = []
var _conduit_root: Node3D = null

var _keys_collected: int = 0
var _active_room_state: int = 0
var _respawn_pos: Vector3 = Vector3(0.0, 0.25, 0.0)
var _respawn_world_side: int = 0
var _stage_center: Vector3 = Vector3.ZERO
var _stage_span: float = 14.0
var _cinematic_active: bool = false


func _ready() -> void:
	stage_id = GameState.current_stage_id
	stage_def = LevelCatalog.get_stage(stage_id)
	if stage_def.is_empty():
		push_error("StageBuilder: Could not load definition for stage %d" % stage_id)
		return
	world_palette = LowPolyMeshLibrary.get_world_palette(int(stage_def.get("world", 1)))

	_world_root = Node3D.new()
	_world_root.name = "WorldGeometry"
	add_child(_world_root)

	_setup_environment()
	_build_stage_geometry()
	_setup_player_and_camera()
	_setup_hud_and_echo()
	_build_energy_conduits()
	_spawn_boss_if_finale()
	_apply_room_state(0)
	_evaluate_door_conditions()

	SaveManager.settings_changed.connect(_on_settings_changed)

	# First-time 3D Opening Cinematic on Stage 1, else World Chapter Story Card or stage intro
	var world_starts := {1: "world_1_story", 21: "world_2_story", 41: "world_3_story", 61: "world_4_story", 81: "world_5_story", 101: "world_6_story"}
	if stage_id == 1 and not SaveManager.is_intro_seen():
		_play_opening_cinematic()
	else:
		_camera_rig.configure_stage_framing(_stage_center, _stage_span, true)
		if world_starts.has(stage_id):
			_hud.show_story_chapter(int(stage_def.get("world", 1)), str(world_starts[stage_id]))
		elif _boss != null:
			_hud.show_toast("boss_w%d_intro" % int(stage_def.get("world", 1)), 5.5)
		else:
			var intro_hint := str(stage_def.get("hint_key", ""))
			if not intro_hint.is_empty():
				_hud.show_toast(intro_hint, 4.8)


func _on_settings_changed() -> void:
	if _conduit_root != null and is_instance_valid(_conduit_root):
		_conduit_root.visible = bool(SaveManager.get_setting("puzzle_guides", true))


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = (world_palette["sky_top"] as Color).lerp(Color(0.025, 0.035, 0.095), 0.45)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = (world_palette["light"] as Color).darkened(0.50)
	env.ambient_light_energy = 0.82
	env.fog_enabled = true
	env.fog_light_color = world_palette["fog"] as Color
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.25
	env.glow_enabled = true
	env.glow_intensity = 0.34
	env.glow_bloom = 0.12

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = world_palette["light"] as Color
	moon.light_energy = 1.18
	moon.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
	moon.shadow_enabled = (str(SaveManager.get_setting("graphics_quality", "medium")) != "low")
	moon.shadow_blur = 2.2
	moon.directional_shadow_max_distance = 52.0
	add_child(moon)

	var rose_fill := DirectionalLight3D.new()
	rose_fill.light_color = Color(0.76, 0.42, 0.58)
	rose_fill.light_energy = 0.32
	rose_fill.rotation_degrees = Vector3(-22.0, -135.0, 0.0)
	rose_fill.shadow_enabled = false
	add_child(rose_fill)

	var blue_rim := DirectionalLight3D.new()
	blue_rim.light_color = Color(0.28, 0.66, 0.88)
	blue_rim.light_energy = 0.38
	blue_rim.rotation_degrees = Vector3(-30.0, 125.0, 0.0)
	blue_rim.shadow_enabled = false
	add_child(blue_rim)
	_spawn_3d_starfield(120)


func _build_stage_geometry() -> void:
	var top_col: Color = world_palette["top"]
	var grass_col: Color = world_palette.get("grass", Color(0.20, 0.38, 0.34))
	var side_col: Color = world_palette["side"]
	var accent_col: Color = world_palette["accent"]
	var accent_alt: Color = world_palette.get("accent_alt", accent_col.darkened(0.2))

	var min_pt := Vector3(INF, INF, INF)
	var max_pt := Vector3(-INF, -INF, -INF)

	# 1. Floating Islands (with tight collision matching playable top surface & rich decorative rims)
	var islands: Array = stage_def.get("islands", [])
	for idx in range(islands.size()):
		var isl: Dictionary = islands[idx]
		var pos: Vector3 = _to_vec3(isl["pos"])
		var sz: Vector3 = _to_vec3(isl["size"])
		var state_req: int = int(isl.get("state", -1))
		var alt_tint: bool = bool(isl.get("alt_world", false))
		var t_col := top_col.darkened(0.24) if alt_tint else top_col
		var g_col := grass_col.darkened(0.22) if alt_tint else grass_col
		if state_req == 1:
			t_col = top_col.lerp(Color(0.58, 0.34, 0.72), 0.38)
			g_col = grass_col.lerp(Color(0.46, 0.28, 0.64), 0.40)

		min_pt = min_pt.min(pos - sz * 0.5)
		max_pt = max_pt.max(pos + sz * 0.5)

		var body := StaticBody3D.new()
		body.name = "Island_%d" % idx
		body.collision_layer = 1
		body.position = pos

		var mesh_inst := MeshInstance3D.new()
		mesh_inst.mesh = LowPolyMeshLibrary.create_floating_island_mesh(sz, t_col, side_col, stage_id * 31 + idx, g_col)
		body.add_child(mesh_inst)

		# Accurate playable surface collider (slight 0.08m inset prevents walking on thin air at beveled edge)
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(maxf(sz.x - 0.08, 1.0), 1.0, maxf(sz.z - 0.08, 1.0))
		col.shape = box
		col.position = Vector3(0.0, -0.5, 0.0)
		body.add_child(col)
		_world_root.add_child(body)

		# Rich low-poly grass clusters & subtle waterfall on larger permanent islands
		if sz.x >= 4.8 and sz.z >= 4.8 and state_req < 0:
			var g1 := LowPolyMeshLibrary.create_grass_tuft(g_col.lightened(0.14))
			g1.position = Vector3(-sz.x * 0.40, 0.0, sz.z * 0.36)
			body.add_child(g1)
			var g2 := LowPolyMeshLibrary.create_grass_tuft(g_col.lightened(0.10))
			g2.position = Vector3(sz.x * 0.38, 0.0, -sz.z * 0.38)
			body.add_child(g2)
			if idx == 0 and sz.x >= 5.6:
				var wf := LowPolyMeshLibrary.create_luminous_waterfall(3.6, 0.75)
				wf.position = Vector3(sz.x * 0.22, -0.15, sz.z * 0.50)
				body.add_child(wf)

		if state_req >= 0:
			_state_nodes.append({"node": body, "body": body, "state": state_req})

	if islands.size() > 0:
		_stage_center = (min_pt + max_pt) * 0.5
		_stage_span = maxf(max_pt.x - min_pt.x, max_pt.z - min_pt.z)

	# 2. Wooden / Luminous Bridges
	var bridges: Array = stage_def.get("bridges", [])
	for idx in range(bridges.size()):
		var br: Dictionary = bridges[idx]
		var p_a: Vector3 = _to_vec3(br["from"])
		var p_b: Vector3 = _to_vec3(br["to"])
		var width: float = float(br.get("width", 1.8))
		var state_req: int = int(br.get("state", -1))
		var req_plate: String = str(br.get("plate_id", ""))

		var br_body := _create_bridge_body(p_a, p_b, width, not req_plate.is_empty() or state_req >= 0)
		br_body.name = "Bridge_%d" % idx
		_world_root.add_child(br_body)

		if state_req >= 0:
			_state_nodes.append({"node": br_body, "body": br_body, "state": state_req})
		if not req_plate.is_empty():
			if not _plate_bridges.has(req_plate):
				_plate_bridges[req_plate] = []
			(_plate_bridges[req_plate] as Array).append({"node": br_body, "body": br_body})
			_set_body_active(br_body, br_body, false)

	# 3. Ambient distant decorative floating islets for cosmic depth
	var rng := RandomNumberGenerator.new()
	rng.seed = stage_id * 101 + 7
	for i in range(7):
		var angle := float(i) * (TAU / 7.0) + rng.randf_range(-0.25, 0.25)
		var dist := rng.randf_range(18.0, 29.0)
		var deco := MeshInstance3D.new()
		var d_sz := Vector3(rng.randf_range(2.0, 3.6), rng.randf_range(2.4, 4.4), rng.randf_range(2.0, 3.6))
		deco.mesh = LowPolyMeshLibrary.create_floating_island_mesh(d_sz, top_col.darkened(0.32), side_col.darkened(0.28), stage_id * 7 + i, grass_col.darkened(0.30))
		deco.position = _stage_center + Vector3(cos(angle) * dist, rng.randf_range(-5.5, 2.5), sin(angle) * dist)
		_world_root.add_child(deco)

	# 4. Props (alternating plum/indigo/pine trees, wooden cabins, benches, lanterns, crystals, rocks, arches)
	var prop_idx := 0
	for prop in stage_def.get("props", []):
		var kind := str(prop["type"])
		var p_pos := _to_vec3(prop["pos"])
		var node: Node3D = null
		match kind:
			"tree":
				var use_pine := (prop_idx % 3 == 1)
				var t_col := accent_col if (prop_idx % 2 == 0) else accent_alt
				node = LowPolyMeshLibrary.create_low_poly_tree(t_col, float(prop.get("scale", 1.0)), use_pine)
			"cabin":
				node = LowPolyMeshLibrary.create_wooden_cabin(float(prop.get("scale", 0.85)))
			"bench":
				node = LowPolyMeshLibrary.create_bench()
			"lantern":
				node = LowPolyMeshLibrary.create_lantern_prop(Color(1.0, 0.78, 0.34), bool(prop.get("light", true)))
			"crystal":
				node = LowPolyMeshLibrary.create_crystal_cluster(Color(0.24, 0.78, 0.94))
			"rock":
				node = LowPolyMeshLibrary.create_rock(side_col.lightened(0.15), float(prop.get("scale", 1.0)))
			"arch":
				node = LowPolyMeshLibrary.create_scenic_arch(side_col.lightened(0.22), accent_col)
			"spire":
				node = LowPolyMeshLibrary.create_crystal_spire(accent_col)
			"monolith", "shrine":
				node = LowPolyMeshLibrary.create_floating_monolith(side_col.lightened(0.18), accent_col)
		if node != null:
			node.position = p_pos
			node.rotation_degrees.y = float(prop.get("rot_y", 0.0))
			_world_root.add_child(node)
		prop_idx += 1

	# 5. Keys
	for k in stage_def.get("keys", []):
		var kp := KeyPickup.new()
		kp.key_id = str(k["id"])
		kp.position = _to_vec3(k["pos"])
		kp.key_collected.connect(_on_key_collected)
		_world_root.add_child(kp)
		var k_state := int(k.get("state", -1))
		if k_state >= 0:
			_state_nodes.append({"node": kp, "body": null, "state": k_state})

	# 6. Pressure Plates
	for pl in stage_def.get("plates", []):
		var plate := PressurePlate.new()
		plate.plate_id = str(pl["id"])
		plate.position = _to_vec3(pl["pos"])
		plate.accept_player = bool(pl.get("accept_player", true))
		plate.accept_echo = bool(pl.get("accept_echo", true))
		plate.accept_block = bool(pl.get("accept_block", true))
		plate.stay_pressed = bool(pl.get("stay_pressed", false))
		plate.plate_state_changed.connect(_on_plate_changed)
		_world_root.add_child(plate)
		_plates[plate.plate_id] = plate

	# 7. Pushable Blocks
	for blk in stage_def.get("blocks", []):
		var pb := PushableBlock.new()
		pb.position = _to_vec3(blk["pos"])
		_world_root.add_child(pb)
		_pushable_blocks.append(pb)

	# 8. Gravity Zones
	for gz in stage_def.get("gravity_zones", []):
		var zone := GravityZone.new()
		zone.zone_id = str(gz["id"])
		zone.position = _to_vec3(gz["pos"])
		zone.zone_size = _to_vec3(gz.get("size", [3.4, 5.5, 3.4]))
		zone.starts_active = bool(gz.get("starts_active", false))
		_world_root.add_child(zone)
		_gravity_zones[zone.zone_id] = zone

	# 9. Checkpoints
	for cp in stage_def.get("checkpoints", []):
		var pad := CheckpointPad.new()
		pad.checkpoint_id = str(cp["id"])
		pad.position = _to_vec3(cp["pos"])
		pad.checkpoint_reached.connect(_on_checkpoint_reached)
		_world_root.add_child(pad)

	# 10. Hidden Memory Secret
	if stage_def.has("secret"):
		var sec: Dictionary = stage_def["secret"]
		var ms := MemorySecret.new()
		ms.secret_id = str(sec["id"])
		ms.lore_key = str(sec["lore_key"])
		ms.position = _to_vec3(sec["pos"])
		ms.secret_collected.connect(_on_secret_collected)
		_world_root.add_child(ms)
		var s_state := int(sec.get("state", -1))
		if s_state >= 0:
			_state_nodes.append({"node": ms, "body": null, "state": s_state})

	# 11. Clue Stones (open Parchment Reading Panel!)
	for cl in stage_def.get("clues", []):
		var cs := ClueStone.new()
		cs.clue_key = str(cl["key"])
		cs.position = _to_vec3(cl["pos"])
		cs.clue_read.connect(func(k: String) -> void: _hud.show_parchment_note(k))
		_world_root.add_child(cs)

	# 12. Four Door Types
	for d in stage_def.get("doors", []):
		var dtype := str(d["type"])
		var dpos := _to_vec3(d["pos"])
		var drot := float(d.get("rot_y", 0.0))
		match dtype:
			"golden":
				var gd := GoldenDoor.new()
				gd.door_id = str(d.get("id", "exit_door"))
				gd.position = dpos
				gd.rotation_degrees.y = drot
				gd.required_keys = int(d.get("required_keys", 0))
				gd.required_switches = int(d.get("required_switches", 0))
				gd.stage_exit_requested.connect(_on_stage_completed)
				_world_root.add_child(gd)
				_golden_door = gd
			"blue":
				var bd := BlueDoor.new()
				bd.door_id = str(d.get("id", "blue_door"))
				bd.position = dpos
				bd.rotation_degrees.y = drot
				bd.linked_zone_id = str(d.get("zone_id", "grav_1"))
				bd.gravity_toggled.connect(_on_gravity_toggled)
				_world_root.add_child(bd)
			"purple":
				var pd := PurpleDoor.new()
				pd.door_id = str(d.get("id", "purple_door"))
				pd.position = dpos
				pd.rotation_degrees.y = drot
				pd.room_state_toggle_requested.connect(_on_purple_door_toggled)
				_world_root.add_child(pd)
				_purple_doors.append(pd)
			"black":
				var kd := BlackDoor.new()
				kd.door_id = str(d.get("id", "black_door"))
				kd.position = dpos
				kd.rotation_degrees.y = drot
				kd.target_position = _to_vec3(d["target_pos"])
				kd.target_world_side = int(d.get("target_world_side", 1))
				kd.world_transfer_requested.connect(_on_black_door_transfer)
				_world_root.add_child(kd)

	# 13. Stage 120 Ending Pedestals
	for ep in stage_def.get("endings", []):
		var ped := EndingPedestal.new()
		ped.ending_id = str(ep["id"])
		ped.position = _to_vec3(ep["pos"])
		ped.emblem = str(ep.get("emblem", "✦"))
		ped.requires_secret_unlock = bool(ep.get("secret_only", false))
		ped.accent_color = Color.html(str(ep.get("color", "#ffcc55")))
		ped.ending_selected.connect(func(eid: String) -> void: GameState.trigger_ending(eid))
		_world_root.add_child(ped)


func _spawn_boss_if_finale() -> void:
	if stage_id % 20 != 0:
		return
	var w_idx := int(stage_def.get("world", 1))
	_boss = GuardianBoss.new()
	_boss.world_index = w_idx
	_boss.is_echo_boss = (w_idx == 5 or w_idx == 6)
	var anchor := _golden_door.position if _golden_door != null else _stage_center
	_boss.position = anchor + Vector3(0.0, 4.2, -1.6)
	_boss.boss_spoke.connect(func(k: String) -> void: _hud.show_toast(k, 5.5))
	_world_root.add_child(_boss)


func _create_bridge_body(p_a: Vector3, p_b: Vector3, width: float, is_magic: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mid := (p_a + p_b) * 0.5
	var diff := p_b - p_a
	var length := maxf(diff.length(), 0.5)
	body.position = mid + Vector3(0.0, 0.035, 0.0)
	body.rotation.y = atan2(diff.x, diff.z)

	var mat := LowPolyMeshLibrary.make_flat_material(
		Color(0.24, 0.58, 0.78) if is_magic else Color(0.36, 0.22, 0.18),
		0.72,
		Color(0.22, 0.68, 0.88) if is_magic else Color.BLACK,
		0.48 if is_magic else 0.0
	)
	var rail_mat := LowPolyMeshLibrary.make_flat_material(
		Color(0.36, 0.72, 0.88) if is_magic else Color(0.24, 0.14, 0.14), 0.78
	)
	var usable_len := maxf(length + 0.55, 0.8)
	var planks := clampi(int(round(usable_len * 2.1)), 3, 16)
	for i in range(planks):
		var t := (float(i) + 0.5) / float(planks) - 0.5
		var plank := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(width, 0.12, (usable_len / float(planks)) * 0.80)
		plank.mesh = box
		plank.position = Vector3(0.0, -0.06, t * usable_len)
		plank.material_override = mat
		body.add_child(plank)

	for side_x in [-width * 0.47, width * 0.47]:
		var rail := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(0.11, 0.16, usable_len)
		rail.mesh = rbox
		rail.position = Vector3(side_x, 0.02, 0.0)
		rail.material_override = rail_mat
		body.add_child(rail)

	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(width + 0.16, 0.28, usable_len + 0.28)
	col.shape = cbox
	col.position = Vector3(0.0, -0.14, 0.0)
	body.add_child(col)
	return body


func _setup_player_and_camera() -> void:
	_respawn_pos = _to_vec3(stage_def.get("spawn", [0.0, 0.25, 0.0]))
	var saved_cp := SaveManager.get_saved_checkpoint(stage_id)
	if not saved_cp.is_empty():
		for cp in stage_def.get("checkpoints", []):
			if str(cp["id"]) == saved_cp:
				_respawn_pos = _to_vec3(cp["pos"]) + Vector3(0.0, 0.25, 0.0)
				break

	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = _respawn_pos
	_player.fell_into_void.connect(_on_player_fell)
	_player.interaction_target_changed.connect(_on_interaction_target_changed)
	add_child(_player)

	_camera_rig = IsoCameraRig.new()
	_camera_rig.name = "IsoCameraRig"
	add_child(_camera_rig)
	_camera_rig.set_target(_player, true)
	_player.set_camera_reference(_camera_rig.camera)


func _setup_hud_and_echo() -> void:
	_hud = HUD_SCENE.instantiate() as GameHUD
	add_child(_hud)
	_hud.set_stage_info(stage_id, str(stage_def.get("title_key", "")), str(stage_def.get("objective_key", "")))
	_hud.restart_checkpoint_requested.connect(_restart_from_checkpoint)
	_hud.next_stage_requested.connect(func() -> void: GameState.start_stage(stage_id + 1))
	_hud.hint_ad_requested.connect(func() -> void: MonetizationBridge.request_hint_ad())
	_hud.skip_stage_ad_requested.connect(func() -> void: MonetizationBridge.request_skip_stage_ad())
	MonetizationBridge.ad_reward_granted.connect(_on_ad_reward_granted)
	MonetizationBridge.ad_unavailable.connect(_on_ad_unavailable)

	_echo_recorder = EchoRecorder.new()
	_echo_recorder.name = "EchoRecorder"
	add_child(_echo_recorder)
	_echo_recorder.setup(_player, _world_root)
	_echo_recorder.state_changed.connect(_hud.update_echo_state)
	_echo_recorder.echo_feedback.connect(func(k: String) -> void: _hud.show_toast(k, 2.8))


func _play_opening_cinematic() -> void:
	## Real in-engine 3D Opening Cinematic on Stage 1 (skippable, bilingual subtitles).
	_cinematic_active = true
	if _player != null:
		_player.movement_locked = true
	var door_pos := _golden_door.position if _golden_door != null else _stage_center
	var lines := ["intro_line_1", "intro_line_2", "intro_line_3", "intro_line_4"]
	var tw := _camera_rig.play_cinematic_shot(
		door_pos + Vector3(0.0, 2.2, 0.0),
		_player.global_position,
		Vector3(16.0, 14.0, 16.0),
		_camera_rig.base_offset,
		11.5
	)
	_hud.play_cinematic_subtitles(lines, func() -> void:
		if tw != null and tw.is_running():
			tw.kill()
		_finish_opening_cinematic()
	)


func _finish_opening_cinematic() -> void:
	if not _cinematic_active:
		return
	_cinematic_active = false
	SaveManager.mark_intro_seen()
	if _camera_rig != null:
		_camera_rig.reset_view()
		_camera_rig.snap_to_target()
	if _player != null:
		_player.movement_locked = false
	_hud.show_story_chapter(1, "world_1_story")


func _on_key_collected(_key_id: String) -> void:
	_keys_collected += 1
	if _boss != null and is_instance_valid(_boss):
		_boss.react_to_progress()
	_evaluate_door_conditions()
	_hud.show_toast("toast_key_collected", 2.5)


func _on_plate_changed(plate_id: String, pressed: bool) -> void:
	if _plate_bridges.has(plate_id):
		for entry in (_plate_bridges[plate_id] as Array):
			_set_body_active(entry["node"] as Node3D, entry["body"] as CollisionObject3D, pressed)
	if pressed and _boss != null and is_instance_valid(_boss):
		_boss.react_to_progress()
	_evaluate_door_conditions()


func _evaluate_door_conditions() -> void:
	if _golden_door == null:
		return
	var active_door_plates := 0
	for pid in _plates.keys():
		if not _plate_bridges.has(pid) and (_plates[pid] as PressurePlate).is_pressed:
			active_door_plates += 1
	_golden_door.update_conditions(_keys_collected, active_door_plates)
	_hud.update_key_counter(_keys_collected, _golden_door.required_keys)
	if _golden_door.is_unlocked and _boss != null and is_instance_valid(_boss):
		_boss.on_door_unlocked()


func _on_gravity_toggled(zone_id: String, reversed: bool) -> void:
	if _gravity_zones.has(zone_id):
		(_gravity_zones[zone_id] as GravityZone).set_zone_active(reversed)
		_hud.show_toast("toast_gravity_on" if reversed else "toast_gravity_off", 2.6)


func _on_purple_door_toggled(_door: PurpleDoor) -> void:
	_apply_room_state(1 - _active_room_state)
	_hud.show_toast("toast_state_b" if _active_room_state == 1 else "toast_state_a", 2.6)


func _apply_room_state(state_idx: int) -> void:
	_active_room_state = state_idx
	if _player != null:
		_player.active_room_state = state_idx
	for pd in _purple_doors:
		pd.set_visual_state(state_idx)
	for entry in _state_nodes:
		var match_state := (int(entry["state"]) == state_idx)
		_set_body_active(entry["node"] as Node3D, entry["body"] as CollisionObject3D, match_state)


func _set_body_active(node: Node3D, body: CollisionObject3D, active: bool) -> void:
	if node != null and is_instance_valid(node):
		if node.has_method("set_state_active"):
			node.call("set_state_active", active)
		else:
			node.visible = active
	if body != null and is_instance_valid(body):
		body.collision_layer = 1 if active else 0


func _on_black_door_transfer(_door: BlackDoor, target_pos: Vector3, target_world_side: int) -> void:
	if _player == null:
		return
	_player.reset_gravity_zone()
	_player.global_position = target_pos
	_player.velocity = Vector3.ZERO
	_player.current_world_side = target_world_side
	_camera_rig.snap_to_target()
	_hud.show_toast("toast_world_alt" if target_world_side == 1 else "toast_world_prime", 2.8)


func _on_checkpoint_reached(cp_id: String, spawn_pos: Vector3) -> void:
	_respawn_pos = spawn_pos
	_respawn_world_side = _player.current_world_side if _player != null else 0
	SaveManager.save_checkpoint(stage_id, cp_id)
	_hud.show_toast("toast_checkpoint", 2.4)


func _on_secret_collected(_secret_id: String, lore_key: String) -> void:
	var total := SaveManager.get_collected_secret_count()
	if total == GameState.POWER_INSIGHT_CRYSTALS:
		_hud.show_toast("power_insight_unlocked", 6.5)
	elif total == GameState.POWER_ECHO_CRYSTALS:
		_hud.show_toast("power_echo_unlocked", 6.5)
	elif total == GameState.POWER_STRIDE_CRYSTALS:
		_hud.show_toast("power_stride_unlocked", 6.5)
	elif total == GameState.SECRET_ENDING_REQUIRED_SECRETS:
		_hud.show_toast("power_secret_unlocked", 6.5)
	else:
		_hud.show_toast(lore_key, 6.5)


func _on_player_fell() -> void:
	_restart_from_checkpoint()


func _restart_from_checkpoint() -> void:
	if _echo_recorder != null:
		_echo_recorder.reset_echo()
	if _player != null:
		_player.reset_gravity_zone()
		_player.global_position = _respawn_pos
		_player.velocity = Vector3.ZERO
		_player.current_world_side = _respawn_world_side
		_camera_rig.snap_to_target()
	for pb in _pushable_blocks:
		pb.reset_block()
	_hud.show_toast("toast_respawned", 2.0)


func _on_interaction_target_changed(target: Node) -> void:
	var cam := _camera_rig.camera if _camera_rig != null else null
	_hud.set_interaction_target(target, cam)


func _on_stage_completed(door: GoldenDoor) -> void:
	SaveManager.mark_stage_completed(stage_id)
	if _player != null:
		_player.movement_locked = true
		var walk_tw := create_tween()
		walk_tw.tween_property(_player, "global_position", door.global_position, 0.95).set_trans(Tween.TRANS_SINE)
	if _camera_rig != null:
		_camera_rig.play_door_zoom_in(door.global_position, 1.15)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 50
	add_child(fade_layer)
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.92, 0.72, 0.0)
	fade_layer.add_child(flash)
	var tw := create_tween()
	tw.tween_interval(0.55)
	tw.tween_property(flash, "color:a", 1.0, 0.65).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func() -> void:
		if stage_id < GameState.TOTAL_STAGES:
			GameState.start_stage(stage_id + 1)
	)


func _spawn_3d_starfield(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = stage_id * 73 + 19
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.albedo_color = Color(0.88, 0.94, 1.0)
	var sph := SphereMesh.new()
	sph.radius = 0.085
	sph.height = 0.17
	sph.radial_segments = 4
	sph.rings = 2
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sph
	mm.instance_count = count
	for i in range(count):
		var dist := rng.randf_range(48.0, 82.0)
		var theta := rng.randf_range(0.0, TAU)
		var phi := rng.randf_range(-0.18, 0.92)
		var pos := Vector3(cos(theta) * cos(phi) * dist, sin(phi) * dist + 2.0, sin(theta) * cos(phi) * dist)
		var sc := rng.randf_range(0.5, 1.35)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(sc, sc, sc)), pos))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = star_mat
	_world_root.add_child(mmi)


func _exit_tree() -> void:
	if MonetizationBridge.ad_reward_granted.is_connected(_on_ad_reward_granted):
		MonetizationBridge.ad_reward_granted.disconnect(_on_ad_reward_granted)
	if MonetizationBridge.ad_unavailable.is_connected(_on_ad_unavailable):
		MonetizationBridge.ad_unavailable.disconnect(_on_ad_unavailable)
	if SaveManager.settings_changed.is_connected(_on_settings_changed):
		SaveManager.settings_changed.disconnect(_on_settings_changed)


static func _to_vec3(v: Variant) -> Vector3:
	if v is Vector3:
		return v as Vector3
	if v is Array and (v as Array).size() >= 3:
		var a := v as Array
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


func _on_ad_reward_granted(placement: String) -> void:
	if placement == "hint":
		var hint_k := str(stage_def.get("hint_key", ""))
		if hint_k.is_empty():
			hint_k = str(stage_def.get("objective_key", "ad_hint_granted"))
		_hud.show_toast(hint_k, 7.0)
	elif placement == "skip_stage" and stage_id < GameState.TOTAL_STAGES:
		SaveManager.mark_stage_completed(stage_id)
		_hud.show_toast("ad_skip_granted", 2.0)
		GameState.start_stage(stage_id + 1)


func _on_ad_unavailable(_placement: String, reason_key: String) -> void:
	_hud.show_toast(reason_key, 3.8)


func _build_energy_conduits() -> void:
	## Redesigned puzzle causality guides: subtle low-profile glowing rune stones embedded along the path
	## instead of crude straight cyan sticks floating across empty air; toggleable in Settings.
	_conduit_root = Node3D.new()
	_conduit_root.name = "PuzzleGuides"
	_conduit_root.visible = bool(SaveManager.get_setting("puzzle_guides", true))
	_world_root.add_child(_conduit_root)

	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = Color(0.24, 0.78, 0.92, 0.58)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.22, 0.76, 0.94)
	rune_mat.emission_energy_multiplier = 0.85
	rune_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var dot_mesh := CylinderMesh.new()
	dot_mesh.top_radius = 0.08
	dot_mesh.bottom_radius = 0.11
	dot_mesh.height = 0.03
	dot_mesh.radial_segments = 6

	for pid in _plates.keys():
		var pl: PressurePlate = _plates[pid]
		var targets: Array[Vector3] = []
		if _plate_bridges.has(pid):
			for entry in (_plate_bridges[pid] as Array):
				var n := entry["node"] as Node3D
				if n != null:
					targets.append(n.position)
		elif _golden_door != null and _golden_door.required_switches > 0:
			targets.append(_golden_door.position)
		for tp in targets:
			var a := Vector3(pl.position.x, pl.position.y + 0.03, pl.position.z)
			var b := Vector3(tp.x, tp.y + 0.03, tp.z)
			var dist := a.distance_to(b)
			if dist < 0.8:
				continue
			# Place 3-6 subtle stepping runes only near plate & target, never cutting across void as a beam
			var steps := clampi(int(dist / 2.2), 2, 6)
			for s in range(1, steps):
				var t := float(s) / float(steps)
				var pt := a.lerp(b, t)
				var m := MeshInstance3D.new()
				m.mesh = dot_mesh
				m.position = pt
				m.material_override = rune_mat
				_conduit_root.add_child(m)
