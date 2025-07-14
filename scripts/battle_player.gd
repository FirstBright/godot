extends CharacterBody2D

enum State { IDLE, PARRY, HURT }
var current_state = State.IDLE

@onready var parry_timer = $ParryTimer
@onready var parry_animation = $AnimatedSprite2D2
@onready var parry_sound = $parry # Assuming the node is named 'parry'
@onready var hurt_sound = $hurt   # Assuming the node is named 'hurt'
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.no_health.connect(_on_no_health)
	parry_animation.visible = false
	# This is the total duration of the parry state.
	parry_timer.wait_time = 0.3

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("parry") and current_state == State.IDLE:
		current_state = State.PARRY
		parry_timer.start()

func _on_parry_timer_timeout() -> void:
	current_state = State.IDLE

func take_damage():
	if current_state == State.PARRY:
		return # Immune while in parry state
	animated_sprite_2d.play("hit")
	hurt_sound.play()
	current_state = State.HURT
	PlayerStats.take_damage()
	if not is_inside_tree():
		return
	
	await get_tree().create_timer(0.3).timeout # Hurt state duration
	current_state = State.IDLE

func _on_health_changed(new_health):
	print("Player health: ", new_health)

func _on_no_health():
	print("Player died!")
	# Handle player death (e.g., game over screen)

func is_parrying():
	return current_state == State.PARRY

func successful_parry():
	animated_sprite_2d.play("parrying")
	parry_sound.play()
	parry_animation.visible = true
	parry_animation.play("default")
	# The await call was removed. The animation will play without blocking.
	# A timer is used to hide it after it's finished.
	get_tree().create_timer(parry_animation.sprite_frames.get_frame_count("default") * (1 / parry_animation.frame_progress)).connect("timeout", func(): parry_animation.visible = false)


func _on_animated_sprite_2d_animation_finished():
	animated_sprite_2d.play("default") 
