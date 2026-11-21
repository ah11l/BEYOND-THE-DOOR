class_name KeyPickup
extends Node3D

## Glowing golden key relic collected automatically on approach or via interact.

signal key_collected(key_id: String)

@export var key_id: String = "key_1"
var collected: bool = false
var _visual: Node3D
var _t: float = 0.0


func _ready() -> void:
	_visual = Node3D.new()
	add_child(_visual)

	var mat := LowPolyMeshLibrary.make_flat_material(Color(1.0, 0.84, 0.32), 0.2, Color(1.0, 0.78, 0.25), 2.0)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.24
	sphere.height = 0.48
	sphere.radial_segments = 6
	sphere.rings = 3
	head.mesh = sphere
	head.position = Vector3(0.0, 0.82, 0.0)
	head.material_override = mat
	_visual.add_child(head)

	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.10, 0.44, 0.10)
	shaft.mesh = box
	shaft.position = Vector3(0.0, 0.46, 0.0)
	shaft.material_override = mat
	_visual.add_child(shaft)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.82, 0.35)
	light.light_energy = 1.2
	light.omni_range = 3.2
	light.position = Vector3(0.0, 0.7, 0.0)
	_visual.add_child(light)

	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.85
	shape.shape = sph
	shape.position = Vector3(0.0, 0.65, 0.0)
	area.add_child(shape)
	area.body_entered.connect(_on_player_touched)
	add_child(area)


func _process(delta: float) -> void:
	if collected or _visual == null:
		return
	_t += delta
	_visual.rotation.y += delta * 1.6
	_visual.position.y = sin(_t * 2.4) * 0.10


func _on_player_touched(_body: Node) -> void:
	_collect()


func interact(_player: Node) -> void:
	_collect()


func _collect() -> void:
	if collected:
		return
	collected = true
	visible = false
	set_process(false)
	AudioManager.play_sfx("key_pickup")
	key_collected.emit(key_id)
