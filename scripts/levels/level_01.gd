class_name Level01
extends Node2D

const MECH_SCENE: PackedScene = preload("res://scenes/entities/mech.tscn")

@export var bounds: Rect2 = Rect2(Vector2(0.0, -540.0), Vector2(5760.0, 1080.0))
@export var mech_spawn_position: Vector2 = Vector2(480.0, 0.0)

@onready var wave_spawner: Node2D = $WaveSpawner
@onready var entities: Node2D = $Entities


func _ready() -> void:
	spawn_mech()


func spawn_mech() -> Mech:
	var mech: Mech = MECH_SCENE.instantiate()
	mech.position = mech_spawn_position
	entities.add_child(mech)
	mech.set_bounds(bounds)
	if wave_spawner.has_method("set_bounds"):
		wave_spawner.set_bounds(bounds)
	return mech


func get_spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child: Node in wave_spawner.get_children():
		if child is Marker2D:
			markers.append(child)
	return markers
