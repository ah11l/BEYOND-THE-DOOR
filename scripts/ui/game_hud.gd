class_name GameHUD
extends CanvasLayer

## Ergonomic mobile-first HUD for wide Android screens (16:9 to 21:9):
## - Thumb-zone joystick and Echo/Jump buttons pulled comfortably inward from screen edges
## - Clean top bar with Pause, Help/Tutorial, Stages, Memories, Reset, Hint, Skip, and Counters
## - Interactive Arabic/English Tutorial overlay shown automatically on Stage 1
## - Zero unsupported emojis (all crisp Arabic/English labels and Noto-supported symbols)

signal restart_checkpoint_requested
signal next_stage_requested
signal hint_ad_requested
signal skip_stage_ad_requested

var _root: Control
var _top_margin: MarginContainer
var _stage_title_label: Label
var _objective_label: Label
var _secret_count_label: Label
var _key_pill: PanelContainer
var _key_count_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _interact_btn: Button
var _echo_btn: Button
var _jump_btn: Button
var _skip_btn: Button
var _pause_overlay: Control
var _settings_overlay: Control
var _stage_select_overlay: Control
var _codex_overlay: Control
var _stage_clear_overlay: Control
var _tutorial_overlay: Control
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
	# Auto-open Arabic/English interactive tutorial on Stage 1 if not seen yet
	if stage_id == 1 and not bool(SaveManager.get_setting("tutorial_seen", false)):
		open_tutorial()


func open_tutorial() -> void:
	if _tutorial_overlay == null:
		return
	_pause_overlay.visible = false
	_tutorial_overlay.visible = true
	get_tree().paused = true


func update_key_counter(held: int, required: int) -> void:
	if _key_pill == null or _key_count_label == null:
		return
	if required > 0:
		_key_pill.visible = true
		_key_count_label.text = "%s: %d / %d" % [LocalizationManager.t("keys_label"), held, required]
	else:
		_key_pill.visible = false


func update_echo_state(echo_state: int, progress: float) -> void:
	if _echo_btn == null:
		return
	match echo_state:
		EchoRecorder.EchoState.RECORDING:
			var secs := EchoRecorder.MAX_RECORD_SECONDS * (1.0 - progress)
			_echo_btn.text = "%s\n%.1fs" % [LocalizationManager.t("hud_echo_rec"), secs]
			UIStyleHelper.style_circle_button(_echo_btn, 100, Color(1.0, 0.38, 0.45), 17)
		EchoRecorder.EchoState.REPLAYING:
			_echo_btn.text = "%s\n%d%%" % [LocalizationManager.t("hud_echo_play"), int(progress * 100.0)]
			UIStyleHelper.style_circle_button(_echo_btn, 100, UIStyleHelper.ACCENT_CYAN, 17)
		_:
			_echo_btn.text = LocalizationManager.t("hud_echo")
			UIStyleHelper.style_circle_button(_echo_btn, 100, UIStyleHelper.ACCENT_CYAN, 19)


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
	if (_stage_clear_overlay != null and _stage_clear_overlay.visible) or (_tutorial_overlay != null and _tutorial_overlay.visible):
		return
	var next_paused := not get_tree().paused
	get_tree().paused = next_paused
	_pause_overlay.visible = next_paused
	_settings_overlay.visible = false
	_stage_select_overlay.visible = false
	_codex_overlay.visible = false


func _on_banner_visibility_changed(is_visible: bool) -> void:
	if _top_margin != null:
		_top_margin.add_theme_constant_override("margin_top", 66 if is_visible else 18)


