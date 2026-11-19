class_name EnemyStats
extends Resource

# stats[enemy_type] = {"scene": "res://...", "hp": int, "fire_rate": float, "score": int}
@export var stats: Dictionary = {}


func has_type(enemy_type: String) -> bool:
	return stats.has(enemy_type)


func get_scene_path(enemy_type: String) -> String:
	return str(_entry(enemy_type).get("scene", ""))


func get_base_hp(enemy_type: String) -> int:
	return int(_entry(enemy_type).get("hp", 0))


func get_base_fire_rate(enemy_type: String) -> float:
	return float(_entry(enemy_type).get("fire_rate", 0.0))


func get_base_score(enemy_type: String) -> int:
	return int(_entry(enemy_type).get("score", 0))


func _entry(enemy_type: String) -> Dictionary:
	if stats.has(enemy_type):
		return stats[enemy_type]
	return {}
