extends Node

## Central game session coordinator, safe deferred scene router, difficulty tuning,
## character wardrobe catalog, and mobile input bridge.

signal touch_move_changed(vec: Vector2)
signal touch_jump_pressed
signal touch_interact_pressed
signal touch_echo_pressed
signal graphics_quality_changed(quality: String)
signal skin_changed(skin_id: String)
signal difficulty_changed(difficulty: String)

const TOTAL_STAGES := 120
const POWER_INSIGHT_CRYSTALS := 10
const POWER_ECHO_CRYSTALS := 25
const POWER_STRIDE_CRYSTALS := 45
const SECRET_ENDING_REQUIRED_SECRETS := 60
const SCENE_MAIN_MENU := "res://scenes/main/main_menu.tscn"
const SCENE_STAGE := "res://scenes/game/stage_scene.tscn"
const SCENE_ENDING := "res://scenes/ui/ending_screen.tscn"

## Approved hooded-protagonist cloak & lantern themes unlockable with collected Memory Crystals
const CHARACTER_SKINS := [
	{
		"id": "wanderer",
		"name_key": "skin_wanderer_name",
		"desc_key": "skin_wanderer_desc",
		"cost": 0,
		"cloak": Color(0.11, 0.12, 0.20),
		"eye": Color(1.0, 0.84, 0.45),
		"lantern": Color(0.24, 0.88, 1.0),
	},
	{
		"id": "dawn_cloak",
		"name_key": "skin_dawn_name",
		"desc_key": "skin_dawn_desc",
		"cost": 10,
		"cloak": Color(0.16, 0.18, 0.34),
		"eye": Color(1.0, 0.90, 0.55),
		"lantern": Color(1.0, 0.78, 0.32),
	},
	{
		"id": "clockwork_keeper",
		"name_key": "skin_clockwork_name",
		"desc_key": "skin_clockwork_desc",
		"cost": 25,
		"cloak": Color(0.22, 0.13, 0.32),
		"eye": Color(0.84, 0.68, 1.0),
		"lantern": Color(0.76, 0.45, 0.98),
	},
	{
		"id": "abyss_walker",
		"name_key": "skin_abyss_name",
		"desc_key": "skin_abyss_desc",
		"cost": 45,
		"cloak": Color(0.18, 0.08, 0.14),
		"eye": Color(1.0, 0.56, 0.62),
		"lantern": Color(0.95, 0.42, 0.58),
	},
	{
		"id": "starlight_architect",
		"name_key": "skin_architect_name",
		"desc_key": "skin_architect_desc",
		"cost": 60,
		"cloak": Color(0.14, 0.22, 0.32),
		"eye": Color(0.78, 0.98, 1.0),
		"lantern": Color(0.32, 0.96, 0.88),
	},
]

var current_stage_id: int = 1
var active_ending_id: String = ""
var touch_move_vector: Vector2 = Vector2.ZERO
var _scene_changing: bool = false


func _ready() -> void:
	SaveManager.settings_changed.connect(_on_settings_changed)
	apply_graphics_quality()


func _on_settings_changed() -> void:
	apply_graphics_quality()
	difficulty_changed.emit(SaveManager.get_difficulty())


func apply_graphics_quality() -> void:
	var quality := str(SaveManager.get_setting("graphics_quality", "medium"))
	var vp := get_viewport()
	if vp != null:
		match quality:
			"high":
				vp.msaa_3d = Viewport.MSAA_2X
			_:
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
	current_stage_id = clampi(stage_id, 1, TOTAL_STAGES)
	SaveManager.set_last_played_stage(current_stage_id)
	_safe_change_scene(SCENE_STAGE)


func go_to_main_menu() -> void:
	_safe_change_scene(SCENE_MAIN_MENU)


func trigger_ending(ending_id: String) -> void:
	active_ending_id = ending_id
	SaveManager.unlock_ending(ending_id)
	SaveManager.mark_stage_completed(TOTAL_STAGES)
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


func has_lantern_insight() -> bool:
	return SaveManager.get_collected_secret_count() >= POWER_INSIGHT_CRYSTALS


func get_echo_duration() -> float:
	var base := 7.0 if SaveManager.get_collected_secret_count() >= POWER_ECHO_CRYSTALS else 5.0
	match SaveManager.get_difficulty():
		"story":
			return base + 2.0
		"master":
			return maxf(3.8, base - 1.0)
		_:
			return base


func get_coyote_time() -> float:
	match SaveManager.get_difficulty():
		"story":
			return 0.20
		"master":
			return 0.09
		_:
			return 0.14


func get_move_speed_multiplier() -> float:
	var base := 1.15 if SaveManager.get_collected_secret_count() >= POWER_STRIDE_CRYSTALS else 1.0
	if SaveManager.get_difficulty() == "master":
		return base * 1.05
	return base


func get_skin_config(skin_id: String) -> Dictionary:
	for s in CHARACTER_SKINS:
		if str(s["id"]) == skin_id:
			return s
	return CHARACTER_SKINS[0]


func try_unlock_or_equip_skin(skin_id: String) -> bool:
	var cfg := get_skin_config(skin_id)
	if SaveManager.is_skin_unlocked(skin_id):
		SaveManager.set_equipped_skin(skin_id)
		skin_changed.emit(skin_id)
		return true
	var cost := int(cfg.get("cost", 0))
	if SaveManager.get_collected_secret_count() >= cost:
		SaveManager.unlock_skin(skin_id)
		SaveManager.set_equipped_skin(skin_id)
		skin_changed.emit(skin_id)
		return true
	return false
