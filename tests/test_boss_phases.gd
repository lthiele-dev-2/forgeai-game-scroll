extends GutTest

class StubBullet:
	extends Area2D

	var damage: float = 0.0
	var direction: Vector2 = Vector2.ZERO
	var is_active: bool = false
	var fire_pos: Vector2 = Vector2.ZERO
	var bullet_pool: ObjectPool = null

	func fire(pos: Vector2, dir: Vector2, dmg: float, pool: ObjectPool, bounds: Rect2) -> void:
		fire_pos = pos
		direction = dir
		damage = dmg
		bullet_pool = pool
		is_active = true
		global_position = pos

	func release() -> void:
		is_active = false
		if bullet_pool != null and is_instance_valid(bullet_pool):
			bullet_pool.release(self)

const GUNSHIP_SCENE: PackedScene = preload("res://scenes/entities/enemies/gunship.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/entities/enemies/boss.tscn")
const DRONE_SCENE: PackedScene = preload("res://scenes/entities/enemies/drone.tscn")
const CHARGE_BLAST_SCENE: PackedScene = preload("res://scenes/entities/projectiles/charge_blast.tscn")
const DELTA: float = 1.0 / 60.0

var gunship: Gunship
var boss: Boss
var player: Node2D
var stub_scene: PackedScene


func before_each() -> void:
	stub_scene = PackedScene.new()
	var template := StubBullet.new()
	stub_scene.pack(template)
	template.free()
	gunship = GUNSHIP_SCENE.instantiate() as Gunship
	gunship.set_physics_process(false)
	add_child(gunship)
	boss = BOSS_SCENE.instantiate() as Boss
	boss.set_physics_process(false)
	add_child(boss)
	player = Node2D.new()
	player.add_to_group("player")
	add_child(player)


func after_each() -> void:
	for node in [gunship, boss, player]:
		if is_instance_valid(node):
			node.queue_free()
	gunship = null
	boss = null
	player = null


func _weapon_of(enemy: Enemy) -> EnemyWeapon:
	return enemy.get_node("Weapon") as EnemyWeapon


func _bullets_under(enemy: Enemy) -> Array[StubBullet]:
	var out: Array[StubBullet] = []
	for child in enemy.get_children():
		if child is StubBullet:
			out.append(child as StubBullet)
	return out


func test_enemy_stats_entries_point_to_existing_gunship_boss_scenes() -> void:
	var stats: EnemyStats = load("res://resources/enemy_stats.tres")
	assert_true(ResourceLoader.exists(stats.get_scene_path("gunship")), "gunship scene path resolves")
	assert_true(ResourceLoader.exists(stats.get_scene_path("boss")), "boss scene path resolves")
	assert_gt(stats.get_base_fire_rate("gunship"), stats.get_base_fire_rate("drone"), "gunship fires at a higher base rate than the drone")
	assert_gt(stats.get_base_hp("boss"), stats.get_base_hp("gunship"), "boss has far more HP than the gunship")


func test_gunship_scene_tree_and_movement_tuning() -> void:
	var root: Node = GUNSHIP_SCENE.instantiate()
	assert_true(root is Gunship and root is Enemy, "gunship.gd extends enemy.gd")
	assert_true(root.has_node("Hitbox") and root.get_node("Hitbox") is Area2D)
	var weapon: Node = root.get_node_or_null("Weapon")
	assert_true(weapon is EnemyWeapon and weapon.has_node("Muzzle"))
	var drone: Drone = DRONE_SCENE.instantiate() as Drone
	assert_gt(gunship.move_speed, drone.move_speed, "gunship moves faster than the drone")
	assert_gt(gunship.attack_range, drone.attack_range, "gunship engages from farther away")
	assert_gt(gunship.preferred_distance, drone.attack_range, "gunship keeps more standoff distance than the drone")
	var gunship_weapon: EnemyWeapon = _weapon_of(gunship)
	assert_eq(gunship_weapon.burst_count, 3, "gunship weapon fires a 3-round burst")
	assert_gt(gunship_weapon.spread_degrees, 0.0, "gunship burst is spread")
	root.queue_free()
	drone.queue_free()


