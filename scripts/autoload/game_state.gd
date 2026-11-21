extends Node

## Central game session coordinator, scene router, and mobile input bridge.

signal touch_move_changed(vec: Vector2)
signal touch_jump_pressed
signal touch_interact_pressed
signal touch_echo_pressed
signal graphics_quality_changed(quality: String)

const SECRET_ENDING_REQUIRED_SECRETS := 18
const SCENE_MAIN_MENU := "res://scenes/main/main_menu.tscn"
const SCENE_STAGE := "res://scenes/game/stage_scene.tscn"
const SCENE_ENDING := "res://scenes/ui/ending_screen.tscn"

var current_stage_id: int = 1
var active_ending_id: String = ""
var touch_move_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	SaveManager.settings_changed.connect(_on_settings_changed)
	apply_graphics_quality()


func _on_settings_changed() -> void:
	apply_graphics_quality()


func apply_graphics_quality() -> void:
	var quality := str(SaveManager.get_setting("graphics_quality", "medium"))
	var vp := get_viewport()
	if vp != null:
		match quality:
			"low":
				vp.msaa_3d = Viewport.MSAA_DISABLED
			"high":
				vp.msaa_3d = Viewport.MSAA_4X
			_:
				vp.msaa_3d = Viewport.MSAA_2X
	graphics_quality_changed.emit(quality)


func start_stage(stage_id: int) -> void:
	current_stage_id = clampi(stage_id, 1, 30)
	SaveManager.set_last_played_stage(current_stage_id)
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(SCENE_STAGE)
	if err != OK:
		push_error("GameState: Failed to load stage scene (error %d)" % err)


func go_to_main_menu() -> void:
	get_tree().paused = false
	touch_move_vector = Vector2.ZERO
	var err := get_tree().change_scene_to_file(SCENE_MAIN_MENU)
	if err != OK:
		push_error("GameState: Failed to load main menu (error %d)" % err)


func trigger_ending(ending_id: String) -> void:
	active_ending_id = ending_id
	SaveManager.unlock_ending(ending_id)
	SaveManager.mark_stage_completed(30)
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(SCENE_ENDING)
	if err != OK:
		push_error("GameState: Failed to load ending screen (error %d)" % err)


func is_secret_ending_unlocked() -> bool:
	return SaveManager.get_collected_secret_count() >= SECRET_ENDING_REQUIRED_SECRETS


func set_touch_move(vec: Vector2) -> void:
	touch_move_vector = vec.limit_length(1.0)
	touch_move_changed.emit(touch_move_vector)


func emit_touch_jump() -> void:
	touch_jump_pressed.emit()


func emit_touch_interact() -> void:
	touch_interact_pressed.emit()


func emit_touch_echo() -> void:
	touch_echo_pressed.emit()