func _build_hud() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Top bar with generous side margins for Android rounded corners / camera cutouts
	_top_margin = MarginContainer.new()
	_top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_margin.add_theme_constant_override("margin_left", 44)
	_top_margin.add_theme_constant_override("margin_right", 44)
	_top_margin.add_theme_constant_override("margin_top", 18)
	_top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_top_margin)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_margin.add_child(top_hbox)

	# Left group: Pause + Help + Stages + Reset
	var pause_btn := Button.new()
	pause_btn.text = ""
	UIStyleHelper.style_button(pause_btn, UIStyleHelper.BORDER_SUBTLE, 14, 20)
	UIStyleHelper.apply_icon(pause_btn, "res://assets/icons/icon_pause.svg", 26)
	pause_btn.custom_minimum_size = Vector2(54, 52)
	pause_btn.pressed.connect(toggle_pause)
	top_hbox.add_child(pause_btn)

	var help_btn := Button.new()
	help_btn.set_meta("loc_key", "btn_help_short")
	UIStyleHelper.style_button(help_btn, UIStyleHelper.ACCENT_CYAN, 14, 16)
	help_btn.custom_minimum_size = Vector2(74, 52)
	help_btn.pressed.connect(open_tutorial)
	top_hbox.add_child(help_btn)

	var map_btn := Button.new()
	map_btn.set_meta("loc_key", "btn_stages_short")
	UIStyleHelper.style_button(map_btn, UIStyleHelper.BORDER_SUBTLE, 14, 16)
	map_btn.custom_minimum_size = Vector2(84, 52)
	map_btn.pressed.connect(_open_stage_select)
	top_hbox.add_child(map_btn)

	var reset_btn := Button.new()
	reset_btn.text = ""
	UIStyleHelper.style_button(reset_btn, UIStyleHelper.BORDER_SUBTLE, 14, 20)
	UIStyleHelper.apply_icon(reset_btn, "res://assets/icons/icon_reset.svg", 26)
	reset_btn.custom_minimum_size = Vector2(52, 52)
	reset_btn.pressed.connect(func() -> void: restart_checkpoint_requested.emit())
	top_hbox.add_child(reset_btn)

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

	# Right group: Hint + Skip + Key Pill + Crystal Counter (clickable for Codex)
	var hint_btn := Button.new()
	hint_btn.set_meta("loc_key", "btn_hint_short")
	UIStyleHelper.style_button(hint_btn, UIStyleHelper.ACCENT_GOLD, 14, 16)
	hint_btn.custom_minimum_size = Vector2(74, 52)
	hint_btn.pressed.connect(func() -> void: hint_ad_requested.emit())
	top_hbox.add_child(hint_btn)

	_skip_btn = Button.new()
	_skip_btn.set_meta("loc_key", "btn_skip_short")
	UIStyleHelper.style_button(_skip_btn, UIStyleHelper.ACCENT_CYAN, 14, 16)
	_skip_btn.custom_minimum_size = Vector2(74, 52)
	_skip_btn.pressed.connect(func() -> void: skip_stage_ad_requested.emit())
	top_hbox.add_child(_skip_btn)

	_key_pill = PanelContainer.new()
	_key_pill.visible = false
	_key_pill.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.ACCENT_GOLD, 14, 1))
	top_hbox.add_child(_key_pill)
	_key_count_label = Label.new()
	_key_count_label.add_theme_font_size_override("font_size", 16)
	_key_count_label.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	_key_pill.add_child(_key_count_label)

	var crystal_btn := Button.new()
	crystal_btn.name = "CrystalBtn"
	UIStyleHelper.style_button(crystal_btn, UIStyleHelper.ACCENT_CYAN, 16, 18)
	UIStyleHelper.apply_icon(crystal_btn, "res://assets/icons/icon_crystal.svg", 26)
	crystal_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	crystal_btn.custom_minimum_size = Vector2(96, 52)
	crystal_btn.pressed.connect(_open_codex)
	top_hbox.add_child(crystal_btn)
	_secret_count_label = null

	# Bottom controls container (ALWAYS LTR so left thumb = joystick, right thumb = Echo + Jump)
	var controls_layer := Control.new()
	controls_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	controls_layer.layout_direction = Control.LAYOUT_DIRECTION_LTR
	controls_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(controls_layer)

	# Ergonomic Left-Thumb Joystick (pulled comfortably inward from corner)
	var joystick := TouchJoystick.new()
	joystick.anchor_left = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 104
	joystick.offset_top = -236
	joystick.offset_right = 276
	joystick.offset_bottom = -64
	controls_layer.add_child(joystick)

	# Bottom-center contextual prompt & toast pill
	var bottom_center := VBoxContainer.new()
	bottom_center.anchor_left = 0.5
	bottom_center.anchor_right = 0.5
	bottom_center.anchor_top = 1.0
	bottom_center.anchor_bottom = 1.0
	bottom_center.offset_left = -240
	bottom_center.offset_right = 240
	bottom_center.offset_top = -175
	bottom_center.offset_bottom = -34
	bottom_center.alignment = BoxContainer.ALIGNMENT_END
	bottom_center.add_theme_constant_override("separation", 10)
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bottom_center)

	_interact_btn = Button.new()
	_interact_btn.visible = false
	UIStyleHelper.style_button(_interact_btn, UIStyleHelper.ACCENT_GOLD, 22, 19)
	_interact_btn.custom_minimum_size = Vector2(260, 56)
	_interact_btn.pressed.connect(func() -> void: GameState.emit_touch_interact())
	bottom_center.add_child(_interact_btn)

	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.ACCENT_CYAN, 18, 2))
	bottom_center.add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.add_theme_font_size_override("font_size", 17)
	_toast_label.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
	_toast_panel.add_child(_toast_label)

	# Ergonomic Right-Thumb Echo + Jump Buttons (pulled comfortably inward from corner)
	var right_controls := HBoxContainer.new()
	right_controls.anchor_left = 1.0
	right_controls.anchor_right = 1.0
	right_controls.anchor_top = 1.0
	right_controls.anchor_bottom = 1.0
	right_controls.offset_left = -330
	right_controls.offset_right = -96
	right_controls.offset_top = -182
	right_controls.offset_bottom = -64
	right_controls.add_theme_constant_override("separation", 22)
	controls_layer.add_child(right_controls)

	_echo_btn = Button.new()
	_echo_btn.text = LocalizationManager.t("hud_echo")
	UIStyleHelper.style_circle_button(_echo_btn, 100, UIStyleHelper.ACCENT_CYAN, 19)
	_echo_btn.pressed.connect(func() -> void: GameState.emit_touch_echo())
	right_controls.add_child(_echo_btn)

	_jump_btn = Button.new()
	_jump_btn.text = "▲"
	UIStyleHelper.style_circle_button(_jump_btn, 110, UIStyleHelper.BORDER_SUBTLE, 32)
	_jump_btn.pressed.connect(func() -> void: GameState.emit_touch_jump())
	right_controls.add_child(_jump_btn)

	_build_pause_overlay()
	_build_settings_overlay()
	_build_stage_select_overlay()
	_build_codex_overlay()
	_build_stage_clear_overlay()
	_build_tutorial_overlay()
	_refresh_counters()


