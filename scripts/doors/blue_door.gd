class_name BlueDoor
extends BaseDoor

## Blue Gravity Door: toggles local gravity reversal / low-gravity lift in its linked zone.

signal gravity_toggled(zone_id: String, reversed: bool)

@export var linked_zone_id: String = "grav_1"
var gravity_active: bool = false


func _ready() -> void:
	door_color = Color(0.24, 0.78, 1.0)
	frame_color = Color(0.14, 0.22, 0.36)
	emblem_text = "▲"
	is_unlocked = true
	super._ready()


func get_prompt_key() -> String:
	return "prompt_toggle_gravity"


func interact(player: Node) -> void:
	gravity_active = not gravity_active
	_target_angle = deg_to_rad(-42.0) if gravity_active else 0.0
	AudioManager.play_sfx("gravity_flip")
	door_activated.emit(self, player)
	gravity_toggled.emit(linked_zone_id, gravity_active)
