class_name Gunship
extends Enemy

const ENEMY_BULLET_SCENE_PATH: String = "res://scenes/entities/projectiles/enemy_bullet.tscn"

@export var move_speed: float = 380.0
@export var deceleration: float = 1200.0
@export var attack_range: float = 620.0
@export var preferred_distance: float = 480.0
@export var strafe_speed: float = 160.0
@export var strafe_period: float = 2.0
@export var player_group: String = "player"

var target: Node2D = null

var _weapon: EnemyWeapon = null
var _strafe_direction: float = 1.0
var _strafe_timer: float = 0.0


func _ready() -> void:
	super._ready()
	_weapon = get_node_or_null("Weapon") as EnemyWeapon
	if _weapon != null:
		if _weapon.bullet_scene == null and ResourceLoader.exists(ENEMY_BULLET_SCENE_PATH):
			_weapon.set_bullet_scene(load(ENEMY_BULLET_SCENE_PATH) as PackedScene)
		_weapon.set_fire_rate(fire_rate)


func setup_wave(type: String, hp_value: float, fire_rate_value: float, score: int) -> void:
	super.setup_wave(type, hp_value, fire_rate_value, score)
	if _weapon != null:
		_weapon.set_fire_rate(fire_rate)


func set_target(node: Node2D) -> void:
	target = node


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	var player: Node2D = _resolve_player()
	var dx: float = 0.0
	velocity.y = move_toward(velocity.y, 0.0, deceleration * delta)
	if player != null:
		dx = player.global_position.x - global_position.x
		if absf(dx) > attack_range:
			velocity.x = signf(dx) * move_speed
		elif absf(dx) > preferred_distance:
			velocity.x = signf(dx) * move_speed * 0.5
		else:
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
			_strafe_timer -= delta
			if _strafe_timer <= 0.0:
				_strafe_timer = strafe_period
				_strafe_direction = -_strafe_direction
			velocity.y = _strafe_direction * strafe_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	move_and_slide()
	if player != null and absf(dx) <= preferred_distance and _weapon != null:
		_weapon.hold_fire(delta)


func _resolve_player() -> Node2D:
	if target != null and is_instance_valid(target):
		return target
	if get_tree() != null:
		return get_tree().get_first_node_in_group(player_group) as Node2D
	return null
