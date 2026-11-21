extends Control

## Lively Main Menu matching 251933.png:
## - Fixed LTR split so frosted-glass buttons stay cleanly on the LEFT while the live 3D island shines on the RIGHT (ZERO overlap!)
## - Real 3D twinkling starfield spheres + deep midnight gradient sky
## - Animated vector-drawn interactive splash screen for مجنون استديو (majnon.studio) that waits for tap to enter
## - Developer branding & clickable Instagram link inside Settings AND Credits

const STUDIO_INSTAGRAM_URL := "https://www.instagram.com/majnon.studio?gwpx=MXZkZm41emg3emk0bA=="
static var _splash_shown: bool = false

var _continue_btn: Button
var _modal_container: Control
var _modal_title: Label
var _modal_body: VBoxContainer
var _confirm_reset: bool = false
var _bg_cam: Camera3D
var _bg_island: Node3D
var _bg_time: float = 0.0


## Inner procedural vector renderer for the majnon.studio spiral logo (crisp at any resolution, animates drawing itself!)
class MajnonLogoCanvas extends Control:
	var draw_progress: float = 0.0:
		set(v):
			draw_progress = clampf(v, 0.0, 1.0)
			queue_redraw()
	var dot_scale: float = 0.0:
		set(v):
			dot_scale = maxf(v, 0.0)
			queue_redraw()
	var glow_alpha: float = 0.0:
		set(v):
			glow_alpha = clampf(v, 0.0, 1.0)
			queue_redraw()

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var ox := (size.x - s) * 0.5
		var oy := (size.y - s) * 0.5
		var stroke_w := s * 0.072
		var off_white := Color(0.96, 0.95, 0.91, 1.0)
		var royal_blue := Color(0.19, 0.34, 0.98, 1.0)

		# Exact square-spiral geometry matching 242372.png
		var pts := PackedVector2Array([
			Vector2(ox + s * 0.21, oy + s * 0.78),
			Vector2(ox + s * 0.21, oy + s * 0.21),
			Vector2(ox + s * 0.79, oy + s * 0.21),
			Vector2(ox + s * 0.79, oy + s * 0.79),
			Vector2(ox + s * 0.38, oy + s * 0.79),
			Vector2(ox + s * 0.38, oy + s * 0.38),
			Vector2(ox + s * 0.62, oy + s * 0.38),
			Vector2(ox + s * 0.62, oy + s * 0.62),
			Vector2(ox + s * 0.50, oy + s * 0.62),
			Vector2(ox + s * 0.50, oy + s * 0.50),
		])

		# Compute total path length for smooth progressive stroke drawing
		var seg_lens: Array[float] = []
		var total_len := 0.0
		for i in range(pts.size() - 1):
			var l := pts[i].distance_to(pts[i + 1])
			seg_lens.append(l)
			total_len += l

		var rem := total_len * draw_progress
		for i in range(pts.size() - 1):
			if rem <= 0.0:
				break
			var a := pts[i]
			var b := pts[i + 1]
			var seg_l := seg_lens[i]
			var end_pt := b if rem >= seg_l else a.lerp(b, rem / maxf(seg_l, 0.001))
			draw_line(a, end_pt, off_white, stroke_w, true)
			draw_circle(a, stroke_w * 0.5, off_white)
			draw_circle(end_pt, stroke_w * 0.5, off_white)
			rem -= seg_l

		# Center royal-blue orb + soft halo pulse
		var center := Vector2(ox + s * 0.50, oy + s * 0.50)
		if glow_alpha > 0.01:
			draw_circle(center, s * 0.18 * (0.9 + 0.25 * glow_alpha), Color(0.24, 0.45, 1.0, 0.28 * glow_alpha))
		if dot_scale > 0.01:
			draw_circle(center, s * 0.088 * dot_scale, royal_blue)


