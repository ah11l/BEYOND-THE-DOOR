class_name GravityZone
extends Node3D

## Controlled local gravity field toggled by a BlueDoor.
## When active, lifts or reduces gravity smoothly inside its volume with visual chevrons.

@export var zone_id: String = "grav_1"
@export var zone_size: Vector3 = Vector3(3.4, 5.5, 3.4)
@export var gravity_scale: float = 0.35
@export var upward_lift: float = 4.6
@export var starts_active: bool = false

var is_active: bool = false
var _player_inside: PlayerController = null
var _field_visual: Node3D
var _chevron_nodes: Array[Node3D] = []
var _t: float = 0.0


func _ready() -> void:
	is_active = starts_active
	_build_visuals()
	_build_area()
	_refresh_visuals()


func _build_visuals() -> void:
	_field_visual = Node3D.new()
	add_child(_field_visual)

	# Translucent cyan column outline
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.84, 1.0, 0.16)
	mat.emission_enabled = true
	mat.emission = Color(0.24, 0.84, 1.0)
	mat.emission_energy_multiplier = 0.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var col := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = zone_size
	col.mesh = box
	col.position = Vector3(0.0, zone_size.y * 0.5, 0.0)
	col.material_override = mat
	_field_visual.add_child(col)

	for i in range(3):
		var lbl := Label3D.new()
		lbl.text = "▲"
		lbl.font_size = 64
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = Color(0.55, 0.94, 1.0, 0.85)
		lbl.position = Vector3(0.0, 0.8 + float(i) * (zone_size.y / 3.0), 0.0)
		_field_visual.add_child(lbl)
		_chevron_nodes.append(lbl)


func _build_area() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = zone_size
	shape.shape = box
	shape.position = Vector3(0.0, zone_size.y * 0.5, 0.0)
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)


func set_zone_active(active: bool) -> void:
	is_active = active
	_refresh_visuals()
	if _player_inside != null and is_instance_valid(_player_inside):
		if is_active:
			_player_inside.set_gravity_zone(gravity_scale, upward_lift)
		else:
			_player_inside.reset_gravity_zone()


func _refresh_visuals() -> void:
	if _field_visual != null:
		_field_visual.visible = is_active


func _process(delta: float) -> void:
	if not is_active:
		return
	_t += delta
	for i in range(_chevron_nodes.size()):
		var y := fmod(_t * 1.8 + float(i) * (zone_size.y / 3.0), zone_size.y)
		_chevron_nodes[i].position.y = 0.4 + y


func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		_player_inside = body as PlayerController
		if is_active:
			_player_inside.set_gravity_zone(gravity_scale, upward_lift)


func _on_body_exited(body: Node) -> void:
	if body == _player_inside:
		_player_inside.reset_gravity_zone()
		_player_inside = null
