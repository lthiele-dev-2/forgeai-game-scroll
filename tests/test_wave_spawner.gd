extends GutTest

class StubEnemy:
	extends Node2D

	var enemy_type: String = ""
	var hp: float = 0.0
	var fire_rate: float = 0.0
	var score_value: int = 0

	func setup_wave(type: String, hp_value: float, fire_rate_value: float, score: int) -> void:
		enemy_type = type
		hp = hp_value
		fire_rate = fire_rate_value
		score_value = score


var spawner: WaveSpawner
var stub_scene: PackedScene


func before_each() -> void:
	stub_scene = PackedScene.new()
	var template: Node2D = StubEnemy.new()
	stub_scene.pack(template)
	template.free()
	spawner = WaveSpawner.new()
	spawner.enemy_stats = load("res://resources/enemy_stats.tres")
	spawner.scene_overrides["drone"] = stub_scene
	spawner.scene_overrides["gunship"] = stub_scene
	spawner.scene_overrides["boss"] = stub_scene
	var marker: Marker2D = Marker2D.new()
	marker.position = Vector2(100.0, -100.0)
	spawner.add_child(marker)
	add_child(spawner)


func after_each() -> void:
	if is_instance_valid(spawner):
		for enemy in spawner.get_alive_enemies():
			if is_instance_valid(enemy):
				enemy.queue_free()
		spawner.queue_free()
	spawner = null


func _make_wave(n: int, counts: Dictionary, interval: float = 0.0) -> WaveData:
	var wave: WaveData = WaveData.new()
	wave.wave_number = n
	wave.enemy_counts = counts
	wave.spawn_interval = interval
	wave.hp_multiplier = 1.0
	wave.fire_rate_multiplier = 1.0
	wave.score_values = {}
	wave.wave_clear_bonus = 100
	return wave


func test_wave_multiplier_for_n_1_to_5() -> void:
	assert_eq(WaveSpawner.wave_multiplier(1), 1.0)
	assert_eq(WaveSpawner.wave_multiplier(2), 1.25)
	assert_eq(WaveSpawner.wave_multiplier(3), 1.5)
	assert_eq(WaveSpawner.wave_multiplier(4), 1.75)
	assert_eq(WaveSpawner.wave_multiplier(5), 2.0)


func test_wave_resources_wave_01_to_05_load_with_data() -> void:
	for n in range(1, 6):
		var wave: WaveData = load("res://resources/waves/wave_%02d.tres" % n) as WaveData
		assert_not_null(wave, "wave_%02d.tres must load" % n)
		assert_eq(wave.wave_number, n)
		assert_gt(wave.get_total_count(), 0, "wave %d must define enemies" % n)
		assert_gt(wave.spawn_interval, 0.0)
		assert_gt(wave.hp_multiplier, 0.0)
		assert_gt(wave.fire_rate_multiplier, 0.0)
		for enemy_type in wave.get_enemy_types():
			assert_gt(wave.get_count(enemy_type), 0)


func test_enemy_stats_resource_holds_drone_gunship_boss() -> void:
	var stats: EnemyStats = load("res://resources/enemy_stats.tres")
	assert_not_null(stats)
	for enemy_type in ["drone", "gunship", "boss"]:
		assert_true(stats.has_type(enemy_type), "missing stats for %s" % enemy_type)
		assert_gt(stats.get_base_hp(enemy_type), 0)
		assert_gt(stats.get_base_fire_rate(enemy_type), 0.0)
		assert_gt(stats.get_base_score(enemy_type), 0)
		assert_true(stats.get_scene_path(enemy_type).begins_with("res://"))


func test_spawn_wave_loads_resource_and_emits_wave_started() -> void:
	watch_signals(Events)
	assert_true(spawner.spawn_wave(1))
	assert_signal_emitted_with_parameters(Events, "wave_started", [1])
	assert_eq(spawner.get_current_wave(), 1)
	assert_true(spawner.is_wave_active())
	await wait_physics_frames(2)
	assert_eq(spawner.get_alive_count(), 1, "first enemy spawns on the first physics frame")
	assert_signal_emit_count(Events, "enemy_spawned", 1)


func test_spawn_wave_rejects_invalid_and_missing_waves() -> void:
	assert_false(spawner.spawn_wave(0))
	assert_false(spawner.spawn_wave(99))
	assert_false(spawner.is_wave_active())


