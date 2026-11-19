class_name Enemy
extends CharacterBody2D

@export var contact_damage: float = 10.0
@export var enemy_multiplier: float = 1.0

var enemy_type: String = ""
var hp: float = 1.0
var max_hp: float = 1.0
var fire_rate: float = 1.0
var score_value: int = 0
var is_alive: bool = true
var pool: ObjectPool = null

var _hitbox: Area2D = null


func _ready() -> void:
	_hitbox = get_node_or_null("Hitbox") as Area2D
	if _hitbox != null and not _hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		_hitbox.area_entered.connect(_on_hitbox_area_entered)


func _exit_tree() -> void:
	if _hitbox != null and _hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		_hitbox.area_entered.disconnect(_on_hitbox_area_entered)


func setup_wave(type: String, hp_value: float, fire_rate_value: float, score: int) -> void:
	enemy_type = type
	hp = hp_value
	max_hp = hp_value
	fire_rate = fire_rate_value
	score_value = score
	is_alive = true


func take_damage(amount: float) -> void:
	if not is_alive:
		return
	hp -= amount
	if hp <= 0.0:
		hp = 0.0
		_die()


func get_hitbox() -> Area2D:
	return _hitbox


func _die() -> void:
	if not is_alive:
		return
	is_alive = false
	Events.enemy_destroyed.emit(enemy_type, global_position, score_value)
	if pool != null and is_instance_valid(pool):
		pool.release(self)
	else:
		queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	var dmg: float = contact_damage
	var damage_value: Variant = area.get("damage")
	if damage_value != null:
		dmg = float(damage_value)
	take_damage(dmg)
