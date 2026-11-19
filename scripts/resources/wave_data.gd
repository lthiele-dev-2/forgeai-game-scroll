class_name WaveData
extends Resource

@export var wave_number: int = 1
@export var enemy_counts: Dictionary = {}
@export var spawn_interval: float = 1.0
@export var hp_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export var score_values: Dictionary = {}
@export var wave_clear_bonus: int = 250


func get_enemy_types() -> Array[String]:
	var types: Array[String] = []
	for key in enemy_counts.keys():
		types.append(str(key))
	return types


func get_count(enemy_type: String) -> int:
	return int(enemy_counts.get(enemy_type, 0))


func get_total_count() -> int:
	var total: int = 0
	for key in enemy_counts.keys():
		total += int(enemy_counts[key])
	return total


func get_score_value(enemy_type: String) -> int:
	return int(score_values.get(enemy_type, 0))
