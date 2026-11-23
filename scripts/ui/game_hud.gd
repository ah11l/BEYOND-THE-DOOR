class_name GameHUD
extends CanvasLayer

## Redesigned mobile-first HUD matching 254211.png & 254212.png:
## - Contextual circular icon interaction button (Hand / Book / Door / Search) projected safely near target
## - Aged Parchment Scroll Reading Panel ("ملاحظة قديمة" / "Ancient Note") for Clue Stones & Lore
## - 3D Opening Cinematic letterbox subtitle overlay with Skip control
## - Difficulty & Puzzle Guides toggles inside Settings

signal restart_checkpoint_requested
signal next_stage_requested
signal hint_ad_requested
signal skip_stage_ad_requested

const CONTEXT_ICONS := {
	"hand": "res://assets/icons/icon_hand.svg",
	"book": "res://assets/icons/icon_book.svg",
	"door": "res://assets/icons/icon_door.svg",
	"search": "res://assets/icons/icon_search.svg",
}

var _root: Control
var _top_margin: MarginContainer
var _stage_title_label: Label
var _objective_label: Label
var _key_pill: PanelContainer
var _key_count_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _context_btn: Button
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
var _context_target: Node = null
var _context_cam: Camera3D = null


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
	_update_context_button_position()


func set_stage_info(stage_id: int, title_key: String, objective_key: String) -> void:
	_current_stage_id = stage_id
	_current_title_key = title_key
	_current_objective_key = objective_key
	_refresh_labels()
	if _skip_btn != null:
		_skip_btn.visible = (stage_id < GameState.TOTAL_STAGES)
	if stage_id == 1 and not bool(SaveManager.get_setting("tutorial_seen", false)) and SaveManager.is_intro_seen():
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
		_key_count_label.text = "★ %d / %d" % [held, required]
	else:
		_key_pill.visible = false


func update_echo_state(echo_state: int, progress: float) -> void:
	if _echo_btn == null:
		return
	match echo_state:
		EchoRecorder.EchoState.RECORDING:
			var secs := GameState.get_echo_duration() * (1.0 - progress)
			_echo_btn.text = "%.1fs" % secs
			UIStyleHelper.style_circle_button(_echo_btn, 96, Color(0.95, 0.36, 0.44), 17)
		EchoRecorder.EchoState.REPLAYING:
			_echo_btn.text = "%d%%" % int(progress * 100.0)
			UIStyleHelper.style_circle_button(_echo_btn, 96, UIStyleHelper.ACCENT_CYAN, 17)
		_:
			_echo_btn.text = ""
			UIStyleHelper.style_circle_button(_echo_btn, 96, UIStyleHelper.ACCENT_CYAN, 18)
			UIStyleHelper.apply_icon(_echo_btn, "res://assets/icons/icon_echo.svg", 38)


func set_interaction_target(target: Node, cam: Camera3D) -> void:
	_context_target = target
	_context_cam = cam
	if _context_btn == null:
		return
	if target == null or not is_instance_valid(target):
		_context_btn.visible = false
		return
	var icon_kind := "hand"
	if target.has_method("get_interact_icon_type"):
		icon_kind = str(target.call("get_interact_icon_type"))
	var icon_path := str(CONTEXT_ICONS.get(icon_kind, CONTEXT_ICONS["hand"]))
	UIStyleHelper.apply_icon(_context_btn, icon_path, 34)
	_context_btn.visible = true
	_update_context_button_position()


func set_interaction_prompt(prompt_key: String) -> void:
	# Backward-compatible fallback if called directly
	if _context_btn == null:
		return
	_context_btn.visible = not prompt_key.is_empty()


