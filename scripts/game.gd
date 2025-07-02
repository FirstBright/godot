extends Node2D


enum GameState { MAIN_GAME, BATTLE, TRANSITION }
var current_state = GameState.MAIN_GAME
var battle_instance = null
var player_start_pos: Vector2

func _ready():
	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	for enemy in enemy_nodes:
		enemy.connect("body_entered", _on_enemy_body_entered)

func _on_enemy_body_entered(body: Node2D):
	if current_state != GameState.MAIN_GAME:
		return
	if "Player" in body.name:
		current_state = GameState.TRANSITION
		player_start_pos = body.global_position
		body.set_physics_process(false)
		var ui = get_tree().current_scene.get_node("UI/AnimationPlayer")
		ui.play("TransIn")
		await ui.animation_finished
		start_battle()
		body.queue_free()

func start_battle():
	if not battle_instance:
		battle_instance = load("res://scenes/battle.tscn").instantiate()
		battle_instance.connect("battle_ended", _on_battle_ended)
		get_tree().current_scene.call_deferred("add_child", battle_instance)
	else:
		battle_instance.visible = true
		battle_instance.set_process(true)
		battle_instance.set_physics_process(true)
		var enemy2 = battle_instance.get_node("Enemy2")
		enemy2.parry_count = 0
		enemy2.battle_end = false
		enemy2.shoot_timer.start()
	current_state = GameState.BATTLE
	get_tree().current_scene.get_node("UI/AnimationPlayer").play("TransOut")

func _on_battle_ended():
	current_state = GameState.TRANSITION
	var ui = get_tree().current_scene.get_node("UI/AnimationPlayer")
	ui.play("TransIn")
	await ui.animation_finished
	battle_instance.visible = false
	battle_instance.set_process(false)
	battle_instance.set_physics_process(false)
	var player = get_tree().current_scene.get_node("Player")
	if player:
		player.global_position = player_start_pos
		player.set_physics_process(true)
		player.playIdle()
	var spawner = get_tree().current_scene.get_node("EnemySpawner")
	spawner.spawn_timer.start()
	current_state = GameState.MAIN_GAME
	ui.play("TransOut")