func _ready() -> void:
	_build_live_3d_backdrop()
	_build_ui()
	LocalizationManager.language_changed.connect(_on_language_changed)
	_on_language_changed(LocalizationManager.current_language, LocalizationManager.is_rtl())
	if not _splash_shown:
		_splash_shown = true
		_play_interactive_studio_splash()


func _process(delta: float) -> void:
	_bg_time += delta
	if _bg_island != null:
		_bg_island.position.y = -0.35 + sin(_bg_time * 1.1) * 0.14
	if _bg_cam != null:
		var sway := sin(_bg_time * 0.42) * 0.45
		_bg_cam.position = Vector3(6.8 + sway, 7.6 + cos(_bg_time * 0.35) * 0.18, 9.2 - sway * 0.4)
		# Look slightly to the left of the island so the island sits cleanly on the RIGHT half of the screen
		_bg_cam.look_at(Vector3(-0.9, 0.7, 0.0), Vector3.UP)


func _build_live_3d_backdrop() -> void:
	var svc := SubViewportContainer.new()
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_2X
	svc.add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.075, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.56, 0.50, 0.78)
	env.ambient_light_energy = 0.88
	env.glow_enabled = true
	env.glow_intensity = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	# Real 3D twinkling stars dome (100% visible on all Android GLES3 GPUs!)
	_spawn_3d_starfield(vp, 110)

	# 3-Point Atmospheric Lights matching 251933.png
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.94, 0.90, 1.0)
	moon.light_energy = 1.25
	moon.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
	moon.shadow_enabled = true
	moon.shadow_blur = 2.0
	vp.add_child(moon)

	var rose := DirectionalLight3D.new()
	rose.light_color = Color(0.95, 0.48, 0.62)
	rose.light_energy = 0.48
	rose.rotation_degrees = Vector3(-20.0, -135.0, 0.0)
	vp.add_child(rose)

	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.32, 0.78, 1.0)
	rim.light_energy = 0.55
	rim.rotation_degrees = Vector3(-30.0, 125.0, 0.0)
	vp.add_child(rim)

	# Floating diorama island placed cleanly on the RIGHT side (zero overlap with left buttons)
	_bg_island = Node3D.new()
	_bg_island.position = Vector3(2.2, -0.35, -0.6)
	vp.add_child(_bg_island)

	var isl_mesh := MeshInstance3D.new()
	isl_mesh.mesh = LowPolyMeshLibrary.create_floating_island_mesh(
		Vector3(6.4, 2.2, 6.4), Color(0.72, 0.65, 0.86), Color(0.26, 0.20, 0.42), 7
	)
	_bg_island.add_child(isl_mesh)

	var tree := LowPolyMeshLibrary.create_low_poly_tree(Color(0.68, 0.44, 0.76), 1.0)
	tree.position = Vector3(-1.8, 0.0, -1.8)
	_bg_island.add_child(tree)

	var bench := LowPolyMeshLibrary.create_bench()
	bench.position = Vector3(-1.5, 0.0, 0.2)
	bench.rotation_degrees.y = 20.0
	_bg_island.add_child(bench)

	var lantern := LowPolyMeshLibrary.create_lantern_prop(Color(1.0, 0.78, 0.32), true)
	lantern.position = Vector3(1.8, 0.0, 1.9)
	_bg_island.add_child(lantern)

	var g1 := LowPolyMeshLibrary.create_grass_tuft()
	g1.position = Vector3(-2.3, 0.0, 2.1)
	_bg_island.add_child(g1)

	var rock := LowPolyMeshLibrary.create_rock(Color(0.34, 0.30, 0.52), 1.1)
	rock.position = Vector3(2.2, 0.0, -1.4)
	_bg_island.add_child(rock)

	var door := GoldenDoor.new()
	door.position = Vector3(0.7, 0.0, -1.0)
	door.rotation_degrees.y = -32.0
	door.required_keys = 0
	door.required_switches = 0
	_bg_island.add_child(door)

	_bg_cam = Camera3D.new()
	_bg_cam.fov = 34.0
	_bg_cam.position = Vector3(6.8, 7.6, 9.2)
	vp.add_child(_bg_cam)
	_bg_cam.look_at(Vector3(-0.9, 0.7, 0.0), Vector3.UP)


