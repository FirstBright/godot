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
	print("Player has died. Showing game over screen.")
	if ui_instance:
		ui_instance.show_game_over_screen()

func restart_stage():
	current_state = GameState.MAIN_GAME
	# Keep current_floor, reset enemies defeated
	enemies_defeated_on_current_floor = 0
	save_game()  # Save the current floor
	if ui_instance:
		ui_instance.hide_game_over_screen()
		ui_instance.update_floor_label(current_floor)
	# Reset player stats and reload the scene
	PlayerStats.reset()
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