func _update_context_button_position() -> void:
	if _context_btn == null or not _context_btn.visible:
		return
	if _context_target == null or not is_instance_valid(_context_target) or not (_context_target is Node3D):
		_context_btn.visible = false
		return
	var vp_size := get_viewport().get_visible_rect().size
	var target_pos := Vector2(vp_size.x * 0.62, vp_size.y * 0.50)
	if _context_cam != null and is_instance_valid(_context_cam):
		var world_pt := (_context_target as Node3D).global_position + Vector3(0.0, 1.45, 0.0)
		if not _context_cam.is_position_behind(world_pt):
			var sp := _context_cam.unproject_position(world_pt)
			target_pos = sp + Vector2(46.0, -34.0)
	# Clamp cleanly inside safe gameplay zone (never overlapping top bar, joystick, or Echo/Jump buttons!)
	var half := _context_btn.size * 0.5
	target_pos.x = clampf(target_pos.x, vp_size.x * 0.28, vp_size.x * 0.78)
	target_pos.y = clampf(target_pos.y, 110.0, vp_size.y - 210.0)
	_context_btn.position = target_pos - half


func show_toast(message_key: String, duration: float = 4.2) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = LocalizationManager.t(message_key)
	_toast_panel.visible = true
	_toast_timer = duration


func show_parchment_note(clue_key: String) -> void:
	## Aged Parchment Scroll Reading Panel matching 254212.png ("ملاحظة قديمة" / "Ancient Note").
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.03, 0.08, 0.78)
	_root.add_child(overlay)

	var scroll_card := PanelContainer.new()
	scroll_card.anchor_left = 0.16
	scroll_card.anchor_right = 0.84
	scroll_card.anchor_top = 0.18
	scroll_card.anchor_bottom = 0.82
	var parch_style := StyleBoxFlat.new()
	parch_style.bg_color = Color(0.84, 0.74, 0.58, 0.98)
	parch_style.border_color = Color(0.45, 0.30, 0.16, 1.0)
	parch_style.set_border_width_all(3)
	parch_style.set_corner_radius_all(18)
	parch_style.content_margin_left = 32
	parch_style.content_margin_right = 32
	parch_style.content_margin_top = 24
	parch_style.content_margin_bottom = 24
	scroll_card.add_theme_stylebox_override("panel", parch_style)
	overlay.add_child(scroll_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	scroll_card.add_child(vbox)

	var hdr_row := HBoxContainer.new()
	vbox.add_child(hdr_row)

	var title_lbl := Label.new()
	title_lbl.text = LocalizationManager.t("parchment_note_title")
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.22, 0.12, 0.06))
	hdr_row.add_child(title_lbl)

	var close_x := Button.new()
	close_x.text = "✕"
	UIStyleHelper.style_circle_button(close_x, 42, Color(0.28, 0.18, 0.12), 18)
	close_x.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		overlay.queue_free()
		get_tree().paused = false
	)
	hdr_row.add_child(close_x)

	var body_lbl := Label.new()
	body_lbl.text = LocalizationManager.t(clue_key)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("font_size", 19)
	body_lbl.add_theme_color_override("font_color", Color(0.16, 0.10, 0.06))
	vbox.add_child(body_lbl)

	LocalizationManager.apply_layout_direction(overlay)
	get_tree().paused = true


