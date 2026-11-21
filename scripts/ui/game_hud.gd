class_name GameHUD
extends CanvasLayer

## Mobile-first in-game HUD matching the visual reference layout:
## Pause, left shortcut rail, crystal/key counters, virtual joystick, contextual Echo/Clue pill,
## dedicated Echo & Jump/Interact touch buttons, and modal Pause / Settings / Stage Select / Codex overlays.

signal restart_checkpoint_requested
signal next_stage_requested
signal hint_ad_requested
signal skip_stage_ad_requested

var _root: Control
var _top_margin: MarginContainer
var _skip_btn: Button
var _stage_title_label: Label
var _objective_label: Label
var _secret_count_label: Label
var _key_count_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _interact_btn: Button
var _echo_btn: Button
var _jump_btn: Button
var _pause_overlay: Control
var _settings_overlay: Control
var _stage_select_overlay: Control
var _codex_overlay: Control
var _stage_clear_overlay: Control
var _stage_clear_title: Label
var _toast_timer: float = 0.0

var _current_stage_id: int = 1
var _current_title_key: String = ""
var _current_objective_key: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	LocalizationManager.language_changed.connect(_on_language_changed)
	SaveManager.progress_updated.connect(_refresh_counters)
	MonetizationBridge.banner_visibility_changed.connect(_on_banner_visibility_changed)
	_on_banner_visibility_changed(MonetizationBridge.banner_visible)
	_on_language_changed(LocalizationManager.current_language, LocalizationManager.is_rtl())


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_panel != null:
			_toast_panel.visible = false
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("restart_checkpoint") and not get_tree().paused:
		restart_checkpoint_requested.emit()


func set_stage_info(stage_id: int, title_key: String, objective_key: String) -> void:
	_current_stage_id = stage_id
	_current_title_key = title_key
	_current_objective_key = objective_key
	_refresh_labels()
	if _skip_btn != null:
		_skip_btn.visible = (stage_id < 30)


func update_key_counter(held: int, required: int) -> void:
	if _key_count_label == null:
		return
	if required > 0:
		_key_count_label.visible = true
		_key_count_label.text = "🔑 %d / %d" % [held, required]
	else:
		_key_count_label.visible = false


func update_echo_state(echo_state: int, progress: float) -> void:
	if _echo_btn == null:
		return
	match echo_state:
		EchoRecorder.EchoState.RECORDING:
			var secs := EchoRecorder.MAX_RECORD_SECONDS * (1.0 - progress)
			_echo_btn.text = "%s\n%.1fs" % [LocalizationManager.t("hud_echo_rec"), secs]
			UIStyleHelper.style_circle_button(_echo_btn, 92, Color(1.0, 0.38, 0.45), 16)
		EchoRecorder.EchoState.REPLAYING:
			_echo_btn.text = "%s\n%d%%" % [LocalizationManager.t("hud_echo_play"), int(progress * 100.0)]
			UIStyleHelper.style_circle_button(_echo_btn, 92, UIStyleHelper.ACCENT_CYAN, 16)
		_:
			_echo_btn.text = LocalizationManager.t("hud_echo")
			UIStyleHelper.style_circle_button(_echo_btn, 92, UIStyleHelper.ACCENT_CYAN, 18)


func set_interaction_prompt(prompt_key: String) -> void:
	if _interact_btn == null:
		return
	if prompt_key.is_empty():
		_interact_btn.visible = false
	else:
		_interact_btn.visible = true
		_interact_btn.text = "✦ " + LocalizationManager.t(prompt_key)


func show_toast(message_key: String, duration: float = 4.2) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = LocalizationManager.t(message_key)
	_toast_panel.visible = true
	_toast_timer = duration


func show_stage_complete(stage_id: int) -> void:
	if _stage_clear_overlay == null:
		return
	_stage_clear_title.text = "%s %d" % [LocalizationManager.t("stage_cleared"), stage_id]
	_stage_clear_overlay.visible = true
	get_tree().paused = true


func toggle_pause() -> void:
	if _stage_clear_overlay != null and _stage_clear_overlay.visible:
		return
	var next_paused := not get_tree().paused
	get_tree().paused = next_paused
	_pause_overlay.visible = next_paused
	_settings_overlay.visible = false
	_stage_select_overlay.visible = false
	_codex_overlay.visible = false


