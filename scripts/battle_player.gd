extends CharacterBody2D

enum State { IDLE, PARRY, HURT }
var current_state = State.IDLE

@onready var parry_timer = $ParryTimer
@onready var parry_animation = $AnimatedSprite2D2

func _ready():
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.no_health.connect(_on_no_health)
	parry_animation.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("parry") and current_state == State.IDLE:
		current_state = State.PARRY
		parry_timer.start()

func _on_parry_timer_timeout() -> void:
	current_state = State.IDLE

func take_damage():
	if current_state != State.PARRY:
		current_state = State.HURT
		PlayerStats.take_damage()
		# Add hurt animation or sound here
		await get_tree().create_timer(0.5).timeout # Hurt state duration
		current_state = State.IDLE

func _on_health_changed(new_health):
	print("Player health: ", new_health)

func _on_no_health():
	print("Player died!")
	# Handle player death (e.g., game over screen)

func is_parrying():
	return current_state == State.PARRY

func successful_parry():
	parry_animation.visible = true
	parry_animation.play("default")
	await parry_animation.animation_finished
	parry_animation.visible = false
