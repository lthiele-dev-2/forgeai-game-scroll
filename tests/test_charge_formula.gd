extends GutTest

class FakeEnemy extends Node2D:
	var enemy_multiplier: float = 1.0
	var hp: float = 50.0
	var is_boss: bool = false

	func take_damage(dmg: float) -> void:
		hp -= dmg


class FakeBoss extends Node2D:
	var is_boss: bool = true
	var hp: float = 1000.0

	func take_damage(dmg: float) -> void:
		hp -= dmg


const MECH_SCENE: PackedScene = preload("res://scenes/entities/mech.tscn")
const BLAST_SCENE: PackedScene = preload("res://scenes/entities/projectiles/charge_blast.tscn")
const DELTA: float = 1.0 / 60.0
const LEVELS: Array[float] = [0.0, 0.25, 0.5, 1.0]

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
	weapon.set_level_bounds(Rect2(Vector2(0.0, -540.0), Vector2(5760.0, 1080.0)))
	add_child(weapon)


func after_each() -> void:
	Input.action_release("shoot")
	Input.action_release("charge_shot")
	if is_instance_valid(container):
		container.queue_free()
	if is_instance_valid(weapon):
		weapon.queue_free()
	container = null
	weapon = null


func _hold(times: int) -> void:
	for i in times:
		weapon.hold_fire(DELTA)


func test_charge_tuning_params_are_exported() -> void:
	for prop_name in ["base_damage", "fire_rate", "full_charge_time", "base_blast_damage", "base_cooldown", "min_charge_level", "pool_size", "projectile_scene"]:
		var exported: bool = false
		for prop in weapon.get_property_list():
			if prop["name"] == prop_name and (prop["usage"] & PROPERTY_USAGE_EDITOR) != 0:
				exported = true
		assert_true(exported, "Expected @export property '%s'" % prop_name)


func test_charge_level_formula_saturates_at_one() -> void:
	assert_eq(Weapon.compute_charge_level(0.0, 2.0), 0.0)
	assert_almost_eq(Weapon.compute_charge_level(1.0, 2.0), 0.5, 0.0001)
	assert_eq(Weapon.compute_charge_level(2.0, 2.0), 1.0)
	assert_eq(Weapon.compute_charge_level(5.0, 2.0), 1.0, "clamp(hold_time / full_charge_time, 0, 1) saturates at 1.0")
	assert_eq(Weapon.compute_charge_level(-1.0, 2.0), 0.0, "negative hold_time clamps to 0")


func test_blast_damage_and_cooldown_match_formulas_for_all_levels() -> void:
	var base_blast: float = 80.0
	var base_cooldown: float = 4.0
	for level in LEVELS:
		var expected_blast: float = base_blast * (0.5 + 0.5 * level)
		var expected_cooldown: float = base_cooldown * (1.0 - 0.5 * level)
		assert_almost_eq(Weapon.compute_blast_damage(base_blast, level), expected_blast, 0.0001, "blast_damage level %s" % level)
		assert_almost_eq(Weapon.compute_cooldown(base_cooldown, level), expected_cooldown, 0.0001, "cooldown level %s" % level)
	assert_almost_eq(Weapon.compute_blast_damage(base_blast, 0.0), 40.0, 0.0001)
	assert_almost_eq(Weapon.compute_blast_damage(base_blast, 1.0), 80.0, 0.0001)
	assert_almost_eq(Weapon.compute_cooldown(base_cooldown, 0.0), 4.0, 0.0001)
	assert_almost_eq(Weapon.compute_cooldown(base_cooldown, 1.0), 2.0, 0.0001)


func test_hold_fire_accumulates_hold_time_and_emits_charge_changed_each_tick() -> void:
	weapon.full_charge_time = 1.0
	weapon.fire_rate = 1000.0
	var charge_events: Array = []
	weapon.charge_changed.connect(func(level: float) -> void: charge_events.append(level))
	_hold(15)
	assert_almost_eq(weapon.hold_time, 0.25, 0.0001, "hold_time accumulates delta each tick")
	assert_almost_eq(weapon.charge_level, 0.25, 0.0001, "charge_level = hold_time / full_charge_time")
	assert_eq(charge_events.size(), 15, "charge_changed emitted each tick while held")
	assert_almost_eq(charge_events[14], 0.25, 0.0001, "emitted level matches current charge_level")
	_hold(45)
	assert_eq(weapon.charge_level, 1.0, "charge_level saturates at 1.0")
	assert_eq(charge_events.size(), 60)