func _spawn_3d_starfield(parent: Node, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.albedo_color = Color(0.92, 0.96, 1.0)
	var sph := SphereMesh.new()
	sph.radius = 0.14
	sph.height = 0.28
	sph.radial_segments = 5
	sph.rings = 3
	for i in range(count):
		var m := MeshInstance3D.new()
		m.mesh = sph
		m.material_override = star_mat
		var dist := rng.randf_range(26.0, 52.0)
		var theta := rng.randf_range(0.0, TAU)
		var phi := rng.randf_range(-0.25, 0.95)
		m.position = Vector3(cos(theta) * cos(phi) * dist, sin(phi) * dist + 2.0, sin(theta) * cos(phi) * dist)
		var sc := rng.randf_range(0.45, 1.35)
		m.scale = Vector3(sc, sc, sc)
		parent.add_child(m)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Keep main menu split LTR so buttons stay strictly on the LEFT and 3D island stays unobstructed on the RIGHT!
	layout_direction = Control.LAYOUT_DIRECTION_LTR

	# Top bar: Title + Crystal Counter pill (top-right)
	var top_bar := MarginContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.add_theme_constant_override("margin_left", 42)
	top_bar.add_theme_constant_override("margin_right", 42)
	top_bar.add_theme_constant_override("margin_top", 20)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(top_row)

	var title_lbl := Label.new()
	title_lbl.name = "HeroTitle"
	title_lbl.text = "ما وراء الباب"
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	top_row.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(spacer)

	var crystal_pill := Button.new()
	crystal_pill.name = "CrystalPill"
	crystal_pill.custom_minimum_size = Vector2(138, 46)
	UIStyleHelper.style_button(crystal_pill, UIStyleHelper.ACCENT_CYAN, 22, 18)
	UIStyleHelper.apply_icon(crystal_pill, "res://assets/icons/icon_crystal.svg", 24)
	crystal_pill.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	crystal_pill.pressed.connect(_show_memories_modal)
	top_row.add_child(crystal_pill)

	# Left Frosted-Glass Pill Menu Column (strictly on the LEFT, never covering the 3D island!)
	var menu_scroll := ScrollContainer.new()
	menu_scroll.anchor_left = 0.04
	menu_scroll.anchor_right = 0.34
	menu_scroll.anchor_top = 0.14
	menu_scroll.anchor_bottom = 0.94
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(menu_scroll)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_vbox.add_theme_constant_override("separation", 9)
	menu_scroll.add_child(btn_vbox)

	_continue_btn = _make_pill_btn("menu_continue", "res://assets/icons/icon_play.svg", true)
	_continue_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		GameState.start_stage(int(SaveManager.data.get("last_played_stage", 1)))
	)
	btn_vbox.add_child(_continue_btn)

	var new_btn := _make_pill_btn("menu_new_game", "res://assets/icons/icon_grid.svg", false)
	new_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		GameState.start_stage(1)
	)
	btn_vbox.add_child(new_btn)

	var how_btn := _make_pill_btn("menu_how_to_play", "res://assets/icons/icon_help.svg", false)
	how_btn.pressed.connect(_show_how_to_play_modal)
	btn_vbox.add_child(how_btn)

	var stages_btn := _make_pill_btn("menu_stage_select", "res://assets/icons/icon_star.svg", false)
	stages_btn.pressed.connect(_show_stage_select_modal)
	btn_vbox.add_child(stages_btn)

	var settings_btn := _make_pill_btn("menu_settings", "res://assets/icons/icon_gear.svg", false)
	settings_btn.pressed.connect(_show_settings_modal)
	btn_vbox.add_child(settings_btn)

	var lang_btn := _make_pill_btn("settings_toggle_lang", "res://assets/icons/icon_globe.svg", false)
	lang_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		LocalizationManager.toggle_language()
	)
	btn_vbox.add_child(lang_btn)

	var credits_btn := _make_pill_btn("menu_credits", "res://assets/icons/icon_info.svg", false)
	credits_btn.pressed.connect(_show_credits_modal)
	btn_vbox.add_child(credits_btn)

	if OS.get_name() != "Web" and OS.get_name() != "iOS":
		var exit_btn := _make_pill_btn("menu_exit", "res://assets/icons/icon_exit.svg", false)
		exit_btn.pressed.connect(func() -> void: get_tree().quit())
		btn_vbox.add_child(exit_btn)

	_build_modal()


