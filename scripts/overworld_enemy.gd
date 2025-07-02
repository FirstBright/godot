extends Area2D

func _ready():
	var sprite = get_node("AnimatedSprite2D")
	if sprite:
		sprite.visible = true  # 스프라이트 보이도록 설정
		print("Enemy sprite initialized: ", self)  # 디버깅
	else:
		push_error("Sprite2D not found in Enemy: ", self)
		
func _on_body_entered(body: Node2D) -> void:
	if "Player" in body.name:
		GameManager._on_enemy_body_entered(body)
