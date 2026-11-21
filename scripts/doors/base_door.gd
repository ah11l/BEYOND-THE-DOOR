class_name BaseDoor
extends Node3D

## Base class for all four door types (Golden, Blue, Purple, Black) with
## stylized low-poly frame, hinged leaf, non-color-only emblem, glow light, and interaction area.

signal door_activated(door: BaseDoor, player: Node)

@export var door_id: String = "door_0"
@export var door_color: Color = Color(1.0, 0.78, 0.30)
@export var frame_color: Color = Color(0.28, 0.17, 0.16)
@export var emblem_text: String = "★"
@export var is_unlocked: bool = true

var _leaf_pivot: Node3D
var _leaf_mat: StandardMaterial3D
var _glow_light: OmniLight3D
var _emblem_label: Label3D
var _open_angle: float = 0.0
var _target_angle: float = 0.0


func _ready() -> void:
	_build_visuals()
	_build_interaction_area()
	_refresh_visual_state()


func _build_visuals() -> void:
	var frame_mat := LowPolyMeshLibrary.make_flat_material(frame_color, 0.78)
	_leaf_mat = LowPolyMeshLibrary.make_flat_material(door_color, 0.25, door_color, 1.8)

	# Left, Right, Top frame pillars
	var post_specs := [
		{"pos": Vector3(-0.78, 1.35, 0.0), "size": Vector3(0.18, 2.7, 0.24)},
		{"pos": Vector3(0.78, 1.35, 0.0), "size": Vector3(0.18, 2.7, 0.24)},
		{"pos": Vector3(0.0, 2.66, 0.0), "size": Vector3(1.74, 0.20, 0.28)},
	]
	for sp in post_specs:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = sp["size"] as Vector3
		m.mesh = b
		m.position = sp["pos"] as Vector3
		m.material_override = frame_mat
		add_child(m)

	# Hinged glowing door leaf
	_leaf_pivot = Node3D.new()
	_leaf_pivot.name = "LeafPivot"
	_leaf_pivot.position = Vector3(-0.68, 0.0, 0.0)
	add_child(_leaf_pivot)

	var leaf := MeshInstance3D.new()
	var leaf_box := BoxMesh.new()
	leaf_box.size = Vector3(1.36, 2.52, 0.10)
	leaf.mesh = leaf_box
	leaf.position = Vector3(0.68, 1.28, 0.0)
	leaf.material_override = _leaf_mat
	_leaf_pivot.add_child(leaf)

	# High-contrast accessibility emblem on both sides of the door
	_emblem_label = Label3D.new()
	_emblem_label.text = emblem_text
	_emblem_label.font_size = 96
	_emblem_label.modulate = Color(1.0, 0.98, 0.94)
	_emblem_label.outline_size = 10
	_emblem_label.outline_modulate = Color(0.08, 0.06, 0.14)
	_emblem_label.position = Vector3(0.68, 1.45, 0.08)
	_leaf_pivot.add_child(_emblem_label)

	var emblem_back := _emblem_label.duplicate() as Label3D
	emblem_back.position = Vector3(0.68, 1.45, -0.08)
	emblem_back.rotation.y = PI
	_leaf_pivot.add_child(emblem_back)

	# Warm or colored portal light
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = door_color
	_glow_light.light_energy = 3.2
	_glow_light.omni_range = 8.5
	_glow_light.shadow_enabled = false
	_glow_light.position = Vector3(0.0, 1.35, 0.35)
	add_child(_glow_light)


func _build_interaction_area() -> void:
	var area := Area3D.new()
	area.name = "InteractTrigger"
	area.collision_layer = 8 # Layer 4: Interactable
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.1, 2.6, 1.8)
	shape.shape = box
	shape.position = Vector3(0.0, 1.3, 0.0)
	area.add_child(shape)
	add_child(area)


func _process(delta: float) -> void:
	if _leaf_pivot != null:
		_open_angle = lerpf(_open_angle, _target_angle, minf(1.0, 6.0 * delta))
		_leaf_pivot.rotation.y = _open_angle


func set_unlocked(unlocked: bool) -> void:
	var changed := is_unlocked != unlocked
	is_unlocked = unlocked
	_target_angle = deg_to_rad(-38.0) if is_unlocked else 0.0
	_refresh_visual_state()
	if changed and is_unlocked:
		AudioManager.play_sfx("door_open")


func _refresh_visual_state() -> void:
	if _leaf_mat != null:
		_leaf_mat.emission_energy_multiplier = 2.1 if is_unlocked else 0.35
		_leaf_mat.albedo_color = door_color if is_unlocked else door_color.darkened(0.55)
	if _glow_light != null:
		_glow_light.light_energy = 3.4 if is_unlocked else 0.55


func can_interact(_player: Node) -> bool:
	return true


func get_prompt_key() -> String:
	return "prompt_interact_door"


func interact(player: Node) -> void:
	if not is_unlocked:
		AudioManager.play_sfx("door_locked")
		return
	door_activated.emit(self, player)
