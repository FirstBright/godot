extends Node2D

@export var enemy_scene: PackedScene
var enemy_pool = []
var max_enemy_count = 5
var spawn_interval_x = 200  # Fixed distance between enemies in pixels

func _ready():
	if not enemy_scene:
		push_error("Enemy scene not set in EnemySpawner")
		return
	# Create a pool of enemies
	for i in range(max_enemy_count):
		var enemy = enemy_scene.instantiate()
		enemy.visible = false
		enemy.add_to_group("enemies")
		# Connect body_entered signal to pass both body and enemy
		enemy.body_entered.connect(func(body): GameManager._on_enemy_body_entered(body, enemy))
		add_child(enemy)
		enemy_pool.append(enemy)
		print("Enemy ", i, " added to pool at ", enemy.global_position)
	# Connect to GameManager signals
	GameManager.signal_references_set.connect(_on_game_manager_references_set)
	GameManager.enemy_freed.connect(_on_enemy_freed)

func _on_game_manager_references_set():
	spawn_enemies(max_enemy_count)

func _on_enemy_freed(enemy: Node2D):
	# Remove the freed enemy from the pool
	if enemy in enemy_pool:
		enemy_pool.erase(enemy)
		print("Enemy freed and removed from pool: ", enemy)

func spawn_enemies(number_to_spawn):
	var player = GameManager.player
	if not player:
		push_error("Player not found for spawning enemies")
		return

	# Clean up any invalid enemies in the pool
	enemy_pool = enemy_pool.filter(func(e): return is_instance_valid(e))
	print("Valid enemies in pool: ", enemy_pool.size())

	# Calculate how many more enemies are needed
	var current_enemies = enemy_pool.size()
	var enemies_needed = max_enemy_count - current_enemies
	# Create new enemies if needed
	for i in range(enemies_needed):
		var enemy = enemy_scene.instantiate()
		enemy.visible = false
		enemy.add_to_group("enemies")
		enemy.body_entered.connect(func(body): GameManager._on_enemy_body_entered(body, enemy))
		add_child(enemy)
		enemy_pool.append(enemy)
		print("New enemy ", i, " added to pool at ", enemy.global_position)

	var spawned_count = 0
	# Calculate x-positions for enemies at regular intervals on the left
	var base_x = player.global_position.x
	var offsets = [1,2,3,4,5]  # Multipliers for spawn_interval_x, all negative for left side
	for i in range(min(number_to_spawn, max_enemy_count)):
		if i >= enemy_pool.size():
			push_error("Enemy pool index out of bounds: ", i)
			break
		var enemy = enemy_pool[i]
		if is_instance_valid(enemy) and not enemy.visible:
			# Spawn enemies at regular x-intervals on the left and similar y-position
			var spawn_x = base_x + offsets[i] * spawn_interval_x
			var spawn_y = player.global_position.y + randf_range(-5, 5)  # Small y-offset
			enemy.global_position = Vector2(spawn_x, spawn_y)
			enemy.visible = true
			enemy.set_physics_process(true)
			spawned_count += 1
			print("Enemy ", i, " spawned at ", enemy.global_position)
			if spawned_count >= number_to_spawn:
				break

func get_available_enemy():
	for enemy in enemy_pool:
		if is_instance_valid(enemy) and not enemy.visible:
			return enemy
	return null

func despawn_enemies():
	# Clean up invalid enemies first
	enemy_pool = enemy_pool.filter(func(e): return is_instance_valid(e))
	for enemy in enemy_pool:
		if is_instance_valid(enemy) and enemy.visible:
			enemy.visible = false
			enemy.set_physics_process(false)
			print("Enemy despawned at ", enemy.global_position)
