class_name GoldenDoor
extends BaseDoor

## Golden Exit Door: opens when all required keys and switches/plates are satisfied.

signal stage_exit_requested(door: GoldenDoor)

@export var required_keys: int = 0
@export var required_switches: int = 0

var _collected_keys: int = 0
var _active_switches: int = 0


func _ready() -> void:
	door_color = Color(1.0, 0.78, 0.30)
	frame_color = Color(0.34, 0.20, 0.16)
	emblem_text = "★"
	is_unlocked = (required_keys <= 0 and required_switches <= 0)
	super._ready()
	if is_unlocked:
		_target_angle = deg_to_rad(-38.0)


func update_conditions(keys_held: int, switches_active: int) -> void:
	_collected_keys = keys_held
	_active_switches = switches_active
	var satisfied := (_collected_keys >= required_keys and _active_switches >= required_switches)
	set_unlocked(satisfied)


func get_prompt_key() -> String:
	return "prompt_enter_golden_door" if is_unlocked else "prompt_door_locked"


func interact(player: Node) -> void:
	if not is_unlocked:
		AudioManager.play_sfx("door_locked")
		return
	AudioManager.play_sfx("stage_complete")
	door_activated.emit(self, player)
	stage_exit_requested.emit(self)