func _make_pill_btn(loc_key: String, icon_path: String, is_primary: bool) -> Button:
	var btn := Button.new()
	btn.set_meta("loc_key", loc_key)
	btn.custom_minimum_size = Vector2(0, 54 if is_primary else 48)
	if is_primary:
		var warm_bg := Color(0.56, 0.25, 0.18, 0.88)
		var warm_hover := Color(0.70, 0.36, 0.22, 0.95)
		btn.add_theme_stylebox_override("normal", UIStyleHelper.make_panel_style(warm_bg, UIStyleHelper.ACCENT_GOLD, 24, 2))
		btn.add_theme_stylebox_override("hover", UIStyleHelper.make_panel_style(warm_hover, Color(1.0, 0.92, 0.65), 24, 2))
		btn.add_theme_stylebox_override("pressed", UIStyleHelper.make_panel_style(warm_hover, UIStyleHelper.ACCENT_GOLD, 24, 2))
		btn.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
		btn.add_theme_font_size_override("font_size", 20)
	else:
		UIStyleHelper.style_button(btn, Color(0.78, 0.80, 0.96, 0.36), 22, 17)
	UIStyleHelper.apply_icon(btn, icon_path, 22)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return btn


func _build_modal() -> void:
	_modal_container = ColorRect.new()
	_modal_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_container.color = Color(0.03, 0.04, 0.10, 0.82)
	_modal_container.visible = false
	add_child(_modal_container)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.14
	panel.anchor_right = 0.86
	panel.anchor_top = 0.08
	panel.anchor_bottom = 0.92
	panel.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style())
	_modal_container.add_child(panel)

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
	UIStyleHelper.style_button(close_btn, UIStyleHelper.BORDER_SUBTLE, 20, 18)
	close_btn.pressed.connect(func() -> void: _modal_container.visible = false; _confirm_reset = false)
	outer.add_child(close_btn)


func _clear_modal_body() -> void:
	LocalizationManager.apply_layout_direction(_modal_container)
	for c in _modal_body.get_children():
		c.queue_free()


func _add_studio_card(parent: VBoxContainer) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.11, 0.12, 0.25, 0.90), UIStyleHelper.ACCENT_CYAN, 16, 1))
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var logo := MajnonLogoCanvas.new()
	logo.custom_minimum_size = Vector2(68, 68)
	logo.draw_progress = 1.0
	logo.dot_scale = 1.0
	logo.glow_alpha = 0.6
	row.add_child(logo)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var dev_lbl := Label.new()
	dev_lbl.text = "إعداد وتطوير: مجنون استديو (majnon.studio)" if LocalizationManager.is_rtl() else "Developed by majnon.studio"
	dev_lbl.add_theme_font_size_override("font_size", 18)
	dev_lbl.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	info.add_child(dev_lbl)

	var ig_btn := Button.new()
	ig_btn.text = LocalizationManager.t("studio_instagram_btn")
	ig_btn.custom_minimum_size = Vector2(0, 42)
	UIStyleHelper.style_button(ig_btn, UIStyleHelper.ACCENT_CYAN, 14, 16)
	ig_btn.pressed.connect(func() -> void: OS.shell_open(STUDIO_INSTAGRAM_URL))
	info.add_child(ig_btn)


