class_name TouchJoystick
extends Control

## Responsive touchscreen virtual joystick matching the bottom-left control in the visual reference.
## Drives GameState.set_touch_move(vec) using real touch/mouse drag input.

@export var max_radius: float = 58.0
@export var deadzone: float = 0.14

var _touch_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO
var _active: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(156, 156)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed and _touch_index == -1:
			_touch_index = ev.index
			_active = true
			_update_knob(ev.position)
			accept_event()
		elif not ev.pressed and ev.index == _touch_index:
			_reset_stick()
			accept_event()
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		if ev.index == _touch_index:
			_update_knob(ev.position)
			accept_event()
	elif event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_active = true
				_update_knob(ev.position)
			else:
				_reset_stick()
			accept_event()
	elif event is InputEventMouseMotion and _active and _touch_index == -1:
		_update_knob((event as InputEventMouseMotion).position)
		accept_event()


func _update_knob(local_pos: Vector2) -> void:
	var center := size * 0.5
	var delta := local_pos - center
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	_knob_offset = delta
	var norm := delta / max_radius
	if norm.length() < deadzone:
		GameState.set_touch_move(Vector2.ZERO)
	else:
		GameState.set_touch_move(norm)
	queue_redraw()


func _reset_stick() -> void:
	_touch_index = -1
	_active = false
	_knob_offset = Vector2.ZERO
	GameState.set_touch_move(Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var outer_r := minf(size.x, size.y) * 0.46
	draw_circle(center, outer_r, Color(0.14, 0.14, 0.28, 0.45))
	draw_arc(center, outer_r, 0.0, TAU, 48, Color(0.75, 0.78, 0.96, 0.48), 2.5, true)

	# 4 subtle directional chevrons
	var arrow_dist := outer_r * 0.68
	var arrow_col := Color(0.92, 0.94, 1.0, 0.72)
	_draw_triangle(center + Vector2(0, -arrow_dist), Vector2(0, -1), 7.0, arrow_col)
	_draw_triangle(center + Vector2(0, arrow_dist), Vector2(0, 1), 7.0, arrow_col)
	_draw_triangle(center + Vector2(-arrow_dist, 0), Vector2(-1, 0), 7.0, arrow_col)
	_draw_triangle(center + Vector2(arrow_dist, 0), Vector2(1, 0), 7.0, arrow_col)

	# Movable thumb knob
	var knob_pos := center + _knob_offset
	draw_circle(knob_pos, 22.0, Color(0.76, 0.80, 0.98, 0.52 if _active else 0.34))
	draw_arc(knob_pos, 22.0, 0.0, TAU, 32, Color(0.95, 0.96, 1.0, 0.75), 2.0, true)


func _draw_triangle(pos: Vector2, dir: Vector2, r: float, color: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([
		pos + dir * r,
		pos - dir * (r * 0.6) + perp * (r * 0.75),
		pos - dir * (r * 0.6) - perp * (r * 0.75),
	])
	draw_colored_polygon(pts, color)
