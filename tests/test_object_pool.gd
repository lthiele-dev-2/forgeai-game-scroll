extends GutTest

var pool
var packed_scene: PackedScene
var _spawned: Array[Node] = []


func before_each() -> void:
	packed_scene = PackedScene.new()
	var template: Node2D = Node2D.new()
	packed_scene.pack(template)
	template.free()
	pool = load("res://scripts/utils/object_pool.gd").new()
	pool.packed_scene = packed_scene
	add_child(pool)


func after_each() -> void:
	for instance in _spawned:
		if is_instance_valid(instance):
			instance.queue_free()
	_spawned.clear()
	if is_instance_valid(pool):
		pool.queue_free()
	pool = null


func _acquire() -> Node:
	var instance: Node = pool.acquire()
	_spawned.append(instance)
	return instance


func test_acquire_instantiates_when_pool_is_empty() -> void:
	var instance: Node = _acquire()
	assert_not_null(instance)
	assert_true(instance is Node2D)
	assert_eq(instance.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_ne(instance.get_parent(), pool)


func test_release_deactivates_and_reparents_under_pool() -> void:
	var instance: Node = _acquire()
	add_child(instance)
	pool.release(instance)
	assert_eq(instance.get_parent(), pool)
	assert_eq(instance.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_false((instance as CanvasItem).visible)


func test_acquire_reuses_released_instance() -> void:
	var first: Node = _acquire()
	pool.release(first)
	var second: Node = _acquire()
	assert_eq(first, second)


func test_initial_size_prefills_pool() -> void:
	var pre = load("res://scripts/utils/object_pool.gd").new()
	pre.packed_scene = packed_scene
	pre.initial_size = 2
	add_child(pre)
	_spawned.append(pre.acquire())
	_spawned.append(pre.acquire())
	_spawned.append(pre.acquire())
	assert_eq(_spawned.size(), 3)
	pre.queue_free()
