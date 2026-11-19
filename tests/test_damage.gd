extends GutTest

class StubEnemyBody:
	extends CharacterBody2D

	var contact_damage: float = 10.0
	var enemy_multiplier: float = 3.0

const MECH_SCENE: PackedScene = preload("res://scenes/entities/mech.tscn")
const DRONE_SCENE: PackedScene = preload("res://scenes/entities/enemies/drone.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/entities/projectiles/enemy_bullet.tscn")
const DELTA: float = 1.0 / 60.0
const BOUNDS: Rect2 = Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))

var mech: Mech
var pool: ObjectPool


func before_each() -> void:
	mech = MECH_SCENE.instantiate()
	mech.set_physics_process(false)
	add_child(mech)
	mech.set_bounds(BOUNDS)
	pool = ObjectPool.new()
	pool.name = "BulletPool"
	pool.packed_scene = BULLET_SCENE
	add_child(pool)


func after_each() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("shoot")
	Input.action_release("charge_shot")
	for child in get_children():
		if child is EnemyBullet and (child as EnemyBullet).is_active:
			(child as EnemyBullet).release()
	if is_instance_valid(mech):
		remove_child(mech)
		mech.free()
	if is_instance_valid(pool):
		pool.queue_free()
	mech = null
	pool = null


func _fire_bullet(pos: Vector2, dmg: float = 8.0) -> EnemyBullet:
	var bullet: EnemyBullet = pool.acquire() as EnemyBullet
	add_child(bullet)
	bullet.fire(pos, Vector2.LEFT, dmg, pool, BOUNDS)
	return bullet


func test_max_hull_is_exported_and_hull_starts_at_max_hull() -> void:
	var exported: bool = false
	for prop in mech.get_property_list():
		if prop["name"] == "max_hull" and (prop["usage"] & PROPERTY_USAGE_EDITOR) != 0:
			exported = true
	assert_true(exported, "Expected @export property 'max_hull'")
	assert_eq(mech.max_hull, 100)
	assert_eq(mech.hull, mech.max_hull, "hull starts at max_hull")


func test_hull_initializes_from_custom_max_hull() -> void:
	var custom: Mech = MECH_SCENE.instantiate()
	custom.max_hull = 40
	add_child(custom)
	assert_eq(custom.hull, 40, "hull follows max_hull set before entering the tree")
	remove_child(custom)
	custom.free()


func test_take_damage_reduces_hull_and_emits_hull_changed() -> void:
	watch_signals(Events)
	mech.take_damage(25.0)
	assert_eq(mech.hull, 75)
	assert_signal_emitted_with_parameters(Events, "hull_changed", [75, 100])
	assert_signal_emit_count(Events, "player_died", 0)


func test_hull_zero_emits_player_died_exactly_once() -> void:
	watch_signals(Events)
	mech.take_damage(60.0)
	mech.take_damage(40.0)
	assert_eq(mech.hull, 0, "hull clamps at 0")
	assert_false(mech.is_alive)
	assert_signal_emit_count(Events, "player_died", 1)
	assert_signal_emitted_with_parameters(Events, "hull_changed", [0, 100])
	mech.take_damage(25.0)
	assert_signal_emit_count(Events, "player_died", 1, "player_died fires exactly once")
	assert_signal_emit_count(Events, "hull_changed", 2, "no further hull_changed after death")


func test_hitbox_bullet_hit_applies_base_damage_times_enemy_multiplier() -> void:
	watch_signals(Events)
	var bullet: EnemyBullet = _fire_bullet(Vector2(300.0, 100.0), 8.0)
	bullet.enemy_multiplier = 2.0
	var pos: Vector2 = bullet.global_position
	mech.hitbox.area_entered.emit(bullet)
	assert_eq(mech.hull, 100 - 16, "damage = base_damage(8) * enemy_multiplier(2)")
	assert_signal_emitted_with_parameters(Events, "hull_changed", [84, 100])
	assert_signal_emitted_with_parameters(Events, "player_hit", [16, pos])