func _build_hud() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Top bar (safe margins for Android notches/rounded corners)
	_top_margin = MarginContainer.new()
	var top_margin := _top_margin
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_right", 24)
	top_margin.add_theme_constant_override("margin_top", 18)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top_margin)

	var top_hbox := HBoxContainer.new()
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.add_child(top_hbox)

	var pause_btn := Button.new()
	pause_btn.text = "❚❚"
	UIStyleHelper.style_button(pause_btn, UIStyleHelper.BORDER_SUBTLE, 14, 22)
	pause_btn.custom_minimum_size = Vector2(56, 56)
	pause_btn.pressed.connect(toggle_pause)
	top_hbox.add_child(pause_btn)

	# Center stage header pill
	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(spacer_l)

	var title_pill := PanelContainer.new()
	title_pill.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.BORDER_SUBTLE, 16, 1))
	top_hbox.add_child(title_pill)

	var title_vbox := VBoxContainer.new()
	title_pill.add_child(title_vbox)

	_stage_title_label = Label.new()
	_stage_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_title_label.add_theme_font_size_override("font_size", 18)
	_stage_title_label.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	title_vbox.add_child(_stage_title_label)

	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.add_theme_font_size_override("font_size", 14)
	_objective_label.add_theme_color_override("font_color", UIStyleHelper.TEXT_MUTED)
	title_vbox.add_child(_objective_label)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(spacer_r)

	# Right counters (Memory Crystals + Keys)
	var counters := HBoxContainer.new()
	counters.add_theme_constant_override("separation", 10)
	top_hbox.add_child(counters)

	var key_pill := PanelContainer.new()
	key_pill.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.ACCENT_GOLD, 16, 1))
	counters.add_child(key_pill)
	_key_count_label = Label.new()
	_key_count_label.visible = false
	_key_count_label.add_theme_font_size_override("font_size", 18)
	_key_count_label.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	key_pill.add_child(_key_count_label)

	var crystal_pill := PanelContainer.new()
	crystal_pill.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.ACCENT_CYAN, 16, 1))
	counters.add_child(crystal_pill)
	_secret_count_label = Label.new()
	_secret_count_label.add_theme_font_size_override("font_size", 18)
	_secret_count_label.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
	crystal_pill.add_child(_secret_count_label)

	# Left quick-action rail matching visual reference
	var left_rail := VBoxContainer.new()
	left_rail.position = Vector2(24, 150)
	left_rail.add_theme_constant_override("separation", 12)
	_root.add_child(left_rail)

	var map_btn := Button.new()
	map_btn.text = "🗺"
	UIStyleHelper.style_button(map_btn, UIStyleHelper.BORDER_SUBTLE, 14, 22)
	map_btn.custom_minimum_size = Vector2(54, 54)
	map_btn.pressed.connect(_open_stage_select)
	left_rail.add_child(map_btn)

	var codex_btn := Button.new()
	codex_btn.text = "◆"
	UIStyleHelper.style_button(codex_btn, UIStyleHelper.ACCENT_CYAN, 14, 22)
	codex_btn.custom_minimum_size = Vector2(54, 54)
	codex_btn.pressed.connect(_open_codex)
	left_rail.add_child(codex_btn)

	var reset_btn := Button.new()
	reset_btn.text = "↺"
	UIStyleHelper.style_button(reset_btn, UIStyleHelper.BORDER_SUBTLE, 14, 24)
	reset_btn.custom_minimum_size = Vector2(54, 54)
	reset_btn.pressed.connect(func() -> void: restart_checkpoint_requested.emit())
	left_rail.add_child(reset_btn)

	var hint_btn := Button.new()
	hint_btn.text = "💡"
	hint_btn.tooltip_text = LocalizationManager.t("hud_hint")
	UIStyleHelper.style_button(hint_btn, UIStyleHelper.ACCENT_GOLD, 14, 22)
	hint_btn.custom_minimum_size = Vector2(54, 54)
	hint_btn.pressed.connect(func() -> void: hint_ad_requested.emit())
	left_rail.add_child(hint_btn)

	_skip_btn = Button.new()
	_skip_btn.text = "⏭"
	_skip_btn.tooltip_text = LocalizationManager.t("hud_skip")
	UIStyleHelper.style_button(_skip_btn, UIStyleHelper.ACCENT_CYAN, 14, 22)
	_skip_btn.custom_minimum_size = Vector2(54, 54)
	_skip_btn.pressed.connect(func() -> void: skip_stage_ad_requested.emit())
	left_rail.add_child(_skip_btn)

	# Bottom-left Touch Joystick
	var joystick := TouchJoystick.new()
	joystick.anchor_left = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 28
	joystick.offset_top = -186
	joystick.offset_right = 184
	joystick.offset_bottom = -30
	_root.add_child(joystick)

	# Bottom-center contextual prompt & toast pill
	var bottom_center := VBoxContainer.new()
	bottom_center.anchor_left = 0.5
	bottom_center.anchor_right = 0.5
	bottom_center.anchor_top = 1.0
	bottom_center.anchor_bottom = 1.0
	bottom_center.offset_left = -220
	bottom_center.offset_right = 220
	bottom_center.offset_top = -156
	bottom_center.offset_bottom = -24
	bottom_center.alignment = BoxContainer.ALIGNMENT_END
	bottom_center.add_theme_constant_override("separation", 10)
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bottom_center)

	_interact_btn = Button.new()
	_interact_btn.visible = false
	UIStyleHelper.style_button(_interact_btn, UIStyleHelper.ACCENT_GOLD, 22, 18)
	_interact_btn.custom_minimum_size = Vector2(220, 52)
	_interact_btn.pressed.connect(func() -> void: GameState.emit_touch_interact())
	bottom_center.add_child(_interact_btn)

	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.ACCENT_CYAN, 20, 2))
	bottom_center.add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.add_theme_font_size_override("font_size", 17)
	_toast_label.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
	_toast_panel.add_child(_toast_label)

	# Bottom-right Echo + Jump buttons
	var right_controls := HBoxContainer.new()
	right_controls.anchor_left = 1.0
	right_controls.anchor_right = 1.0
	right_controls.anchor_top = 1.0
	right_controls.anchor_bottom = 1.0
	right_controls.offset_left = -246
	right_controls.offset_right = -28
	right_controls.offset_top = -132
	right_controls.offset_bottom = -28
	right_controls.add_theme_constant_override("separation", 18)
	_root.add_child(right_controls)

	_echo_btn = Button.new()
	_echo_btn.text = LocalizationManager.t("hud_echo")
	UIStyleHelper.style_circle_button(_echo_btn, 92, UIStyleHelper.ACCENT_CYAN, 18)
	_echo_btn.pressed.connect(func() -> void: GameState.emit_touch_echo())
	right_controls.add_child(_echo_btn)

	_jump_btn = Button.new()
	_jump_btn.text = "▲"
	UIStyleHelper.style_circle_button(_jump_btn, 102, UIStyleHelper.BORDER_SUBTLE, 30)
	_jump_btn.pressed.connect(func() -> void: GameState.emit_touch_jump())
	right_controls.add_child(_jump_btn)

	_build_pause_overlay()
	_build_settings_overlay()
	_build_stage_select_overlay()
	_build_codex_overlay()
	_build_stage_clear_overlay()
	_refresh_counters()


