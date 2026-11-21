extends Node

## Central game session coordinator, safe deferred scene router, and mobile input bridge.

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
var _scene_changing: bool = false


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
			"high":
				vp.msaa_3d = Viewport.MSAA_2X
			_:
				# Keep MSAA disabled on Low/Medium for rock-solid Android GLES3 stability & FPS
				vp.msaa_3d = Viewport.MSAA_DISABLED
	graphics_quality_changed.emit(quality)


func _safe_change_scene(path: String) -> void:
	if _scene_changing:
		return
	_scene_changing = true
	touch_move_vector = Vector2.ZERO
	get_tree().paused = false
	call_deferred("_do_change_scene", path)


func _do_change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	_scene_changing = false
	if err != OK:
		push_error("GameState: Failed to load scene %s (error %d)" % [path, err])


func start_stage(stage_id: int) -> void:
	current_stage_id = clampi(stage_id, 1, 30)
	SaveManager.set_last_played_stage(current_stage_id)
	_safe_change_scene(SCENE_STAGE)


func go_to_main_menu() -> void:
	_safe_change_scene(SCENE_MAIN_MENU)


func trigger_ending(ending_id: String) -> void:
	active_ending_id = ending_id
	SaveManager.unlock_ending(ending_id)
	SaveManager.mark_stage_completed(30)
	_safe_change_scene(SCENE_ENDING)


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