func _show_how_to_play_modal() -> void:
	AudioManager.play_sfx("ui_click")
	_clear_modal_body()
	_modal_title.text = LocalizationManager.t("tut_title")
	_modal_container.visible = true

	for i in range(1, 4):
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIStyleHelper.make_panel_style(Color(0.12, 0.13, 0.27, 0.92), UIStyleHelper.ACCENT_CYAN, 14, 1))
		_modal_body.add_child(card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		var st_title := Label.new()
		st_title.text = LocalizationManager.t("tut_step%d_title" % i)
		st_title.add_theme_font_size_override("font_size", 19)
		st_title.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
		cv.add_child(st_title)

		var st_body := Label.new()
		st_body.text = LocalizationManager.t("tut_step%d_body" % i)
		st_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		st_body.add_theme_font_size_override("font_size", 16)
		st_body.add_theme_color_override("font_color", UIStyleHelper.TEXT_PRIMARY)
		cv.add_child(st_body)


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

		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_modal_body.add_child(grid)

		var w_start := (w - 1) * 20 + 1
		var w_count := 20
		for offset in range(w_count):
			var sid := w_start + offset
			var unlocked := SaveManager.is_stage_unlocked(sid)
			var done := SaveManager.is_stage_completed(sid)
			var mem := SaveManager.is_secret_collected("mem_%03d" % sid)
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 54)
			btn.text = ("%d%s%s" % [sid, " ★" if done else "", " ◆" if mem else ""]) if unlocked else ("%d" % sid)
			btn.disabled = not unlocked
			UIStyleHelper.style_button(btn, UIStyleHelper.ACCENT_GOLD if done else UIStyleHelper.BORDER_SUBTLE, 14, 17)
			btn.pressed.connect(func() -> void: GameState.start_stage(sid))
			grid.add_child(btn)


func _show_memories_modal() -> void:
	AudioManager.play_sfx("ui_click")
	_clear_modal_body()
	_modal_title.text = "%s (%d / 120)" % [LocalizationManager.t("menu_memories"), SaveManager.get_collected_secret_count()]
	_modal_container.visible = true

	var hint := Label.new()
	hint.text = LocalizationManager.t("secret_ending_hint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", UIStyleHelper.ACCENT_GOLD)
	_modal_body.add_child(hint)

	for s in range(1, 121):
		var found := SaveManager.is_secret_collected("mem_%03d" % s)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = ("◆ #%03d — %s" % [s, LocalizationManager.t("lore_%03d" % s)]) if found else ("◇ #%03d — %s" % [s, LocalizationManager.t("memory_locked")])
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
	gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + UIStyleHelper.quality_label_ar(str(SaveManager.get_setting("graphics_quality", "medium")))
	gfx_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(gfx_btn, UIStyleHelper.BORDER_SUBTLE, 16, 17)
	gfx_btn.pressed.connect(func() -> void:
		var cur := str(SaveManager.get_setting("graphics_quality", "medium"))
		var nxt := "high" if cur == "medium" else ("low" if cur == "high" else "medium")
		SaveManager.set_setting("graphics_quality", nxt)
		gfx_btn.text = LocalizationManager.t("settings_graphics") + ": " + UIStyleHelper.quality_label_ar(nxt)
	)
	_modal_body.add_child(gfx_btn)

	_add_studio_card(_modal_body)

	var reset_btn := Button.new()
	reset_btn.text = LocalizationManager.t("settings_reset_progress")
	reset_btn.custom_minimum_size = Vector2(0, 48)
	UIStyleHelper.style_button(reset_btn, Color(0.95, 0.35, 0.42), 16, 17)
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

	_add_studio_card(_modal_body)

	var txt := Label.new()
	txt.text = LocalizationManager.t("credits_body")
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.add_theme_font_size_override("font_size", 17)
	_modal_body.add_child(txt)


