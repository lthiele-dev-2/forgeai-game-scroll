class_name Drone
extends Enemy

const ENEMY_BULLET_SCENE_PATH: String = "res://scenes/entities/projectiles/enemy_bullet.tscn"

@export var move_speed: float = 240.0
@export var deceleration: float = 900.0
@export var attack_range: float = 420.0
@export var player_group: String = "player"

var target: Node2D = null

var _weapon: EnemyWeapon = null


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
	var in_range: bool = player != null
	if player != null:
		var dx: float = player.global_position.x - global_position.x
		if absf(dx) > attack_range:
			velocity.x = signf(dx) * move_speed
			in_range = false
		else:
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.y = 0.0
	move_and_slide()
	if in_range and _weapon != null:
		_weapon.hold_fire(delta)


func _resolve_player() -> Node2D:
	if target != null and is_instance_valid(target):
		return target
	if get_tree() != null:
		return get_tree().get_first_node_in_group(player_group) as Node2D
	return null