func play_cinematic_subtitles(line_keys: Array, on_finished: Callable) -> void:
	## Letterbox cinematic subtitle bar + Skip button for the 3D Opening Cinematic.
	var cine := Control.new()
	cine.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(cine)

	var top_bar := ColorRect.new()
	top_bar.anchor_right = 1.0
	top_bar.offset_bottom = 64
	top_bar.color = Color(0.01, 0.015, 0.04, 0.92)
	cine.add_child(top_bar)

	var bot_bar := ColorRect.new()
	bot_bar.anchor_top = 1.0
	bot_bar.anchor_right = 1.0
	bot_bar.anchor_bottom = 1.0
	bot_bar.offset_top = -128
	bot_bar.color = Color(0.01, 0.015, 0.04, 0.92)
	cine.add_child(bot_bar)

	var sub_lbl := Label.new()
	sub_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.add_theme_font_size_override("font_size", 22)
	sub_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	bot_bar.add_child(sub_lbl)

	var skip_btn := Button.new()
	skip_btn.text = LocalizationManager.t("cine_skip")
	skip_btn.anchor_left = 1.0
	skip_btn.anchor_right = 1.0
	skip_btn.offset_left = -150
	skip_btn.offset_right = -24
	skip_btn.offset_top = 14
	skip_btn.offset_bottom = 52
	UIStyleHelper.style_button(skip_btn, UIStyleHelper.ACCENT_GOLD, 16, 16)
	cine.add_child(skip_btn)

	var done := {"v": false}
	var finish := func() -> void:
		if done["v"]:
			return
		done["v"] = true
		cine.queue_free()
		on_finished.call()

	skip_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		finish.call()
	)

	var tw := create_tween()
	for k in line_keys:
		tw.tween_callback(func() -> void:
			sub_lbl.modulate.a = 0.0
			sub_lbl.text = LocalizationManager.t(str(k))
		)
		tw.tween_property(sub_lbl, "modulate:a", 1.0, 0.45)
		tw.tween_interval(2.05)
		tw.tween_property(sub_lbl, "modulate:a", 0.0, 0.35)
	tw.tween_callback(finish)


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

	_top_margin = MarginContainer.new()
	_top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_margin.add_theme_constant_override("margin_left", 40)
	_top_margin.add_theme_constant_override("margin_right", 40)
	_top_margin.add_theme_constant_override("margin_top", 18)
	_top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_top_margin)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_margin.add_child(top_hbox)

	var pause_btn := Button.new()
	pause_btn.text = ""
	UIStyleHelper.style_circle_button(pause_btn, 52, UIStyleHelper.BORDER_SUBTLE, 18)
	UIStyleHelper.apply_icon(pause_btn, "res://assets/icons/icon_pause.svg", 24)
	pause_btn.pressed.connect(toggle_pause)
	top_hbox.add_child(pause_btn)

	var reset_btn := Button.new()
	reset_btn.text = ""
	UIStyleHelper.style_circle_button(reset_btn, 52, UIStyleHelper.BORDER_SUBTLE, 18)
	UIStyleHelper.apply_icon(reset_btn, "res://assets/icons/icon_reset.svg", 24)
	reset_btn.pressed.connect(func() -> void: restart_checkpoint_requested.emit())
	top_hbox.add_child(reset_btn)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(spacer_l)

	var title_pill := PanelContainer.new()
	title_pill.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.06, 0.08, 0.18, 0.82), Color(0.55, 0.68, 0.92, 0.45), 20, 1))
	top_hbox.add_child(title_pill)

	var title_vbox := VBoxContainer.new()
	title_pill.add_child(title_vbox)

	_stage_title_label = Label.new()
	_stage_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_title_label.add_theme_font_size_override("font_size", 17)
	_stage_title_label.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	title_vbox.add_child(_stage_title_label)

	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.add_theme_font_size_override("font_size", 13)
	_objective_label.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
	title_vbox.add_child(_objective_label)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(spacer_r)

	_key_pill = PanelContainer.new()
	_key_pill.visible = false
	_key_pill.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.06, 0.08, 0.18, 0.84), UIStyleHelper.ACCENT_GOLD, 22, 1))
	top_hbox.add_child(_key_pill)
	_key_count_label = Label.new()
	_key_count_label.add_theme_font_size_override("font_size", 16)
	_key_count_label.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	_key_pill.add_child(_key_count_label)

	var crystal_btn := Button.new()
	crystal_btn.name = "CrystalBtn"
	UIStyleHelper.style_button(crystal_btn, UIStyleHelper.ACCENT_CYAN, 22, 16)
	UIStyleHelper.apply_icon(crystal_btn, "res://assets/icons/icon_crystal.svg", 24)
	crystal_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	crystal_btn.custom_minimum_size = Vector2(96, 48)
	crystal_btn.pressed.connect(_open_codex)
	top_hbox.add_child(crystal_btn)

	# Bottom controls container (ALWAYS LTR)
	var controls_layer := Control.new()
	controls_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	controls_layer.layout_direction = Control.LAYOUT_DIRECTION_LTR
	controls_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(controls_layer)

	var joystick := TouchJoystick.new()
	joystick.anchor_left = 0.0
	joystick.anchor_top = 0.14
	joystick.anchor_right = 0.48
	joystick.anchor_bottom = 1.0
	controls_layer.add_child(joystick)

	# Floating contextual circular interaction button (Hand / Book / Door / Search)
	_context_btn = Button.new()
	_context_btn.visible = false
	_context_btn.text = ""
	UIStyleHelper.style_circle_button(_context_btn, 76, UIStyleHelper.ACCENT_CYAN, 20)
	UIStyleHelper.apply_icon(_context_btn, CONTEXT_ICONS["hand"], 34)
	_context_btn.pressed.connect(func() -> void: GameState.emit_touch_interact())
	controls_layer.add_child(_context_btn)

	# Bottom-center toast pill only (NO permanent rectangular interact text bar!)
	var bottom_center := VBoxContainer.new()
	bottom_center.anchor_left = 0.5
	bottom_center.anchor_right = 0.5
	bottom_center.anchor_top = 1.0
	bottom_center.anchor_bottom = 1.0
	bottom_center.offset_left = -190
	bottom_center.offset_right = 190
	bottom_center.offset_top = -120
	bottom_center.offset_bottom = -28
	bottom_center.alignment = BoxContainer.ALIGNMENT_END
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bottom_center)

	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.06, 0.08, 0.18, 0.88), UIStyleHelper.ACCENT_CYAN, 18, 1))
	bottom_center.add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
	_toast_panel.add_child(_toast_label)

	var right_controls := HBoxContainer.new()
	right_controls.anchor_left = 1.0
	right_controls.anchor_right = 1.0
	right_controls.anchor_top = 1.0
	right_controls.anchor_bottom = 1.0
	right_controls.offset_left = -316
	right_controls.offset_right = -82
	right_controls.offset_top = -172
	right_controls.offset_bottom = -58
	right_controls.add_theme_constant_override("separation", 20)
	controls_layer.add_child(right_controls)

	_echo_btn = Button.new()
	_echo_btn.text = ""
	UIStyleHelper.style_circle_button(_echo_btn, 96, UIStyleHelper.ACCENT_CYAN, 18)
	UIStyleHelper.apply_icon(_echo_btn, "res://assets/icons/icon_echo.svg", 38)
	_echo_btn.pressed.connect(func() -> void: GameState.emit_touch_echo())
	right_controls.add_child(_echo_btn)

	_jump_btn = Button.new()
	_jump_btn.text = "▲"
	UIStyleHelper.style_circle_button(_jump_btn, 106, UIStyleHelper.BORDER_SUBTLE, 30)
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
		{"name": "BtnStages", "key": "menu_stage_select", "cb": func() -> void: _pause_overlay.visible = false; _open_stage_select()},
		{"name": "BtnHint", "key": "hud_hint", "cb": func() -> void: toggle_pause(); hint_ad_requested.emit()},
		{"name": "BtnSkip", "key": "hud_skip", "cb": func() -> void: toggle_pause(); skip_stage_ad_requested.emit()},
		{"name": "BtnHowTo", "key": "menu_how_to_play", "cb": func() -> void: open_tutorial()},
		{"name": "BtnRestart", "key": "menu_restart_cp", "cb": func() -> void: toggle_pause(); restart_checkpoint_requested.emit()},
		{"name": "BtnSettings", "key": "menu_settings", "cb": func() -> void: _pause_overlay.visible = false; _settings_overlay.visible = true},
		{"name": "BtnMainMenu", "key": "menu_main", "cb": func() -> void: GameState.go_to_main_menu()},
	]
	for b in buttons:
		var btn := Button.new()
		btn.name = str(b["name"])
		btn.set_meta("loc_key", str(b["key"]))
		btn.custom_minimum_size = Vector2(0, 48)
		UIStyleHelper.style_button(btn)
		btn.pressed.connect(b["cb"] as Callable)
		vbox.add_child(btn)


