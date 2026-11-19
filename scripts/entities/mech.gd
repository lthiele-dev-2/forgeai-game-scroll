class_name Mech
extends CharacterBody2D

@export var max_speed: float = 420.0
@export var acceleration: float = 1400.0
@export var deceleration: float = 650.0
@export var gravity: float = 2400.0
@export var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))
@export var camera_smoothing_speed: float = 8.0
@export var camera_zoom: float = 1.0

@onready var camera: Camera2D = $Camera2D

var level_midline_y: float = 540.0


func _ready() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_smoothing_speed
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	set_bounds(bounds)


func set_bounds(rect: Rect2) -> void:
	bounds = rect
	level_midline_y = rect.get_center().y
	if camera == null:
		return
	camera.limit_left = rect.position.x
	camera.limit_right = rect.end.x
	camera.limit_top = rect.position.y
	camera.limit_bottom = rect.end.y


func _physics_process(delta: float) -> void:
	var input_x: float = Input.get_axis("move_left", "move_right")
	var input_y: float = Input.get_axis("move_up", "move_down")

	var rate_x: float = acceleration if input_x != 0.0 else deceleration
	var rate_y: float = acceleration if input_y != 0.0 else deceleration
	velocity.x = move_toward(velocity.x, input_x * max_speed, rate_x * delta)
	velocity.y = move_toward(velocity.y, input_y * max_speed, rate_y * delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.y = clampf(position.y, bounds.position.y, bounds.end.y)

	camera.global_position.y = level_midline_y
