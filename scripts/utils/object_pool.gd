class_name ObjectPool
extends Node

@export var packed_scene: PackedScene
@export var initial_size: int = 0

var _pool: Array[Node] = []


func _ready() -> void:
	for i in range(initial_size):
		_instantiate()


func acquire() -> Node:
	if packed_scene == null:
		push_error("ObjectPool: packed_scene is not set")
		return null
	var instance: Node
	if _pool.is_empty():
		instance = packed_scene.instantiate()
	else:
		instance = _pool.pop_back()
	if instance.get_parent() == self:
		remove_child(instance)
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is CanvasItem:
		(instance as CanvasItem).show()
	return instance


func release(instance: Node) -> void:
	if instance == null or _pool.has(instance):
		return
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is CanvasItem:
		(instance as CanvasItem).hide()
	if instance.get_parent() != self:
		if instance.get_parent() != null:
			instance.get_parent().remove_child(instance)
		add_child(instance)
	_pool.append(instance)


func _instantiate() -> Node:
	var instance: Node = packed_scene.instantiate()
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is CanvasItem:
		(instance as CanvasItem).hide()
	add_child(instance)
	_pool.append(instance)
	return instance
