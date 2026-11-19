extends GutTest

const MECH_SCENE: PackedScene = preload("res://scenes/entities/mech.tscn")
const DELTA: float = 1.0 / 60.0
const TICKS_TO_MAX: int = 120

var mech: Mech


func before_each() -> void:
	mech = MECH_SCENE.instantiate()
	mech.set_physics_process(false)
	add_child(mech)
	mech.set_bounds(Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)))


func after_each() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	if is_instance_valid(mech):
		remove_child(mech)
		mech.free()
	mech = null


func _tick(times: int = 1) -> void:
	for i in times:
		mech._physics_process(DELTA)


func test_scene_root_and_children_match_architecture() -> void:
	assert_true(mech is CharacterBody2D)
	assert_eq(mech.name, "Mech")
	assert_true(mech.has_node("CollisionShape2D"))
	assert_true(mech.get_node("Visual") is Node2D)
	assert_true(mech.get_node("Visual/AnimatedSprite2D") is AnimatedSprite2D)
	assert_true(mech.get_node("Visual/ChargeGlow") is CanvasItem)
	assert_true(mech.get_node("Weapon") is Node2D)
	assert_true(mech.get_node("Weapon/Muzzle") is Marker2D)
	assert_true(mech.get_node("Hitbox") is Area2D)
	assert_true(mech.get_node("Camera2D") is Camera2D)


func test_tuning_params_are_exported() -> void:
	for prop_name in ["max_speed", "acceleration", "deceleration", "gravity", "bounds"]:
		var exported: bool = false
		for prop in mech.get_property_list():
			if prop["name"] == prop_name and (prop["usage"] & PROPERTY_USAGE_EDITOR) != 0:
				exported = true
		assert_true(exported, "Expected @export property '%s'" % prop_name)


func test_ramp_to_max_speed_with_fixed_delta() -> void:
	Input.action_press("move_right")
	_tick()
	assert_almost_eq(mech.velocity.x, move_toward(0.0, mech.max_speed, mech.acceleration * DELTA), 0.001, "one tick ramps by acceleration*delta")
	_tick(TICKS_TO_MAX)
	assert_eq(mech.velocity.x, mech.max_speed, "velocity.x converges exactly to max_speed")


func test_release_deceleration_lag() -> void:
	Input.action_press("move_right")
	_tick(TICKS_TO_MAX)
	assert_eq(mech.velocity.x, mech.max_speed)
	Input.action_release("move_right")
	_tick()
	assert_almost_eq(mech.velocity.x, move_toward(mech.max_speed, 0.0, mech.deceleration * DELTA), 0.001, "decays by deceleration*delta, not instantly")
	assert_gt(mech.velocity.x, 0.0, "floaty: still moving after input release")
	assert_lt(mech.velocity.x, mech.max_speed)


func test_gravity_integration_while_airborne() -> void:
	assert_false(mech.is_on_floor())
	_tick()
	assert_eq(mech.velocity.y, mech.gravity * DELTA, "airborne: velocity.y += gravity*delta each tick")


func test_diagonal_axes_integrate_independently() -> void:
	Input.action_press("move_right")
	Input.action_press("move_down")
	_tick()
	assert_almost_eq(mech.velocity.x, move_toward(0.0, mech.max_speed, mech.acceleration * DELTA), 0.001, "x ramps independently")
	var expected_y: float = move_toward(0.0, mech.max_speed, mech.acceleration * DELTA) + mech.gravity * DELTA
	assert_almost_eq(mech.velocity.y, expected_y, 0.001, "y ramps independently of x, plus gravity while airborne")
	_tick(TICKS_TO_MAX)
	assert_eq(mech.velocity.x, mech.max_speed)


func test_position_clamped_to_bounds_max() -> void:
	mech.set_bounds(Rect2(Vector2(100.0, 100.0), Vector2(200.0, 200.0)))
	mech.position = Vector2(250.0, 280.0)
	Input.action_press("move_right")
	Input.action_press("move_down")
	_tick(TICKS_TO_MAX * 2)
	assert_eq(mech.position, Vector2(300.0, 300.0), "clamped to bounds end after move_and_slide")


func test_position_clamped_to_bounds_min_x() -> void:
	mech.set_bounds(Rect2(Vector2(100.0, 0.0), Vector2(200.0, 1080.0)))
	mech.position = Vector2(50.0, 500.0)
	Input.action_press("move_left")
	_tick(TICKS_TO_MAX * 2)
	assert_eq(mech.position.x, 100.0, "clamped to bounds min x after move_and_slide")