func _make_modal_backdrop() -> ColorRect:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.10, 0.82)
	bg.visible = false
	_root.add_child(bg)
	return bg


func _make_responsive_modal_panel(parent: Control, border: Color = UIStyleHelper.BORDER_SUBTLE) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.14
	panel.anchor_right = 0.86
	panel.anchor_top = 0.08
	panel.anchor_bottom = 0.92
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, border, 20, 2))
	parent.add_child(panel)
	return panel


func _build_tutorial_overlay() -> void:
	_tutorial_overlay = _make_modal_backdrop()
	var panel := _make_responsive_modal_panel(_tutorial_overlay, UIStyleHelper.ACCENT_GOLD)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.set_meta("loc_key", "tut_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var steps := VBoxContainer.new()
	steps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	steps.add_theme_constant_override("separation", 12)
	scroll.add_child(steps)

	for i in range(1, 4):
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.12, 0.13, 0.27, 0.92), UIStyleHelper.ACCENT_CYAN, 14, 1))
		steps.add_child(card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		var st_title := Label.new()
		st_title.set_meta("loc_key", "tut_step%d_title" % i)
		st_title.add_theme_font_size_override("font_size", 19)
		st_title.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
		cv.add_child(st_title)

		var st_body := Label.new()
		st_body.set_meta("loc_key", "tut_step%d_body" % i)
		st_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		st_body.add_theme_font_size_override("font_size", 16)
		st_body.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
		cv.add_child(st_body)

	var start_btn := Button.new()
	start_btn.set_meta("loc_key", "tut_start_btn")
	start_btn.custom_minimum_size = Vector2(0, 54)
	UIStyleHelper.style_button(start_btn, UIStyleHelper.ACCENT_GOLD, 16, 20)
	start_btn.pressed.connect(func() -> void:
		SaveManager.set_setting("tutorial_seen", true)
		_tutorial_overlay.visible = false
		get_tree().paused = false
	)
	vbox.add_child(start_btn)


func _build_pause_overlay() -> void:
	_pause_overlay = _make_modal_backdrop()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header := Label.new()
	header.name = "PauseHeader"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	vbox.add_child(header)

	var buttons := [
		{"name": "BtnResume", "key": "menu_resume", "cb": func() -> void: toggle_pause()},
		{"name": "BtnHowTo", "key": "menu_how_to_play", "cb": func() -> void: open_tutorial()},
		{"name": "BtnRestart", "key": "menu_restart_cp", "cb": func() -> void: toggle_pause(); restart_checkpoint_requested.emit()},
		{"name": "BtnSettings", "key": "menu_settings", "cb": func() -> void: _pause_overlay.visible = false; _settings_overlay.visible = true},
		{"name": "BtnMainMenu", "key": "menu_main", "cb": func() -> void: GameState.go_to_main_menu()},
	]
	for b in buttons:
		var btn := Button.new()
		btn.name = str(b["name"])
		btn.set_meta("loc_key", str(b["key"]))
		btn.custom_minimum_size = Vector2(0, 50)
		UIStyleHelper.style_button(btn)
		btn.pressed.connect(b["cb"] as Callable)
		vbox.add_child(btn)


func _build_settings_overlay() -> void:
	_settings_overlay = _make_modal_backdrop()
	var panel := _make_responsive_modal_panel(_settings_overlay)

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
	lang_btn.custom_minimum_size = Vector2(0, 50)
	UIStyleHelper.style_button(lang_btn, UIStyleHelper.ACCENT_CYAN)
	lang_btn.pressed.connect(func() -> void: LocalizationManager.toggle_language())
	vbox.add_child(lang_btn)

	var gfx_btn := Button.new()
	gfx_btn.name = "GfxBtn"
	gfx_btn.custom_minimum_size = Vector2(0, 50)
	UIStyleHelper.style_button(gfx_btn)
	gfx_btn.pressed.connect(func() -> void:
		var cur := str(SaveManager.get_setting("graphics_quality", "medium"))
		var nxt := "high" if cur == "medium" else ("low" if cur == "high" else "medium")
		SaveManager.set_setting("graphics_quality", nxt)
		gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + UIStyleHelper.quality_label_ar(nxt)
	)
	vbox.add_child(gfx_btn)

	var back_btn := Button.new()
	back_btn.set_meta("loc_key", "menu_back")
	back_btn.custom_minimum_size = Vector2(0, 50)
	UIStyleHelper.style_button(back_btn)
	back_btn.pressed.connect(func() -> void: _settings_overlay.visible = false; _pause_overlay.visible = true)
	vbox.add_child(back_btn)


func _build_stage_select_overlay() -> void:
	_stage_select_overlay = _make_modal_backdrop()
	var panel := _make_responsive_modal_panel(_stage_select_overlay)
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

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for w in range(1, 7):
		var w_lbl := Label.new()
		w_lbl.text = "%s %d — %s" % [LocalizationManager.t("world_label"), w, LocalizationManager.t("world_%d_name" % w)]
		w_lbl.add_theme_font_size_override("font_size", 18)
		w_lbl.add_theme_color_override("font_color", UIStyleHelper.ACCENT_CYAN)
		list.add_child(w_lbl)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

		for offset in range(5):
			var sid := (w - 1) * 5 + offset + 1
			var unlocked := SaveManager.is_stage_unlocked(sid)
			var completed := SaveManager.is_stage_completed(sid)
			var secret_done := SaveManager.is_secret_collected("mem_%02d" % sid)
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 56)
			var badge := " ★" if completed else ""
			var mem_badge := " ◆" if secret_done else ""
			btn.text = ("%d%s%s" % [sid, badge, mem_badge]) if unlocked else ("%d" % sid)
			btn.disabled = not unlocked
			UIStyleHelper.style_button(btn, UIStyleHelper.ACCENT_GOLD if completed else UIStyleHelper.BORDER_SUBTLE, 12, 18)
			btn.pressed.connect(func() -> void: GameState.start_stage(sid))
			row.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = LocalizationManager.t("menu_close")
	close_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(close_btn)
	close_btn.pressed.connect(func() -> void: _stage_select_overlay.visible = false; get_tree().paused = false)
	root_vbox.add_child(close_btn)


func _build_codex_overlay() -> void:
	_codex_overlay = _make_modal_backdrop()
	var panel := _make_responsive_modal_panel(_codex_overlay, UIStyleHelper.ACCENT_CYAN)
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
	panel.custom_minimum_size = Vector2(440, 0)
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
		gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + UIStyleHelper.quality_label_ar(str(SaveManager.get_setting("graphics_quality", "medium")))
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
	var cbtn := _root.find_child("CrystalBtn", true, false) as Button
	if cbtn != null:
		cbtn.text = " %d / 30" % SaveManager.get_collected_secret_count()
