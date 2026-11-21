class_name GoldenDoor
extends BaseDoor

## Golden Exit Door: opens when required keys and switches are satisfied.
## Triggers automatic cinematic transition when the player walks into or interacts with it.

signal stage_exit_requested(door: GoldenDoor)

@export var required_keys: int = 0
@export var required_switches: int = 0

var _collected_keys: int = 0
var _active_switches: int = 0
var _exit_triggered: bool = false


func _ready() -> void:
	door_color = Color(1.0, 0.80, 0.34)
	frame_color = Color(0.32, 0.19, 0.16)
	emblem_text = "★"
	is_unlocked = (required_keys <= 0 and required_switches <= 0)
	super._ready()
	if is_unlocked:
		_target_angle = deg_to_rad(-38.0)

	# Auto-enter trigger when walking directly into an unlocked Golden Door
	var walk_area := Area3D.new()
	walk_area.name = "AutoEnterArea"
	walk_area.collision_layer = 0
	walk_area.collision_mask = 2 # Player
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 2.4, 1.35)
	shape.shape = box
	shape.position = Vector3(0.0, 1.2, 0.0)
	walk_area.add_child(shape)
	walk_area.body_entered.connect(_on_player_walked_in)
	add_child(walk_area)


func update_conditions(keys_held: int, switches_active: int) -> void:
	_collected_keys = keys_held
	_active_switches = switches_active
	var satisfied := (_collected_keys >= required_keys and _active_switches >= required_switches)
	set_unlocked(satisfied)


func get_prompt_key() -> String:
	return "prompt_enter_golden_door" if is_unlocked else "prompt_door_locked"


func _on_player_walked_in(body: Node) -> void:
	if is_unlocked and not _exit_triggered and body is PlayerController:
		_trigger_cinematic_exit(body)


func interact(player: Node) -> void:
	if not is_unlocked:
		AudioManager.play_sfx("door_locked")
		return
	if not _exit_triggered:
		_trigger_cinematic_exit(player)


func _trigger_cinematic_exit(player: Node) -> void:
	_exit_triggered = true
	_target_angle = deg_to_rad(-108.0)
	if _glow_light != null:
		var tw := create_tween()
		tw.tween_property(_glow_light, "light_energy", 8.0, 0.85)
	AudioManager.play_sfx("stage_complete")
	door_activated.emit(self, player)
	stage_exit_requested.emit(self)
