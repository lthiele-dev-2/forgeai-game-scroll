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

const DRONE_SCENE: PackedScene = preload("res://scenes/entities/enemies/drone.tscn")
const DELTA: float = 1.0 / 60.0

var drone: Drone
var player: Node2D
var stub_scene: PackedScene
var pool: ObjectPool


func before_each() -> void:
	stub_scene = PackedScene.new()
	var template := StubBullet.new()
	stub_scene.pack(template)
	template.free()
	drone = DRONE_SCENE.instantiate() as Drone
	drone.set_physics_process(false)
	add_child(drone)
	player = Node2D.new()
	player.add_to_group("player")
	add_child(player)
	pool = null


func after_each() -> void:
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(pool):
		pool.queue_free()
	if is_instance_valid(drone):
		drone.queue_free()
	player = null
	pool = null
	drone = null


func _weapon() -> EnemyWeapon:
	return drone.get_node("Weapon") as EnemyWeapon


func _last_bullet() -> StubBullet:
	for i in range(drone.get_child_count() - 1, -1, -1):
		var child: Node = drone.get_child(i)
		if child is StubBullet:
			return child as StubBullet
	return null


func test_enemy_base_class_exposes_contract() -> void:
	var base := Enemy.new()
	assert_true(base is CharacterBody2D, "enemy.gd is a CharacterBody2D base")
	assert_true(base.has_method("take_damage"), "base provides take_damage(amount)")
	assert_true(base.has_method("setup_wave"), "base provides setup_wave for the WaveSpawner")
	assert_true("hp" in base, "base provides hp")
	base.free()


func test_drone_scene_tree_matches_architecture() -> void:
	var root: Node = DRONE_SCENE.instantiate()
	assert_true(root is CharacterBody2D)
	assert_true(root is Drone, "drone.tscn root runs drone.gd (Enemy subclass)")
	assert_true(root.has_node("CollisionShape2D"), "tree has CollisionShape2D")
	assert_true(root.has_node("Sprite2D"), "tree has Sprite2D")
	var hitbox: Area2D = root.get_node_or_null("Hitbox") as Area2D
	assert_not_null(hitbox, "tree has Hitbox (Area2D)")
	assert_eq(hitbox.collision_layer, 2, "hitbox lives on layer 2 so player shots (mask 2) detect it")
	var weapon: Node = root.get_node_or_null("Weapon")
	assert_true(weapon is EnemyWeapon, "tree has Weapon (Node2D) running enemy_weapon.gd")
	assert_true(weapon.has_node("Muzzle") and weapon.get_node("Muzzle") is Marker2D, "Weapon has Muzzle (Marker2D)")
	root.queue_free()


func test_setup_wave_applies_scaled_stats_and_fire_rate() -> void:
	drone.setup_wave("drone", 45.0, 1.8, 100)
	assert_eq(drone.enemy_type, "drone")
	assert_eq(drone.hp, 45.0, "wave-scaled hp from WaveSpawner")
	assert_eq(drone.max_hp, 45.0)
	assert_eq(drone.score_value, 100)
	assert_almost_eq(_weapon().fire_rate, 1.8, 0.0001, "fire_rate from enemy_stats.tres scaled by the wave multiplier")


func test_hitbox_area_entered_calls_take_damage() -> void:
	drone.setup_wave("drone", 30.0, 1.2, 100)
	var hitbox: Area2D = drone.get_node("Hitbox")
	var shot_area := StubBullet.new()
	shot_area.damage = 7.0
	hitbox.area_entered.emit(shot_area)
	assert_almost_eq(drone.hp, 23.0, 0.001, "area-carried damage is applied")
	var plain := Area2D.new()
	hitbox.area_entered.emit(plain)
	assert_almost_eq(drone.hp, 23.0 - drone.contact_damage, 0.001, "areas without damage fall back to contact_damage")
	shot_area.free()
	plain.free()


