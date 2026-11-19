class_name PlayerShot
extends Area2D

signal returned_to_pool(shot: PlayerShot)

@export var speed: float = 900.0
@export var max_lifetime: float = 3.0

var damage: float = 10.0
var direction: Vector2 = Vector2.RIGHT
var level_bounds: Rect2 = Rect2()
var is_active: bool = false
var pool: ObjectPool = null

var _lifetime: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _exit_tree() -> void:
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)


func fire(pos: Vector2, dir: Vector2, dmg: float, shot_pool: ObjectPool, bounds: Rect2) -> void:
	global_position = pos
	direction = dir.normalized()
	damage = dmg
	pool = shot_pool
	level_bounds = bounds
	_lifetime = 0.0
	is_active = true
	monitoring = true
	show()


func release() -> void:
	if not is_active:
		return
	is_active = false
	monitoring = false
	if pool != null and is_instance_valid(pool):
		pool.release(self)
	returned_to_pool.emit(self)


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	_lifetime += delta
	global_position += direction * speed * delta
	if _lifetime >= max_lifetime or (level_bounds.has_area() and not level_bounds.has_point(global_position)):
		release()


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	var enemy: Node = area.get_parent()
	if enemy != null and enemy.has_method("take_damage"):
		var mult_value: Variant = enemy.get("enemy_multiplier")
		var multiplier: float = 1.0 if mult_value == null else float(mult_value)
		enemy.call("take_damage", damage * multiplier)
	release()
