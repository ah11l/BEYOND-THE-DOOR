class_name UIStyleHelper
extends RefCounted

## Frosted-glass dark-indigo UI style matching the reference visual aesthetic.
## V26: Strips Godot's default white rectangular focus box on Android touch buttons.

const BG_PANEL := Color(0.10, 0.11, 0.24, 0.76)
const BG_BUTTON := Color(0.16, 0.16, 0.34, 0.62)
const BG_BUTTON_HOVER := Color(0.24, 0.24, 0.48, 0.82)
const BG_BUTTON_PRESSED := Color(0.32, 0.28, 0.58, 0.92)
const BORDER_SUBTLE := Color(0.78, 0.80, 0.96, 0.42)
const ACCENT_GOLD := Color(1.0, 0.82, 0.40, 1.0)
const ACCENT_CYAN := Color(0.36, 0.88, 1.0, 1.0)
const TEXT_PRIMARY := Color(0.97, 0.98, 1.0, 1.0)
const TEXT_MUTED := Color(0.78, 0.82, 0.94, 1.0)


static func make_panel_style(bg: Color = BG_PANEL, border: Color = BORDER_SUBTLE, radius: int = 18, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0.02, 0.02, 0.08, 0.35)
	sb.shadow_size = 8
	return sb


static func style_button(btn: Button, accent: Color = BORDER_SUBTLE, radius: int = 16, font_size: int = 19) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", make_panel_style(BG_BUTTON, accent, radius, 2))
	btn.add_theme_stylebox_override("hover", make_panel_style(BG_BUTTON_HOVER, accent.lightened(0.2), radius, 2))
	btn.add_theme_stylebox_override("pressed", make_panel_style(BG_BUTTON_PRESSED, ACCENT_GOLD, radius, 2))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", make_panel_style(Color(0.10, 0.10, 0.18, 0.42), Color(0.45, 0.46, 0.62, 0.22), radius, 1))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", ACCENT_GOLD)
	btn.add_theme_color_override("font_pressed_color", ACCENT_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.56, 0.68, 0.60))
	btn.add_theme_font_size_override("font_size", font_size)


static func style_circle_button(btn: Button, diameter: int, accent: Color = BORDER_SUBTLE, font_size: int = 20) -> void:
	btn.custom_minimum_size = Vector2(diameter, diameter)
	style_button(btn, accent, diameter / 2, font_size)


static func apply_icon(btn: Button, icon_path: String, icon_width: int = 28) -> void:
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_theme_constant_override("icon_max_width", icon_width)


static func quality_label_ar(q: String) -> String:
	match q:
		"low":
			return "منخفض" if LocalizationManager.is_rtl() else "Low"
		"medium":
			return "متوسط" if LocalizationManager.is_rtl() else "Medium"
		"ultra":
			return "فائق (Ultra)" if LocalizationManager.is_rtl() else "Ultra"
		_:
			return "عالي" if LocalizationManager.is_rtl() else "High"


static func next_quality(q: String) -> String:
	match q:
		"low":
			return "medium"
		"medium":
			return "high"
		"high":
			return "ultra"
		_:
			return "low"