func test_start_wave_spawns_scaled_count_and_applies_scaling() -> void:
	watch_signals(Events)
	var wave: WaveData = _make_wave(3, {"drone": 4})
	assert_true(spawner.start_wave(wave))
	await wait_physics_frames(10)
	assert_eq(spawner.get_alive_count(), 6, "count 4 scaled by wave_multiplier(3) = 1.5")
	assert_signal_emit_count(Events, "enemy_spawned", 6)
	assert_signal_emitted_with_parameters(Events, "wave_started", [3])
	for enemy in spawner.get_alive_enemies():
		var stub: StubEnemy = enemy as StubEnemy
		assert_eq(stub.enemy_type, "drone")
		assert_eq(stub.hp, 45.0, "base hp 30 * multiplier 1.5")
		assert_almost_eq(stub.fire_rate, 1.8, 0.0001, "base fire_rate 1.2 * multiplier 1.5")
		assert_eq(stub.score_value, 100, "falls back to enemy_stats base score")


func test_wave_cleared_fires_exactly_once_at_zero_alive() -> void:
	spawner.start_wave(_make_wave(1, {"drone": 3}))
	await wait_physics_frames(10)
	assert_eq(spawner.get_alive_count(), 3)
	watch_signals(Events)
	for enemy in spawner.get_alive_enemies():
		enemy.queue_free()
	await wait_physics_frames(3)
	assert_signal_emitted_with_parameters(Events, "wave_cleared", [1])
	assert_signal_emit_count(Events, "wave_cleared", 1)
	await wait_physics_frames(5)
	assert_signal_emit_count(Events, "wave_cleared", 1, "wave_cleared must fire exactly once")
	assert_false(spawner.is_wave_active())


func test_wave_cleared_via_enemy_destroyed_signal() -> void:
	spawner.start_wave(_make_wave(2, {"drone": 4}))
	await wait_physics_frames(10)
	assert_eq(spawner.get_alive_count(), 5, "count 4 scaled by wave_multiplier(2) = 1.25")
	watch_signals(Events)
	for i in range(5):
		Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	assert_signal_emit_count(Events, "wave_cleared", 1, "signal path clears synchronously")
	assert_signal_emitted_with_parameters(Events, "wave_cleared", [2])
	assert_true(spawner.is_wave_cleared(2))


func test_cleared_wave_is_never_respawned() -> void:
	var wave: WaveData = _make_wave(2, {"drone": 4})
	assert_true(spawner.start_wave(wave))
	await wait_physics_frames(10)
	watch_signals(Events)
	for i in range(5):
		Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	assert_signal_emit_count(Events, "wave_cleared", 1)
	assert_false(spawner.spawn_wave(2), "cleared wave must not respawn")
	assert_false(spawner.start_wave(wave), "cleared wave must not restart")
	await wait_physics_frames(5)
	assert_signal_emit_count(Events, "enemy_spawned", 0)
	assert_eq(spawner.get_alive_count(), 0)


func test_max_alive_cap_queues_excess_spawns() -> void:
	spawner.max_alive = 3
	watch_signals(Events)
	spawner.start_wave(_make_wave(1, {"drone": 6}))
	await wait_physics_frames(10)
	assert_eq(spawner.get_alive_count(), 3, "alive count capped at max_alive")
	assert_eq(spawner.get_pending_count(), 3, "excess spawns stay queued")
	assert_signal_emit_count(Events, "enemy_spawned", 3)
	for i in range(3):
		Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	await wait_physics_frames(5)
	assert_lte(spawner.get_alive_count(), 3, "cap must hold while queue drains")
	assert_signal_emit_count(Events, "enemy_spawned", 6, "all queued enemies eventually spawn")
	for i in range(3):
		Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	await wait_physics_frames(5)
	assert_signal_emit_count(Events, "wave_cleared", 1)


func test_pooled_enemies_are_reused_across_waves() -> void:
	spawner.start_wave(_make_wave(1, {"drone": 2}))
	await wait_physics_frames(10)
	var first: Array[Node] = spawner.get_alive_enemies()
	assert_eq(first.size(), 2)
	var pool: ObjectPool = spawner.get_pool("drone")
	assert_not_null(pool, "spawner must create an ObjectPool per enemy type")
	for enemy in first:
		Events.enemy_destroyed.emit("drone", enemy.global_position, 100)
		pool.release(enemy)
	await wait_physics_frames(3)
	assert_true(spawner.is_wave_cleared(1))
	var expected: int = int(round(4 * WaveSpawner.wave_multiplier(2)))
	assert_true(spawner.start_wave(_make_wave(2, {"drone": 4})))
	await wait_physics_frames(10)
	var second: Array[Node] = spawner.get_alive_enemies()
	assert_eq(second.size(), expected)
	for enemy in first:
		assert_true(second.has(enemy), "pool must reuse released instances")
