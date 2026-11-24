class_name StageSuspenseDirector
extends Node3D

## Real playable suspense & discovery moments triggered every 2-3 stages across all 120 stages:
## 1. Watching Shadow (watcher_shadow): A mysterious hooded figure watches from afar and vanishes in sparks when approached.
## 2. Sky Tremor & Door Beacon (sky_tremor): A sudden tremor shakes the camera as a luminous light pillar strikes the Golden Door.
## 3. Guiding Memory Wisp (memory_wisp): A glowing spirit orb dances toward the stage's key/door and whispers a secret when touched.
## 4. Distant Guardian Omen (guardian_omen): A giant translucent astral eye-ring glides overhead with a mysterious whisper.

var _world_index: int = 1
var _stage_id: int = 1
var _player: Node3D = null
var _camera_rig: IsoCameraRig = null
var _hud: GameHUD = null
var _goal_pos: Vector3 = Vector3.ZERO
var _stage_center: Vector3 = Vector3.ZERO

var _event_type: String = ""
var _event_node: Node3D = null
var _triggered: bool = false
var _elapsed: float = 0.0
var _wisp_start: Vector3 = Vector3.ZERO
var _wisp_end: Vector3 = Vector3.ZERO
var _watcher_pos: Vector3 = Vector3.ZERO


func setup(stage_id: int, world_idx: int, player: Node3D, camera_rig: IsoCameraRig, hud: GameHUD, goal_pos: Vector3, stage_center: Vector3) -> void:
	_stage_id = stage_id
	_world_index = clampi(world_idx, 1, 6)
	_player = player
	_camera_rig = camera_rig
	_hud = hud
	_goal_pos = goal_pos
	_stage_center = stage_center

	# Trigger every 2-3 stages, skipping stages that already have a major intro/mid/boss cinematic
	var major_cinematics := [1, 5, 10, 20, 21, 30, 40, 41, 50, 60, 61, 70, 80, 81, 90, 100, 101, 110, 120]
	if _stage_id in major_cinematics:
		return
	var mod_val := _stage_id % 5
	if mod_val != 2 and mod_val != 4:
		return

	var cycle := (_stage_id / 2) % 4
	match cycle:
		0:
			_spawn_watching_shadow()
		1:
			_event_type = "sky_tremor"
		2:
			_spawn_memory_wisp()
		_:
			_spawn_guardian_omen()


func _spawn_watching_shadow() -> void:
	_event_type = "watcher_shadow"
	var p_pos := _player.global_position if _player != null else Vector3.ZERO
	var dir := (_goal_pos - p_pos)
	dir.y = 0.0
	if dir.length() < 1.5:
		dir = Vector3(1.0, 0.0, -1.0)
	dir = dir.normalized()
	_watcher_pos = p_pos + dir * 5.2 + Vector3(0.0, 0.15, 0.0)

	_event_node = LowPolyMeshLibrary.build_hooded_character(true, "wanderer")
	_event_node.name = "SuspenseWatcher"
	_event_node.position = _watcher_pos
	_event_node.look_at(Vector3(p_pos.x, _watcher_pos.y, p_pos.z), Vector3.UP)
	add_child(_event_node)


func _spawn_memory_wisp() -> void:
	_event_type = "memory_wisp"
	var pal := LowPolyMeshLibrary.get_world_palette(_world_index)
	var glow_col: Color = pal.get("rune_glow", Color(0.32, 0.88, 1.0))
	var p_pos := _player.global_position if _player != null else Vector3.ZERO
	_wisp_start = p_pos + Vector3(1.4, 1.35, -1.4)
	_wisp_end = _goal_pos + Vector3(0.0, 1.65, 0.0)

	_event_node = Node3D.new()
	_event_node.name = "SuspenseWisp"
	_event_node.position = _wisp_start

	var core := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.22
	sph.height = 0.44
	sph.radial_segments = 8
	sph.rings = 4
	core.mesh = sph
	core.material_override = LowPolyMeshLibrary.make_flat_material(glow_col.lightened(0.3), 0.1, glow_col, 2.5)
	_event_node.add_child(core)

	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.30
	tor.outer_radius = 0.36
	tor.rings = 16
	tor.ring_segments = 6
	ring.mesh = tor
	ring.material_override = LowPolyMeshLibrary.make_flat_material(Color(1.0, 0.88, 0.48), 0.15, Color(1.0, 0.84, 0.40), 1.8)
	_event_node.add_child(ring)

	var light := OmniLight3D.new()
	light.light_color = glow_col
	light.light_energy = 1.6
	light.omni_range = 4.5
	_event_node.add_child(light)
	add_child(_event_node)


