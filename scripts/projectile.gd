extends Area2D

@export var speed: float = 500.0
var direction: Vector2 = Vector2.RIGHT
var hit_delay = 0.05 # Wait 0.1s after collision to check for parry
var is_waiting_hit = false
@onready var sprite = $Sprite2D
signal parried
signal destroyed

func setup(start_position, target_direction):
	position = start_position
	direction = target_direction
	visible = true
	set_physics_process(true)
	is_waiting_hit = false

func _physics_process(delta):
	if not is_waiting_hit:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_parrying"):
		is_waiting_hit = true
		await get_tree().create_timer(hit_delay).timeout
		
		# After waiting, check if the player is in the parry state.
		if body.is_parrying():
			print("Parried!")
			emit_signal("parried")
			if body.has_method("successful_parry"):
				body.successful_parry()
			disable()
		else:
			print("Hit Player")
			body.take_damage()
			disable()

func disable():
	visible = false
	set_physics_process(false)
	is_waiting_hit = false
	emit_signal("destroyed")