func test_gunship_hit_and_run_standoff_then_burst_fire() -> void:
	var weapon: EnemyWeapon = _weapon_of(gunship)
	weapon.set_bullet_scene(stub_scene)
	gunship.setup_wave("gunship", 60.0, 60.0, 250)
	player.global_position = Vector2(0.0, 0.0)
	gunship.global_position = Vector2(2000.0, 0.0)
	gunship._physics_process(DELTA)
	assert_almost_eq(gunship.velocity.x, -gunship.move_speed, 0.001, "full speed approach while out of range")
	gunship.global_position = Vector2(500.0, 0.0)
	gunship._physics_process(DELTA)
	assert_almost_eq(gunship.velocity.x, -gunship.move_speed * 0.5, 0.001, "closes the gap slowly between attack range and standoff")
	watch_signals(weapon)
	gunship.global_position = Vector2(400.0, 0.0)
	for i in 5:
		gunship._physics_process(DELTA)
	assert_signal_emit_count(weapon, "bullet_fired", 5, "fire_rate 60 at 60 Hz fires once per tick in range")
	assert_ne(gunship.velocity.y, 0.0, "hit-and-run strafe kicks in at standoff distance")
	var bullets: Array[StubBullet] = _bullets_under(gunship)
	assert_eq(bullets.size(), 15, "5 bursts x 3 bullets spawned")
	var directions: Array[Vector2] = []
	for bullet in bullets:
		if not directions.has(bullet.direction):
			directions.append(bullet.direction)
	assert_eq(directions.size(), 3, "burst spreads across 3 distinct directions")
	assert_true(directions.has(Vector2.LEFT), "burst is centered on Vector2.LEFT toward the player")
	for dir in directions:
		assert_lt(dir.x, 0.0, "every burst bullet still travels left toward the player")


func test_gunship_death_emits_enemy_destroyed_type_gunship() -> void:
	watch_signals(Events)
	gunship.setup_wave("gunship", 60.0, 2.0, 250)
	gunship.global_position = Vector2(500.0, -100.0)
	gunship.take_damage(60.0)
	assert_signal_emitted_with_parameters(Events, "enemy_destroyed", ["gunship", Vector2(500.0, -100.0), 250])
	assert_signal_emit_count(Events, "enemy_destroyed", 1)
	assert_false(gunship.is_alive)
	await wait_physics_frames(2)
	assert_false(is_instance_valid(gunship), "gunship removed via queue_free()")


func test_boss_scene_has_phase_state_machine_child_and_boss_flag() -> void:
	var root: Node = BOSS_SCENE.instantiate()
	assert_true(root is Boss and root is Enemy)
	var phases: Node = root.get_node_or_null("BossPhases")
	assert_true(phases is BossPhases, "boss.tscn has a BossPhases state-machine child")
	assert_true((root as Boss).is_boss, "is_boss flag lets the charge blast apply raw blast damage")
	root.queue_free()
	boss.setup_wave("boss", 500.0, 1.0, 1000)
	assert_eq(boss.get_phases().current_phase, 1, "phase 1 at full HP")


func test_boss_phase_transitions_at_hp_thresholds() -> void:
	boss.setup_wave("boss", 500.0, 1.0, 1000)
	var phases: BossPhases = boss.get_phases()
	var weapon: EnemyWeapon = _weapon_of(boss)
	watch_signals(phases)
	boss.take_damage(240.0)
	assert_eq(phases.current_phase, 1, "52% HP is still phase 1")
	assert_signal_emit_count(phases, "phase_changed", 0)
	boss.take_damage(20.0)
	assert_almost_eq(boss.hp, 240.0, 0.001)
	assert_eq(phases.current_phase, 2, "below 50% HP switches to phase 2")
	assert_signal_emitted_with_parameters(phases, "phase_changed", [2])
	assert_signal_emit_count(phases, "phase_changed", 1)
	assert_almost_eq(weapon.fire_rate, 2.0, 0.0001, "phase 2 doubles the fire rate")
	assert_eq(weapon.burst_count, 5, "phase 2 switches to a 5-round burst")
	assert_eq(weapon.spread_degrees, 60.0, "phase 2 widens the spread")


func test_boss_phase_two_at_exactly_50_percent_hp() -> void:
	boss.setup_wave("boss", 500.0, 1.0, 1000)
	boss.take_damage(250.0)
	assert_eq(boss.get_phases().current_phase, 2, "exactly 50% HP is already phase 2")
	assert_true(boss.is_alive)


