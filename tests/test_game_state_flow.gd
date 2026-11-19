extends GutTest

class StubSpawner:
	extends Node

	var spawned_waves: Array[int] = []

	func spawn_wave(n: int) -> bool:
		spawned_waves.append(n)
		return true


const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var stub_spawner: StubSpawner
var main: Node = null


func before_each() -> void:
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.TITLE
	GameManager.set_wave_spawner(null)
	GameManager._pending_wave = 0
	GameManager._breather_remaining = 0.0
	GameManager.breather_seconds = 0.05
	stub_spawner = StubSpawner.new()
	add_child(stub_spawner)
	GameManager.set_wave_spawner(stub_spawner)


func after_each() -> void:
	get_tree().paused = false
	GameManager.set_wave_spawner(null)
	GameManager.current_state = GameManager.GameState.TITLE
	GameManager._pending_wave = 0
	GameManager._breather_remaining = 0.0
	GameManager.breather_seconds = 2.0
	if is_instance_valid(main):
		main.queue_free()
	main = null
	if is_instance_valid(stub_spawner):
		stub_spawner.queue_free()
	stub_spawner = null


func _pause_event() -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	return event


func test_boot_state_is_title() -> void:
	assert_eq(GameManager.current_state, GameManager.GameState.TITLE)


func test_change_state_validates_transition_and_emits_event() -> void:
	watch_signals(Events)
	assert_true(GameManager.change_state(GameManager.GameState.GAMEPLAY))
	assert_eq(GameManager.current_state, GameManager.GameState.GAMEPLAY)
	assert_signal_emitted_with_parameters(Events, "game_state_changed", [GameManager.GameState.GAMEPLAY])


func test_invalid_transitions_are_rejected_without_signal() -> void:
	watch_signals(Events)
	assert_false(GameManager.change_state(GameManager.GameState.PAUSE), "TITLE -> PAUSE must be invalid")
	assert_false(GameManager.change_state(GameManager.GameState.GAME_OVER))
	assert_false(GameManager.change_state(GameManager.GameState.VICTORY))
	assert_eq(GameManager.current_state, GameManager.GameState.TITLE)
	assert_signal_not_emitted(Events, "game_state_changed")
	assert_true(GameManager.change_state(GameManager.GameState.GAMEPLAY))
	assert_false(GameManager.change_state(GameManager.GameState.TITLE), "GAMEPLAY -> TITLE must be invalid")
	assert_eq(GameManager.current_state, GameManager.GameState.GAMEPLAY)
	assert_signal_emit_count(Events, "game_state_changed", 1)


func test_pause_input_toggles_pause_and_tree_pause_flag() -> void:
	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	GameManager._unhandled_input(_pause_event())
	assert_eq(GameManager.current_state, GameManager.GameState.PAUSE)
	assert_true(get_tree().paused, "tree must pause in PAUSE state")
	GameManager._unhandled_input(_pause_event())
	assert_eq(GameManager.current_state, GameManager.GameState.GAMEPLAY)
	assert_false(get_tree().paused, "tree must resume when leaving PAUSE")


func test_player_died_in_gameplay_leads_to_game_over() -> void:
	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	watch_signals(Events)
	Events.player_died.emit()
	assert_eq(GameManager.current_state, GameManager.GameState.GAME_OVER)
	assert_signal_emitted_with_parameters(Events, "game_state_changed", [GameManager.GameState.GAME_OVER])
	assert_signal_emitted(Events, "game_over")


func test_player_died_outside_gameplay_is_ignored() -> void:
	watch_signals(Events)
	Events.player_died.emit()
	assert_eq(GameManager.current_state, GameManager.GameState.TITLE)
	assert_signal_not_emitted(Events, "game_over")


func test_final_wave_cleared_leads_to_victory() -> void:
	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	watch_signals(Events)
	Events.wave_cleared.emit(GameManager.final_wave)
	assert_eq(GameManager.current_state, GameManager.GameState.VICTORY)
	assert_signal_emitted_with_parameters(Events, "game_state_changed", [GameManager.GameState.VICTORY])
	assert_signal_emitted(Events, "victory")
	assert_eq(stub_spawner.spawned_waves.size(), 0, "no further wave spawns after the final wave")


func test_non_final_wave_breather_then_spawns_next_wave() -> void:
	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	watch_signals(Events)
	Events.wave_cleared.emit(2)
	assert_eq(GameManager.current_state, GameManager.GameState.GAMEPLAY, "breather keeps GAMEPLAY state")
	assert_eq(stub_spawner.spawned_waves.size(), 0, "spawn_wave must wait for the breather")
	await wait_physics_frames(10)
	assert_eq(stub_spawner.spawned_waves, [3], "after the breather GameManager calls down spawn_wave(n + 1)")


func test_wave_cleared_outside_gameplay_is_ignored() -> void:
	Events.wave_cleared.emit(1)
	assert_eq(GameManager.current_state, GameManager.GameState.TITLE)
	await wait_physics_frames(10)
	assert_eq(stub_spawner.spawned_waves.size(), 0)


func test_main_scene_drives_menu_visibility_and_world_level() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	var world: Node2D = main.get_node("World")
	var menu_layer: Control = main.get_node("UI/MenuLayer")
	var title_menu: Control = menu_layer.get_node("TitleMenu")
	var pause_menu: Control = menu_layer.get_node("PauseMenu")
	var game_over_menu: Control = menu_layer.get_node("GameOverMenu")
	var victory_menu: Control = menu_layer.get_node("VictoryMenu")

	assert_eq(GameManager.current_state, GameManager.GameState.TITLE)
	assert_eq(world.get_child_count(), 0, "World holds no level in TITLE")
	assert_true(title_menu.visible)
	assert_false(pause_menu.visible)
	assert_false(game_over_menu.visible)
	assert_false(victory_menu.visible)
	assert_eq(menu_layer.visible_menu_count(), 1)

	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	assert_eq(world.get_child_count(), 1, "World holds the active level in GAMEPLAY")
	assert_true(is_instance_valid(main.get_level()))
	assert_eq(menu_layer.visible_menu_count(), 0, "no menu visible in GAMEPLAY")

	GameManager.change_state(GameManager.GameState.PAUSE)
	assert_eq(world.get_child_count(), 1, "World keeps the level in PAUSE")
	assert_true(get_tree().paused)
	assert_true(pause_menu.visible)
	assert_eq(menu_layer.visible_menu_count(), 1, "exactly one menu per state")

	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	assert_false(get_tree().paused)
	assert_eq(menu_layer.visible_menu_count(), 0)

	Events.player_died.emit()
	assert_eq(GameManager.current_state, GameManager.GameState.GAME_OVER)
	assert_eq(world.get_child_count(), 0, "World drops the level on GAME_OVER")
	assert_true(game_over_menu.visible)
	assert_eq(menu_layer.visible_menu_count(), 1)

	GameManager.change_state(GameManager.GameState.TITLE)
	assert_true(title_menu.visible)
	assert_eq(menu_layer.visible_menu_count(), 1)

	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	assert_eq(world.get_child_count(), 1)
	Events.wave_cleared.emit(GameManager.final_wave)
	assert_eq(GameManager.current_state, GameManager.GameState.VICTORY)
	assert_eq(world.get_child_count(), 0, "World drops the level on VICTORY")
	assert_true(victory_menu.visible)
	assert_eq(menu_layer.visible_menu_count(), 1)
