class_name EchoRecorder
extends Node

## Signature "Echo / صدى المكان" mechanic:
## Records up to 5.0 seconds (7.0s with Crystal Power) of player movement at fixed physics ticks
## and replays them via a glowing cyan ghost that respects recorded world_side & room_state.

enum EchoState { IDLE, RECORDING, REPLAYING }

signal state_changed(new_state: int, progress: float)
signal echo_feedback(message_key: String)

const MAX_RECORD_SECONDS := 5.0
const MIN_RECORD_SECONDS := 0.25
const GHOST_SCENE := preload("res://scenes/player/echo_ghost.tscn")

var state: int = EchoState.IDLE
var player: PlayerController = null
var ghost_parent: Node3D = null

var _recorded_frames: Array[Dictionary] = []
var _record_elapsed: float = 0.0
var _replay_elapsed: float = 0.0
var _replay_duration: float = 0.0
var _active_ghost: EchoGhost = null


func _ready() -> void:
	GameState.touch_echo_pressed.connect(toggle_echo_action)


func setup(player_ref: PlayerController, parent_3d: Node3D) -> void:
	player = player_ref
	ghost_parent = parent_3d
	reset_echo()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("echo_action"):
		toggle_echo_action()

	match state:
		EchoState.RECORDING:
			if player == null or not is_instance_valid(player):
				reset_echo()
				return
			_recorded_frames.append({
				"pos": player.global_position,
				"rot_y": player.rotation.y,
				"world_side": player.current_world_side,
				"room_state": player.active_room_state,
			})
			_record_elapsed += delta
			var max_dur := GameState.get_echo_duration()
			var ratio := clampf(_record_elapsed / max_dur, 0.0, 1.0)
			state_changed.emit(state, ratio)
			if _record_elapsed >= max_dur:
				stop_and_replay()
		EchoState.REPLAYING:
			_replay_elapsed += delta
			var remaining := 1.0 - clampf(_replay_elapsed / maxf(_replay_duration, 0.01), 0.0, 1.0)
			state_changed.emit(state, remaining)


func toggle_echo_action() -> void:
	if player == null or player.movement_locked:
		return
	match state:
		EchoState.IDLE:
			start_recording()
		EchoState.RECORDING:
			stop_and_replay()
		EchoState.REPLAYING:
			# Cancel active replay cleanly so player can immediately record a fresh path
			reset_echo()
			echo_feedback.emit("echo_cancelled")


func start_recording() -> void:
	_clear_ghost()
	_recorded_frames.clear()
	_record_elapsed = 0.0
	state = EchoState.RECORDING
	AudioManager.play_sfx("echo_record")
	state_changed.emit(state, 0.0)
	echo_feedback.emit("echo_recording_started")


func stop_and_replay() -> void:
	if state != EchoState.RECORDING:
		return
	if _record_elapsed < MIN_RECORD_SECONDS or _recorded_frames.size() < 4:
		state = EchoState.IDLE
		_recorded_frames.clear()
		state_changed.emit(state, 0.0)
		echo_feedback.emit("echo_too_short")
		return

	state = EchoState.REPLAYING
	_replay_elapsed = 0.0
	_replay_duration = _record_elapsed
	AudioManager.play_sfx("echo_replay")
	_spawn_ghost()
	state_changed.emit(state, 1.0)
	echo_feedback.emit("echo_replaying")


func _spawn_ghost() -> void:
	_clear_ghost()
	if ghost_parent == null:
		return
	_active_ghost = GHOST_SCENE.instantiate() as EchoGhost
	ghost_parent.add_child(_active_ghost)
	_active_ghost.replay_finished.connect(_on_ghost_finished)
	_active_ghost.start_replay(_recorded_frames, player)


func _on_ghost_finished() -> void:
	_active_ghost = null
	if state == EchoState.REPLAYING:
		state = EchoState.IDLE
		state_changed.emit(state, 0.0)


func _clear_ghost() -> void:
	if _active_ghost != null and is_instance_valid(_active_ghost):
		_active_ghost.queue_free()
	_active_ghost = null


func reset_echo() -> void:
	_clear_ghost()
	_recorded_frames.clear()
	_record_elapsed = 0.0
	_replay_elapsed = 0.0
	state = EchoState.IDLE
	state_changed.emit(state, 0.0)


func _exit_tree() -> void:
	if GameState.touch_echo_pressed.is_connected(toggle_echo_action):
		GameState.touch_echo_pressed.disconnect(toggle_echo_action)
