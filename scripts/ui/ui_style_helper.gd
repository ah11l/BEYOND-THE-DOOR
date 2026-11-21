class_name UIStyleHelper
extends RefCounted

## Shared visual style factory matching the calm dark-indigo translucent mobile UI reference.

const BG_PANEL := Color(0.08, 0.09, 0.20, 0.84)
const BG_BUTTON := Color(0.14, 0.15, 0.30, 0.78)
const BG_BUTTON_HOVER := Color(0.22, 0.24, 0.46, 0.90)
const BG_BUTTON_PRESSED := Color(0.30, 0.26, 0.56, 0.95)
const BORDER_SUBTLE := Color(0.56, 0.62, 0.88, 0.42)
const ACCENT_GOLD := Color(1.0, 0.80, 0.36, 1.0)
const ACCENT_CYAN := Color(0.28, 0.88, 1.0, 1.0)
const TEXT_PRIMARY := Color(0.96, 0.97, 1.0, 1.0)
const TEXT_MUTED := Color(0.75, 0.79, 0.92, 1.0)


static func make_panel_style(bg: Color = BG_PANEL, border: Color = BORDER_SUBTLE, radius: int = 18, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


static func style_button(btn: Button, accent: Color = BORDER_SUBTLE, radius: int = 16, font_size: int = 20) -> void:
	btn.add_theme_stylebox_override("normal", make_panel_style(BG_BUTTON, accent, radius, 2))
	btn.add_theme_stylebox_override("hover", make_panel_style(BG_BUTTON_HOVER, accent.lightened(0.2), radius, 2))
	btn.add_theme_stylebox_override("pressed", make_panel_style(BG_BUTTON_PRESSED, ACCENT_GOLD, radius, 2))
	btn.add_theme_stylebox_override("disabled", make_panel_style(Color(0.10, 0.10, 0.18, 0.48), Color(0.35, 0.36, 0.48, 0.25), radius, 1))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", ACCENT_GOLD)
	btn.add_theme_color_override("font_pressed_color", ACCENT_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.56, 0.68, 0.65))
	btn.add_theme_font_size_override("font_size", font_size)


static func style_circle_button(btn: Button, diameter: int, accent: Color = BORDER_SUBTLE, font_size: int = 22) -> void:
	btn.custom_minimum_size = Vector2(diameter, diameter)
	style_button(btn, accent, diameter / 2, font_size)