func test_release_below_min_threshold_fires_normal_shot_without_blast() -> void:
	weapon.full_charge_time = 10.0
	weapon.min_charge_level = 0.25
	weapon.fire_rate = 1000.0
	watch_signals(weapon)
	_hold(5)
	assert_eq(container.get_child_count(), 5)
	weapon.release_fire()
	assert_eq(container.get_child_count(), 6, "release below the minimum threshold fires a normal shot")
	assert_eq(weapon.hold_time, 0.0, "hold_time resets on release")
	assert_eq(weapon.charge_level, 0.0)
	assert_false(weapon.charging)
	assert_signal_not_emitted(weapon, "charge_fired")
	assert_false(weapon.get_charge_blast().is_active, "no blast below the threshold")
	assert_signal_emitted_with_parameters(weapon, "charge_changed", [0.0], -1)


func test_release_at_full_charge_fires_single_reusable_blast_and_starts_cooldown() -> void:
	weapon.full_charge_time = 0.5
	weapon.base_blast_damage = 100.0
	weapon.base_cooldown = 4.0
	weapon.min_charge_level = 0.25
	weapon.fire_rate = 1000.0
	watch_signals(weapon)
	_hold(60)
	assert_eq(weapon.charge_level, 1.0, "saturates at full charge")
	weapon.release_fire()
	var blast: ChargeBlast = weapon.get_charge_blast()
	assert_true(blast.is_active, "the single charge_blast instance fires")
	assert_almost_eq(blast.damage, 100.0 * (0.5 + 0.5 * 1.0), 0.0001, "blast_damage = base_blast * (0.5 + 0.5 * level)")
	assert_almost_eq(weapon.cooldown_timer, 4.0 * (1.0 - 0.5 * 1.0), 0.0001, "cooldown = base_cooldown * (1 - 0.5 * level)")
	assert_eq(weapon.hold_time, 0.0)
	assert_signal_emitted_with_parameters(weapon, "charge_fired", [1.0], -1)
	blast._deactivate()
	_hold(180)
	assert_eq(weapon.charge_level, 1.0, "charging resumes after the cooldown elapsed")
	weapon.release_fire()
	assert_eq(weapon.get_charge_blast(), blast, "the same single blast instance is reused, never reinstantiated")
	assert_true(blast.is_active)


func test_cooldown_blocks_charging_and_charge_changed() -> void:
	weapon.full_charge_time = 0.5
	weapon.base_cooldown = 4.0
	weapon.min_charge_level = 0.25
	weapon.fire_rate = 1000.0
	var charge_events: Array = []
	weapon.charge_changed.connect(func(level: float) -> void: charge_events.append(level))
	_hold(60)
	weapon.release_fire()
	assert_almost_eq(weapon.cooldown_timer, 2.0, 0.0001)
	var count_after_release: int = charge_events.size()
	var ticks: int = 0
	while weapon.cooldown_timer > 0.0 and ticks < 600:
		weapon.hold_fire(DELTA)
		ticks += 1
	assert_eq(weapon.hold_time, 0.0, "hold_time does not accumulate during cooldown")
	assert_eq(weapon.charge_level, 0.0, "charge meter reads 0 during cooldown")
	assert_eq(charge_events.size(), count_after_release, "charge_changed is not emitted during cooldown")
	weapon.hold_fire(DELTA)
	assert_true(weapon.hold_time > 0.0, "charging resumes once the cooldown elapses")
	assert_true(charge_events.size() > count_after_release, "charge_changed resumes after cooldown")


func test_charge_blast_scene_is_area2d_on_player_layer() -> void:
	var blast: ChargeBlast = BLAST_SCENE.instantiate()
	assert_true(blast is Area2D)
	assert_eq(blast.collision_layer, 4, "player projectiles live on layer 4")
	assert_eq(blast.collision_mask, 2, "blast detects enemy hitboxes on layer 2")
	assert_true(blast.has_node("CollisionShape2D"))
	assert_false(blast.is_active, "blast starts inactive")
	blast.queue_free()


