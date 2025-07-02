extends Node

enum GameState { MAIN_GAME, BATTLE, TRANSITION }
var current_state = GameState.MAIN_GAME
var battle_instance = null
var player_start_pos: Vector2
var game_scene = null
var player = null
var ui_animation_player = null
var collided_enemy = null
var enemy_spawner = null

func _ready():
	pass

func set_game_scene_references(scene: Node):
	game_scene = scene
	player = game_scene.get_node("Player")
	ui_animation_player = game_scene.get_node("UI/AnimationPlayer")
	enemy_spawner = game_scene.get_node("EnemySpawner")
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

func start_battle():
	if not battle_instance:
		battle_instance = load("res://scenes/battle.tscn").instantiate()
		battle_instance.connect("battle_ended", _on_battle_ended)
		if game_scene:
			game_scene.call_deferred("add_child", battle_instance)
		print("Battle instance created and added")
	else:
		battle_instance.visible = true
		battle_instance.set_process(true)
		battle_instance.set_physics_process(true)
		var enemy2 = battle_instance.get_node("Enemy2")
		if enemy2:
			enemy2.start_battle()
		print("Battle instance reused")
	current_state = GameState.BATTLE
	if ui_animation_player:
		ui_animation_player.play("TransOut")

func _on_battle_ended():
	current_state = GameState.TRANSITION	
	
	battle_instance.visible = false
	battle_instance.set_process(false)
	battle_instance.set_physics_process(false)
	
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
	if ui_animation_player:
		ui_animation_player.play("TransOut")
