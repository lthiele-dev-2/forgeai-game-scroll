extends Node

enum GameState { TITLE, GAMEPLAY, PAUSE, GAME_OVER, VICTORY }

var current_state: GameState = GameState.TITLE


func _ready() -> void:
	current_state = GameState.TITLE


func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	Events.game_state_changed.emit(current_state)


func is_state(state: GameState) -> bool:
	return current_state == state
