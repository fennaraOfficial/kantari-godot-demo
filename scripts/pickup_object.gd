extends StaticBody3D

@export var required_size: float = 0.5
@export var score_value: int = 10
@export var tier: int = 0
@export var display_name: String = "Toy"
@export var highlight_color: Color = Color(1.0, 0.9, 0.35, 1.0)

var collected: bool = false
var base_scale: Vector3 = Vector3.ONE
var base_y: float = 0.0
var pulse_seed: float = 0.0
var highlight_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("collectibles")
	base_scale = scale
	base_y = position.y
	pulse_seed = float(abs(hash(name)) % 1000) * 0.01
	highlight_meshes.clear()
	_collect_meshes(self)
	for mesh: MeshInstance3D in highlight_meshes:
		mesh.set_instance_shader_parameter("rim_color", highlight_color)

func _process(delta: float) -> void:
	if collected:
		rotation.y += delta * 0.8
		return
	var time_value: float = Time.get_ticks_msec() * 0.001 + pulse_seed
	position.y = base_y + sin(time_value * 1.6) * 0.025
	var pulse: float = 1.0 + sin(time_value * 2.5) * 0.025
	scale = base_scale * pulse

func get_required_size() -> float:
	return required_size

func get_score_value() -> int:
	return score_value

func pick_up(parent_node: Node3D, local_attach_position: Vector3, ball_radius: float) -> void:
	if collected:
		return
	collected = true
	remove_from_group("collectibles")
	collision_layer = 0
	collision_mask = 0
	for child: Node in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true
	var old_global: Transform3D = global_transform
	get_parent().remove_child(self)
	parent_node.add_child(self)
	owner = parent_node.owner
	global_transform = old_global
	var target: Vector3 = local_attach_position.normalized() * maxf(0.18, ball_radius * 0.74)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale * 0.82, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_available(can_collect: bool) -> void:
	if collected:
		return
	var target_scale: Vector3 = base_scale * (1.08 if can_collect else 1.0)
	scale = scale.lerp(target_scale, 0.12)

func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		highlight_meshes.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child)
