extends GutTest

class FakeEnemy extends Node2D:
	var enemy_multiplier: float = 2.0
	var hp: float = 100.0

	func take_damage(dmg: float) -> void:
		hp -= dmg

const MECH_SCENE: PackedScene = preload("res://scenes/entities/mech.tscn")
const SHOT_SCENE: PackedScene = preload("res://scenes/entities/projectiles/player_shot.tscn")
const DELTA: float = 1.0 / 60.0

var weapon: Weapon
var container: Node2D


func before_each() -> void:
	weapon = Weapon.new()
	weapon.name = "Weapon"
	var muzzle: Marker2D = Marker2D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector2(40.0, -20.0)
	weapon.add_child(muzzle)
	container = Node2D.new()
	container.name = "Projectiles"
	add_child(container)
	weapon.set_projectiles_container(container)
	add_child(weapon)


func after_each() -> void:
	Input.action_release("shoot")
	if is_instance_valid(container):
		container.queue_free()
	if is_instance_valid(weapon):
		weapon.queue_free()
	container = null
	weapon = null


func _hold(times: int) -> void:
	for i in times:
		weapon.hold_fire(DELTA)


func _newest_shot() -> PlayerShot:
	return container.get_child(container.get_child_count() - 1) as PlayerShot


func test_tuning_params_are_exported() -> void:
	for prop_name in ["base_damage", "fire_rate", "pool_size", "projectile_scene"]:
		var exported: bool = false
		for prop in weapon.get_property_list():
			if prop["name"] == prop_name and (prop["usage"] & PROPERTY_USAGE_EDITOR) != 0:
				exported = true
		assert_true(exported, "Expected @export property '%s'" % prop_name)


func test_player_shot_scene_is_poolable_area2d() -> void:
	var shot: PlayerShot = SHOT_SCENE.instantiate()
	assert_true(shot is Area2D)
	assert_eq(shot.collision_layer, 4, "player projectiles live on layer 4")
	assert_eq(shot.collision_mask, 2, "player shots detect enemy hitboxes on layer 2")
	assert_true(shot.has_node("CollisionShape2D"))
	shot.queue_free()


func test_first_hold_fires_immediately_at_muzzle() -> void:
	var fired: Array = []
	weapon.shot_fired.connect(func(pos: Vector2) -> void: fired.append(pos))
	weapon.hold_fire(DELTA)
	assert_eq(container.get_child_count(), 1, "first hold_fire must fire without waiting for cooldown")
	assert_eq(fired.size(), 1, "weapon emits shot_fired up")
	assert_eq(fired[0], weapon.muzzle.global_position, "shot_fired carries the muzzle position")
	var shot: PlayerShot = _newest_shot()
	assert_eq(shot.global_position, weapon.muzzle.global_position, "shot spawns at the muzzle")
	assert_true(shot.is_active)


func test_fire_rate_60_fires_every_tick() -> void:
	weapon.fire_rate = 60.0
	_hold(60)
	assert_eq(container.get_child_count(), 60, "fire_rate 60 at 60Hz fires once per tick")


func test_fire_rate_30_spaces_shots_every_two_ticks() -> void:
	weapon.fire_rate = 30.0
	_hold(60)
	assert_eq(container.get_child_count(), 31, "immediate first shot plus 30 shots in one second")


func test_release_fire_stops_and_next_hold_fires_immediately() -> void:
	weapon.fire_rate = 60.0
	_hold(5)
	assert_eq(container.get_child_count(), 5)
	weapon.release_fire()
	_hold(0)
	assert_eq(container.get_child_count(), 5, "no shots while fire is released")
	weapon.hold_fire(DELTA)
	assert_eq(container.get_child_count(), 6, "release resets cooldown so the next hold fires at once")


func test_shot_moves_right_by_speed_times_delta() -> void:
	weapon.hold_fire(DELTA)
	var shot: PlayerShot = _newest_shot()
	shot.set_physics_process(false)
	shot._physics_process(DELTA)
	assert_almost_eq(shot.global_position.x, 40.0 + shot.speed * DELTA, 0.001, "moves right at exported speed scaled by delta")
	assert_almost_eq(shot.global_position.y, -20.0, 0.001, "no vertical drift")


func test_shot_releases_to_pool_when_out_of_bounds() -> void:
	weapon.set_level_bounds(Rect2(Vector2(0.0, -540.0), Vector2(5760.0, 1080.0)))
	weapon.hold_fire(DELTA)
	var shot: PlayerShot = _newest_shot()
	shot.set_physics_process(false)
	shot.global_position = Vector2(6000.0, 0.0)
	shot._physics_process(DELTA)
	assert_false(shot.is_active, "out-of-bounds shot deactivates")
	assert_eq(shot.get_parent(), weapon.pool, "released shot is reparented under the pool, never freed")
	assert_true(is_instance_valid(shot), "pool release must not free() mid-frame")


func test_shot_damages_enemy_hitbox_with_multiplier_and_releases() -> void:
	var enemy := FakeEnemy.new()
	var hitbox := Area2D.new()
	hitbox.collision_layer = 2
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	hitbox.add_child(shape)
	enemy.add_child(hitbox)
	container.add_child(enemy)
	enemy.global_position = Vector2(40.0, -20.0)
	weapon.hold_fire(DELTA)
	var shot: PlayerShot = _newest_shot()
	shot.area_entered.emit(hitbox)
	assert_almost_eq(enemy.hp, 100.0 - weapon.base_damage * 2.0, 0.001, "damage = base_damage * enemy_multiplier")
	assert_false(shot.is_active, "shot releases after hitting")
	assert_eq(shot.get_parent(), weapon.pool)
	enemy.queue_free()


func test_pool_cap_releases_oldest_and_reuses_instead_of_instantiating() -> void:
	weapon.pool_size = 4
	weapon.fire_rate = 60.0
	var fired: Array[PlayerShot] = []
	for i in 10:
		weapon.hold_fire(DELTA)
		fired.append(_newest_shot())
	assert_eq(container.get_child_count(), 4, "active shots never exceed the pool cap")
	var unique: Array[PlayerShot] = []
	for shot in fired:
		if not unique.has(shot):
			unique.append(shot)
	assert_eq(unique.size(), 4, "only pool_size instances were ever created")
	assert_eq(fired[9], fired[5], "oldest shot was released and reused")
	for shot in unique:
		assert_true(is_instance_valid(shot), "pooled shots are reused, never freed mid-frame")


func test_mech_scene_has_weapon_child_and_relays_shot_fired_to_events() -> void:
	var mech: Mech = MECH_SCENE.instantiate()
	mech.set_physics_process(false)
	add_child(mech)
	assert_true(mech.get_node("Weapon") is Weapon, "mech.tscn Weapon node runs weapon.gd")
	var mech_container := Node2D.new()
	add_child(mech_container)
	mech.set_projectiles_container(mech_container)
	watch_signals(Events)
	Input.action_press("shoot")
	mech._physics_process(DELTA)
	Input.action_release("shoot")
	assert_signal_emitted_with_parameters(Events, "shot_fired", [mech.weapon.muzzle.global_position], "Weapon -> Mech -> Events relay")
	assert_eq(mech_container.get_child_count(), 1, "holding shoot in mech._physics_process fires a pooled shot")
	mech_container.queue_free()
	mech.queue_free()