func test_hitbox_enemy_body_contact_applies_contact_damage_times_multiplier() -> void:
	watch_signals(Events)
	var body := StubEnemyBody.new()
	add_child(body)
	body.global_position = Vector2(120.0, 60.0)
	var pos: Vector2 = body.global_position
	mech.hitbox.body_entered.emit(body)
	assert_eq(mech.hull, 100 - 30, "damage = contact_damage(10) * enemy_multiplier(3)")
	assert_signal_emitted_with_parameters(Events, "player_hit", [30, pos])
	remove_child(body)
	body.free()


func test_dead_mech_stops_accepting_movement_and_fire_input() -> void:
	mech.take_damage(1000.0)
	assert_false(mech.is_alive)
	Input.action_press("move_right")
	Input.action_press("shoot")
	mech._physics_process(DELTA)
	assert_eq(mech.velocity.x, 0.0, "no movement input accepted after player_died")
	assert_eq(mech.weapon.get_active_shot_count(), 0, "weapon is not held after death")


func test_enemy_bullet_travels_left_at_exported_speed_in_physics_process() -> void:
	var bullet: EnemyBullet = _fire_bullet(Vector2(1000.0, 500.0))
	assert_true(bullet.is_active)
	bullet._physics_process(DELTA)
	assert_almost_eq(bullet.global_position.x, 1000.0 - bullet.speed * DELTA, 0.001, "moves left by speed*delta")
	assert_eq(bullet.global_position.y, 500.0, "no vertical drift on a straight shot")


func test_enemy_bullet_releases_to_pool_when_leaving_bounds() -> void:
	var bullet: EnemyBullet = _fire_bullet(Vector2(4.0, 500.0))
	for i in 5:
		bullet._physics_process(DELTA)
	assert_false(bullet.is_active, "released after leaving level bounds")
	assert_eq(bullet.get_parent(), pool, "reparented under the pool")


func test_enemy_bullet_releases_to_pool_on_hit() -> void:
	var bullet: EnemyBullet = _fire_bullet(Vector2(1000.0, 500.0))
	bullet.area_entered.emit(mech.hitbox)
	assert_false(bullet.is_active, "released on hit")
	assert_eq(bullet.get_parent(), pool)


func test_bullet_pool_reuses_released_instance() -> void:
	var first: EnemyBullet = _fire_bullet(Vector2(1000.0, 500.0))
	first.release()
	var second: EnemyBullet = pool.acquire() as EnemyBullet
	assert_eq(first, second, "pool reuses the released bullet instead of instantiating")


func test_drone_weapon_fires_pooled_enemy_bullet_left() -> void:
	var drone: Drone = DRONE_SCENE.instantiate()
	drone.set_physics_process(false)
	add_child(drone)
	var weapon: EnemyWeapon = drone.get_node("Weapon") as EnemyWeapon
	assert_not_null(weapon.bullet_scene, "drone auto-loads res://scenes/entities/projectiles/enemy_bullet.tscn")
	weapon.set_fire_rate(60.0)
	weapon.hold_fire(DELTA)
	var bullet: EnemyBullet = null
	for child in drone.get_children():
		if child is EnemyBullet:
			bullet = child as EnemyBullet
	assert_not_null(bullet, "a pooled EnemyBullet was spawned")
	assert_true(bullet.is_active)
	assert_eq(bullet.direction, Vector2.LEFT, "enemy bullets travel left toward the player")
	assert_almost_eq(bullet.damage, weapon.base_damage, 0.001)
	watch_signals(Events)
	mech.hitbox.area_entered.emit(bullet)
	assert_eq(mech.hull, 100 - int(weapon.base_damage * bullet.enemy_multiplier), "mech hitbox applies bullet damage")
	assert_signal_emit_count(Events, "player_hit", 1)
	bullet.area_entered.emit(mech.hitbox)
	assert_false(bullet.is_active, "bullet releases on hit")
	assert_eq(bullet.get_parent(), weapon.pool, "released back into the weapon pool")
	remove_child(drone)
	drone.free()