func _make_modal_backdrop() -> ColorRect:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.10, 0.78)
	bg.visible = false
	_root.add_child(bg)
	return bg


func _build_pause_overlay() -> void:
	_pause_overlay = _make_modal_backdrop()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header := Label.new()
	header.name = "PauseHeader"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	vbox.add_child(header)

	var buttons := [
		{"name": "BtnResume", "key": "menu_resume", "cb": func() -> void: toggle_pause()},
		{"name": "BtnRestart", "key": "menu_restart_cp", "cb": func() -> void: toggle_pause(); restart_checkpoint_requested.emit()},
		{"name": "BtnSettings", "key": "menu_settings", "cb": func() -> void: _pause_overlay.visible = false; _settings_overlay.visible = true},
		{"name": "BtnMainMenu", "key": "menu_main", "cb": func() -> void: GameState.go_to_main_menu()},
	]
	for b in buttons:
		var btn := Button.new()
		btn.name = str(b["name"])
		btn.set_meta("loc_key", str(b["key"]))
		btn.custom_minimum_size = Vector2(0, 52)
		UIStyleHelper.style_button(btn)
		btn.pressed.connect(b["cb"] as Callable)
		vbox.add_child(btn)


func _build_settings_overlay() -> void:
	_settings_overlay = _make_modal_backdrop()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var hdr := Label.new()
	hdr.set_meta("loc_key", "menu_settings")
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 24)
	hdr.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	vbox.add_child(hdr)

	var music_lbl := Label.new()
	music_lbl.set_meta("loc_key", "settings_music")
	vbox.add_child(music_lbl)
	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = float(SaveManager.get_setting("music_volume", 0.75))
	music_slider.value_changed.connect(func(v: float) -> void: SaveManager.set_setting("music_volume", v))
	vbox.add_child(music_slider)

	var sfx_lbl := Label.new()
	sfx_lbl.set_meta("loc_key", "settings_sfx")
	vbox.add_child(sfx_lbl)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = float(SaveManager.get_setting("sfx_volume", 0.85))
	sfx_slider.value_changed.connect(func(v: float) -> void: SaveManager.set_setting("sfx_volume", v))
	vbox.add_child(sfx_slider)

	var lang_btn := Button.new()
	lang_btn.set_meta("loc_key", "settings_toggle_lang")
	lang_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(lang_btn, UIStyleHelper.ACCENT_CYAN)
	lang_btn.pressed.connect(func() -> void: LocalizationManager.toggle_language())
	vbox.add_child(lang_btn)

	var gfx_btn := Button.new()
	gfx_btn.name = "GfxBtn"
	gfx_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(gfx_btn)
	gfx_btn.pressed.connect(func() -> void:
		var cur := str(SaveManager.get_setting("graphics_quality", "medium"))
		var nxt := "high" if cur == "medium" else ("low" if cur == "high" else "medium")
		SaveManager.set_setting("graphics_quality", nxt)
		gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + nxt.to_upper()
	)
	vbox.add_child(gfx_btn)

	var back_btn := Button.new()
	back_btn.set_meta("loc_key", "menu_back")
	back_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(back_btn)
	back_btn.pressed.connect(func() -> void: _settings_overlay.visible = false; _pause_overlay.visible = true)
	vbox.add_child(back_btn)


