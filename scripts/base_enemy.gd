extends CharacterBody2D

# EXPORTED VARIABLES (to be configured per enemy type)
@export var health: int = 3
@export var attack_patterns: Array[Resource]
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

	var attack_component_node: Node

	# Check the type of the pattern resource to find the correct component.
	if chosen_pattern is ProjectileAttackPattern:
		# The original node for projectiles was named AttackComponent.
		attack_component_node = get_node_or_null("AttackComponent")
	elif chosen_pattern is TimedAttackPattern:
		attack_component_node = get_node_or_null("TimedAttack")
	else:
		print("ERROR: Unknown attack pattern type!")
		current_state = State.IDLE
		return

	if not attack_component_node:
		print("ERROR: Could not find a compatible AttackComponent node for the chosen pattern.")
		current_state = State.IDLE
		return

	# We have a valid component, so cast it and fire.
	var component_to_fire = attack_component_node as AttackComponent
	var parry_count = await component_to_fire.fire(chosen_pattern, _target)

	# --- Vulnerability Logic ---
	# For projectile attacks, we check if it was fully parried.
	if chosen_pattern is ProjectileAttackPattern:
		if parry_count >= chosen_pattern.timings.size():
			print("BaseEnemy: Projectile pattern fully parried! Becoming vulnerable.")
			become_vulnerable()
		else:
			print("BaseEnemy: Projectile pattern not fully parried. Returning to idle.")
			_return_to_idle_and_cooldown()
	# For timed attacks, we can decide on a different logic.
	# For now, let's say they never make the enemy vulnerable.
	elif chosen_pattern is TimedAttackPattern:
		print("BaseEnemy: Timed attack finished. Returning to idle.")
		_return_to_idle_and_cooldown()

func _return_to_idle_and_cooldown():
	current_state = State.IDLE
	await get_tree().create_timer(2.0).timeout # 2-second cooldown
	if current_state == State.IDLE: # Check if we weren't interrupted
		start_attack()

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
