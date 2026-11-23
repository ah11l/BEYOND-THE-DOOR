class_name KeyPickup
extends Node3D

## Glowing golden key relic on a luminous stone pedestal (matching 254211.png):
## - Outer radius (2.1m) shows the floating circular Hand interaction button
## - Inner touch radius (0.65m) or tapping the circular Hand button collects it cleanly
## - Strictly respects room_state visibility AND collision/monitoring

signal key_collected(key_id: String)

@export var key_id: String = "key_1"
var collected: bool = false
var _state_active: bool = true
var _visual: Node3D
var _pickup_area: Area3D
var _pickup_shape: CollisionShape3D
var _interact_area: Area3D
var _interact_shape: CollisionShape3D
var _t: float = 0.0


func _ready() -> void:
	# Luminous stone pedestal base (matches 254211.png)
	var ped := MeshInstance3D.new()
	var pcyl := CylinderMesh.new()
	pcyl.top_radius = 0.52
	pcyl.bottom_radius = 0.64
	pcyl.height = 0.14
	pcyl.radial_segments = 8
	ped.mesh = pcyl
	ped.position = Vector3(0.0, 0.07, 0.0)
	ped.material_override = LowPolyMeshLibrary.make_flat_material(Color(0.24, 0.28, 0.42), 0.78, Color(0.24, 0.78, 0.96), 0.35)
	add_child(ped)

	_visual = Node3D.new()
	add_child(_visual)

	var mat := LowPolyMeshLibrary.make_flat_material(Color(1.0, 0.84, 0.32), 0.2, Color(1.0, 0.78, 0.25), 2.1)
	var head := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.24
	torus.rings = 14
	torus.ring_segments = 6
	head.mesh = torus
	head.position = Vector3(0.0, 1.05, 0.0)
	head.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	head.material_override = mat
	_visual.add_child(head)

	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.09, 0.48, 0.09)
	shaft.mesh = box
	shaft.position = Vector3(0.0, 0.64, 0.0)
	shaft.material_override = mat
	_visual.add_child(shaft)

	var tooth := MeshInstance3D.new()
	var tbox := BoxMesh.new()
	tbox.size = Vector3(0.20, 0.08, 0.08)
	tooth.mesh = tbox
	tooth.position = Vector3(0.11, 0.48, 0.0)
	tooth.material_override = mat
	_visual.add_child(tooth)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.82, 0.35)
	light.light_energy = 1.4
	light.omni_range = 3.8
	light.position = Vector3(0.0, 0.85, 0.0)
	_visual.add_child(light)

	# Outer contextual Hand button detection zone (Layer 8)
	_interact_area = Area3D.new()
	_interact_area.collision_layer = 8
	_interact_area.collision_mask = 0
	_interact_shape = CollisionShape3D.new()
	var isph := SphereShape3D.new()
	isph.radius = 2.1
	_interact_shape.shape = isph
	_interact_shape.position = Vector3(0.0, 0.7, 0.0)
	_interact_area.add_child(_interact_shape)
	add_child(_interact_area)

	# Inner direct-touch auto-pickup zone (tight 0.65m so player sees the circular Hand button first!)
	_pickup_area = Area3D.new()
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = 2
	_pickup_shape = CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.65
	_pickup_shape.shape = sph
	_pickup_shape.position = Vector3(0.0, 0.65, 0.0)
	_pickup_area.add_child(_pickup_shape)
	_pickup_area.body_entered.connect(_on_player_touched)
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
	return "hand"


func _process(delta: float) -> void:
	if collected or not _state_active or _visual == null:
		return
	_t += delta
	_visual.rotation.y += delta * 1.6
	_visual.position.y = sin(_t * 2.4) * 0.11


func _on_player_touched(_body: Node) -> void:
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
	AudioManager.play_sfx("key_pickup")
	key_collected.emit(key_id)
