extends CanvasLayer

signal battle_ended
@onready var enemy2: Node2D = $Enemy2
@onready var vulnerability_prompt: Label = $VulnerabilityPrompt

func _ready() -> void:
	if enemy2:
		enemy2.connect("battle_ended", _on_battle_ended)
		print("battle.gd: Connected battle_ended signal from enemy2.")
	else:
		push_error("Enemy2 node not found in Battle scene!")

func _process(_delta: float) -> void:
	if enemy2 and enemy2.is_in_vulnerable_state():
		vulnerability_prompt.visible = true
	else:
		vulnerability_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("kill"):
		print("battle.gd: 'kill_enemy' input detected!")
		if enemy2 and enemy2.is_in_vulnerable_state():
			print("battle.gd: Calling enemy2.kill_enemy().")
			enemy2.kill_enemy()

func _on_battle_ended():
	print("battle.gd: _on_battle_ended called.")
	visible = false
	set_process(false)
	set_physics_process(false)
	var enemy2_node = get_node("Enemy2")
	if enemy2_node:
		print("battle.gd: enemy2_node is valid. Cleaning up arrows.")
		for arrow in enemy2_node.arrow_pool:
			if is_instance_valid(arrow):
				arrow.disable()
		# Removed enemy2_node.queue_free() from here. GameManager will handle freeing the battle_instance.
	else:
		print("battle.gd: enemy2_node is NOT valid. Cannot cleanup or free.")
	emit_signal("battle_ended")
	print("battle.gd: battle_ended signal emitted.")
