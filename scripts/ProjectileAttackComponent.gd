extends AttackComponent

# This component is responsible for firing projectiles based on a pattern.

var _parry_count = 0
var _active_projectiles = 0
var _pattern_finished = false


# This function now returns the number of successful parries.
func fire(pattern: Resource, target: Node2D) -> int:
	if not pattern or not pattern.projectile_scene:
		print("ERROR: Invalid pattern or projectile scene provided to ProjectileAttack.")
		return 0

	if not is_instance_valid(target):
		print("ERROR: Target is not valid.")
		return 0

	var owner_enemy = get_owner()
	if not owner_enemy or not owner_enemy is CharacterBody2D:
		print("ERROR: AttackComponent must be a child of a CharacterBody2D.")
		return 0

	# This function now becomes async itself to properly manage the sequence.
	await _fire_sequence(pattern, target, owner_enemy)
	return _parry_count


func _fire_sequence(pattern: ProjectileAttackPattern, target: Node2D, owner_enemy: Node2D) -> int:
	_parry_count = 0
	_active_projectiles = pattern.timings.size()
	_pattern_finished = false

	var animated_sprite = owner_enemy.get_node_or_null("AnimatedSprite2D")

	# Startup Phase
	if animated_sprite and pattern.startup_animation != "":
		animated_sprite.play(pattern.startup_animation)
		await animated_sprite.animation_finished
	else:
		# Use the startup delay from the pattern
		if pattern.startup_delay > 0:
			await get_tree().create_timer(pattern.startup_delay).timeout

	for shot_delay in pattern.timings:
		if not is_instance_valid(owner_enemy) or not is_instance_valid(target):
			break

		var projectile = pattern.projectile_scene.instantiate()
		
		# Set the speed from the pattern
		if projectile.has_method("set_speed"):
			projectile.set_speed(pattern.projectile_speed)
		
		projectile.z_index = 1 # A high value to ensure it's on top
		projectile.parried.connect(_on_projectile_parried)
		projectile.destroyed.connect(_on_projectile_destroyed)
		# Add it to the scene tree as a sibling of the enemy to ensure it's on the same layer.
		owner_enemy.get_parent().add_child(projectile)

		# Play sound if it exists
		var audio_player = owner_enemy.get_node_or_null("AudioStreamPlayer")
		if audio_player and pattern.attack_sound:
			audio_player.stream = pattern.attack_sound
			audio_player.play()

		var start_pos = owner_enemy.global_position
		var direction = (target.global_position - start_pos).normalized()
		
		if projectile.has_method("setup"):
			projectile.setup(start_pos, direction)
		else:
			projectile.global_position = start_pos

		await get_tree().create_timer(shot_delay).timeout
	
	# Wait until all projectiles are resolved
	while _active_projectiles > 0:
		await get_tree().create_timer(0.1).timeout


	print("Pattern finished. Final parry count: ", _parry_count, " / Required: ", pattern.timings.size())
	return _parry_count

func _on_projectile_parried():
	_parry_count += 1
	print("Parry count: ", _parry_count)

func _on_projectile_destroyed():
	_active_projectiles -= 1
