class_name BlackDoor
extends BaseDoor

## Black Alternate-World Door: transfers the player seamlessly to the paired alternate
## version of the room/world without disorienting coordinate or camera jumps.

signal world_transfer_requested(door: BlackDoor, target_pos: Vector3, target_world_side: int)

@export var target_position: Vector3 = Vector3.ZERO
@export var target_world_side: int = 1


func _ready() -> void:
	door_color = Color(0.14, 0.16, 0.28)
	frame_color = Color(0.70, 0.78, 0.92)
	emblem_text = "☾"
	is_unlocked = true
	super._ready()


func get_prompt_key() -> String:
	return "prompt_enter_black_door"


func interact(player: Node) -> void:
	AudioManager.play_sfx("portal_warp")
	door_activated.emit(self, player)
	world_transfer_requested.emit(self, target_position, target_world_side)