func test_death_emits_enemy_destroyed_once_and_queue_frees() -> void:
	watch_signals(Events)
	drone.setup_wave("drone", 30.0, 1.2, 100)
	drone.global_position = Vector2(500.0, -100.0)
	drone.take_damage(30.0)
	assert_signal_emitted_with_parameters(Events, "enemy_destroyed", ["drone", Vector2(500.0, -100.0), 100])
	assert_signal_emit_count(Events, "enemy_destroyed", 1)
	assert_false(drone.is_alive)
	assert_eq(drone.hp, 0.0)
	drone.take_damage(10.0)
	assert_signal_emit_count(Events, "enemy_destroyed", 1, "death is idempotent")
	await wait_physics_frames(2)
	assert_false(is_instance_valid(drone), "removed via queue_free(), never free() mid-frame")


func test_death_releases_to_pool_when_pool_is_set() -> void:
	pool = ObjectPool.new()
	pool.packed_scene = stub_scene
	add_child(pool)
	watch_signals(Events)
	drone.pool = pool
	drone.setup_wave("drone", 10.0, 1.0, 100)
	drone.take_damage(50.0)
	assert_signal_emit_count(Events, "enemy_destroyed", 1)
	assert_true(is_instance_valid(drone), "pool release must not free the node")
	assert_eq(drone.get_parent(), pool, "dead enemy is reparented under its pool")
	assert_false(drone.is_alive)


func test_drone_approaches_left_until_attack_range_then_stops() -> void:
	drone.setup_wave("drone", 30.0, 0.0, 100)
	drone.attack_range = 400.0
	player.global_position = Vector2(0.0, 0.0)
	drone.global_position = Vector2(2000.0, 0.0)
	drone._physics_process(DELTA)
	assert_almost_eq(drone.velocity.x, -drone.move_speed, 0.001, "moves leftward toward the player's x")
	var start_x: float = drone.global_position.x
	drone._physics_process(DELTA)
	assert_lt(drone.global_position.x, start_x, "position advances left in _physics_process")
	drone.global_position = Vector2(300.0, 0.0)
	for i in 60:
		drone._physics_process(DELTA)
	assert_lt(absf(drone.velocity.x), 1.0, "stops once within the exported attack range")


func test_drone_fires_bullets_left_only_within_attack_range() -> void:
	var weapon: EnemyWeapon = _weapon()
	weapon.set_bullet_scene(stub_scene)
	weapon.set_fire_rate(60.0)
	drone.setup_wave("drone", 30.0, 60.0, 100)
	player.global_position = Vector2(0.0, 0.0)
	drone.global_position = Vector2(2000.0, 0.0)
	watch_signals(weapon)
	for i in 5:
		drone._physics_process(DELTA)
	assert_signal_emit_count(weapon, "bullet_fired", 0, "no fire while approaching")
	drone.global_position = Vector2(300.0, 0.0)
	for i in 5:
		drone._physics_process(DELTA)
	assert_signal_emit_count(weapon, "bullet_fired", 5, "fire_rate 60 at 60 Hz fires once per tick in range")
	var bullet: StubBullet = _last_bullet()
	assert_not_null(bullet, "a pooled enemy bullet was spawned")
	assert_eq(bullet.direction, Vector2.LEFT, "enemy bullets travel left toward the player")
	assert_almost_eq(bullet.damage, weapon.base_damage, 0.001)
	assert_eq(bullet.fire_pos, weapon.get_muzzle().global_position, "bullet spawns at the muzzle")
	assert_true(bullet.is_active)


func test_weapon_pool_caps_active_bullets() -> void:
	var weapon: EnemyWeapon = _weapon()
	weapon.set_bullet_scene(stub_scene)
	weapon.pool_size = 4
	weapon.set_fire_rate(60.0)
	for i in 10:
		weapon.hold_fire(DELTA)
	assert_eq(weapon.get_active_bullet_count(), 4, "active bullets never exceed the pool cap")
