class_name LevelCatalog
extends RefCounted

## Aggregates all 30 stage definitions across Worlds 1-6.

static var _cache: Dictionary = {}


static func _ensure_loaded() -> void:
	if not _cache.is_empty():
		return
	for world_dict in [
		World1Data.get_stages(),
		World2Data.get_stages(),
		World3Data.get_stages(),
		World4Data.get_stages(),
		World5Data.get_stages(),
		World6Data.get_stages(),
	]:
		for sid in world_dict.keys():
			_cache[sid] = world_dict[sid]


static func get_stage(stage_id: int) -> Dictionary:
	_ensure_loaded()
	return _cache.get(stage_id, {})


static func get_stage_count() -> int:
	_ensure_loaded()
	return _cache.size()
