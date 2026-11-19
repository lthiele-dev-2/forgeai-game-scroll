extends Control

var _menus: Dictionary = {}


func _ready() -> void:
	_menus = {
		GameManager.GameState.TITLE: get_node_or_null("TitleMenu"),
		GameManager.GameState.PAUSE: get_node_or_null("PauseMenu"),
		GameManager.GameState.GAME_OVER: get_node_or_null("GameOverMenu"),
		GameManager.GameState.VICTORY: get_node_or_null("VictoryMenu"),
	}
	Events.game_state_changed.connect(_on_game_state_changed)
	_apply_state(GameManager.current_state)


func _exit_tree() -> void:
	if Events.game_state_changed.is_connected(_on_game_state_changed):
		Events.game_state_changed.disconnect(_on_game_state_changed)


func get_menu(state: int) -> Control:
	return _menus.get(state, null)


func visible_menu_count() -> int:
	var count: int = 0
	for menu in _menus.values():
		if menu != null and menu.visible:
			count += 1
	return count


func _on_game_state_changed(new_state: int) -> void:
	_apply_state(new_state)


func _apply_state(state: int) -> void:
	for s in _menus.keys():
		var menu: Node = _menus[s]
		if menu != null:
			menu.visible = s == state