func _build_settings_overlay() -> void:
	_settings_overlay = _make_modal_backdrop()
	var panel := _make_responsive_modal_panel(_settings_overlay)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

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

	var diff_btn := Button.new()
	diff_btn.name = "DiffBtn"
	diff_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(diff_btn, UIStyleHelper.ACCENT_GOLD)
	diff_btn.pressed.connect(func() -> void:
		var cur := SaveManager.get_difficulty()
		var nxt := "master" if cur == "normal" else ("story" if cur == "master" else "normal")
		SaveManager.set_difficulty(nxt)
		_refresh_labels()
	)
	vbox.add_child(diff_btn)

	var guides_btn := Button.new()
	guides_btn.name = "GuidesBtn"
	guides_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(guides_btn, UIStyleHelper.ACCENT_CYAN)
	guides_btn.pressed.connect(func() -> void:
		var cur := bool(SaveManager.get_setting("puzzle_guides", true))
		SaveManager.set_setting("puzzle_guides", not cur)
		_refresh_labels()
	)
	vbox.add_child(guides_btn)

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
		_refresh_labels()
	)
	vbox.add_child(gfx_btn)

	var dev_btn := Button.new()
	dev_btn.text = "إعداد وتطوير: majnon.studio (إنستغرام)"
	dev_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(dev_btn, UIStyleHelper.ACCENT_GOLD, 14, 16)
	UIStyleHelper.apply_icon(dev_btn, "res://assets/icons/majnon_studio_logo.png", 26)
	dev_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dev_btn.pressed.connect(func() -> void: OS.shell_open("https://www.instagram.com/majnon.studio?gwpx=MXZkZm41emg3emk0bA=="))
	vbox.add_child(dev_btn)

	var back_btn := Button.new()
	back_btn.set_meta("loc_key", "menu_back")
	back_btn.custom_minimum_size = Vector2(0, 48)
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

		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		list.add_child(grid)

		var w_start := (w - 1) * 20 + 1
		for offset in range(20):
			var sid := w_start + offset
			var unlocked := SaveManager.is_stage_unlocked(sid)
			var completed := SaveManager.is_stage_completed(sid)
			var secret_done := SaveManager.is_secret_collected("mem_%03d" % sid)
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 56)
			var badge := " ★" if completed else ""
			var mem_badge := " ◆" if secret_done else ""
			btn.text = ("%d%s%s" % [sid, badge, mem_badge]) if unlocked else ("%d" % sid)
			btn.disabled = not unlocked
			UIStyleHelper.style_button(btn, UIStyleHelper.ACCENT_GOLD if completed else UIStyleHelper.BORDER_SUBTLE, 12, 18)
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
	hdr.text = "%s (%d / 120)" % [LocalizationManager.t("menu_memories"), SaveManager.get_collected_secret_count()]
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

	for s in range(1, 121):
		var mem_id := "mem_%03d" % s
		var found := SaveManager.is_secret_collected(mem_id)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 16)
		if found:
			lbl.text = "◆ #%03d — %s" % [s, LocalizationManager.t("lore_%03d" % s)]
			lbl.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
		else:
			lbl.text = "◇ #%03d — %s" % [s, LocalizationManager.t("memory_locked")]
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
	var pause_hdr := _pause_overlay.find_child("PauseHeader", true, false) as Label
	if pause_hdr != null:
		pause_hdr.text = LocalizationManager.t("menu_paused")
	_apply_meta_localization(_root)
	var gfx_btn := _settings_overlay.find_child("GfxBtn", true, false) as Button
	if gfx_btn != null:
		gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + UIStyleHelper.quality_label_ar(str(SaveManager.get_setting("graphics_quality", "medium")))
	var diff_btn := _settings_overlay.find_child("DiffBtn", true, false) as Button
	if diff_btn != null:
		diff_btn.text = LocalizationManager.t("settings_difficulty") + ": " + LocalizationManager.t("diff_" + SaveManager.get_difficulty())
	var guides_btn := _settings_overlay.find_child("GuidesBtn", true, false) as Button
	if guides_btn != null:
		var g_on := bool(SaveManager.get_setting("puzzle_guides", true))
		guides_btn.text = LocalizationManager.t("settings_puzzle_guides") + ": " + LocalizationManager.t("state_on" if g_on else "state_off")
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
		cbtn.text = " %d / 120" % SaveManager.get_collected_secret_count()


