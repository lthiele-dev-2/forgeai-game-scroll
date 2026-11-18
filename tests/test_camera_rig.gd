extends GutTest

const MECH_SCENE: PackedScene = preload("res://scenes/entities/mech.tscn")
const DELTA: float = 1.0 / 60.0
const LEVEL_BOUNDS: Rect2 = Rect2(Vector2(0.0, -540.0), Vector2(5760.0, 1080.0))

var mech: Mech


func before_each() -> void:
	mech = MECH_SCENE.instantiate()
	mech.set_physics_process(false)
	add_child(mech)


func after_each() -> void:
	if is_instance_valid(mech):
		mech.queue_free()
	mech = null


func test_camera_child_has_smoothing_enabled_and_tuned_speed() -> void:
	var camera: Camera2D = mech.get_node("Camera2D")
	assert_true(camera.position_smoothing_enabled, "position_smoothing_enabled must be true")
	assert_gt(camera.position_smoothing_speed, 0.0, "position_smoothing_speed must be tuned > 0")
	assert_eq(camera.position_smoothing_speed, mech.camera_smoothing_speed)


func test_camera_zoom_matches_design_frame_at_1920x1080() -> void:
	var camera: Camera2D = mech.get_node("Camera2D")
	assert_eq(camera.zoom, Vector2(1.0, 1.0), "zoom 1.0 shows exactly the 1920x1080 design frame")


func test_set_bounds_writes_all_camera_limits_from_level_rect() -> void:
	mech.set_bounds(LEVEL_BOUNDS)
	var camera: Camera2D = mech.get_node("Camera2D")
	assert_eq(camera.limit_left, LEVEL_BOUNDS.position.x)
	assert_eq(camera.limit_right, LEVEL_BOUNDS.end.x)
	assert_eq(camera.limit_top, LEVEL_BOUNDS.position.y)
	assert_eq(camera.limit_bottom, LEVEL_BOUNDS.end.y)


func test_camera_follows_horizontal_only_and_y_pinned_to_level_midline() -> void:
	mech.set_bounds(LEVEL_BOUNDS)
	mech.position = Vector2(500.0, 100.0)
	mech._physics_process(DELTA)
	var camera: Camera2D = mech.get_node("Camera2D")
	assert_eq(camera.global_position.x, mech.position.x, "camera x follows the mech")
	assert_eq(camera.global_position.y, LEVEL_BOUNDS.get_center().y, "camera y stays fixed at the level midline")


func test_camera_y_stays_pinned_while_mech_moves_vertically() -> void:
	mech.set_bounds(LEVEL_BOUNDS)
	mech.position = Vector2(800.0, -400.0)
	Input.action_press("move_down")
	for i in 120:
		mech._physics_process(DELTA)
	Input.action_release("move_down")
	var camera: Camera2D = mech.get_node("Camera2D")
	assert_eq(camera.global_position.y, LEVEL_BOUNDS.get_center().y, "vertical mech motion must not move the camera y")
	assert_eq(camera.global_position.x, mech.position.x)
