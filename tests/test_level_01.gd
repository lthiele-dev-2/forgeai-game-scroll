extends GutTest

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/level_01.tscn")

var level: Level01


func before_each() -> void:
	level = LEVEL_SCENE.instantiate()
	add_child(level)


func after_each() -> void:
	if is_instance_valid(level):
		level.queue_free()
	level = null


func _world_rect(shape: CollisionShape2D) -> Rect2:
	var local: Rect2 = shape.shape.get_rect()
	return Rect2(shape.global_position + local.position, local.size)


func test_root_node2d_has_architecture_32_children() -> void:
	assert_true(level is Node2D, "root must be Node2D")
	assert_true(level.get_node("ParallaxBackground") is ParallaxBackground)
	assert_true(level.get_node("Bounds") is StaticBody2D)
	assert_true(level.get_node("WaveSpawner") is Node2D)
	assert_true(level.get_node("Entities") is Node2D)
	assert_true(level.get_node("Projectiles") is Node2D)


func test_bounds_is_valid_non_empty_rect2() -> void:
	assert_true(level.bounds.has_area(), "bounds must be a valid non-empty Rect2")
	assert_eq(level.bounds.size, Vector2(5760.0, 1080.0), "level 01 spans 5760x1080")


func test_bounds_static_body_covers_all_four_edges() -> void:
	var bounds_body: StaticBody2D = level.get_node("Bounds")
	var rects: Array[Rect2] = []
	for child: Node in bounds_body.get_children():
		assert_true(child is CollisionShape2D, "Bounds may only contain CollisionShape2D children")
		var shape: CollisionShape2D = child
		rects.append(_world_rect(shape))
	assert_eq(rects.size(), 4, "all four level edges need a CollisionShape2D")
	var b: Rect2 = level.bounds
	var probes: Array[Vector2] = [
		Vector2(b.position.x - 1.0, b.get_center().y),
		Vector2(b.end.x + 1.0, b.get_center().y),
		Vector2(b.get_center().x, b.position.y - 1.0),
		Vector2(b.get_center().x, b.end.y + 1.0),
	]
	for probe: Vector2 in probes:
		var covered: bool = false
		for rect: Rect2 in rects:
			if rect.has_point(probe):
				covered = true
				break
		assert_true(covered, "edge probe %s must be covered by a bounds shape" % str(probe))


func test_parallax_has_three_layers_scrolling_at_decreasing_rates() -> void:
	var background: ParallaxBackground = level.get_node("ParallaxBackground")
	var layer_count: int = 0
	for child: Node in background.get_children():
		if child is ParallaxLayer:
			layer_count += 1
	assert_eq(layer_count, 3, "far/mid/near parallax layers required")
	var far: ParallaxLayer = background.get_node("Far")
	var mid: ParallaxLayer = background.get_node("Mid")
	var near: ParallaxLayer = background.get_node("Near")
	assert_lt(far.motion_scale.x, mid.motion_scale.x, "far scrolls slower than mid")
	assert_lt(mid.motion_scale.x, near.motion_scale.x, "mid scrolls slower than near")
	assert_lte(near.motion_scale.x, 1.0, "near layer must not scroll faster than the camera")


func test_spawn_markers_positioned_along_level_length() -> void:
	var markers: Array[Marker2D] = level.get_spawn_markers()
	assert_gt(markers.size(), 0, "WaveSpawner must expose Marker2D spawn points")
	var last_x: float = -INF
	for marker: Marker2D in markers:
		assert_true(level.bounds.has_point(marker.global_position), "spawn point %s must lie inside the level bounds" % marker.name)
		assert_gt(marker.global_position.x, last_x, "spawn points must advance along the level length")
		last_x = marker.global_position.x


func test_mech_spawned_into_entities_with_bounds_pushed_down() -> void:
	var entities: Node2D = level.get_node("Entities")
	var mech_count: int = 0
	var mech: Mech = null
	for child: Node in entities.get_children():
		if child is Mech:
			mech_count += 1
			mech = child
	assert_eq(mech_count, 1, "level spawns exactly one mech into Entities")
	assert_eq(mech.bounds, level.bounds, "mech.set_bounds(bounds) must be called down on spawn")
	var camera: Camera2D = mech.get_node("Camera2D")
	assert_eq(camera.limit_left, level.bounds.position.x)
	assert_eq(camera.limit_right, level.bounds.end.x)
	assert_eq(camera.limit_top, level.bounds.position.y)
	assert_eq(camera.limit_bottom, level.bounds.end.y)
