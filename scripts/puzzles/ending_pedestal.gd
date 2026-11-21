class_name EndingPedestal
extends Node3D

## Final Stage 30 choice altar triggering Ending A (Stop), Ending B (Restart), or Secret Ending (Liberation).

signal ending_selected(ending_id: String)

@export var ending_id: String = "ending_stop"
@export var accent_color: Color = Color(1.0, 0.78, 0.32)
@export var emblem: String = "✦"
@export var requires_secret_unlock: bool = false

var unlocked: bool = true


func _ready() -> void:
	unlocked = (not requires_secret_unlock) or GameState.is_secret_ending_unlocked()

	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.68
	cyl.height = 1.15
	cyl.radial_segments = 6
	pillar.mesh = cyl
	pillar.position = Vector3(0.0, 0.57, 0.0)
	pillar.material_override = LowPolyMeshLibrary.make_flat_material(
		Color(0.22, 0.20, 0.34), 0.75, accent_color if unlocked else Color.BLACK, 0.55 if unlocked else 0.0
	)
	add_child(pillar)

	var orb := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.32
	sph.height = 0.64
	sph.radial_segments = 8
	sph.rings = 4
	orb.mesh = sph
	orb.position = Vector3(0.0, 1.62, 0.0)
	var orb_col := accent_color if unlocked else Color(0.28, 0.28, 0.34)
	orb.material_override = LowPolyMeshLibrary.make_flat_material(orb_col, 0.2, orb_col, 2.2 if unlocked else 0.15)
	add_child(orb)

	var lbl := Label3D.new()
	lbl.text = emblem if unlocked else "🔒"
	lbl.font_size = 64
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 2.28, 0.0)
	lbl.modulate = Color(1.0, 0.97, 0.90)
	add_child(lbl)

	if unlocked:
		var light := OmniLight3D.new()
		light.light_color = accent_color
		light.light_energy = 1.8
		light.omni_range = 4.8
		light.position = Vector3(0.0, 1.62, 0.0)
		add_child(light)

	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 1.45
	shape.shape = s
	shape.position = Vector3(0.0, 0.8, 0.0)
	area.add_child(shape)
	add_child(area)


func get_prompt_key() -> String:
	if not unlocked:
		return "prompt_secret_ending_locked"
	return "prompt_choose_" + ending_id


func interact(_player: Node) -> void:
	if not unlocked:
		AudioManager.play_sfx("door_locked")
		return
	AudioManager.play_sfx("stage_complete")
	ending_selected.emit(ending_id)