func _build_stage_select_overlay() -> void:
	_stage_select_overlay = _make_modal_backdrop()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_select_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 500)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "StageListRoot"
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)


func _open_stage_select() -> void:
	get_tree().paused = true
	_stage_select_overlay.visible = true
	var root_vbox := _stage_select_overlay.find_child("StageListRoot", true, false) as VBoxContainer
	if root_vbox == null:
		return
	for c in root_vbox.get_children():
		c.queue_free()

	var hdr := Label.new()
	hdr.text = LocalizationManager.t("menu_stage_select")
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 24)
	hdr.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	root_vbox.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for s in range(1, 31):
		var unlocked := SaveManager.is_stage_unlocked(s)
		var completed := SaveManager.is_stage_completed(s)
		var secret_done := SaveManager.is_secret_collected("mem_%02d" % s)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(128, 66)
		var badge := " ★" if completed else ""
		var mem_badge := " ◆" if secret_done else ""
		btn.text = "%d%s%s" % [s, badge, mem_badge] if unlocked else "🔒 %d" % s
		btn.disabled = not unlocked
		UIStyleHelper.style_button(btn, UIStyleHelper.ACCENT_GOLD if completed else UIStyleHelper.BORDER_SUBTLE, 14, 18)
		var sid := s
		btn.pressed.connect(func() -> void: GameState.start_stage(sid))
		grid.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = LocalizationManager.t("menu_close")
	close_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(close_btn)
	close_btn.pressed.connect(func() -> void: _stage_select_overlay.visible = false; get_tree().paused = false)
	root_vbox.add_child(close_btn)


func _build_codex_overlay() -> void:
	_codex_overlay = _make_modal_backdrop()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_codex_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(740, 500)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "CodexListRoot"
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)


