extends Area2D

func _ready():
	var sprite = get_node("AnimatedSprite2D")
	if sprite:
		sprite.visible = true  # Make sprite visible
		print("Enemy sprite initialized: ", self)  # Debugging
	else:
		push_error("AnimatedSprite2D not found in Enemy: ", self)

func _on_body_entered(body: Node2D) -> void:
	if "Player" in body.name:
		GameManager._on_enemy_body_entered(body, self)
