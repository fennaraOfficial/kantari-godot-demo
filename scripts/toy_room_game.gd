extends Node3D

@export var time_limit: float = 120.0
@export var win_score: int = 950
@export var win_size: float = 1.85

var time_left: float = 0.0
var finished: bool = false
var camera_shake: float = 0.0
var last_score: int = 0
var starting_collectibles: int = 0

@onready var player: RigidBody3D = $PlayerYarnBall
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/FollowCamera
@onready var hud: Control = $HUD
@onready var score_label: Label = $HUD/TopBar/MetricRow/ScoreLabel
@onready var size_label: Label = $HUD/TopBar/MetricRow/SizeLabel
@onready var timer_label: Label = $HUD/TopBar/MetricRow/TimerLabel
@onready var tier_label: Label = $HUD/TierToast
@onready var objective_bar: ProgressBar = $HUD/ObjectivePanel/ObjectiveStack/ObjectiveBar
@onready var objective_label: Label = $HUD/ObjectivePanel/ObjectiveStack/ObjectiveLabel
@onready var center_message: Label = $HUD/CenterMessage
@onready var floating_layer: Control = $HUD/FloatingTextLayer
@onready var pickup_audio: AudioStreamPlayer = $PickupAudio
@onready var unlock_audio: AudioStreamPlayer = $UnlockAudio

func _ready() -> void:
	time_left = 0.0
	starting_collectibles = get_tree().get_nodes_in_group("collectibles").size()
	player.pickup_collected.connect(_on_pickup_collected)
	player.pickup_rejected.connect(_on_pickup_rejected)
	player.tier_unlocked.connect(_on_tier_unlocked)
	_setup_audio()
	_update_hud()
	center_message.text = "Roll up tiny treasures"
	var tween: Tween = create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(center_message, "modulate:a", 0.0, 0.45)

func _physics_process(delta: float) -> void:
	if finished:
		return
	time_left += delta
	_update_collectible_hints()
	_update_camera(delta)
	_update_hud()

func _update_camera(delta: float) -> void:
	var target: Vector3 = player.global_position
	var calm_target: Vector3 = Vector3(target.x, maxf(0.0, target.y - 0.35), target.z)
	camera_pivot.global_position = camera_pivot.global_position.lerp(calm_target, 1.0 - exp(-delta * 1.65))
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, 0.0, 1.0 - exp(-delta * 0.9))
	var desired_distance: float = 13.5 + player.current_radius * 2.2
	var desired_height: float = 9.0 + player.current_radius * 1.15
	camera.position = camera.position.lerp(Vector3(0.0, desired_height, desired_distance), 1.0 - exp(-delta * 1.35))
	camera.look_at_from_position(camera.global_position, player.global_position + Vector3.UP * (0.65 + player.current_radius * 0.7), Vector3.UP)
	if camera_shake > 0.01:
		camera.h_offset = randf_range(-camera_shake, camera_shake)
		camera.v_offset = randf_range(-camera_shake, camera_shake)
		camera_shake = move_toward(camera_shake, 0.0, delta * 1.6)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

func _update_collectible_hints() -> void:
	for pickup: Node in get_tree().get_nodes_in_group("collectibles"):
		if pickup.has_method("show_available") and pickup.has_method("get_required_size"):
			pickup.call("show_available", player.can_collect(float(pickup.call("get_required_size"))))

func _update_hud() -> void:
	score_label.text = "Score  %d" % player.score
	size_label.text = "Yarn  %.2fm" % player.current_radius
	timer_label.text = "Time  %02d:%02d" % [int(time_left) / 60.0, int(time_left) % 60]
	objective_bar.max_value = maxf(1.0, float(starting_collectibles))
	objective_bar.value = float(player.collected_count)
	objective_label.text = "Collect everything  %d/%d" % [player.collected_count, starting_collectibles]

func _on_pickup_collected(pickup: Node, score_value: int, _new_radius: float) -> void:
	last_score = player.score
	camera_shake = maxf(camera_shake, minf(0.18, float(score_value) * 0.004))
	_spawn_floating_text("+%d" % score_value, pickup as Node3D)
	_play_pickup_sound(score_value)

func _on_pickup_rejected(pickup: Node, required_size: float) -> void:
	center_message.modulate.a = 1.0
	center_message.text = "Grow to %.2fm for %s" % [required_size, String(pickup.get("display_name"))]
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(center_message, "modulate:a", 0.0, 0.28)

func _on_tier_unlocked(tier: int) -> void:
	var names: Array[String] = ["buttons", "blocks", "books", "plushies", "furniture"]
	var label_text: String = "New tier unlocked!"
	if tier >= 0 and tier < names.size():
		label_text = "Now sticky enough for %s" % names[tier]
	tier_label.text = label_text
	tier_label.modulate.a = 1.0
	camera_shake = maxf(camera_shake, 0.14)
	unlock_audio.pitch_scale = 1.0 + float(tier) * 0.12
	unlock_audio.play()
	var tween: Tween = create_tween()
	tween.tween_property(tier_label, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.25)
	tween.tween_property(tier_label, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(tier_label, "scale", Vector2.ONE, 0.4)

func _spawn_floating_text(text_value: String, world_node: Node3D) -> void:
	var label: Label = Label.new()
	label.name = "FloatingScore"
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.52, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.18, 0.08, 0.22, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	floating_layer.add_child(label)
	var screen_position: Vector2 = camera.unproject_position(world_node.global_position + Vector3.UP * 0.8)
	label.position = screen_position - Vector2(40.0, 20.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0.0, -48.0), 0.75)
	tween.tween_property(label, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(label.queue_free)

func _finish_game(won: bool) -> void:
	finished = true
	player.set("control_enabled", false)
	center_message.modulate.a = 1.0
	center_message.text = "Room wrapped in magic!" if won else "Time is up - try a faster roll!"
	center_message.add_theme_font_size_override("font_size", 38)

func _setup_audio() -> void:
	var pickup_stream: AudioStreamGenerator = AudioStreamGenerator.new()
	pickup_stream.mix_rate = 22050.0
	pickup_stream.buffer_length = 0.08
	pickup_audio.stream = pickup_stream
	pickup_audio.max_polyphony = 8
	var unlock_stream: AudioStreamGenerator = AudioStreamGenerator.new()
	unlock_stream.mix_rate = 22050.0
	unlock_stream.buffer_length = 0.18
	unlock_audio.stream = unlock_stream

func _play_pickup_sound(score_value: int) -> void:
	pickup_audio.pitch_scale = 1.0 + minf(0.8, float(score_value) / 120.0)
	pickup_audio.play()
