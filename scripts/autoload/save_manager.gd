extends Node

## Local offline JSON save system with backup recovery, settings persistence,
## difficulty selection, character cloak wardrobe unlocks, and cinematic progress.

signal save_loaded
signal progress_updated
signal settings_changed

const SAVE_PATH := "user://beyond_the_door_save.json"
const BACKUP_PATH := "user://beyond_the_door_save.bak.json"
const SAVE_VERSION := 2

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func _create_default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"highest_unlocked_stage": 1,
		"last_played_stage": 1,
		"completed_stages": [],
		"collected_secrets": [],
		"unlocked_endings": [],
		"stage_checkpoints": {},
		"equipped_skin": "wanderer",
		"unlocked_skins": ["wanderer"],
		"intro_cinematic_seen": false,
		"settings": {
			"language": "ar",
			"music_volume": 0.75,
			"sfx_volume": 0.85,
			"graphics_quality": "high",
			"shadows_enabled": true,
			"bloom_enabled": true,
			"difficulty": "normal",
			"puzzle_guides": true,
		},
	}


func load_game() -> void:
	var loaded := _try_read_json(SAVE_PATH)
	if loaded.is_empty():
		loaded = _try_read_json(BACKUP_PATH)
		if not loaded.is_empty():
			push_warning("SaveManager: Primary save was missing or corrupt; restored from backup.")
	if loaded.is_empty():
		data = _create_default_data()
		save_game()
	else:
		data = _merge_with_defaults(loaded)
	save_loaded.emit()


func _try_read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: Could not open %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var text := file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: Invalid JSON structure in %s" % path)
		return {}
	return parsed as Dictionary


func _merge_with_defaults(loaded: Dictionary) -> Dictionary:
	var merged := _create_default_data()
	for key in merged.keys():
		if loaded.has(key):
			if typeof(merged[key]) == TYPE_DICTIONARY and typeof(loaded[key]) == TYPE_DICTIONARY:
				var sub: Dictionary = merged[key]
				var loaded_sub: Dictionary = loaded[key]
				for sub_k in loaded_sub.keys():
					sub[sub_k] = loaded_sub[sub_k]
			else:
				merged[key] = loaded[key]
	merged["highest_unlocked_stage"] = clampi(int(merged["highest_unlocked_stage"]), 1, 120)
	merged["last_played_stage"] = clampi(int(merged["last_played_stage"]), 1, 120)
	var skins: Array = merged.get("unlocked_skins", ["wanderer"])
	if not ("wanderer" in skins):
		skins.append("wanderer")
	merged["unlocked_skins"] = skins
	return merged


func save_game() -> bool:
	var json_str := JSON.stringify(data, "\t")
	if FileAccess.file_exists(SAVE_PATH):
		var old_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if old_file != null:
			var old_text := old_file.get_as_text()
			old_file.close()
			var bak := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if bak != null:
				bak.store_string(old_text)
				bak.close()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to write save file %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	file.store_string(json_str)
	file.flush()
	file.close()
	return true


func has_progress() -> bool:
	return int(data.get("highest_unlocked_stage", 1)) > 1 or not (data.get("completed_stages", []) as Array).is_empty()


func is_stage_unlocked(stage_id: int) -> bool:
	return stage_id <= int(data.get("highest_unlocked_stage", 1))


func is_stage_completed(stage_id: int) -> bool:
	var completed: Array = data.get("completed_stages", [])
	return stage_id in completed or float(stage_id) in completed


func mark_stage_completed(stage_id: int) -> void:
	var completed: Array = data.get("completed_stages", [])
	if not is_stage_completed(stage_id):
		completed.append(stage_id)
		data["completed_stages"] = completed
	var next_stage := clampi(stage_id + 1, 1, 120)
	if next_stage > int(data.get("highest_unlocked_stage", 1)):
		data["highest_unlocked_stage"] = next_stage
	data["last_played_stage"] = next_stage
	var cps: Dictionary = data.get("stage_checkpoints", {})
	cps.erase(str(stage_id))
	data["stage_checkpoints"] = cps
	save_game()
	progress_updated.emit()


func set_last_played_stage(stage_id: int) -> void:
	data["last_played_stage"] = clampi(stage_id, 1, 120)
	save_game()


func save_checkpoint(stage_id: int, checkpoint_id: String) -> void:
	var cps: Dictionary = data.get("stage_checkpoints", {})
	cps[str(stage_id)] = checkpoint_id
	data["stage_checkpoints"] = cps
	save_game()


func get_saved_checkpoint(stage_id: int) -> String:
	var cps: Dictionary = data.get("stage_checkpoints", {})
	return str(cps.get(str(stage_id), ""))


func is_secret_collected(secret_id: String) -> bool:
	var secrets: Array = data.get("collected_secrets", [])
	return secret_id in secrets


func collect_secret(secret_id: String) -> bool:
	if is_secret_collected(secret_id):
		return false
	var secrets: Array = data.get("collected_secrets", [])
	secrets.append(secret_id)
	data["collected_secrets"] = secrets
	save_game()
	progress_updated.emit()
	return true


func get_collected_secret_count() -> int:
	return (data.get("collected_secrets", []) as Array).size()


func unlock_ending(ending_id: String) -> void:
	var endings: Array = data.get("unlocked_endings", [])
	if not (ending_id in endings):
		endings.append(ending_id)
		data["unlocked_endings"] = endings
		save_game()
		progress_updated.emit()


func is_ending_unlocked(ending_id: String) -> bool:
	var endings: Array = data.get("unlocked_endings", [])
	return ending_id in endings


func get_equipped_skin() -> String:
	return str(data.get("equipped_skin", "wanderer"))


func set_equipped_skin(skin_id: String) -> void:
	if not is_skin_unlocked(skin_id):
		return
	data["equipped_skin"] = skin_id
	save_game()
	progress_updated.emit()


func is_skin_unlocked(skin_id: String) -> bool:
	var skins: Array = data.get("unlocked_skins", ["wanderer"])
	return skin_id in skins


func unlock_skin(skin_id: String) -> bool:
	var skins: Array = data.get("unlocked_skins", ["wanderer"])
	if not (skin_id in skins):
		skins.append(skin_id)
		data["unlocked_skins"] = skins
		save_game()
		progress_updated.emit()
		return true
	return false


func is_intro_seen() -> bool:
	return bool(data.get("intro_cinematic_seen", false))


func mark_intro_seen() -> void:
	data["intro_cinematic_seen"] = true
	save_game()


func get_difficulty() -> String:
	return str(get_setting("difficulty", "normal"))


func set_difficulty(diff: String) -> void:
	if diff in ["story", "normal", "master"]:
		set_setting("difficulty", diff)


func get_setting(key: String, default_value: Variant) -> Variant:
	var settings: Dictionary = data.get("settings", {})
	return settings.get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	var settings: Dictionary = data.get("settings", {})
	settings[key] = value
	data["settings"] = settings
	save_game()
	settings_changed.emit()


func reset_progress() -> void:
	var preserved_settings: Dictionary = (data.get("settings", {}) as Dictionary).duplicate(true)
	var preserved_skins: Array = (data.get("unlocked_skins", ["wanderer"]) as Array).duplicate(true)
	var preserved_equipped: String = get_equipped_skin()
	data = _create_default_data()
	data["settings"] = preserved_settings
	data["unlocked_skins"] = preserved_skins
	data["equipped_skin"] = preserved_equipped
	save_game()
	progress_updated.emit()