func _open_codex() -> void:
	get_tree().paused = true
	_codex_overlay.visible = true
	var root_vbox := _codex_overlay.find_child("CodexListRoot", true, false) as VBoxContainer
	if root_vbox == null:
		return
	for c in root_vbox.get_children():
		c.queue_free()

	var hdr := Label.new()
	hdr.text = "%s (%d / 30)" % [LocalizationManager.t("menu_memories"), SaveManager.get_collected_secret_count()]
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 24)
	hdr.add_theme_color_override("font_color", UIStyleHelper.ACCENT_CYAN)
	root_vbox.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for s in range(1, 31):
		var mem_id := "mem_%02d" % s
		var found := SaveManager.is_secret_collected(mem_id)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 16)
		if found:
			lbl.text = "◆ #%02d — %s" % [s, LocalizationManager.t("lore_%02d" % s)]
			lbl.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
		else:
			lbl.text = "◇ #%02d — %s" % [s, LocalizationManager.t("memory_locked")]
			lbl.add_theme_color_override("font_color", UIStyleHelper.TEXT_MUTED)
		list.add_child(lbl)

	var close_btn := Button.new()
	close_btn.text = LocalizationManager.t("menu_close")
	close_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(close_btn)
	close_btn.pressed.connect(func() -> void: _codex_overlay.visible = false; get_tree().paused = false)
	root_vbox.add_child(close_btn)


func _build_stage_clear_overlay() -> void:
	_stage_clear_overlay = _make_modal_backdrop()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_clear_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.ACCENT_GOLD, 20, 2))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_stage_clear_title = Label.new()
	_stage_clear_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_clear_title.add_theme_font_size_override("font_size", 26)
	_stage_clear_title.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	vbox.add_child(_stage_clear_title)

	var next_btn := Button.new()
	next_btn.set_meta("loc_key", "menu_next_stage")
	next_btn.custom_minimum_size = Vector2(0, 54)
	UIStyleHelper.style_button(next_btn, UIStyleHelper.ACCENT_GOLD)
	next_btn.pressed.connect(func() -> void:
		_stage_clear_overlay.visible = false
		get_tree().paused = false
		next_stage_requested.emit()
	)
	vbox.add_child(next_btn)

	var menu_btn := Button.new()
	menu_btn.set_meta("loc_key", "menu_main")
	menu_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(menu_btn)
	menu_btn.pressed.connect(func() -> void: GameState.go_to_main_menu())
	vbox.add_child(menu_btn)


func _on_language_changed(_lang: String, _rtl: bool) -> void:
	LocalizationManager.apply_layout_direction(_root)
	_refresh_labels()


func _refresh_labels() -> void:
	if _stage_title_label != null and not _current_title_key.is_empty():
		_stage_title_label.text = "%d. %s" % [_current_stage_id, LocalizationManager.t(_current_title_key)]
	if _objective_label != null and not _current_objective_key.is_empty():
		_objective_label.text = LocalizationManager.t(_current_objective_key)
	if _echo_btn != null:
		_echo_btn.text = LocalizationManager.t("hud_echo")
	var pause_hdr := _pause_overlay.find_child("PauseHeader", true, false) as Label
	if pause_hdr != null:
		pause_hdr.text = LocalizationManager.t("menu_paused")
	_apply_meta_localization(_root)
	var gfx_btn := _settings_overlay.find_child("GfxBtn", true, false) as Button
	if gfx_btn != null:
		gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + str(SaveManager.get_setting("graphics_quality", "medium")).to_upper()
	_refresh_counters()


func _apply_meta_localization(node: Node) -> void:
	if node.has_meta("loc_key"):
		var k := str(node.get_meta("loc_key"))
		if node is Button:
			(node as Button).text = LocalizationManager.t(k)
		elif node is Label:
			(node as Label).text = LocalizationManager.t(k)
	for c in node.get_children():
		_apply_meta_localization(c)


func _refresh_counters() -> void:
	if _secret_count_label != null:
		_secret_count_label.text = "◆ %d / 30" % SaveManager.get_collected_secret_count()


func _on_banner_visibility_changed(is_visible: bool) -> void:
	if _top_margin != null:
		_top_margin.add_theme_constant_override("margin_top", 68 if is_visible else 18)