func test_boss_phases_ratio_boundaries() -> void:
	var phases := BossPhases.new()
	assert_eq(phases.get_phase_for_ratio(1.0), 1)
	assert_eq(phases.get_phase_for_ratio(0.75), 1)
	assert_eq(phases.get_phase_for_ratio(0.5), 2)
	assert_eq(phases.get_phase_for_ratio(0.0), 2)
	add_child(phases)
	watch_signals(phases)
	assert_true(phases.update_phase(0.4))
	assert_eq(phases.current_phase, 2)
	assert_false(phases.update_phase(0.3), "same phase must not re-emit")
	assert_signal_emit_count(phases, "phase_changed", 1)
	phases.reset()
	assert_eq(phases.current_phase, 1)
	phases.queue_free()
	await wait_physics_frames(2)


func test_boss_takes_blast_damage_but_regular_shots_do_not_one_shot() -> void:
	watch_signals(Events)
	boss.setup_wave("boss", 500.0, 1.0, 1000)
	boss.take_damage(60.0)
	assert_almost_eq(boss.hp, 440.0, 0.001, "charge blast applies its full blast_damage")
	assert_true(boss.is_alive)
	boss.take_damage(10.0)
	assert_almost_eq(boss.hp, 430.0, 0.001, "regular shot applies its small damage")
	assert_true(boss.is_alive, "regular shots cannot one-shot the boss")
	assert_signal_emit_count(Events, "enemy_destroyed", 0, "enemy_destroyed fires only on death")
	boss.take_damage(430.0)
	assert_false(boss.is_alive)
	assert_signal_emitted_with_parameters(Events, "enemy_destroyed", ["boss", boss.global_position, 1000])
	assert_signal_emit_count(Events, "enemy_destroyed", 1)


func test_charge_blast_applies_raw_damage_to_boss_and_destroy_damage_to_gunship() -> void:
	watch_signals(Events)
	boss.setup_wave("boss", 500.0, 1.0, 1000)
	gunship.setup_wave("gunship", 60.0, 2.0, 250)
	var blast: ChargeBlast = CHARGE_BLAST_SCENE.instantiate() as ChargeBlast
	blast.fire(Vector2.ZERO, 60.0, Rect2())
	blast._on_area_entered(boss.get_hitbox())
	assert_almost_eq(boss.hp, 440.0, 0.001, "boss takes the raw blast damage, not the destroy multiplier")
	assert_true(boss.is_alive)
	blast._on_area_entered(gunship.get_hitbox())
	assert_false(gunship.is_alive, "non-boss enemies take destroy-multiplied blast damage")
	assert_signal_emitted_with_parameters(Events, "enemy_destroyed", ["gunship", gunship.global_position, 250])
	blast.free()


func test_final_wave_spawner_loads_real_boss_and_gunship_scenes() -> void:
	var spawner := WaveSpawner.new()
	spawner.enemy_stats = load("res://resources/enemy_stats.tres")
	var marker := Marker2D.new()
	marker.position = Vector2(100.0, -100.0)
	spawner.add_child(marker)
	add_child(spawner)
	var wave: WaveData = WaveData.new()
	wave.wave_number = 99
	wave.enemy_counts = {"gunship": 2, "boss": 1}
	wave.spawn_interval = 0.0
	wave.hp_multiplier = 1.0
	wave.fire_rate_multiplier = 1.0
	wave.score_values = {}
	assert_true(spawner.start_wave(wave))
	await wait_physics_frames(10)
	var saw_boss: bool = false
	var saw_gunship: bool = false
	for enemy in spawner.get_alive_enemies():
		if enemy is Boss:
			saw_boss = true
			assert_eq(enemy.get("enemy_type"), "boss")
			assert_true(enemy.get("is_boss"))
			assert_not_null((enemy as Boss).get_phases())
		elif enemy is Gunship:
			saw_gunship = true
			assert_eq(enemy.get("enemy_type"), "gunship")
	assert_true(saw_boss, "final wave spawns the boss from boss.tscn")
	assert_true(saw_gunship, "final wave spawns gunships from gunship.tscn")
	for enemy in spawner.get_alive_enemies():
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawner.queue_free()
	await wait_physics_frames(2)
