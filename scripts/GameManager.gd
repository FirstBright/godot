extends Node

enum GameState { MAIN_GAME, BATTLE, TRANSITION }
var current_state = GameState.MAIN_GAME
var battle_instance = null
var player_start_pos: Vector2
var game_scene = null
var player = null
var ui_animation_player = null
var ui_instance = null
var collided_enemy = null
var enemy_spawner = null
var EndingScene = preload("res://scenes/ending.tscn")
var ending_instance = null

var current_floor = 1
var enemies_defeated_on_current_floor = 0
var enemies_per_floor = 5
var save_file_path = "user://savegame.json"
var initial_y_position: float = 0.0  # Store the initial y-position
var floor_height: float = 300.0  # Consistent height per floor

signal signal_references_set
signal enemy_freed(enemy: Node2D)

func _ready():
	PlayerStats.no_health.connect(_on_player_no_health)
	load_game()
	signal_references_set.connect(_on_references_set)


func _on_player_no_health():
	if current_state == GameState.TRANSITION:
		print("GameManager: Ignoring no_health signal, already in TRANSITION state")
		return
	print("GameManager: Player has died. Cleaning up battle and showing ending scene.")
	current_state = GameState.TRANSITION
	
	# Clean up battle scene
	if battle_instance and is_instance_valid(battle_instance):
		battle_instance.queue_free()
		battle_instance = null
		print("GameManager: Battle scene removed")
	
	# Clean up collided enemy
	if collided_enemy and is_instance_valid(collided_enemy):
		emit_signal("enemy_freed", collided_enemy)
		collided_enemy.queue_free()
		collided_enemy = null
		print("GameManager: Collided enemy freed")
	
	# Hide and pause player
	if player:
		player.visible = false
		player.set_physics_process(false)
		print("GameManager: Player hidden and physics paused")
	
	# Stop background music
	if Music:
		if Music.get("enable") != null:
			if Music.enable:
				Music.stop()
				print("GameManager: Background music stopped (enable = true)")
		else:
			Music.stop()
			print("GameManager: Background music stopped (no enable variable)")
	else:
		push_error("GameManager: Music autoload not found")
	
	# Transition back to main game state
	current_state = GameState.MAIN_GAME
	
	# Instantiate and add ending scene (CanvasLayer root)
	if ending_instance == null:
		ending_instance = EndingScene.instantiate()
		if game_scene:
			game_scene.add_child(ending_instance)
			await get_tree().process_frame
			if not ending_instance.is_inside_tree():
				push_error("GameManager: Ending scene not in tree after add_child")
				current_state = GameState.MAIN_GAME
				return
			print("GameManager: Ending scene instantiated and added to game_scene")
		else:
			push_error("GameManager: game_scene is null, cannot add ending scene")
			current_state = GameState.MAIN_GAME
			return
		
		# Ensure the ending scene is visible
		ending_instance.visible = true
		
		var animated_sprite = ending_instance.get_node_or_null("AnimatedSprite2D")
		if animated_sprite and animated_sprite is AnimatedSprite2D:
			animated_sprite.visible = true
			animated_sprite.play("default")
		else:
			push_error("GameManager: AnimatedSprite2D not found in ending.tscn")
		
		# Play sound
		var sound = ending_instance.get_node_or_null("Sound")
		if sound and (sound is AudioStreamPlayer or sound is AudioStreamPlayer2D):
			if sound.stream:
				sound.volume_db = 0.0  # Ensure audible volume
				sound.play()
				print("GameManager: Ending scene sound played, volume_db = ", sound.volume_db)
			else:
				push_error("GameManager: Sound node has no stream assigned")
		else:
			push_error("GameManager: Sound node not found or invalid in ending.tscn")
		
	await get_tree().create_timer(2.0).timeout
	
	# Show game over screen
	if ui_instance:
		ui_instance.show_game_over_screen()
		print("GameManager: Game over screen shown")
	else:
		push_error("GameManager: UI instance not found, cannot show game over screen")
		
	current_state = GameState.MAIN_GAME	
	
func restart_stage():
	current_state = GameState.MAIN_GAME
	# Keep current_floor, reset enemies defeated
	enemies_defeated_on_current_floor = 0
	save_game()  # Save the current floor
	if ui_instance:
		ui_instance.hide_game_over_screen()
		ui_instance.update_floor_label(current_floor)
	# Reset player stats and reload the scene
	if ending_instance and is_instance_valid(ending_instance):
		ending_instance.queue_free()
		ending_instance = null
	PlayerStats.reset()
	if Music:
		if Music.get("enable") != null:
			if Music.enable:
				Music.play()
				print("GameManager: Background music resumed (enable = true)")
		else:
			Music.play()
			print("GameManager: Background music resumed (no enable variable)")
	else:
		push_error("GameManager: Music autoload not found")
	get_tree().reload_current_scene()

func _on_regame_requested():
	print("Regame requested.")
	# Keep current_floor, reset enemies defeated
	enemies_defeated_on_current_floor = 0
	save_game()
	restart_stage()
	
