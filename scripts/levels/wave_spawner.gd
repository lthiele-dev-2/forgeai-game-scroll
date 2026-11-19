class_name WaveSpawner
extends Node2D

const MAX_ALIVE_ENEMIES: int = 24
const WAVE_RESOURCE_FORMAT: String = "res://resources/waves/wave_%02d.tres"

@export var enemy_stats: EnemyStats
@export var entities_path: NodePath = ^"../Entities"
@export var projectiles_path: NodePath = ^"../Projectiles"
@export var max_alive: int = MAX_ALIVE_ENEMIES

var scene_overrides: Dictionary = {}

var _pools: Dictionary = {}
var _alive: Array[Node] = []
var _spawn_queue: Array[Dictionary] = []
var _spawn_timer: float = 0.0
var _current_interval: float = 0.0
var _current_wave: int = 0
var _wave_active: bool = false
var _cleared_emitted: bool = true
var _cleared_waves: Dictionary = {}
var _bounds: Rect2 = Rect2()
var _marker_index: int = 0


static func wave_multiplier(n: int) -> float:
	return 1.0 + 0.25 * float(n - 1)


func _ready() -> void:
	Events.enemy_destroyed.connect(_on_enemy_destroyed)


func _exit_tree() -> void:
	if Events.enemy_destroyed.is_connected(_on_enemy_destroyed):
		Events.enemy_destroyed.disconnect(_on_enemy_destroyed)


func set_bounds(rect: Rect2) -> void:
	_bounds = rect


func spawn_wave(n: int) -> bool:
	if n < 1:
		return false
	if _wave_active or _cleared_waves.get(n, false):
		return false
	var path: String = WAVE_RESOURCE_FORMAT % n
	if not ResourceLoader.exists(path):
		push_warning("WaveSpawner: wave resource missing: %s" % path)
		return false
	var wave: WaveData = load(path) as WaveData
	if wave == null:
		push_warning("WaveSpawner: wave resource missing or invalid: %s" % path)
		return false
	return start_wave(wave)


func start_wave(wave: WaveData) -> bool:
	if wave == null or _wave_active:
		return false
	if _cleared_waves.get(wave.wave_number, false):
		return false
	_prune_alive()
	_current_wave = wave.wave_number
	_wave_active = true
	_cleared_emitted = false
	_current_interval = wave.spawn_interval
	_spawn_timer = 0.0
	_spawn_queue.clear()
	var mult: float = wave_multiplier(wave.wave_number)
	var per_type: Array[Array] = []
	for enemy_type in wave.get_enemy_types():
		var base_count: int = wave.get_count(enemy_type)
		var scaled_count: int = int(round(base_count * mult)) if base_count > 0 else 0
		var hp: float = float(_base_hp(enemy_type)) * wave.hp_multiplier * mult
		var fire_rate: float = _base_fire_rate(enemy_type) * wave.fire_rate_multiplier * mult
		var score: int = wave.get_score_value(enemy_type)
		if score <= 0 and enemy_stats != null:
			score = enemy_stats.get_base_score(enemy_type)
		var jobs: Array = []
		for i in range(scaled_count):
			jobs.append({"type": enemy_type, "hp": hp, "fire_rate": fire_rate, "score": score})
		per_type.append(jobs)
	var progressed: bool = true
	while progressed:
		progressed = false
		for jobs in per_type:
			if not jobs.is_empty():
				_spawn_queue.append(jobs.pop_front())
				progressed = true
	Events.wave_started.emit(_current_wave)
	return true


func _physics_process(delta: float) -> void:
	_prune_alive()
	_check_wave_cleared()
	if _spawn_queue.is_empty():
		return
	if _alive.size() >= max_alive:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _current_interval
		_spawn_one()


func get_spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child: Node in get_children():
		if child is Marker2D:
			markers.append(child)
	return markers


func get_current_wave() -> int:
	return _current_wave


func is_wave_active() -> bool:
	return _wave_active


