class_name Boss
extends Enemy

const ENEMY_BULLET_SCENE_PATH: String = "res://scenes/entities/projectiles/enemy_bullet.tscn"

@export var move_speed: float = 60.0
@export var deceleration: float = 400.0
@export var attack_range: float = 900.0
@export var preferred_distance: float = 700.0
@export var player_group: String = "player"
@export var is_boss: bool = true
@export var phase_fire_rate_multipliers: Array[float] = [1.0, 2.0]
@export var phase_burst_counts: Array[int] = [1, 5]
@export var phase_spread_degrees: Array[float] = [0.0, 60.0]

var target: Node2D = null

var _weapon: EnemyWeapon = null
var _phases: BossPhases = null


func _ready() -> void:
	super._ready()
	_weapon = get_node_or_null("Weapon") as EnemyWeapon
	_phases = get_node_or_null("BossPhases") as BossPhases
	if _weapon != null and _weapon.bullet_scene == null and ResourceLoader.exists(ENEMY_BULLET_SCENE_PATH):
		_weapon.set_bullet_scene(load(ENEMY_BULLET_SCENE_PATH) as PackedScene)
	if _phases != null and not _phases.phase_changed.is_connected(_on_phase_changed):
		_phases.phase_changed.connect(_on_phase_changed)
	_apply_phase()


func _exit_tree() -> void:
	super._exit_tree()
	if _phases != null and _phases.phase_changed.is_connected(_on_phase_changed):
		_phases.phase_changed.disconnect(_on_phase_changed)


func setup_wave(type: String, hp_value: float, fire_rate_value: float, score: int) -> void:
	super.setup_wave(type, hp_value, fire_rate_value, score)
	if _phases != null:
		_phases.reset()
	_apply_phase()


func take_damage(amount: float) -> void:
	if not is_alive:
		return
	hp -= amount
	if _phases != null and max_hp > 0.0:
		_phases.update_phase(hp / max_hp)
	if hp <= 0.0:
		hp = 0.0
		_die()


func set_target(node: Node2D) -> void:
	target = node


func get_phases() -> BossPhases:
	return _phases


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	var player: Node2D = _resolve_player()
	var in_range: bool = player != null
	if player != null:
		var dx: float = player.global_position.x - global_position.x
		if absf(dx) > attack_range:
			velocity.x = signf(dx) * move_speed
			in_range = false
		elif absf(dx) > preferred_distance:
			velocity.x = signf(dx) * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.y = 0.0
	move_and_slide()
	if in_range and _weapon != null:
		_weapon.hold_fire(delta)


func _on_phase_changed(_phase: int) -> void:
	_apply_phase()


func _apply_phase() -> void:
	if _weapon == null:
		return
	var phase: int = _phases.current_phase if _phases != null else 1
	var rate_idx: int = clampi(phase - 1, 0, maxi(phase_fire_rate_multipliers.size() - 1, 0))
	_weapon.set_fire_rate(fire_rate * phase_fire_rate_multipliers[rate_idx])
	if phase_burst_counts.size() > 0:
		_weapon.burst_count = phase_burst_counts[clampi(phase - 1, 0, phase_burst_counts.size() - 1)]
	if phase_spread_degrees.size() > 0:
		_weapon.spread_degrees = phase_spread_degrees[clampi(phase - 1, 0, phase_spread_degrees.size() - 1)]


func _resolve_player() -> Node2D:
	if target != null and is_instance_valid(target):
		return target
	if get_tree() != null:
		return get_tree().get_first_node_in_group(player_group) as Node2D
	return null