func _exit_tree() -> void:
	if LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
	if SaveManager.progress_updated.is_connected(_refresh_counters):
		SaveManager.progress_updated.disconnect(_refresh_counters)
	if MonetizationBridge.banner_visibility_changed.is_connected(_on_banner_visibility_changed):
		MonetizationBridge.banner_visibility_changed.disconnect(_on_banner_visibility_changed)


func show_story_chapter(world_idx: int, story_key: String) -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.04, 0.11, 0.90)
	_root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.12
	panel.anchor_right = 0.88
	panel.anchor_top = 0.16
	panel.anchor_bottom = 0.84
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.08, 0.09, 0.22, 0.96), UIStyleHelper.ACCENT_GOLD, 22, 2))
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var chapter_lbl := Label.new()
	chapter_lbl.text = "%s %d — %s" % [LocalizationManager.t("world_label"), world_idx, LocalizationManager.t("world_%d_name" % world_idx)]
	chapter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_lbl.add_theme_font_size_override("font_size", 28)
	chapter_lbl.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	vbox.add_child(chapter_lbl)

	var body_lbl := Label.new()
	body_lbl.text = LocalizationManager.t(story_key)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.add_theme_font_size_override("font_size", 20)
	body_lbl.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
	vbox.add_child(body_lbl)

	var cont_btn := Button.new()
	cont_btn.text = "متابعة ✦" if LocalizationManager.is_rtl() else "Continue ✦"
	cont_btn.custom_minimum_size = Vector2(220, 52)
	UIStyleHelper.style_button(cont_btn, UIStyleHelper.ACCENT_GOLD, 20, 19)
	cont_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		overlay.queue_free()
		get_tree().paused = false
	)
	vbox.add_child(cont_btn)
	LocalizationManager.apply_layout_direction(overlay)
	get_tree().paused = true


