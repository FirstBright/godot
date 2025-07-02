extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var hit_delay = 0.05 
var is_waiting_hit = false
@onready var sprite = $Sprite2D
signal parried

func _ready():
	# 방향에 따라 좌우 반전
	sprite.flip_h = direction.x < 0
func _physics_process(delta):
	if not is_waiting_hit:
		position += direction * speed * delta		

func _on_body_entered(body: Node2D) -> void:
	if body.get_name() == "Player2":
		is_waiting_hit = true
		await get_tree().create_timer(hit_delay).timeout
		if body.can_parry:
			is_waiting_hit = false
			print("Parried!")
			$parry.play(0.0)
			emit_signal("parried")
			disable_arrow()
		else:
			$hurt.play(0.0)
			print("Hit Player")
#			body.take_damage()
			disable_arrow()
			
func disable_arrow():
	visible = false
	set_physics_process(false)
	is_waiting_hit = false
