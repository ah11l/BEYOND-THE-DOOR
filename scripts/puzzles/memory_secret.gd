class_name MemorySecret
extends Node3D

## Hidden Memory Crystal (30 total across all stages) unlocking lore & Secret Ending.

signal secret_collected(secret_id: String, lore_key: String)

@export var secret_id: String = "mem_01"
@export var lore_key: String = "lore_01"

var collected: bool = false
var _visual: Node3D
var _t: float = 0.0


func _ready() -> void:
	collected = SaveManager.is_secret_collected(secret_id)
	_visual = LowPolyMeshLibrary.create_crystal_cluster(Color(0.32, 0.88, 1.0))
	_visual.scale = Vector3(0.65, 0.65, 0.65)
	_visual.position = Vector3(0.0, 0.35, 0.0)
	add_child(_visual)

	var light := OmniLight3D.new()
	light.light_color = Color(0.35, 0.88, 1.0)
	light.light_energy = 1.4
	light.omni_range = 3.8
	light.position = Vector3(0.0, 0.75, 0.0)
	_visual.add_child(light)

	if collected:
		visible = false
		return

	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.95
	shape.shape = sph
	shape.position = Vector3(0.0, 0.7, 0.0)
	area.add_child(shape)
	area.body_entered.connect(_on_player_entered)
	add_child(area)


func _process(delta: float) -> void:
	if collected or _visual == null:
		return
	_t += delta
	_visual.rotation.y += delta * 1.2
	_visual.position.y = 0.35 + sin(_t * 2.2) * 0.12


func _on_player_entered(_body: Node) -> void:
	_collect()


func interact(_player: Node) -> void:
	_collect()


func _collect() -> void:
	if collected:
		return
	collected = true
	visible = false
	set_process(false)
	SaveManager.collect_secret(secret_id)
	AudioManager.play_sfx("secret_found")
	secret_collected.emit(secret_id, lore_key)
