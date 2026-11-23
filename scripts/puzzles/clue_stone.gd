class_name ClueStone
extends Node3D

## Environmental lore tablet / puzzle inscription readable via interaction.

signal clue_read(clue_key: String)

@export var clue_key: String = "clue_default"


func _ready() -> void:
	var stone := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.62, 1.25, 0.24)
	stone.mesh = box
	stone.position = Vector3(0.0, 0.62, 0.0)
	stone.material_override = LowPolyMeshLibrary.make_flat_material(
		Color(0.24, 0.22, 0.36), 0.85, Color(0.35, 0.68, 0.95), 0.30
	)
	add_child(stone)

	var rune := Label3D.new()
	rune.text = "❖"
	rune.font_size = 56
	rune.position = Vector3(0.0, 0.82, 0.14)
	rune.modulate = Color(0.75, 0.92, 1.0)
	add_child(rune)

	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.25
	shape.shape = sph
	shape.position = Vector3(0.0, 0.65, 0.0)
	area.add_child(shape)
	add_child(area)


func get_prompt_key() -> String:
	return "prompt_read_clue"


func interact(_player: Node) -> void:
	AudioManager.play_sfx("ui_click")
	clue_read.emit(clue_key)

func get_interact_icon_type() -> String:
	return "book"
