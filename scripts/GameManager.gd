extends Node

enum GameState { MAIN_GAME, BATTLE, TRANSITION }
var current_state = GameState.MAIN_GAME
var battle_instance = null
var player_start_pos: Vector2
var game_scene = null
var player = null
var ui_animation_player = null
var ui_instance = null # Add a reference to the UI instance
var collided_enemy = null
var enemy_spawner = null

func _ready():
	PlayerStats.no_health.connect(_on_player_no_health)

func _on_player_no_health():
	print("Player has died. Showing game over screen.")
	if ui_instance:
		ui_instance.show_game_over_screen()

func restart_stage():
	PlayerStats.reset()
	current_state = GameState.MAIN_GAME
	if ui_instance:
		ui_instance.hide_game_over_screen() # Hide game over screen on restart
	get_tree().reload_current_scene()

func _on_regame_requested():
	print("Regame requested.")
	restart_stage()

func _on_exit_requested():
	print("Exit requested. Quitting game.")
	get_tree().quit()

func set_game_scene_references(scene: Node):
	game_scene = scene
	player = game_scene.get_node("Player")
	ui_animation_player = game_scene.get_node("UI/AnimationPlayer")
	enemy_spawner = game_scene.get_node("EnemySpawner")
	ui_instance = game_scene.get_node("UI") # Get reference to the UI instance
	if ui_instance:
		ui_instance.regame_requested.connect(_on_regame_requested)
		ui_instance.exit_requested.connect(_on_exit_requested)
	else:
		push_error("UI node not found in Game scene")
	if not player:
		push_error("Player node not found in Game scene")
	if not ui_animation_player:
		push_error("UI/AnimationPlayer node not found in Game scene")
	if not enemy_spawner:
		push_error("EnemySpawner node not found in Game scene")

func _on_enemy_body_entered(body: Node2D):
	if current_state != GameState.MAIN_GAME:
		print("Ignoring collision, not in MAIN_GAME state: ", current_state)
		return
	if "Player" in body.name:
		current_state = GameState.TRANSITION
		player_start_pos = body.global_position
		print("Player start pos: ", player_start_pos)
		body.set_physics_process(false)
		body.velocity = Vector2.ZERO
		body.playPause()
		
		collided_enemy = body
		
		if ui_animation_player:
			ui_animation_player.play("TransIn")
			await ui_animation_player.animation_finished
		
		start_battle()

var BattleScene = preload("res://scenes/battle.tscn")

func start_battle():
	if not battle_instance:
		battle_instance = BattleScene.instantiate()
		battle_instance.connect("battle_ended", _on_battle_ended)
		if game_scene:
			game_scene.call_deferred("add_child", battle_instance)
		print("Battle instance created and added")
	current_state = GameState.BATTLE
	if ui_animation_player:
		ui_animation_player.play("TransOut")
		await ui_animation_player.animation_finished
		var enemy2 = battle_instance.get_node("Enemy2")
		if enemy2:
			enemy2.start_battle()
	else:
		battle_instance.visible = true
		battle_instance.set_process(true)
		battle_instance.set_physics_process(true)
		current_state = GameState.BATTLE
		if ui_animation_player:
			ui_animation_player.play("TransOut")
			await ui_animation_player.animation_finished
			var enemy2 = battle_instance.get_node("Enemy2")
			if enemy2:
				enemy2.start_battle()

func _on_battle_ended():
	print("GameManager: _on_battle_ended called.")
	current_state = GameState.TRANSITION	

	if ui_animation_player:
		ui_animation_player.play("TransOut")
		await ui_animation_player.animation_finished # Wait for the transition out animation to finish

	# Free the battle instance after it has ended and after the transition animation
	if battle_instance and is_instance_valid(battle_instance):
		battle_instance.queue_free()
		battle_instance = null

	if collided_enemy:
		collided_enemy.visible = false
		collided_enemy.set_physics_process(false)
		collided_enemy = null

	if enemy_spawner:
		enemy_spawner.start_spawning_if_needed()

	if player:
		player.global_position = player_start_pos
		player.visible = true
		player.set_physics_process(true)
		player.playRun()
		
	current_state = GameState.MAIN_GAME
