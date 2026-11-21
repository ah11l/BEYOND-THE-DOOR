extends Control

## Atmospheric Main Menu for BEYOND THE DOOR — ما وراء الباب.
## Supports New Game / Continue, Stage Select, Memories Codex, Settings, Language, Credits, and Exit.

var _continue_btn: Button
var _modal_container: Control
var _modal_title: Label
var _modal_body: VBoxContainer
var _confirm_reset: bool = false


func _ready() -> void:
	_build_ui()
	LocalizationManager.language_changed.connect(_on_language_changed)
	_on_language_changed(LocalizationManager.current_language, LocalizationManager.is_rtl())


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Deep midnight gradient background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.055, 0.065, 0.165, 1.0)
	add_child(bg)

	# Subtle violet horizon band
	var horizon := ColorRect.new()
	horizon.anchor_left = 0.0
	horizon.anchor_right = 1.0
	horizon.anchor_top = 0.55
	horizon.anchor_bottom = 1.0
	horizon.color = Color(0.20, 0.11, 0.32, 0.45)
	add_child(horizon)

	var main_hbox := HBoxContainer.new()
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 40)
	add_child(main_hbox)

	# Left / Title Hero Column
	var left_center := CenterContainer.new()
	left_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(left_center)

	var hero_vbox := VBoxContainer.new()
	hero_vbox.add_theme_constant_override("separation", 12)
	left_center.add_child(hero_vbox)

	var icon_rect := TextureRect.new()
	if ResourceLoader.exists("res://icon.svg"):
		icon_rect.texture = load("res://icon.svg")
	icon_rect.custom_minimum_size = Vector2(148, 148)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_vbox.add_child(icon_rect)

	var title_en := Label.new()
	title_en.text = "BEYOND THE DOOR"
	title_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_en.add_theme_font_size_override("font_size", 42)
	title_en.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	hero_vbox.add_child(title_en)

	var title_ar := Label.new()
	title_ar.text = "ما وراء الباب"
	title_ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_ar.add_theme_font_size_override("font_size", 32)
	title_ar.add_theme_color_override("font_color", Color(0.98, 0.88, 0.62))
	hero_vbox.add_child(title_ar)

	var tagline := Label.new()
	tagline.set_meta("loc_key", "game_tagline")
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 17)
	tagline.add_theme_color_override("font_color", UIStyleHelper.TEXT_MUTED)
	hero_vbox.add_child(tagline)

	var stats_lbl := Label.new()
	stats_lbl.name = "StatsLabel"
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 16)
	stats_lbl.add_theme_color_override("font_color", UIStyleHelper.ACCENT_CYAN)
	hero_vbox.add_child(stats_lbl)

	# Right / Navigation Buttons Column
	var right_center := CenterContainer.new()
	right_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 0)
	card.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	right_center.add_child(card)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	card.add_child(btn_vbox)

	_continue_btn = Button.new()
	_continue_btn.set_meta("loc_key", "menu_continue")
	_continue_btn.custom_minimum_size = Vector2(0, 54)
	UIStyleHelper.style_button(_continue_btn, UIStyleHelper.ACCENT_GOLD, 16, 20)
	_continue_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		GameState.start_stage(int(SaveManager.data.get("last_played_stage", 1)))
	)
	btn_vbox.add_child(_continue_btn)

	var new_btn := Button.new()
	new_btn.set_meta("loc_key", "menu_new_game")
	new_btn.custom_minimum_size = Vector2(0, 50)
	UIStyleHelper.style_button(new_btn)
	new_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		GameState.start_stage(1)
	)
	btn_vbox.add_child(new_btn)

	var stages_btn := Button.new()
	stages_btn.set_meta("loc_key", "menu_stage_select")
	stages_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(stages_btn)
	stages_btn.pressed.connect(_show_stage_select_modal)
	btn_vbox.add_child(stages_btn)

	var mem_btn := Button.new()
	mem_btn.set_meta("loc_key", "menu_memories")
	mem_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(mem_btn, UIStyleHelper.ACCENT_CYAN)
	mem_btn.pressed.connect(_show_memories_modal)
	btn_vbox.add_child(mem_btn)

	var settings_btn := Button.new()
	settings_btn.set_meta("loc_key", "menu_settings")
	settings_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(settings_btn)
	settings_btn.pressed.connect(_show_settings_modal)
	btn_vbox.add_child(settings_btn)

	var lang_btn := Button.new()
	lang_btn.set_meta("loc_key", "settings_toggle_lang")
	lang_btn.custom_minimum_size = Vector2(0, 46)
	UIStyleHelper.style_button(lang_btn)
	lang_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		LocalizationManager.toggle_language()
	)
	btn_vbox.add_child(lang_btn)

	var credits_btn := Button.new()
	credits_btn.set_meta("loc_key", "menu_credits")
	credits_btn.custom_minimum_size = Vector2(0, 44)
	UIStyleHelper.style_button(credits_btn)
	credits_btn.pressed.connect(_show_credits_modal)
	btn_vbox.add_child(credits_btn)

	if OS.get_name() != "Web" and OS.get_name() != "iOS":
		var exit_btn := Button.new()
		exit_btn.set_meta("loc_key", "menu_exit")
		exit_btn.custom_minimum_size = Vector2(0, 44)
		UIStyleHelper.style_button(exit_btn)
		exit_btn.pressed.connect(func() -> void: get_tree().quit())
		btn_vbox.add_child(exit_btn)

	_build_modal()


