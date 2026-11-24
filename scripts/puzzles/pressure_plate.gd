class_name PressurePlate
extends Node3D

## Configurable puzzle pressure plate reacting to Player, Echo ghost, and/or Pushable blocks.
## Features world-harmonized sculpted stone/bronze frame and crisp emissive activation feedback.

signal plate_state_changed(plate_id: String, pressed: bool)

@export var plate_id: String = "plate_1"
@export var world_index: int = 1
@export var accept_player: bool = true
@export var accept_echo: bool = true
@export var accept_block: bool = true
@export var stay_pressed: bool = false

var is_pressed: bool = false
var _bodies_on_plate: Array[Node] = []
var _pad_mesh: MeshInstance3D
var _pad_mat: StandardMaterial3D
var _base_color: Color = Color(0.92, 0.72, 0.34)


func _ready() -> void:
	if accept_echo and not accept_player:
		_base_color = Color(0.24, 0.90, 1.0)
	elif world_index == 5:
		_base_color = Color(0.84, 0.86, 0.96)
	elif world_index == 4:
		_base_color = Color(0.76, 0.62, 0.32)
	else:
		_base_color = Color(0.95, 0.74, 0.34)
	_build_visuals()
	_build_detector()


func _build_visuals() -> void:
	var pal := LowPolyMeshLibrary.get_world_palette(world_index)
	var rune_col: Color = pal.get("rune_glow", Color(0.32, 0.88, 1.0))

	var frame := MeshInstance3D.new()
	var f_box := BoxMesh.new()
	f_box.size = Vector3(1.52, 0.08, 1.52)
	frame.mesh = f_box
	frame.position = Vector3(0.0, 0.04, 0.0)
	frame.material_override = LowPolyMeshLibrary.make_flat_material(Color(0.18, 0.20, 0.28), 0.75)
	add_child(frame)

	var trim := MeshInstance3D.new()
	var t_box := BoxMesh.new()
	t_box.size = Vector3(1.36, 0.09, 1.36)
	trim.mesh = t_box
	trim.position = Vector3(0.0, 0.055, 0.0)
	trim.material_override = LowPolyMeshLibrary.make_flat_material(rune_col.darkened(0.35), 0.45, rune_col, 0.30)
	add_child(trim)

	_pad_mesh = MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(1.16, 0.12, 1.16)
	_pad_mesh.mesh = p_box
	_pad_mesh.position = Vector3(0.0, 0.11, 0.0)
	_pad_mat = LowPolyMeshLibrary.make_flat_material(_base_color.darkened(0.28), 0.38, _base_color, 0.30)
	_pad_mat.metallic = 0.22
	_pad_mesh.material_override = _pad_mat
	add_child(_pad_mesh)

	var sym := Label3D.new()
	sym.text = "◈" if (accept_echo and not accept_player) else "◎"
	sym.font_size = 44
	sym.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	sym.position = Vector3(0.0, 0.185, 0.0)
	sym.modulate = Color(0.98, 0.96, 0.90)
	add_child(sym)


func _build_detector() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	var mask := 0
	if accept_player:
		mask |= 2  # Layer 2: Player
	if accept_echo:
		mask |= 4  # Layer 3: Echo
	if accept_block:
		mask |= 16 # Layer 5: Pushable
	area.collision_mask = mask

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 0.8, 1.3)
	shape.shape = box
	shape.position = Vector3(0.0, 0.4, 0.0)
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)


func _on_body_entered(body: Node) -> void:
	if not (body in _bodies_on_plate):
		_bodies_on_plate.append(body)
	_update_pressed_state()


func _on_body_exited(body: Node) -> void:
	_bodies_on_plate.erase(body)
	_update_pressed_state()


func _update_pressed_state() -> void:
	var valid_count := 0
	for b in _bodies_on_plate:
		if is_instance_valid(b):
			valid_count += 1
	var next_pressed := true if (stay_pressed and is_pressed) else (valid_count > 0)
	if next_pressed != is_pressed:
		is_pressed = next_pressed
		_refresh_visual()
		if is_pressed:
			AudioManager.play_sfx("plate_press")
		plate_state_changed.emit(plate_id, is_pressed)


func _refresh_visual() -> void:
	if _pad_mesh != null:
		_pad_mesh.position.y = 0.06 if is_pressed else 0.11
	if _pad_mat != null:
		_pad_mat.albedo_color = _base_color if is_pressed else _base_color.darkened(0.28)
		_pad_mat.emission_energy_multiplier = 1.85 if is_pressed else 0.30


func reset_plate() -> void:
	_bodies_on_plate.clear()
	if is_pressed:
		is_pressed = false
		_refresh_visual()
		plate_state_changed.emit(plate_id, false)
