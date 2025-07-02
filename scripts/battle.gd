extends CanvasLayer

signal battle_ended
@onready var enemy2: Node2D = $Enemy2

func _ready() -> void:
	if enemy2:
		enemy2.connect("battle_ended", _on_battle_ended)
	else:
		push_error("Enemy2 node not found in Battle scene!")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("kill"):
		if enemy2 and enemy2.is_in_vulnerable_state():
			enemy2.kill_enemy()

func _on_battle_ended():
	visible = false
	set_process(false)
	set_physics_process(false)
	var enemy2_node = get_node("Enemy2")
	if enemy2_node:
		for arrow in enemy2_node.arrow_pool:
			if is_instance_valid(arrow):
				arrow.visible = false
				arrow.set_physics_process(false)
				arrow.is_waiting_hit = false
	emit_signal("battle_ended")
	print("be")
