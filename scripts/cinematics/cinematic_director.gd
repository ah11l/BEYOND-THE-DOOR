class_name CinematicDirector
extends Node

## Real 3D in-engine Cinematic Director:
## Orchestrates dynamic camera choreography, spawned 3D Echo/Guardian actors,
## lighting pulses, and skippable bilingual subtitles for:
## - Opening Sequence, all 6 World Introductions (1, 21, 41, 61, 81, 101)
## - 6 Mid-World Story/Discovery Cinematics (10, 30, 50, 70, 90, 110)
## - Boss Entrance Cinematics (5, 20, 40, 60, 80, 100, 120)

signal cinematic_finished

var _active: bool = false
var _temp_actors: Array[Node3D] = []
var _active_tween: Tween = null


func is_playing() -> bool:
	return _active


func play_sequence(
	world_root: Node3D,
	camera_rig: IsoCameraRig,
	player: PlayerController,
	hud: GameHUD,
	focus_a: Vector3,
	focus_b: Vector3,
	from_offset: Vector3,
	to_offset: Vector3,
	line_keys: Array,
	spawn_echo_actor_pos: Vector3 = Vector3(9999.0, 0.0, 0.0),
	spawn_guardian_pos: Vector3 = Vector3(9999.0, 0.0, 0.0),
	on_done: Callable = Callable()
) -> void:
	if _active or camera_rig == null or hud == null:
		if on_done.is_valid():
			on_done.call()
		return
	_active = true
	if player != null and is_instance_valid(player):
		player.movement_locked = true

	# Optionally stage live 3D Echo or Guardian actors during story beats!
	if world_root != null and spawn_echo_actor_pos.x < 9000.0:
		var echo_vis := LowPolyMeshLibrary.build_hooded_character(true)
		echo_vis.position = spawn_echo_actor_pos
		if player != null:
			echo_vis.look_at(player.global_position, Vector3.UP)
		world_root.add_child(echo_vis)
		_temp_actors.append(echo_vis)

	if world_root != null and spawn_guardian_pos.x < 9000.0:
		var guard := GuardianBoss.new()
		guard.world_index = clampi(int(ceil(float(GameState.current_stage_id) / 20.0)), 1, 6)
		guard.position = spawn_guardian_pos
		world_root.add_child(guard)
		_temp_actors.append(guard)

	var total_dur := maxf(4.0, float(line_keys.size()) * 2.85)
	_active_tween = camera_rig.play_cinematic_shot(focus_a, focus_b, from_offset, to_offset, total_dur)

	hud.play_cinematic_subtitles(line_keys, func() -> void:
		_cleanup(camera_rig, player)
		if on_done.is_valid():
			on_done.call()
		cinematic_finished.emit()
	)


func _cleanup(camera_rig: IsoCameraRig, player: PlayerController) -> void:
	_active = false
	if _active_tween != null and _active_tween.is_running():
		_active_tween.kill()
	_active_tween = null
	for a in _temp_actors:
		if is_instance_valid(a):
			a.queue_free()
	_temp_actors.clear()
	if camera_rig != null and is_instance_valid(camera_rig):
		camera_rig.reset_view()
		camera_rig.snap_to_target()
	if player != null and is_instance_valid(player):
		player.movement_locked = false
