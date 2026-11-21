extends Control

## Ending narrative summary screen displaying Ending A (Stop), Ending B (Restart),
## or Secret Ending (Liberation), plus ending unlock tracker and replay options.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	LocalizationManager.apply_layout_direction(self)
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.045, 0.055, 0.14, 1.0)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(UIStyleHelper.BG_PANEL, UIStyleHelper.ACCENT_GOLD, 22, 2))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var eid := GameState.active_ending_id
	if eid.is_empty():
		eid = "ending_stop"

	var title := Label.new()
	title.text = LocalizationManager.t(eid + "_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	vbox.add_child(title)

	var body := Label.new()
	body.text = LocalizationManager.t(eid + "_body")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
	vbox.add_child(body)

	var unlocked_count := (SaveManager.data.get("unlocked_endings", []) as Array).size()
	var summary := Label.new()
	summary.text = "%s: %d / 3   •   %s: %d / 120" % [
		LocalizationManager.t("endings_unlocked_label"),
		unlocked_count,
		LocalizationManager.t("menu_memories"),
		SaveManager.get_collected_secret_count()
	]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 17)
	summary.add_theme_color_override("font_color", UIStyleHelper.ACCENT_CYAN)
	vbox.add_child(summary)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var replay_btn := Button.new()
	replay_btn.text = LocalizationManager.t("ending_replay_finale")
	replay_btn.custom_minimum_size = Vector2(220, 52)
	UIStyleHelper.style_button(replay_btn, UIStyleHelper.ACCENT_CYAN)
	replay_btn.pressed.connect(func() -> void: GameState.start_stage(120))
	btn_row.add_child(replay_btn)

	var menu_btn := Button.new()
	menu_btn.text = LocalizationManager.t("menu_main")
	menu_btn.custom_minimum_size = Vector2(220, 52)
	UIStyleHelper.style_button(menu_btn, UIStyleHelper.ACCENT_GOLD)
	menu_btn.pressed.connect(func() -> void: GameState.go_to_main_menu())
	btn_row.add_child(menu_btn)
