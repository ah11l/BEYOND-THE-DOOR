extends Node

## Runtime CSV localization manager supporting Arabic (RTL), English (LTR), and Spanish-ready expansion.

signal language_changed(lang_code: String, rtl: bool)

const TRANSLATIONS_CSV_PATH := "res://assets/localization/translations.csv"
const SUPPORTED_LANGUAGES := ["ar", "en"]
const RTL_LANGUAGES := ["ar", "he", "fa", "ur"]

var current_language: String = "ar"
var _tables: Dictionary = {} # lang_code -> Dictionary[key, text]


func _ready() -> void:
	_load_csv()
	var saved_lang := str(SaveManager.get_setting("language", "ar"))
	set_language(saved_lang, false)


func _load_csv() -> void:
	_tables.clear()
	if not FileAccess.file_exists(TRANSLATIONS_CSV_PATH):
		push_error("LocalizationManager: Missing translations CSV at %s" % TRANSLATIONS_CSV_PATH)
		return
	var file := FileAccess.open(TRANSLATIONS_CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("LocalizationManager: Cannot read %s" % TRANSLATIONS_CSV_PATH)
		return

	var headers := file.get_csv_line()
	if headers.size() < 2:
		push_error("LocalizationManager: Invalid CSV header in %s" % TRANSLATIONS_CSV_PATH)
		file.close()
		return

	for i in range(1, headers.size()):
		var lang := headers[i].strip_edges()
		if not lang.is_empty():
			_tables[lang] = {}

	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2:
			continue
		var key := row[0].strip_edges()
		if key.is_empty() or key.begins_with("#"):
			continue
		for i in range(1, min(row.size(), headers.size())):
			var lang := headers[i].strip_edges()
			if _tables.has(lang):
				_tables[lang][key] = row[i]
	file.close()


func set_language(lang_code: String, persist: bool = true) -> void:
	if not _tables.has(lang_code):
		lang_code = "en"
	current_language = lang_code
	TranslationServer.set_locale(lang_code)
	if persist:
		SaveManager.set_setting("language", lang_code)
	language_changed.emit(current_language, is_rtl())


func toggle_language() -> void:
	if current_language == "ar":
		set_language("en")
	else:
		set_language("ar")


func is_rtl() -> bool:
	return current_language in RTL_LANGUAGES


func t(key: String, fallback: String = "") -> String:
	if _tables.has(current_language):
		var lang_dict: Dictionary = _tables[current_language]
		if lang_dict.has(key) and not str(lang_dict[key]).is_empty():
			return str(lang_dict[key])
	if _tables.has("en"):
		var en_dict: Dictionary = _tables["en"]
		if en_dict.has(key) and not str(en_dict[key]).is_empty():
			return str(en_dict[key])
	return fallback if not fallback.is_empty() else key


func apply_layout_direction(root_control: Control) -> void:
	if root_control == null:
		return
	root_control.layout_direction = (
		Control.LAYOUT_DIRECTION_RTL if is_rtl() else Control.LAYOUT_DIRECTION_LTR
	)