func test_blast_destroys_regular_enemies_and_deals_formula_damage_to_bosses() -> void:
	var blast: ChargeBlast = BLAST_SCENE.instantiate()
	add_child(blast)
	var regular := FakeEnemy.new()
	var regular_hitbox := Area2D.new()
	regular_hitbox.collision_layer = 2
	var regular_shape := CollisionShape2D.new()
	regular_shape.shape = CircleShape2D.new()
	regular_hitbox.add_child(regular_shape)
	regular.add_child(regular_hitbox)
	add_child(regular)
	var boss := FakeBoss.new()
	var boss_hitbox := Area2D.new()
	boss_hitbox.collision_layer = 2
	var boss_shape := CollisionShape2D.new()
	boss_shape.shape = CircleShape2D.new()
	boss_hitbox.add_child(boss_shape)
	boss.add_child(boss_hitbox)
	add_child(boss)
	var blast_damage: float = 120.0
	blast.fire(Vector2(100.0, 0.0), blast_damage, Rect2())
	assert_true(blast.is_active)
	blast.area_entered.emit(regular_hitbox)
	assert_true(regular.hp <= 0.0, "regular enemies on screen are destroyed by the blast")
	blast.area_entered.emit(boss_hitbox)
	assert_almost_eq(boss.hp, 1000.0 - blast_damage, 0.0001, "bosses take exactly blast_damage = base_blast * (0.5 + 0.5 * level)")
	blast.set_physics_process(false)
	blast._physics_process(blast.blast_duration)
	assert_false(blast.is_active, "blast deactivates after blast_duration")
	regular.queue_free()
	boss.queue_free()
	blast.queue_free()


func test_mech_shows_charge_glow_and_relays_charge_events() -> void:
	var mech: Mech = MECH_SCENE.instantiate()
	mech.set_physics_process(false)
	add_child(mech)
	var mech_container := Node2D.new()
	add_child(mech_container)
	mech.set_projectiles_container(mech_container)
	mech.set_bounds(Rect2(Vector2(0.0, -540.0), Vector2(5760.0, 1080.0)))
	mech.weapon.full_charge_time = 0.1
	mech.weapon.min_charge_level = 0.25
	mech.weapon.fire_rate = 1000.0
	var glow: CanvasItem = mech.get_node("Visual/ChargeGlow")
	assert_false(glow.visible, "ChargeGlow starts hidden")
	watch_signals(Events)
	Input.action_press("shoot")
	for i in 10:
		mech._physics_process(DELTA)
	Input.action_release("shoot")
	assert_true(glow.visible, "ChargeGlow becomes visible while charging")
	assert_eq(mech.weapon.charge_level, 1.0)
	assert_signal_emitted(Events, "charge_changed")
	mech._physics_process(DELTA)
	assert_false(glow.visible, "ChargeGlow hides after release")
	assert_signal_emitted_with_parameters(Events, "charge_fired", [1.0], -1)
	var blast: ChargeBlast = mech.weapon.get_charge_blast()
	assert_true(blast.is_active, "release at full charge fires the blast through the mech")
	assert_almost_eq(blast.damage, mech.weapon.base_blast_damage, 0.0001)
	assert_almost_eq(mech.weapon.cooldown_timer, mech.weapon.base_cooldown * 0.5, 0.0001)
	mech_container.queue_free()
	mech.queue_free()


func test_mech_release_below_threshold_fires_normal_shot_and_no_charge_fired() -> void:
	var mech: Mech = MECH_SCENE.instantiate()
	mech.set_physics_process(false)
	add_child(mech)
	var mech_container := Node2D.new()
	add_child(mech_container)
	mech.set_projectiles_container(mech_container)
	mech.set_bounds(Rect2(Vector2(0.0, -540.0), Vector2(5760.0, 1080.0)))
	mech.weapon.full_charge_time = 10.0
	mech.weapon.fire_rate = 1000.0
	Input.action_press("shoot")
	mech._physics_process(DELTA)
	mech._physics_process(DELTA)
	Input.action_release("shoot")
	watch_signals(Events)
	mech._physics_process(DELTA)
	assert_signal_not_emitted(Events, "charge_fired")
	assert_eq(mech_container.get_child_count(), 3, "two holds plus one release shot")
	assert_false(mech.weapon.get_charge_blast().is_active)
	mech_container.queue_free()
	mech.queue_free()
