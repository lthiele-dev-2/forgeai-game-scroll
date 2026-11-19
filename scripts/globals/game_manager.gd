extends Node

enum GameState { TITLE, GAMEPLAY, PAUSE, GAME_OVER, VICTORY }

const VALID_TRANSITIONS: Dictionary = {
	GameState.TITLE: [GameState.GAMEPLAY],
	GameState.GAMEPLAY: [GameState.PAUSE, GameState.GAME_OVER, GameState.VICTORY],
	GameState.PAUSE: [GameState.GAMEPLAY, GameState.TITLE],
	GameState.GAME_OVER: [GameState.TITLE, GameState.GAMEPLAY],
	GameState.VICTORY: [GameState.TITLE, GameState.GAMEPLAY],
}

@export var final_wave: int = 5
@export var breather_seconds: float = 2.0

var current_state: GameState = GameState.TITLE
var wave_spawner: Node = null

var _pending_wave: int = 0
var _breather_remaining: float = 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	current_state = GameState.TITLE
	Events.player_died.connect(_on_player_died)
	Events.wave_cleared.connect(_on_wave_cleared)


func _exit_tree() -> void:
	if Events.player_died.is_connected(_on_player_died):
		Events.player_died.disconnect(_on_player_died)
	if Events.wave_cleared.is_connected(_on_wave_cleared):
		Events.wave_cleared.disconnect(_on_wave_cleared)


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
	current_state = new_state
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


func _on_wave_cleared(n: int) -> void:
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
