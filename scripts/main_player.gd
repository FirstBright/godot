extends CharacterBody2D

const SPEED = 10000.0

func _ready():
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.no_health.connect(_on_no_health)

func _physics_process(delta: float) -> void:
	velocity.x = SPEED * delta
	move_and_slide()

func playPause():
	$AnimatedSprite2D.play("idle")

func playRun():
	$AnimatedSprite2D.play("run")

func _on_health_changed(new_health):
	print("Player health: ", new_health)

func _on_no_health():
	print("Player died!")
	# Handle player death (e.g., game over screen)
