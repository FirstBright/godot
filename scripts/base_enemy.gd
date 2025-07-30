extends CharacterBody2D

# EXPORTED VARIABLES (to be configured per enemy type)
@export var health: int = 3
@export var attack_patterns: Array[AttackPattern]
@export var death_animation_name: String = "death"

# Components
@onready var attack_component: AttackComponent = $AttackComponent

# Internal state machine
enum State { IDLE, ATTACKING, VULNERABLE, DEAD }
var current_state = State.IDLE

# Signals
signal battle_ended

var _target: Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	# No longer connecting to pattern_parried signal, as fire() now returns the count.
	pass

func start_battle(target: Node2D):
	_target = target
	# Ensure we start with the default animation and in the IDLE state
	animated_sprite.play("default")
	current_state = State.IDLE
	# Kick off the first attack
	start_attack()

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func start_attack():
	if current_state != State.IDLE:
		return
	
	current_state = State.ATTACKING
	_start_next_attack_pattern()

func _start_next_attack_pattern():
	if attack_patterns.is_empty():
		print("ERROR: No attack patterns defined for this enemy.")
		current_state = State.IDLE # Go back to idle if no patterns
		return

	var chosen_pattern = attack_patterns.pick_random()
	
	if not is_instance_valid(_target):
		print("ERROR: Target is not valid.")
		current_state = State.IDLE
		return

	if attack_component:
		var parry_count = await attack_component.fire(chosen_pattern, _target)
		
		print("BaseEnemy: Deciding vulnerability. Received parry_count: ", parry_count, " Pattern size: ", chosen_pattern.timings.size())

		# Now, the BaseEnemy decides what to do based on the result.
		if parry_count >= chosen_pattern.timings.size():
			print("BaseEnemy: Pattern fully parried! Becoming vulnerable.")
			become_vulnerable()
		else:
			# If the attack finishes and we weren't parried, go back to idle for a cooldown.
			print("BaseEnemy: Pattern not fully parried. Returning to idle.")
			current_state = State.IDLE
			await get_tree().create_timer(2.0).timeout # 2 second cooldown
			start_attack() # Start the next attack

func become_vulnerable():
	current_state = State.VULNERABLE
	print("Enemy is now VULNERABLE. Press W to attack!")
	
	if animated_sprite.sprite_frames.has_animation("vulnerable"):
		animated_sprite.play("vulnerable")

	var vulnerability_timer = get_tree().create_timer(3.0)
	await vulnerability_timer.timeout

	if current_state == State.VULNERABLE:
		print("Vulnerability window missed. Returning to idle.")
		animated_sprite.play("default")
		current_state = State.IDLE
		start_attack()

func is_in_vulnerable_state() -> bool:
	return current_state == State.VULNERABLE

func die():
	# The player can only kill the enemy when it's vulnerable
	if current_state != State.VULNERABLE:
		return

	current_state = State.DEAD
	
	# Play death animation before freeing
	if animated_sprite.sprite_frames.has_animation(death_animation_name):
		animated_sprite.play(death_animation_name)
		await animated_sprite.animation_finished
	
	emit_signal("battle_ended")
	queue_free()
