class_name ChargeBlast
extends Area2D

signal blast_finished(blast: ChargeBlast)

const DESTROY_DAMAGE_MULTIPLIER: float = 100.0

@export var blast_duration: float = 0.5
@export var screen_size: Vector2 = Vector2(1920.0, 1080.0)

var damage: float = 0.0
var is_active: bool = false
var level_bounds: Rect2 = Rect2()

var _timer: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	var rect: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	if rect != null:
		rect.size = screen_size
	is_active = false
	monitoring = false
	hide()


func _exit_tree() -> void:
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)


func fire(pos: Vector2, dmg: float, bounds: Rect2) -> void:
	damage = dmg
	level_bounds = bounds
	var rect: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	if bounds.has_area():
		global_position = bounds.get_center()
		if rect != null:
			rect.size = bounds.size
	else:
		global_position = pos
		if rect != null:
			rect.size = screen_size
	_timer = 0.0
	is_active = true
	monitoring = true
	show()


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	_timer += delta
	if _timer >= blast_duration:
		_deactivate()


func _deactivate() -> void:
	if not is_active:
		return
	is_active = false
	monitoring = false
	hide()
	blast_finished.emit(self)


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	var enemy: Node = area.get_parent()
	if enemy == null or not enemy.has_method("take_damage"):
		return
	var boss_flag: Variant = enemy.get("is_boss")
	if boss_flag != null and bool(boss_flag):
		enemy.call("take_damage", damage)
	else:
		enemy.call("take_damage", damage * DESTROY_DAMAGE_MULTIPLIER)
