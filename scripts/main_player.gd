extends CharacterBody2D


const SPEED = 10000.0


func _physics_process(delta: float) -> void:	
	velocity.x = SPEED	*delta
	move_and_slide()

func playPause():
	$AnimatedSprite2D.play("idle")
	
func playRun():
	$AnimatedSprite2D.play("run")