func _build_modal() -> void:
	_modal_container = ColorRect.new()
	_modal_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_container.color = Color(0.03, 0.04, 0.10, 0.84)
	_modal_container.visible = false
	add_child(_modal_container)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_container.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 500)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)

	_modal_title = Label.new()
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_title.add_theme_font_size_override("font_size", 24)
	_modal_title.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	outer.add_child(_modal_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	_modal_body = VBoxContainer.new()
	_modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_body.add_theme_constant_override("separation", 10)
	scroll.add_child(_modal_body)

	var close_btn := Button.new()
	close_btn.set_meta("loc_key", "menu_close")
	close_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(close_btn)
	close_btn.pressed.connect(func() -> void: _modal_container.visible = false; _confirm_reset = false)
	outer.add_child(close_btn)


func _clear_modal_body() -> void:
	for c in _modal_body.get_children():
		c.queue_free()


func _show_stage_select_modal() -> void:
	AudioManager.play_sfx("ui_click")
	_clear_modal_body()
	_modal_title.text = LocalizationManager.t("menu_stage_select")
	_modal_container.visible = true

	for w in range(1, 7):
		var w_lbl := Label.new()
		w_lbl.text = "%s %d — %s" % [LocalizationManager.t("world_label"), w, LocalizationManager.t("world_%d_name" % w)]
		w_lbl.add_theme_font_size_override("font_size", 18)
		w_lbl.add_theme_color_override("font_color", UIStyleHelper.ACCENT_CYAN)
		_modal_body.add_child(w_lbl)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_modal_body.add_child(row)

		for offset in range(5):
			var sid := (w - 1) * 5 + offset + 1
			var unlocked := SaveManager.is_stage_unlocked(sid)
			var done := SaveManager.is_stage_completed(sid)
			var mem := SaveManager.is_secret_collected("mem_%02d" % sid)
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 56)
			btn.text = "%d%s%s" % [sid, " ★" if done else "", " ◆" if mem else ""] if unlocked else "🔒 %d" % sid
			btn.disabled = not unlocked
			UIStyleHelper.style_button(btn, UIStyleHelper.ACCENT_GOLD if done else UIStyleHelper.BORDER_SUBTLE, 12, 16)
			btn.pressed.connect(func() -> void: GameState.start_stage(sid))
			row.add_child(btn)


func _show_memories_modal() -> void:
	AudioManager.play_sfx("ui_click")
	_clear_modal_body()
	_modal_title.text = "%s (%d / 30)" % [LocalizationManager.t("menu_memories"), SaveManager.get_collected_secret_count()]
	_modal_container.visible = true

	var hint := Label.new()
	hint.text = LocalizationManager.t("secret_ending_hint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	_modal_body.add_child(hint)

	for s in range(1, 31):
		var found := SaveManager.is_secret_collected("mem_%02d" % s)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = ("◆ #%02d — %s" % [s, LocalizationManager.t("lore_%02d" % s)]) if found else ("◇ #%02d — %s" % [s, LocalizationManager.t("memory_locked")])
		lbl.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY if found else UIStyleHelper.TEXT_MUTED)
		_modal_body.add_child(lbl)


