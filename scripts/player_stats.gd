extends Node

var max_health = 3
var current_health = max_health

signal health_changed(new_health)
signal no_health

func take_damage():
	if current_health > 0:
		current_health -= 1
		emit_signal("health_changed", current_health)
		if current_health <= 0:
			emit_signal("no_health")

func get_health():
	return current_health

func reset():
	current_health = max_health
	emit_signal("health_changed", current_health)
