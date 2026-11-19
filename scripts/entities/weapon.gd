class_name Weapon
extends Node2D

signal shot_fired(muzzle_pos: Vector2)

const PLAYER_SHOT_SCENE: PackedScene = preload("res://scenes/entities/projectiles/player_shot.tscn")
const MAX_POOLED_SHOTS: int = 64

@export var base_damage: float = 10.0
@export var fire_rate: float = 8.0
@export var pool_size: int = MAX_POOLED_SHOTS
@export var projectile_scene: PackedScene = PLAYER_SHOT_SCENE

@onready var muzzle: Marker2D = $Muzzle

var pool: ObjectPool
var projectiles_container: Node2D = null
var level_bounds: Rect2 = Rect2()

var _cooldown: float = 0.0
var _active_shots: Array[PlayerShot] = []


func _ready() -> void:
	pool = ObjectPool.new()
	pool.name = "ShotPool"
	pool.packed_scene = projectile_scene
	pool.initial_size = 0
	add_child(pool)


func set_projectiles_container(container: Node2D) -> void:
	projectiles_container = container


func set_level_bounds(rect: Rect2) -> void:
	level_bounds = rect


func hold_fire(delta: float) -> void:
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown += 1.0 / fire_rate
		_fire()


func release_fire() -> void:
	_cooldown = 0.0


func get_active_shot_count() -> int:
	_prune_active()
	return _active_shots.size()


func _fire() -> void:
	_prune_active()
	if _active_shots.size() >= pool_size:
		var oldest: PlayerShot = _active_shots.pop_front()
		oldest.release()
	var acquired: Node = pool.acquire()
	if acquired == null:
		return
	var shot: PlayerShot = acquired as PlayerShot
	if shot == null:
		pool.release(acquired)
		return
	var parent: Node = projectiles_container
	if parent == null or not is_instance_valid(parent):
		parent = get_parent()
	if parent == null:
		parent = self
	parent.add_child(shot)
	shot.fire(muzzle.global_position, Vector2.RIGHT, base_damage, pool, level_bounds)
	_active_shots.append(shot)
	shot_fired.emit(muzzle.global_position)


func _prune_active() -> void:
	for i in range(_active_shots.size() - 1, -1, -1):
		var shot: PlayerShot = _active_shots[i]
		if shot == null or not is_instance_valid(shot) or not shot.is_active:
			_active_shots.remove_at(i)
