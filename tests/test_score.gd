extends GutTest

const GAME_MANAGER_SCRIPT: GDScript = preload("res://scripts/globals/game_manager.gd")

var game_manager


func before_each() -> void:
	game_manager = GAME_MANAGER_SCRIPT.new()
	add_child(game_manager)


func after_each() -> void:
	if is_instance_valid(game_manager):
		game_manager.queue_free()
	game_manager = null


func test_kill_score_is_base_score_times_wave_multiplier() -> void:
	watch_signals(Events)
	Events.wave_started.emit(3)
	Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	assert_eq(game_manager.score, 150, "drone base 100 from enemy_stats.tres * wave 3 multiplier 1.5 = 150")
	assert_signal_emitted_with_parameters(Events, "score_changed", [150])


func test_kill_score_before_any_wave_uses_multiplier_one() -> void:
	watch_signals(Events)
	Events.enemy_destroyed.emit("gunship", Vector2.ZERO, 250)
	assert_eq(game_manager.score, 250, "wave 1 multiplier is 1.0, gunship base 250")
	assert_signal_emitted_with_parameters(Events, "score_changed", [250])


func test_kill_score_falls_back_to_event_value_for_unknown_type() -> void:
	watch_signals(Events)
	Events.wave_started.emit(2)
	Events.enemy_destroyed.emit("unknown", Vector2.ZERO, 40)
	assert_eq(game_manager.score, 50, "unknown type falls back to score_value 40 * wave 2 multiplier 1.25 = 50")
	assert_signal_emitted_with_parameters(Events, "score_changed", [50])


func test_wave_cleared_adds_wave_resource_bonus() -> void:
	watch_signals(Events)
	Events.wave_cleared.emit(2)
	assert_eq(game_manager.score, 400, "wave_02.tres wave_clear_bonus = 400")
	assert_signal_emitted_with_parameters(Events, "score_changed", [400])


func test_wave_cleared_without_resource_falls_back_to_default_bonus() -> void:
	watch_signals(Events)
	Events.wave_cleared.emit(99)
	assert_eq(game_manager.score, 250, "missing wave resource falls back to DEFAULT_WAVE_CLEAR_BONUS 250")
	assert_signal_emitted_with_parameters(Events, "score_changed", [250])


func test_charge_blast_multi_kill_adds_per_kill_bonus_on_top() -> void:
	game_manager.blast_window_seconds = 60.0
	watch_signals(Events)
	Events.charge_fired.emit(1.0)
	Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	Events.enemy_destroyed.emit("gunship", Vector2.ZERO, 250)
	assert_eq(game_manager.score, 350, "kill scores only while the blast window is open")
	game_manager._close_blast_window()
	assert_eq(game_manager.score, 450, "multi-kill bonus = 50 per kill * 2 kills = 100 on top")
	assert_signal_emitted_with_parameters(Events, "score_changed", [450])


func test_single_blast_kill_gets_no_multi_kill_bonus() -> void:
	game_manager.blast_window_seconds = 60.0
	watch_signals(Events)
	Events.charge_fired.emit(0.8)
	Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	game_manager._close_blast_window()
	assert_eq(game_manager.score, 100, "a single blast kill is not a multi-kill")
	assert_signal_emit_count(Events, "score_changed", 1)


func test_blast_window_closes_itself_after_the_timer() -> void:
	game_manager.blast_window_seconds = 0.01
	Events.charge_fired.emit(1.0)
	Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	await wait_physics_frames(5)
	assert_eq(game_manager.score, 300, "200 kill score + 50 * 2 multi-kill bonus once the window expires")


func test_score_is_display_only_and_never_changes_game_state() -> void:
	watch_signals(Events)
	game_manager.change_state(game_manager.GameState.GAMEPLAY)
	Events.enemy_destroyed.emit("boss", Vector2.ZERO, 1000)
	Events.wave_cleared.emit(1)
	assert_eq(game_manager.score, 1250, "boss 1000 * 1.0 + wave 1 bonus 250")
	assert_eq(game_manager.current_state, game_manager.GameState.GAMEPLAY, "score has no fail state")
	assert_signal_not_emitted(Events, "game_over")


func test_entering_gameplay_from_title_resets_score() -> void:
	watch_signals(Events)
	Events.enemy_destroyed.emit("drone", Vector2.ZERO, 100)
	assert_eq(game_manager.score, 100)
	game_manager.change_state(game_manager.GameState.GAMEPLAY)
	assert_eq(game_manager.score, 0)
	assert_signal_emitted_with_parameters(Events, "score_changed", [0])
