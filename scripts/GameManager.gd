extends Node

enum GameState { MAIN_GAME, BATTLE, TRANSITION }
var current_state = GameState.MAIN_GAME
var battle_instance = null
var player_start_pos: Vector2
var game_scene = null  # Game 씬 참조
var player = null

func _ready():
	# Game 씬 로드 시 초기화
	if get_tree().current_scene.name == "Game":
		game_scene = get_tree().current_scene
		player = game_scene.get_node("Player")
		if not player:
			push_error("Player node not found in Game scene")
			return
		var enemy_nodes = get_tree().get_nodes_in_group("enemies")
		print("Found enemies: ", enemy_nodes)  # 디버깅
		for enemy in enemy_nodes:
			enemy.connect("body_entered", _on_enemy_body_entered)

func _on_enemy_body_entered(body: Node2D):
	if current_state != GameState.MAIN_GAME:
		print("Ignoring collision, not in MAIN_GAME state: ", current_state)
		return
	if "Player" in body.name:
		current_state = GameState.TRANSITION
		player_start_pos = body.global_position
		print("Player start pos: ", player_start_pos)  # 디버깅
		body.set_physics_process(false)
		body.velocity = Vector2.ZERO  # 이동 멈춤
		body.visible = false  # 플레이어 숨김
		body.playPause()  # idle 애니메이션
		start_battle()

func start_battle():
	if not battle_instance:
		battle_instance = load("res://scenes/battle.tscn").instantiate()
		battle_instance.connect("battle_ended", _on_battle_ended)
		game_scene.call_deferred("add_child", battle_instance)
		print("Battle instance created and added")
	else:
		battle_instance.visible = true
		battle_instance.set_process(true)
		battle_instance.set_physics_process(true)
		var enemy2 = battle_instance.get_node("Enemy2")
		enemy2.parry_count = 0
		enemy2.battle_end = false
		enemy2.shoot_timer.start()
		print("Battle instance reused")
	current_state = GameState.BATTLE

func _on_battle_ended():
	print("back")
	current_state = GameState.MAIN_GAME
	battle_instance.visible = false
	battle_instance.set_process(false)
	battle_instance.set_physics_process(false)
	player = game_scene.get_node("Player")
	if player:
		player.global_position = player_start_pos
		player.visible = true
		player.set_physics_process(true)
		player.playRun()
		#var camera = player.get_node("Camera2D")
		#if camera:
			#camera.enabled = true
			#camera.global_position = player.global_position  # 카메라 위치 동기화
			#print("Camera enabled at: ", camera.global_position)  # 디버깅
		#else:
			#push_error("Camera2D not found in Player")
	var spawner = game_scene.get_node("EnemySpawner")
	if spawner:
		spawner.spawn_enemy()
		print("EnemySpawner triggered")  # 디버깅
	else:
		push_error("EnemySpawner not found")
