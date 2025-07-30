extends CanvasLayer

signal battle_ended
@onready var vulnerability_prompt: Label = $VulnerabilityPrompt

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	var enemy = get_node_or_null("Enemy2")
	if enemy and enemy.has_method("is_in_vulnerable_state") and enemy.is_in_vulnerable_state():
		vulnerability_prompt.visible = true
	else:
		vulnerability_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	print("battle.gd: _unhandled_input received event: ", event)
	if event.is_action_pressed("kill"):
		var enemy = get_node_or_null("Enemy2")
		if enemy and enemy.has_method("is_in_vulnerable_state") and enemy.is_in_vulnerable_state():
			enemy.die()

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
