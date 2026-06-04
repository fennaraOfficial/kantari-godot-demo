extends RigidBody3D

signal pickup_collected(pickup: Node, score_value: int, new_radius: float)
signal pickup_rejected(pickup: Node, required_size: float)
signal tier_unlocked(tier: int)

@export var move_force: float = 46.0
@export var max_speed: float = 8.5
@export var torque_strength: float = 10.5
@export var start_radius: float = 0.52
@export var growth_per_score: float = 0.012
@export var tier_sizes: Array[float] = [0.55, 0.82, 1.12, 1.48, 1.9]
@export var sticky_reach: float = 0.08

var current_radius: float = 0.52
var score: int = 0
var collected_count: int = 0
var current_tier: int = 0
var control_enabled: bool = true

@onready var visual: Node3D = $Visual
@onready var ball_mesh: MeshInstance3D = $Visual/YarnSphere
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var attachment_root: Node3D = $Visual/AttachedObjects
@onready var collect_particles: GPUParticles3D = $PickupSparkles

func _ready() -> void:
	current_radius = start_radius
	contact_monitor = true
	max_contacts_reported = 16
	body_entered.connect(_on_body_entered)
	_update_size(false)

func _physics_process(delta: float) -> void:
	if not control_enabled:
		linear_velocity = linear_velocity.move_toward(Vector3.ZERO, delta * 8.0)
		angular_velocity = angular_velocity.move_toward(Vector3.ZERO, delta * 8.0)
		return

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_vector.length() > 0.05:
		var camera: Camera3D = get_viewport().get_camera_3d()
		var forward: Vector3 = Vector3.FORWARD
		var right: Vector3 = Vector3.RIGHT
		if camera != null:
			forward = -camera.global_transform.basis.z
			right = camera.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		var direction: Vector3 = (right * input_vector.x + forward * -input_vector.y).normalized()
		if linear_velocity.length() < max_speed + current_radius:
			apply_central_force(direction * move_force * (1.0 + current_radius * 0.35))
		apply_torque(Vector3(direction.z, 0.0, -direction.x) * torque_strength * current_radius)

	_scan_sticky_pickups()

	if global_position.y < -4.0:
		global_position = Vector3(0.0, 1.2, 0.0)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func _scan_sticky_pickups() -> void:
	for pickup: Node in get_tree().get_nodes_in_group("collectibles"):
		if pickup == null or not pickup is Node3D:
			continue
		if not pickup.has_method("get_required_size"):
			continue
		var required_size: float = float(pickup.call("get_required_size"))
		var pickup_position: Vector3 = (pickup as Node3D).global_position
		var reach: float = current_radius + maxf(0.12, required_size * 0.25) + sticky_reach
		if global_position.distance_to(pickup_position) <= reach:
			try_collect(pickup)

func can_collect(required_size: float) -> bool:
	return current_radius + 0.025 >= required_size

func try_collect(pickup: Node) -> void:
	if pickup.get("collected") == true:
		return
	if not pickup.has_method("get_required_size") or not pickup.has_method("pick_up"):
		return
	var required_size: float = pickup.call("get_required_size")
	if not can_collect(required_size):
		pickup_rejected.emit(pickup, required_size)
		return

	var value: int = int(pickup.call("get_score_value"))
	var attach_position: Vector3 = to_local((pickup as Node3D).global_position)
	pickup.call("pick_up", attachment_root, attach_position, current_radius)
	score += value
	collected_count += 1
	current_radius = start_radius + sqrt(float(score)) * growth_per_score
	_update_size(true)
	_check_tier_unlock()
	collect_particles.global_position = (pickup as Node3D).global_position
	collect_particles.restart()
	pickup_collected.emit(pickup, value, current_radius)

func _on_body_entered(body: Node) -> void:
	try_collect(body)

func _update_size(animated: bool) -> void:
	var diameter: float = current_radius * 2.0
	var sphere_shape: SphereShape3D = collision_shape.shape as SphereShape3D
	if sphere_shape != null:
		sphere_shape.radius = current_radius
	visual.scale = Vector3.ONE * diameter
	mass = maxf(1.0, current_radius * 4.0)
	if animated:
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		visual.scale = Vector3.ONE * diameter * 1.16
		tween.tween_property(visual, "scale", Vector3.ONE * diameter, 0.24)

func _check_tier_unlock() -> void:
	var unlocked: int = current_tier
	for index: int in range(tier_sizes.size()):
		if current_radius >= tier_sizes[index]:
			unlocked = index
	if unlocked > current_tier:
		current_tier = unlocked
		tier_unlocked.emit(current_tier)
