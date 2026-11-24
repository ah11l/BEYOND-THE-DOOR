class_name TouchJoystick
extends Control

## Floating full-left-half virtual touchpad joystick.
## Touch ANYWHERE on the left half of the screen: the joystick centers right under your thumb,
## supports smooth 360-degree analog movement, and fades gently when released.

@export var max_radius: float = 68.0
@export var deadzone: float = 0.10

var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO
var _active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed and _touch_index == -1:
			_touch_index = ev.index
			_active = true
			_origin = ev.position
			_knob_offset = Vector2.ZERO
			GameState.set_touch_move(Vector2.ZERO)
			queue_redraw()
			accept_event()
		elif not ev.pressed and ev.index == _touch_index:
			_reset_stick()
			accept_event()
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		if ev.index == _touch_index:
			_update_knob(ev.position)
			accept_event()
	elif event is InputEventMouseButton and _touch_index == -1:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_active = true
				_origin = ev.position
				_knob_offset = Vector2.ZERO
				queue_redraw()
			else:
				_reset_stick()
			accept_event()
	elif event is InputEventMouseMotion and _active and _touch_index == -1:
		_update_knob((event as InputEventMouseMotion).position)
		accept_event()


func _update_knob(local_pos: Vector2) -> void:
	var delta := local_pos - _origin
	var dist := delta.length()
	if dist > max_radius:
		# Softly follow thumb if dragged far so changing direction stays instant
		_origin = local_pos - delta.normalized() * max_radius
		delta = delta.normalized() * max_radius
		dist = max_radius
	_knob_offset = delta
	var norm_len := dist / max_radius
	if norm_len < deadzone:
		GameState.set_touch_move(Vector2.ZERO)
	else:
		# Smooth analog curve from deadzone..1.0
		var scaled := (norm_len - deadzone) / (1.0 - deadzone)
		GameState.set_touch_move(delta.normalized() * clampf(scaled, 0.0, 1.0))
	queue_redraw()


func _reset_stick() -> void:
	_touch_index = -1
	_active = false
	_knob_offset = Vector2.ZERO
	GameState.set_touch_move(Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	var resting_center := Vector2(minf(size.x * 0.34, 170.0), maxf(size.y - 125.0, size.y * 0.65))
	var center := _origin if _active else resting_center
	var alpha_mult := 1.0 if _active else 0.42
	var outer_r := max_radius

	draw_circle(center, outer_r, Color(0.14, 0.14, 0.30, 0.38 * alpha_mult))
	draw_arc(center, outer_r, 0.0, TAU, 48, Color(0.84, 0.86, 1.0, 0.62 * alpha_mult), 2.4, true)

	# 4 subtle directional chevrons
	var arrow_dist := outer_r * 0.68
	var arrow_col := Color(0.95, 0.96, 1.0, 0.72 * alpha_mult)
	_draw_triangle(center + Vector2(0, -arrow_dist), Vector2(0, -1), 6.5, arrow_col)
	_draw_triangle(center + Vector2(0, arrow_dist), Vector2(0, 1), 6.5, arrow_col)
	_draw_triangle(center + Vector2(-arrow_dist, 0), Vector2(-1, 0), 6.5, arrow_col)
	_draw_triangle(center + Vector2(arrow_dist, 0), Vector2(1, 0), 6.5, arrow_col)

	# Movable thumb knob
	var knob_pos := center + _knob_offset
	draw_circle(knob_pos, 24.0, Color(0.80, 0.86, 1.0, (0.62 if _active else 0.35) * alpha_mult))
	draw_arc(knob_pos, 24.0, 0.0, TAU, 32, Color(0.98, 0.99, 1.0, 0.85 * alpha_mult), 2.0, true)


func _draw_triangle(pos: Vector2, dir: Vector2, r: float, color: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([
		pos + dir * r,
		pos - dir * (r * 0.6) + perp * (r * 0.75),
		pos - dir * (r * 0.6) - perp * (r * 0.75),
	])
	draw_colored_polygon(pts, color)