func update_boss_bar(world_idx: int, remaining_seals: int, total_seals: int) -> void:
	var bar_panel := _root.find_child("BossSealBar", true, false) as PanelContainer
	if remaining_seals <= 0 or total_seals <= 0:
		if bar_panel != null:
			bar_panel.visible = false
		return
	if bar_panel == null:
		bar_panel = PanelContainer.new()
		bar_panel.name = "BossSealBar"
		bar_panel.anchor_left = 0.30
		bar_panel.anchor_right = 0.70
		bar_panel.anchor_top = 0.0
		bar_panel.offset_top = 78
		bar_panel.offset_bottom = 114
		bar_panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.14, 0.06, 0.18, 0.88), Color(0.92, 0.45, 0.78), 16, 1))
		_root.add_child(bar_panel)
		var lbl := Label.new()
		lbl.name = "BossSealLabel"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.96))
		bar_panel.add_child(lbl)
	bar_panel.visible = true
	var b_lbl := bar_panel.find_child("BossSealLabel", true, false) as Label
	if b_lbl != null:
		b_lbl.text = "%s — %s: %d / %d" % [LocalizationManager.t("boss_title_w%d" % clampi(world_idx, 1, 6)), LocalizationManager.t("boss_seals_label"), remaining_seals, total_seals]
