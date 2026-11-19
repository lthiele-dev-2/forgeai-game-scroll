class_name Level01
extends Node2D

const MECH_SCENE: PackedScene = preload("res://scenes/entities/mech.tscn")

@export var bounds: Rect2 = Rect2(Vector2(0.0, -540.0), Vector2(5760.0, 1080.0))
@export var mech_spawn_position: Vector2 = Vector2(480.0, 0.0)

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var entities: Node2D = $Entities
@onready var projectiles: Node2D = $Projectiles


func _ready() -> void:
	GameManager.set_wave_spawner(wave_spawner)
	spawn_mech()


func _exit_tree() -> void:
	if is_instance_valid(GameManager) and GameManager.wave_spawner == wave_spawner:
		GameManager.set_wave_spawner(null)


func spawn_mech() -> Mech:
	var mech: Mech = MECH_SCENE.instantiate()
	mech.position = mech_spawn_position
	entities.add_child(mech)
	mech.set_bounds(bounds)
	mech.set_projectiles_container(projectiles)
	if wave_spawner.has_method("set_bounds"):
		wave_spawner.set_bounds(bounds)
	return mech


func start_wave(n: int) -> bool:
	return wave_spawner.spawn_wave(n)


func get_spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child: Node in wave_spawner.get_children():
		if child is Marker2D:
			markers.append(child)
	return markers