func _show_settings_modal() -> void:
	AudioManager.play_sfx("ui_click")
	_clear_modal_body()
	_modal_title.text = LocalizationManager.t("menu_settings")
	_modal_container.visible = true

	var m_lbl := Label.new()
	m_lbl.text = LocalizationManager.t("settings_music")
	_modal_body.add_child(m_lbl)
	var m_slider := HSlider.new()
	m_slider.min_value = 0.0
	m_slider.max_value = 1.0
	m_slider.step = 0.05
	m_slider.value = float(SaveManager.get_setting("music_volume", 0.75))
	m_slider.value_changed.connect(func(v: float) -> void: SaveManager.set_setting("music_volume", v))
	_modal_body.add_child(m_slider)

	var s_lbl := Label.new()
	s_lbl.text = LocalizationManager.t("settings_sfx")
	_modal_body.add_child(s_lbl)
	var s_slider := HSlider.new()
	s_slider.min_value = 0.0
	s_slider.max_value = 1.0
	s_slider.step = 0.05
	s_slider.value = float(SaveManager.get_setting("sfx_volume", 0.85))
	s_slider.value_changed.connect(func(v: float) -> void: SaveManager.set_setting("sfx_volume", v))
	_modal_body.add_child(s_slider)

	var gfx_btn := Button.new()
	gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + str(SaveManager.get_setting("graphics_quality", "medium")).to_upper()
	gfx_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(gfx_btn)
	gfx_btn.pressed.connect(func() -> void:
		var cur := str(SaveManager.get_setting("graphics_quality", "medium"))
		var nxt := "high" if cur == "medium" else ("low" if cur == "high" else "medium")
		SaveManager.set_setting("graphics_quality", nxt)
		gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + nxt.to_upper()
	)
	_modal_body.add_child(gfx_btn)

	var reset_btn := Button.new()
	reset_btn.text = LocalizationManager.t("settings_reset_progress")
	reset_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(reset_btn, Color(0.95, 0.35, 0.42))
	reset_btn.pressed.connect(func() -> void:
		if not _confirm_reset:
			_confirm_reset = true
			reset_btn.text = LocalizationManager.t("settings_reset_confirm")
		else:
			SaveManager.reset_progress()
			_confirm_reset = false
			_modal_container.visible = false
			_refresh_texts()
	)
	_modal_body.add_child(reset_btn)


func _show_credits_modal() -> void:
	AudioManager.play_sfx("ui_click")
	_clear_modal_body()
	_modal_title.text = LocalizationManager.t("menu_credits")
	_modal_container.visible = true

	var txt := Label.new()
	txt.text = LocalizationManager.t("credits_body")
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.add_theme_font_size_override("font_size", 18)
	_modal_body.add_child(txt)


func _on_language_changed(_lang: String, _rtl: bool) -> void:
	LocalizationManager.apply_layout_direction(self)
	_refresh_texts()


func _refresh_texts() -> void:
	_continue_btn.visible = SaveManager.has_progress()
	_apply_loc(self)
	var stats := find_child("StatsLabel", true, false) as Label
	if stats != null:
		var done_cnt := (SaveManager.data.get("completed_stages", []) as Array).size()
		var mem_cnt := SaveManager.get_collected_secret_count()
		var end_cnt := (SaveManager.data.get("unlocked_endings", []) as Array).size()
		stats.text = "★ %d/30   •   ◆ %d/30   •   🏆 %d/3" % [done_cnt, mem_cnt, end_cnt]


func _apply_loc(node: Node) -> void:
	if node.has_meta("loc_key"):
		var k := str(node.get_meta("loc_key"))
		if node is Button:
			(node as Button).text = LocalizationManager.t(k)
		elif node is Label:
			(node as Label).text = LocalizationManager.t(k)
	for c in node.get_children():
		_apply_loc(c)
