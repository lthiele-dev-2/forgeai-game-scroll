class_name BossPhases
extends Node

signal phase_changed(phase: int)

@export var hp_thresholds: Array[float] = [1.0, 0.5]

var current_phase: int = 1


func get_phase_for_ratio(hp_ratio: float) -> int:
	var phase: int = 1
	for i in range(hp_thresholds.size()):
		if hp_ratio <= hp_thresholds[i]:
			phase = i + 1
	return phase


func update_phase(hp_ratio: float) -> bool:
	var new_phase: int = get_phase_for_ratio(hp_ratio)
	if new_phase == current_phase:
		return false
	current_phase = new_phase
	phase_changed.emit(current_phase)
	return true


func reset() -> void:
	current_phase = 1