func _spawn_guardian_omen() -> void:
	_event_type = "guardian_omen"
	var pal := LowPolyMeshLibrary.get_world_palette(_world_index)
	var glow_col: Color = pal.get("rune_glow", Color(0.32, 0.88, 1.0))

	_event_node = Node3D.new()
	_event_node.name = "SuspenseOmen"
	_event_node.position = _stage_center + Vector3(-14.0, 9.5, -14.0)

	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 2.6
	tor.outer_radius = 3.0
	tor.rings = 24
	tor.ring_segments = 6
	ring.mesh = tor
	ring.rotation_degrees = Vector3(68.0, 0.0, 0.0)
	ring.material_override = LowPolyMeshLibrary.make_flat_material(glow_col, 0.2, glow_col, 1.6)
	_event_node.add_child(ring)

	var eye := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.85
	sph.height = 1.7
	sph.radial_segments = 8
	sph.rings = 4
	eye.mesh = sph
	eye.material_override = LowPolyMeshLibrary.make_flat_material(Color(1.0, 0.82, 0.42), 0.1, Color(1.0, 0.78, 0.34), 2.2)
	_event_node.add_child(eye)
	add_child(_event_node)


func _process(delta: float) -> void:
	if _event_type.is_empty():
		return
	_elapsed += delta

	match _event_type:
		"watcher_shadow":
			if _event_node != null and is_instance_valid(_event_node) and not _triggered:
				_event_node.position.y = _watcher_pos.y + sin(_elapsed * 2.2) * 0.12
				if _player != null and is_instance_valid(_player):
					var d := _player.global_position.distance_to(_event_node.global_position)
					if d < 4.0 or _elapsed > 8.5:
						_vanish_watcher()
		"sky_tremor":
			if not _triggered and _elapsed >= 3.8:
				_trigger_sky_tremor()
		"memory_wisp":
			if _event_node != null and is_instance_valid(_event_node) and not _triggered:
				var progress := clampf((_elapsed - 1.2) / 6.5, 0.0, 1.0)
				var base_p := _wisp_start.lerp(_wisp_end, progress)
				_event_node.position = base_p + Vector3(sin(_elapsed * 2.8) * 0.45, sin(_elapsed * 4.2) * 0.22, cos(_elapsed * 2.4) * 0.45)
				_event_node.rotation.y += delta * 2.2
				if (_player != null and is_instance_valid(_player) and _player.global_position.distance_to(_event_node.global_position) < 2.2) or progress >= 1.0:
					_dissolve_wisp()
		"guardian_omen":
			if _event_node != null and is_instance_valid(_event_node):
				_event_node.position.x += delta * 2.6
				_event_node.rotation.y += delta * 0.6
				if not _triggered and _elapsed >= 3.2:
					_triggered = true
					if _camera_rig != null:
						_camera_rig.trigger_shake(0.14, 0.55)
					AudioManager.play_sfx("state_shift")
					if _hud != null:
						_hud.show_toast("suspense_omen_w%d" % _world_index, 4.6)
				if _elapsed >= 13.0:
					_event_node.queue_free()
					_event_type = ""


func _vanish_watcher() -> void:
	_triggered = true
	AudioManager.play_sfx("echo_replay")
	if _hud != null:
		_hud.show_toast("suspense_watcher_w%d" % _world_index, 4.6)
	if _event_node != null and is_instance_valid(_event_node):
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_event_node, "scale", Vector3(0.05, 2.2, 0.05), 0.55).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(_event_node, "position:y", _event_node.position.y + 1.8, 0.55)
		tw.chain().tween_callback(func() -> void:
			if is_instance_valid(_event_node):
				_event_node.queue_free()
		)


func _trigger_sky_tremor() -> void:
	_triggered = true
	if _camera_rig != null:
		_camera_rig.trigger_shake(0.24, 0.80)
	AudioManager.play_sfx("gravity_flip")
	if _hud != null:
		_hud.show_toast("suspense_tremor_w%d" % _world_index, 4.6)

	var pal := LowPolyMeshLibrary.get_world_palette(_world_index)
	var glow_col: Color = pal.get("rune_glow", Color(1.0, 0.82, 0.40))
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.95
	cyl.height = 18.0
	cyl.radial_segments = 10
	beam.mesh = cyl
	beam.position = _goal_pos + Vector3(0.0, 9.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(glow_col.r, glow_col.g, glow_col.b, 0.36)
	mat.emission_enabled = true
	mat.emission = glow_col
	mat.emission_energy_multiplier = 2.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = mat
	add_child(beam)

	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(beam):
			beam.queue_free()
	)


func _dissolve_wisp() -> void:
	_triggered = true
	AudioManager.play_sfx("secret_found")
	if _hud != null:
		_hud.show_toast("suspense_wisp_w%d" % _world_index, 4.6)
	if _event_node != null and is_instance_valid(_event_node):
		var tw := create_tween()
		tw.tween_property(_event_node, "scale", Vector3(2.2, 2.2, 2.2), 0.35)
		tw.tween_property(_event_node, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
		tw.tween_callback(func() -> void:
			if is_instance_valid(_event_node):
				_event_node.queue_free()
		)
