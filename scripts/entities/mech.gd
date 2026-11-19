class_name Mech
extends CharacterBody2D

@export var max_speed: float = 420.0
@export var acceleration: float = 1400.0
@export var deceleration: float = 650.0
@export var gravity: float = 2400.0
@export var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))
@export var camera_smoothing_speed: float = 8.0
@export var camera_zoom: float = 1.0
@export var max_hull: int = 100

@onready var camera: Camera2D = $Camera2D
@onready var weapon: Weapon = $Weapon
@onready var charge_glow: Sprite2D = $Visual/ChargeGlow
@onready var hitbox: Area2D = $Hitbox

var level_midline_y: float = 540.0
var hull: int = 0
var is_alive: bool = true


func _ready() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_smoothing_speed
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	weapon.shot_fired.connect(_on_weapon_shot_fired)
	weapon.charge_changed.connect(_on_weapon_charge_changed)
	weapon.charge_fired.connect(_on_weapon_charge_fired)
	if charge_glow != null:
		charge_glow.visible = false
	set_bounds(bounds)
	hull = max_hull
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	Events.hull_changed.emit(hull, max_hull)


func _exit_tree() -> void:
	if weapon != null:
		if weapon.shot_fired.is_connected(_on_weapon_shot_fired):
			weapon.shot_fired.disconnect(_on_weapon_shot_fired)
		if weapon.charge_changed.is_connected(_on_weapon_charge_changed):
			weapon.charge_changed.disconnect(_on_weapon_charge_changed)
		if weapon.charge_fired.is_connected(_on_weapon_charge_fired):
			weapon.charge_fired.disconnect(_on_weapon_charge_fired)
	if hitbox != null:
		if hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.disconnect(_on_hitbox_area_entered)
		if hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.disconnect(_on_hitbox_body_entered)


func set_bounds(rect: Rect2) -> void:
	bounds = rect
	level_midline_y = rect.get_center().y
	if weapon != null:
		weapon.set_level_bounds(rect)
	if camera == null:
		return
	camera.limit_left = rect.position.x
	camera.limit_right = rect.end.x
	camera.limit_top = rect.position.y
	camera.limit_bottom = rect.end.y


func take_damage(d: float) -> void:
	if not is_alive:
		return
	var amount: int = maxi(int(round(d)), 0)
	hull = maxi(hull - amount, 0)
	Events.hull_changed.emit(hull, max_hull)
	if hull <= 0:
		_die()


func _physics_process(delta: float) -> void:
	var input_x: float = 0.0
	var input_y: float = 0.0
	if is_alive:
		input_x = Input.get_axis("move_left", "move_right")
		input_y = Input.get_axis("move_up", "move_down")

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

	if is_alive and (Input.is_action_pressed("shoot") or Input.is_action_pressed("charge_shot")):
		weapon.hold_fire(delta)
	else:
		weapon.release_fire()


func set_projectiles_container(container: Node2D) -> void:
	weapon.set_projectiles_container(container)


func _on_weapon_shot_fired(muzzle_pos: Vector2) -> void:
	Events.shot_fired.emit(muzzle_pos)


func _on_weapon_charge_changed(level: float) -> void:
	if charge_glow != null:
		charge_glow.visible = level > 0.0
	Events.charge_changed.emit(level)


func _on_weapon_charge_fired(level: float) -> void:
	Events.charge_fired.emit(level)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not is_alive:
		return
	var base_damage: float = 0.0
	var mult_value: Variant = area.get("enemy_multiplier")
	var damage_value: Variant = area.get("damage")
	if damage_value != null:
		base_damage = float(damage_value)
	else:
		var owner: Node = area.get_parent()
		var contact_value: Variant = owner.get("contact_damage") if owner != null else null
		if contact_value == null:
			return
		base_damage = float(contact_value)
		if mult_value == null and owner != null:
			mult_value = owner.get("enemy_multiplier")
	var multiplier: float = 1.0 if mult_value == null else float(mult_value)
	_apply_hit(base_damage * multiplier, area.global_position)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not is_alive:
		return
	var contact_value: Variant = body.get("contact_damage")
	if contact_value == null:
		return
	var mult_value: Variant = body.get("enemy_multiplier")
	var multiplier: float = 1.0 if mult_value == null else float(mult_value)
	_apply_hit(float(contact_value) * multiplier, body.global_position)


func _apply_hit(damage: float, pos: Vector2) -> void:
	var damage_int: int = maxi(int(round(damage)), 0)
	take_damage(damage_int)
	Events.player_hit.emit(damage_int, pos)


func _die() -> void:
	if not is_alive:
		return
	is_alive = false
	Events.player_died.emit()