func _on_language_changed(_lang: String, _rtl: bool) -> void:
	_refresh_texts()


func _refresh_texts() -> void:
	_continue_btn.visible = SaveManager.has_progress()
	_apply_loc(self)
	var hero := find_child("HeroTitle", true, false) as Label
	if hero != null:
		hero.text = "ما وراء الباب" if LocalizationManager.is_rtl() else "BEYOND THE DOOR"
	var cpill := find_child("CrystalPill", true, false) as Button
	if cpill != null:
		cpill.text = " %d / 120" % SaveManager.get_collected_secret_count()


func _apply_loc(node: Node) -> void:
	if node.has_meta("loc_key"):
		var k := str(node.get_meta("loc_key"))
		if node is Button:
			(node as Button).text = LocalizationManager.t(k)
		elif node is Label:
			(node as Label).text = LocalizationManager.t(k)
	for c in node.get_children():
		_apply_loc(c)


func _play_interactive_studio_splash() -> void:
	## Animated vector-drawn majnon.studio logo intro — waits for player tap to enter (NO premature auto-skip!)
	var splash := Button.new()
	splash.flat = true
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(splash)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.065, 0.065, 0.085, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)

	var logo_wrap := CenterContainer.new()
	logo_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(logo_wrap)

	var logo := MajnonLogoCanvas.new()
	logo.custom_minimum_size = Vector2(200, 200)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_wrap.add_child(logo)

	var title_ar := Label.new()
	title_ar.text = "مجنون استديو"
	title_ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_ar.add_theme_font_size_override("font_size", 42)
	title_ar.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	title_ar.modulate.a = 0.0
	box.add_child(title_ar)

	var handle_lbl := Label.new()
	handle_lbl.text = "majnon.studio"
	handle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	handle_lbl.add_theme_font_size_override("font_size", 20)
	handle_lbl.add_theme_color_override("font_color", Color(0.35, 0.56, 1.0, 0.96))
	handle_lbl.modulate.a = 0.0
	box.add_child(handle_lbl)

	var tap_lbl := Label.new()
	tap_lbl.text = "اضغط في أي مكان للدخول"
	tap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_lbl.add_theme_font_size_override("font_size", 17)
	tap_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 0.92))
	tap_lbl.modulate.a = 0.0
	box.add_child(tap_lbl)

	# 1) Draw spiral stroke smoothly, 2) pop blue center orb, 3) reveal studio name, 4) pulse tap prompt
	var anim := create_tween()
	anim.tween_property(logo, "draw_progress", 1.0, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	anim.tween_property(logo, "dot_scale", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim.parallel().tween_property(logo, "glow_alpha", 1.0, 0.55)
	anim.parallel().tween_property(title_ar, "modulate:a", 1.0, 0.45)
	anim.tween_property(handle_lbl, "modulate:a", 1.0, 0.35)
	anim.tween_property(tap_lbl, "modulate:a", 1.0, 0.40)

	# Continuous breathing glow & tap prompt pulse until user taps
	var pulse := create_tween().set_loops()
	pulse.tween_property(tap_lbl, "modulate:a", 0.35, 0.85)
	pulse.tween_property(tap_lbl, "modulate:a", 1.0, 0.85)

	var ready_to_enter := {"ok": false}
	anim.finished.connect(func() -> void: ready_to_enter["ok"] = true)

	var dismissed := {"done": false}
	splash.pressed.connect(func() -> void:
		if dismissed["done"] or not ready_to_enter["ok"]:
			return
		dismissed["done"] = true
		pulse.kill()
		AudioManager.play_sfx("ui_click")
		var out_tw := create_tween()
		out_tw.tween_property(splash, "modulate:a", 0.0, 0.45)
		out_tw.tween_callback(splash.queue_free)
	)