func _on_restart_requested():
	print("Restart requested.")
	# Reset to 1st floor and delete save file
	if FileAccess.file_exists(save_file_path):
		var dir = DirAccess.open("user://")
		if dir:
			var err = dir.remove(save_file_path)
			if err == OK:
				print("Save file deleted: ", save_file_path)
			else:
				push_error("Failed to delete save file: ", err)
	current_floor = 1
	enemies_defeated_on_current_floor = 0
	save_game()
	restart_stage()

func _on_exit_requested():
	print("Exit requested. Quitting game.")
	get_tree().quit()

func save_game():
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var data = {
			"current_floor": current_floor
		}
		file.store_string(JSON.stringify(data))
		file.close()
		print("Saved game: current_floor = ", current_floor)
	else:
		push_error("Failed to open save file for writing: ", save_file_path)

func load_game():
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data and data.has("current_floor"):
				current_floor = data["current_floor"]
			else:
				current_floor = 1
			file.close()
		else:
			current_floor = 1
	else:
		current_floor = 1
	print("Loaded game: current_floor = ", current_floor)
	if ui_instance:
		ui_instance.update_floor_label(current_floor)

func set_game_scene_references(scene: Node):
	game_scene = scene
	player = game_scene.get_node("Player")
	ui_animation_player = game_scene.get_node("UI/AnimationPlayer")
	enemy_spawner = game_scene.get_node("EnemySpawner")
	ui_instance = game_scene.get_node("UI")
	if ui_instance:
		ui_instance.regame_requested.connect(_on_regame_requested)
		ui_instance.restart_requested.connect(_on_restart_requested)
		ui_instance.exit_requested.connect(_on_exit_requested)
		ui_instance.update_floor_label(current_floor)
	else:
		push_error("UI node not found in Game scene")
	if not player:
		push_error("Player node not found in Game scene")
	else:
		# Store initial y-position and set player position for the current floor
		if initial_y_position == 0.0:
			initial_y_position = player.global_position.y
		player.global_position = Vector2(0, initial_y_position - (current_floor - 1) * floor_height)
		player_start_pos = player.global_position
		print("Player positioned at: ", player.global_position)

	if not ui_animation_player:
		push_error("UI/AnimationPlayer node not found in Game scene")
	if not enemy_spawner:
		push_error("EnemySpawner node not found in Game scene")
	emit_signal("signal_references_set")

func _on_references_set():
	# Spawn initial enemies after references are set
	if enemy_spawner:
		enemy_spawner.spawn_enemies(enemies_per_floor)
	else:
		push_error("EnemySpawner not set, cannot spawn enemies")

func _on_enemy_body_entered(body: Node2D, enemy: Node2D):
	if current_state != GameState.MAIN_GAME:
		print("Ignoring collision, not in MAIN_GAME state: ", current_state)
		return
	if body.name == "Player":
		current_state = GameState.TRANSITION
		player_start_pos = body.global_position
		body.set_physics_process(false)
		body.velocity = Vector2.ZERO
		body.playPause()
		
		collided_enemy = enemy
		
		if ui_animation_player:
			ui_animation_player.play("TransIn")
			await ui_animation_player.animation_finished
		start_battle()

var BattleScene = preload("res://scenes/battle.tscn")

func start_battle():
	if not battle_instance:
		battle_instance = BattleScene.instantiate()
		battle_instance.battle_ended.connect(_on_battle_ended)
		game_scene.call_deferred("add_child", battle_instance)
		print("Battle instance created and added")
	current_state = GameState.BATTLE
	if ui_animation_player:
		ui_animation_player.play("TransOut")
		await ui_animation_player.animation_finished
		var enemy2 = battle_instance.get_node("Enemy2")
		if enemy2:
			enemy2.start_battle()

func _on_battle_ended():
	print("GameManager: Battle ended.")
	current_state = GameState.TRANSITION
	enemies_defeated_on_current_floor += 1

	if enemies_defeated_on_current_floor >= enemies_per_floor:
		current_floor += 1
		enemies_defeated_on_current_floor = 0
		save_game()
		if ui_instance:
			ui_instance.update_floor_label(current_floor)
		
		# Despawn old enemies
		if enemy_spawner:
			enemy_spawner.despawn_enemies()

		# Move player to a new floor (upward, negative y)
		var new_y = player.global_position.y - floor_height
		player.global_position = Vector2(0, new_y)
		player_start_pos = player.global_position
		print("Moved to floor ", current_floor, " at y = ", new_y)

		# Spawn new enemies for the new floor
		if enemy_spawner:
			enemy_spawner.spawn_enemies(enemies_per_floor)

	if ui_animation_player:
		ui_animation_player.play("TransOut")
		await ui_animation_player.animation_finished

	if battle_instance and is_instance_valid(battle_instance):
		battle_instance.queue_free()
		battle_instance = null

	if collided_enemy:
		emit_signal("enemy_freed", collided_enemy)
		collided_enemy.queue_free()
		collided_enemy = null

	if player:
		player.global_position = player_start_pos
		player.visible = true
		player.set_physics_process(true)
		player.playRun()
		
	current_state = GameState.MAIN_GAME