func is_wave_cleared(n: int) -> bool:
	return bool(_cleared_waves.get(n, false))


func get_alive_count() -> int:
	return _alive.size()


func get_alive_enemies() -> Array[Node]:
	return _alive.duplicate()


func get_pending_count() -> int:
	return _spawn_queue.size()


func get_pool(enemy_type: String) -> ObjectPool:
	return _pools.get(enemy_type, null)


func _spawn_one() -> void:
	if _spawn_queue.is_empty() or _alive.size() >= max_alive:
		return
	var job: Dictionary = _spawn_queue.pop_front()
	var enemy_type: String = str(job["type"])
	var pool: ObjectPool = _get_pool(enemy_type)
	if pool == null:
		push_warning("WaveSpawner: no scene for enemy type '%s', spawn skipped" % enemy_type)
		return
	var enemy: Node = pool.acquire()
	if enemy == null:
		return
	var parent: Node = get_node_or_null(entities_path)
	if parent == null:
		parent = get_parent()
	if parent == null:
		parent = self
	parent.add_child(enemy)
	var marker: Marker2D = _next_marker()
	var pos: Vector2 = marker.global_position if marker != null else global_position
	if _bounds.has_area():
		pos = Vector2(
			clampf(pos.x, _bounds.position.x, _bounds.end.x),
			clampf(pos.y, _bounds.position.y, _bounds.end.y)
		)
	enemy.global_position = pos
	if enemy.has_method("setup_wave"):
		enemy.setup_wave(enemy_type, float(job["hp"]), float(job["fire_rate"]), int(job["score"]))
	if enemy is Enemy:
		enemy.pool = pool
	var weapon: Node = enemy.get_node_or_null("Weapon")
	if weapon != null and weapon.has_method("set_projectiles_container"):
		var projectiles: Node = get_node_or_null(projectiles_path)
		if projectiles != null:
			weapon.call("set_projectiles_container", projectiles)
		if _bounds.has_area():
			weapon.call("set_level_bounds", _bounds)
	_alive.append(enemy)
	Events.enemy_spawned.emit(enemy_type)


func _get_pool(enemy_type: String) -> ObjectPool:
	if _pools.has(enemy_type):
		return _pools[enemy_type]
	var scene: PackedScene = scene_overrides.get(enemy_type, null)
	if scene == null and enemy_stats != null:
		var path: String = enemy_stats.get_scene_path(enemy_type)
		if path != "":
			scene = load(path)
	if scene == null:
		return null
	var pool := ObjectPool.new()
	pool.name = "Pool_%s" % enemy_type
	pool.packed_scene = scene
	add_child(pool)
	_pools[enemy_type] = pool
	return pool


func _next_marker() -> Marker2D:
	var markers: Array[Marker2D] = get_spawn_markers()
	if markers.is_empty():
		return null
	var marker: Marker2D = markers[_marker_index % markers.size()]
	_marker_index += 1
	return marker


func _base_hp(enemy_type: String) -> int:
	return enemy_stats.get_base_hp(enemy_type) if enemy_stats != null else 0


func _base_fire_rate(enemy_type: String) -> float:
	return enemy_stats.get_base_fire_rate(enemy_type) if enemy_stats != null else 1.0


func _on_enemy_destroyed(enemy_type: String, pos: Vector2, score_value: int) -> void:
	_prune_alive()
	if not _alive.is_empty():
		_alive.pop_back()
	_check_wave_cleared()


func _prune_alive() -> void:
	for i in range(_alive.size() - 1, -1, -1):
		if not is_instance_valid(_alive[i]):
			_alive.remove_at(i)


func _check_wave_cleared() -> void:
	if not _wave_active or _cleared_emitted:
		return
	if not _spawn_queue.is_empty() or not _alive.is_empty():
		return
	_cleared_emitted = true
	_wave_active = false
	_cleared_waves[_current_wave] = true
	Events.wave_cleared.emit(_current_wave)
