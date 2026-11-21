class_name MemorySecret
extends Node3D

## Hidden Memory Crystal (120 total across all stages) unlocking lore, powers, & Secret Ending.
## Respects room_state visibility AND collision/monitoring so hidden crystals cannot be collected.

signal secret_collected(secret_id: String, lore_key: String)

@export var secret_id: String = "mem_001"
@export var lore_key: String = "lore_001"

var collected: bool = false
var _state_active: bool = true
var _visual: Node3D
var _area: Area3D
var _shape: CollisionShape3D
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
		set_process(false)
		return

	_area = Area3D.new()
	_area.collision_layer = 8
	_area.collision_mask = 2
	_shape = CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.95
	_shape.shape = sph
	_shape.position = Vector3(0.0, 0.7, 0.0)
	_area.add_child(_shape)
	_area.body_entered.connect(_on_player_entered)
	add_child(_area)
	_apply_effective_state()


func set_state_active(active: bool) -> void:
	_state_active = active
	_apply_effective_state()


func _apply_effective_state() -> void:
	var effective := _state_active and not collected
	visible = effective
	if _area != null and is_instance_valid(_area):
		_area.set_deferred("monitoring", effective)
		_area.set_deferred("monitorable", effective)
		_area.collision_layer = 8 if effective else 0
		_area.collision_mask = 2 if effective else 0
	if _shape != null and is_instance_valid(_shape):
		_shape.set_deferred("disabled", not effective)


func can_interact(_player: Node) -> bool:
	return _state_active and not collected


func _process(delta: float) -> void:
	if collected or not _state_active or _visual == null:
		return
	_t += delta
	_visual.rotation.y += delta * 1.2
	_visual.position.y = 0.35 + sin(_t * 2.2) * 0.12


func _on_player_entered(_body: Node) -> void:
	if not _state_active or collected:
		return
	_collect()


func interact(_player: Node) -> void:
	if not _state_active or collected:
		return
	_collect()


func _collect() -> void:
	if collected or not _state_active:
		return
	collected = true
	_apply_effective_state()
	set_process(false)
	SaveManager.collect_secret(secret_id)
	AudioManager.play_sfx("secret_found")
	secret_collected.emit(secret_id, lore_key)
