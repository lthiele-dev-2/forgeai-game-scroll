class_name Weapon
extends Node2D

signal shot_fired(muzzle_pos: Vector2)
signal charge_changed(level: float)
signal charge_fired(level: float)

const PLAYER_SHOT_SCENE: PackedScene = preload("res://scenes/entities/projectiles/player_shot.tscn")
const CHARGE_BLAST_SCENE: PackedScene = preload("res://scenes/entities/projectiles/charge_blast.tscn")
const MAX_POOLED_SHOTS: int = 64

@export var base_damage: float = 10.0
@export var fire_rate: float = 8.0
@export var pool_size: int = MAX_POOLED_SHOTS
@export var projectile_scene: PackedScene = PLAYER_SHOT_SCENE
@export var full_charge_time: float = 1.5
@export var base_blast_damage: float = 60.0
@export var base_cooldown: float = 3.0
@export var min_charge_level: float = 0.25

@onready var muzzle: Marker2D = $Muzzle

var pool: ObjectPool
var projectiles_container: Node2D = null
var level_bounds: Rect2 = Rect2()

var hold_time: float = 0.0
var charge_level: float = 0.0
var charging: bool = false
var cooldown_timer: float = 0.0

var _cooldown: float = 0.0
var _active_shots: Array[PlayerShot] = []
var _charge_blast: ChargeBlast = null


static func compute_charge_level(hold_time: float, full_charge_time: float) -> float:
	if full_charge_time <= 0.0:
		return 1.0
	return clampf(hold_time / full_charge_time, 0.0, 1.0)


static func compute_blast_damage(base_blast: float, level: float) -> float:
	return base_blast * (0.5 + 0.5 * level)


static func compute_cooldown(base_cooldown: float, level: float) -> float:
	return base_cooldown * (1.0 - 0.5 * level)


func _ready() -> void:
	pool = ObjectPool.new()
	pool.name = "ShotPool"
	pool.packed_scene = projectile_scene
	pool.initial_size = 0
	add_child(pool)
	_charge_blast = CHARGE_BLAST_SCENE.instantiate() as ChargeBlast
	if _charge_blast != null:
		_charge_blast.name = "ChargeBlast"
		_charge_blast.top_level = true
		add_child(_charge_blast)


func set_projectiles_container(container: Node2D) -> void:
	projectiles_container = container


func set_level_bounds(rect: Rect2) -> void:
	level_bounds = rect


func hold_fire(delta: float) -> void:
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown += 1.0 / fire_rate
		_fire()
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		return
	hold_time += delta
	charging = true
	charge_level = compute_charge_level(hold_time, full_charge_time)
	charge_changed.emit(charge_level)


func release_fire() -> void:
	_cooldown = 0.0
	if not charging:
		return
	charging = false
	var level: float = charge_level
	if level >= min_charge_level:
		_fire_charge_blast(level)
		cooldown_timer = compute_cooldown(base_cooldown, level)
		charge_fired.emit(level)
	else:
		_fire()
	hold_time = 0.0
	charge_level = 0.0
	charge_changed.emit(0.0)


func get_active_shot_count() -> int:
	_prune_active()
	return _active_shots.size()


func get_charge_blast() -> ChargeBlast:
	return _charge_blast


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


func _fire_charge_blast(level: float) -> void:
	if _charge_blast == null or not is_instance_valid(_charge_blast):
		return
	if _charge_blast.is_active:
		return
	var dmg: float = compute_blast_damage(base_blast_damage, level)
	_charge_blast.fire(muzzle.global_position, dmg, level_bounds)


func _prune_active() -> void:
	for i in range(_active_shots.size() - 1, -1, -1):
		var shot: PlayerShot = _active_shots[i]
		if shot == null or not is_instance_valid(shot) or not shot.is_active:
			_active_shots.remove_at(i)
