class_name PurpleDoor
extends BaseDoor

## Purple State Door: toggles the stage between Room State A (0) and Room State B (1),
## revealing alternate platforms, bridges, and objects.

signal room_state_toggle_requested(door: PurpleDoor)

var current_state: int = 0


func _ready() -> void:
	door_color = Color(0.76, 0.36, 0.96)
	frame_color = Color(0.24, 0.13, 0.34)
	emblem_text = "◈"
	is_unlocked = true
	super._ready()


func set_visual_state(state_idx: int) -> void:
	current_state = state_idx
	_target_angle = deg_to_rad(-40.0) if current_state == 1 else 0.0


func get_prompt_key() -> String:
	return "prompt_shift_state"


func interact(player: Node) -> void:
	AudioManager.play_sfx("state_shift")
	door_activated.emit(self, player)
	room_state_toggle_requested.emit(self)
