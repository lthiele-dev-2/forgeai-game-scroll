extends GutTest

var game_manager


func before_each() -> void:
	game_manager = load("res://scripts/globals/game_manager.gd").new()
	add_child(game_manager)


func after_each() -> void:
	if is_instance_valid(game_manager):
		game_manager.queue_free()
	game_manager = null


func test_initial_state_is_title() -> void:
	assert_eq(game_manager.current_state, game_manager.GameState.TITLE)


func test_state_enum_covers_all_five_states() -> void:
	assert_eq(game_manager.GameState.TITLE, 0)
	assert_eq(game_manager.GameState.GAMEPLAY, 1)
	assert_eq(game_manager.GameState.PAUSE, 2)
	assert_eq(game_manager.GameState.GAME_OVER, 3)
	assert_eq(game_manager.GameState.VICTORY, 4)


func test_change_state_updates_state_and_emits_event() -> void:
	watch_signals(Events)
	game_manager.change_state(game_manager.GameState.GAMEPLAY)
	assert_eq(game_manager.current_state, game_manager.GameState.GAMEPLAY)
	assert_signal_emitted_with_parameters(Events, "game_state_changed", [game_manager.GameState.GAMEPLAY])


func test_change_state_to_same_state_emits_nothing() -> void:
	watch_signals(Events)
	game_manager.change_state(game_manager.GameState.TITLE)
	assert_signal_not_emitted(Events, "game_state_changed")
