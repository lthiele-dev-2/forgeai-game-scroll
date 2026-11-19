extends GutTest

const EXPECTED_SIGNALS: Array[String] = [
	"game_state_changed",
	"hull_changed",
	"player_died",
	"player_hit",
	"shot_fired",
	"charge_changed",
	"charge_fired",
	"enemy_spawned",
	"enemy_destroyed",
	"wave_started",
	"wave_cleared",
	"score_changed",
	"victory",
	"game_over",
]


func test_declares_exactly_the_14_signal_catalog() -> void:
	assert_eq(Events.get_script().get_script_signal_list().size(), 14, "Events must declare exactly 14 signals")
	for signal_name in EXPECTED_SIGNALS:
		assert_true(Events.has_signal(signal_name), "Events must declare signal '%s'" % signal_name)


func test_game_state_changed_roundtrip() -> void:
	watch_signals(Events)
	Events.game_state_changed.emit(2)
	assert_signal_emitted_with_parameters(Events, "game_state_changed", [2])


func test_typed_signal_roundtrip() -> void:
	watch_signals(Events)
	Events.enemy_destroyed.emit("drone", Vector2(10.0, 20.0), 100)
	assert_signal_emitted_with_parameters(Events, "enemy_destroyed", ["drone", Vector2(10.0, 20.0), 100])
