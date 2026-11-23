class_name MemorySecret
extends Node3D

## Hidden Memory Crystal (120 total) on a glowing stone pedestal (matching 254212.png):
## - Outer 2.2m zone displays the circular Magnifying Glass contextual interaction button
## - Tight inner 0.65m touch zone or tapping the circular button collects it cleanly
## - Strictly respects room_state visibility AND collision/monitoring

signal secret_collected(secret_id: String, lore_key: String)

@export var secret_id: String = "mem_001"
@export var lore_key: String = "lore_001"

var collected: bool = false
var _state_active: bool = true
var _visual: Node3D
var _pickup_area: Area3D
var _pickup_shape: CollisionShape3D
var _interact_area: Area3D
var _interact_shape: CollisionShape3D
var _t: float = 0.0


func _ready() -> void:
	collected = SaveManager.is_secret_collected(secret_id)

	var ped := MeshInstance3D.new()
	var pcyl := CylinderMesh.new()
	pcyl.top_radius = 0.56
	pcyl.bottom_radius = 0.68
	pcyl.height = 0.14
	pcyl.radial_segments = 8
	ped.mesh = pcyl
	ped.position = Vector3(0.0, 0.07, 0.0)
	ped.material_override = LowPolyMeshLibrary.make_flat_material(Color(0.20, 0.24, 0.38), 0.78, Color(0.24, 0.82, 0.96), 0.40)
	add_child(ped)

	_visual = LowPolyMeshLibrary.create_crystal_cluster(Color(0.28, 0.86, 1.0))
	_visual.scale = Vector3(0.74, 0.74, 0.74)
	_visual.position = Vector3(0.0, 0.24, 0.0)
	add_child(_visual)

	var light := OmniLight3D.new()
	light.light_color = Color(0.30, 0.86, 1.0)
	light.light_energy = 1.4
	light.omni_range = 3.8
	light.position = Vector3(0.0, 0.75, 0.0)
	_visual.add_child(light)

	if collected:
		visible = false
		set_process(false)
		return

	_interact_area = Area3D.new()
	_interact_area.collision_layer = 8
	_interact_area.collision_mask = 0
	_interact_shape = CollisionShape3D.new()
	var isph := SphereShape3D.new()
	isph.radius = 2.2
	_interact_shape.shape = isph
	_interact_shape.position = Vector3(0.0, 0.7, 0.0)
	_interact_area.add_child(_interact_shape)
	add_child(_interact_area)

	_pickup_area = Area3D.new()
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = 2
	_pickup_shape = CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.65
	_pickup_shape.shape = sph
	_pickup_shape.position = Vector3(0.0, 0.7, 0.0)
	_pickup_area.add_child(_pickup_shape)
	_pickup_area.body_entered.connect(_on_player_entered)
	add_child(_pickup_area)
	_apply_effective_state()


func set_state_active(active: bool) -> void:
	_state_active = active
	_apply_effective_state()


func _apply_effective_state() -> void:
	var effective := _state_active and not collected
	visible = effective
	for a in [_pickup_area, _interact_area]:
		if a != null and is_instance_valid(a):
			a.set_deferred("monitoring", effective)
			a.set_deferred("monitorable", effective)
	if _interact_area != null and is_instance_valid(_interact_area):
		_interact_area.collision_layer = 8 if effective else 0
	if _pickup_area != null and is_instance_valid(_pickup_area):
		_pickup_area.collision_mask = 2 if effective else 0
	for sh in [_pickup_shape, _interact_shape]:
		if sh != null and is_instance_valid(sh):
			sh.set_deferred("disabled", not effective)


func can_interact(_player: Node) -> bool:
	return _state_active and not collected


func get_interact_icon_type() -> String:
	return "search"


func _process(delta: float) -> void:
	if collected or not _state_active or _visual == null:
		return
	_t += delta
	_visual.rotation.y += delta * 1.2
	_visual.position.y = 0.24 + sin(_t * 2.2) * 0.10


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
