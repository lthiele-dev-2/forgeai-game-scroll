class_name EnemyWeapon
extends Node2D

signal bullet_fired(muzzle_pos: Vector2)

const MAX_POOLED_BULLETS: int = 64

@export var bullet_scene: PackedScene = null
@export var base_damage: float = 8.0
@export var pool_size: int = MAX_POOLED_BULLETS

var fire_rate: float = 1.0
var pool: ObjectPool = null
var projectiles_container: Node2D = null
var level_bounds: Rect2 = Rect2()

var _fire_timer: float = 0.0
var _muzzle: Marker2D = null
var _active_bullets: Array[Node] = []


func _ready() -> void:
	_muzzle = get_node_or_null("Muzzle") as Marker2D
	_build_pool()


func set_fire_rate(value: float) -> void:
	fire_rate = maxf(value, 0.0001)


func set_bullet_scene(scene: PackedScene) -> void:
	bullet_scene = scene
	_build_pool()


func set_projectiles_container(container: Node2D) -> void:
	projectiles_container = container


func set_level_bounds(rect: Rect2) -> void:
	level_bounds = rect


func get_muzzle() -> Marker2D:
	return _muzzle


func reset_fire_timer() -> void:
	_fire_timer = 0.0


func get_active_bullet_count() -> int:
	_prune_active()
	return _active_bullets.size()


func hold_fire(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer += 1.0 / fire_rate
		_fire()


func _fire() -> void:
	if bullet_scene == null or pool == null or _muzzle == null:
		return
	_prune_active()
	if _active_bullets.size() >= pool_size:
		var oldest: Node = _active_bullets.pop_front()
		if is_instance_valid(oldest) and oldest.has_method("release"):
			oldest.call("release")
	var bullet: Node = pool.acquire()
	if bullet == null:
		return
	var parent: Node = projectiles_container
	if parent == null or not is_instance_valid(parent):
		parent = get_parent()
	if parent == null:
		parent = self
	parent.add_child(bullet)
	if bullet.has_method("fire"):
		bullet.call("fire", _muzzle.global_position, Vector2.LEFT, base_damage, pool, level_bounds)
	_active_bullets.append(bullet)
	bullet_fired.emit(_muzzle.global_position)


func _build_pool() -> void:
	if bullet_scene == null:
		return
	if pool == null:
		pool = ObjectPool.new()
		pool.name = "BulletPool"
		pool.initial_size = 0
		add_child(pool)
	pool.packed_scene = bullet_scene


func _prune_active() -> void:
	for i in range(_active_bullets.size() - 1, -1, -1):
		var bullet: Node = _active_bullets[i]
		if bullet == null or not is_instance_valid(bullet):
			_active_bullets.remove_at(i)
			continue
		var active: Variant = bullet.get("is_active")
		if active != null and not bool(active):
			_active_bullets.remove_at(i)
