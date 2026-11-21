class_name EchoGhost
extends CharacterBody3D

## Translucent cyan-glowing Echo ghost that deterministically replays up to 5-7 seconds
## of recorded player frames and activates Echo-enabled pressure plates/switches
## ONLY when its recorded world_side and room_state match the active stage state.

signal replay_finished

var _frames: Array[Dictionary] = []
var _frame_index: int = 0
var _active: bool = false
var _rig: Node3D = null
var _player_ref: PlayerController = null
var _collision_shape: CollisionShape3D = null


func _ready() -> void:
	collision_layer = 4 # Layer 3: Echo
	collision_mask = 0  # Ghost moves along recorded trajectory cleanly without snagging
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	_rig = LowPolyMeshLibrary.build_hooded_character(true)
	add_child(_rig)


func start_replay(recorded_frames: Array[Dictionary], player_ref: PlayerController = null) -> void:
	if recorded_frames.is_empty():
		replay_finished.emit()
		queue_free()
		return
	_player_ref = player_ref
	_frames = recorded_frames.duplicate(true)
	_frame_index = 0
	_active = true
	_apply_frame(_frames[0])


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	if _frame_index >= _frames.size():
		_active = false
		replay_finished.emit()
		queue_free()
		return
	_apply_frame(_frames[_frame_index])
	_frame_index += 1


func _apply_frame(frame: Dictionary) -> void:
	global_position = frame["pos"] as Vector3
	rotation.y = float(frame["rot_y"])
	if _rig != null:
		_rig.position.y = 0.04 * sin(float(_frame_index) * 0.25)

	var in_sync := true
	if _player_ref != null and is_instance_valid(_player_ref):
		var rec_world := int(frame.get("world_side", 0))
		var rec_room := int(frame.get("room_state", 0))
		in_sync = (rec_world == _player_ref.current_world_side and rec_room == _player_ref.active_room_state)

	visible = in_sync
	collision_layer = 4 if in_sync else 0
	if _collision_shape != null and is_instance_valid(_collision_shape):
		_collision_shape.disabled = not in_sync
