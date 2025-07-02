extends CharacterBody2D

var can_parry = false
@onready var parry_timer = $ParryTimer

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("parry"):
		can_parry = true
		parry_timer.start()

func _on_parry_timer_timeout() -> void:
	can_parry = false
