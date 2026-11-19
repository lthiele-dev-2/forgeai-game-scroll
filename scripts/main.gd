extends Node

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/level_01.tscn")

@export var first_wave: int = 1

@onready var world: Node2D = $World

var _level: Node2D = null


func _ready() -> void:
	Events.game_state_changed.connect(_on_game_state_changed)
	_on_game_state_changed(GameManager.current_state)


func _exit_tree() -> void:
	if Events.game_state_changed.is_connected(_on_game_state_changed):
		Events.game_state_changed.disconnect(_on_game_state_changed)


func get_level() -> Node2D:
	return _level


func _on_game_state_changed(new_state: int) -> void:
	if new_state == GameManager.GameState.GAMEPLAY or new_state == GameManager.GameState.PAUSE:
		_ensure_level()
	else:
		_clear_level()


func _ensure_level() -> void:
	if is_instance_valid(_level):
		return
	_level = LEVEL_SCENE.instantiate()
	world.add_child(_level)
	if _level is Level01:
		_level.start_wave(first_wave)


func _clear_level() -> void:
	if is_instance_valid(_level):
		world.remove_child(_level)
		_level.queue_free()
	_level = null
