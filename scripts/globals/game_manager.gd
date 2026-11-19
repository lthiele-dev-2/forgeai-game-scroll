extends Node

enum GameState { TITLE, GAMEPLAY, PAUSE, GAME_OVER, VICTORY }

const VALID_TRANSITIONS: Dictionary = {
	GameState.TITLE: [GameState.GAMEPLAY],
	GameState.GAMEPLAY: [GameState.PAUSE, GameState.GAME_OVER, GameState.VICTORY],
	GameState.PAUSE: [GameState.GAMEPLAY, GameState.TITLE],
	GameState.GAME_OVER: [GameState.TITLE, GameState.GAMEPLAY],
	GameState.VICTORY: [GameState.TITLE, GameState.GAMEPLAY],
}

const ENEMY_STATS_PATH: String = "res://resources/enemy_stats.tres"
const DEFAULT_WAVE_CLEAR_BONUS: int = 250
const MIN_MULTI_KILL: int = 2

@export var final_wave: int = 5
@export var breather_seconds: float = 2.0
@export var enemy_stats: EnemyStats = null
@export var multi_kill_bonus_per_kill: int = 50
@export var blast_window_seconds: float = 0.5

var current_state: GameState = GameState.TITLE
var wave_spawner: Node = null
var score: int = 0
var current_wave: int = 1

var _pending_wave: int = 0
var _breather_remaining: float = 0.0
var _blast_window_remaining: float = 0.0
var _blast_kill_count: int = 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	current_state = GameState.TITLE
	if enemy_stats == null:
		enemy_stats = load(ENEMY_STATS_PATH) as EnemyStats
	Events.player_died.connect(_on_player_died)
	Events.wave_cleared.connect(_on_wave_cleared)
	Events.wave_started.connect(_on_wave_started)
	Events.enemy_destroyed.connect(_on_enemy_destroyed)
	Events.charge_fired.connect(_on_charge_fired)


func _exit_tree() -> void:
	if Events.player_died.is_connected(_on_player_died):
		Events.player_died.disconnect(_on_player_died)
	if Events.wave_cleared.is_connected(_on_wave_cleared):
		Events.wave_cleared.disconnect(_on_wave_cleared)
	if Events.wave_started.is_connected(_on_wave_started):
		Events.wave_started.disconnect(_on_wave_started)
	if Events.enemy_destroyed.is_connected(_on_enemy_destroyed):
		Events.enemy_destroyed.disconnect(_on_enemy_destroyed)
	if Events.charge_fired.is_connected(_on_charge_fired):
		Events.charge_fired.disconnect(_on_charge_fired)


func set_wave_spawner(spawner: Node) -> void:
	wave_spawner = spawner


func is_state(state: GameState) -> bool:
	return current_state == state


func change_state(new_state: GameState) -> bool:
	if new_state == current_state:
		return false
	if not _is_transition_valid(current_state, new_state):
		push_warning("GameManager: invalid state transition %s -> %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
		return false
	var previous_state: GameState = current_state
	current_state = new_state
	if new_state == GameState.GAMEPLAY and (previous_state == GameState.TITLE or previous_state == GameState.GAME_OVER):
		reset_score()
	if get_tree() != null:
		get_tree().paused = new_state == GameState.PAUSE
	Events.game_state_changed.emit(current_state)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == GameState.GAMEPLAY:
			change_state(GameState.PAUSE)
		elif current_state == GameState.PAUSE:
			change_state(GameState.GAMEPLAY)


func _physics_process(delta: float) -> void:
	if _blast_window_remaining > 0.0:
		_blast_window_remaining -= delta
		if _blast_window_remaining <= 0.0:
			_blast_window_remaining = 0.0
			_close_blast_window()
	if _breather_remaining > 0.0 and current_state == GameState.GAMEPLAY:
		_breather_remaining -= delta
		if _breather_remaining <= 0.0:
			_breather_remaining = 0.0
			_spawn_pending_wave()


func _is_transition_valid(from: GameState, to: GameState) -> bool:
	var allowed: Array = VALID_TRANSITIONS.get(from, [])
	return allowed.has(to)


func _on_player_died() -> void:
	if current_state != GameState.GAMEPLAY:
		return
	change_state(GameState.GAME_OVER)
	Events.game_over.emit()


func reset_score() -> void:
	score = 0
	current_wave = 1
	_blast_window_remaining = 0.0
	_blast_kill_count = 0
	Events.score_changed.emit(score)


func get_score() -> int:
	return score


func _on_wave_started(n: int) -> void:
	current_wave = n


func _on_enemy_destroyed(enemy_type: String, pos: Vector2, score_value: int) -> void:
	var base_score: int = score_value
	if enemy_stats != null and enemy_stats.has_type(enemy_type):
		base_score = enemy_stats.get_base_score(enemy_type)
	var gained: int = int(round(float(base_score) * WaveSpawner.wave_multiplier(current_wave)))
	_add_score(gained)
	if _blast_window_remaining > 0.0:
		_blast_kill_count += 1


func _on_charge_fired(level: float) -> void:
	_blast_window_remaining = blast_window_seconds
	_blast_kill_count = 0


func _close_blast_window() -> void:
	if _blast_kill_count >= MIN_MULTI_KILL:
		_add_score(multi_kill_bonus_per_kill * _blast_kill_count)
	_blast_kill_count = 0


func _wave_clear_bonus(n: int) -> int:
	var wave: WaveData = load(WaveSpawner.WAVE_RESOURCE_FORMAT % n) as WaveData
	if wave != null:
		return wave.wave_clear_bonus
	return DEFAULT_WAVE_CLEAR_BONUS


func _add_score(amount: int) -> void:
	score += amount
	Events.score_changed.emit(score)


func _on_wave_cleared(n: int) -> void:
	_add_score(_wave_clear_bonus(n))
	if current_state != GameState.GAMEPLAY:
		return
	if n >= final_wave:
		change_state(GameState.VICTORY)
		Events.victory.emit()
		return
	_pending_wave = n + 1
	_breather_remaining = breather_seconds


func _spawn_pending_wave() -> void:
	if _pending_wave < 1:
		return
	var n: int = _pending_wave
	_pending_wave = 0
	if is_instance_valid(wave_spawner) and wave_spawner.has_method("spawn_wave"):
		wave_spawner.spawn_wave(n)
