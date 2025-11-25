extends AttackComponent

# This component performs a timed, non-projectile attack (e.g., a slash or explosion).

func fire(pattern: Resource, target: Node2D) -> int:
	# Ensure the pattern is the correct type.
	if not pattern is TimedAttackPattern:
		print("ERROR: Wrong pattern type provided to TimedAttack.")
		return 0

	var owner_enemy = get_owner()
	if not owner_enemy or not owner_enemy is CharacterBody2D:
		print("ERROR: TimedAttackComponent must be a child of a CharacterBody2D.")
		return 0

	# The fire function becomes async to handle the timing.
	await _perform_attack(pattern, owner_enemy, target)

	# For now, timed attacks cannot be parried, so we return 0.
	# We can change this later if we add a parry mechanic for them.
	return 0


func _perform_attack(pattern: TimedAttackPattern, owner_enemy: CharacterBody2D, target: Node2D):
	var animated_sprite = owner_enemy.get_node_or_null("AnimatedSprite2D")

	# 1. Startup Phase
	if animated_sprite and pattern.startup_animation != "":
		animated_sprite.play(pattern.startup_animation)
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(pattern.startup_delay).timeout
	if animated_sprite and animated_sprite.sprite_frames.has_animation(pattern.animation_name):
		animated_sprite.play(pattern.animation_name)

	# 3. Create and check the hitbox
	var hitbox = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	shape.size = pattern.area_size
	collision_shape.shape = shape
	hitbox.add_child(collision_shape)

	# Position the hitbox directly on the target's current position.
	hitbox.global_position = target.global_position

	owner_enemy.add_child(hitbox)

	# Check for the player immediately
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"): # Assuming your player is in the "player" group
			print("Player hit by timed attack!")
			if body.has_method("take_damage"):
				body.take_damage()
			else:
				push_error("Player in group 'player' but has no take_damage method")

	# Play sound if it exists
	var audio_player = owner_enemy.get_node_or_null("AudioStreamPlayer")
	if audio_player and pattern.attack_sound:
		audio_player.stream = pattern.attack_sound
		audio_player.play()

	# 4. Active Duration
	await get_tree().create_timer(pattern.active_duration).timeout

	# 5. Cleanup
	hitbox.queue_free()
