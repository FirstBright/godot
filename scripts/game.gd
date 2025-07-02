extends Node2D

func _ready():
	# Set game scene references in GameManager
	GameManager.set_game_scene_references(self)

	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	print("enemy_nodes",enemy_nodes)
	for enemy in enemy_nodes:
		enemy.connect("body_entered", Callable(GameManager, "_on_enemy_body_entered"))

	var spawner = get_node("EnemySpawner")
	if spawner:
		spawner.spawn_enemy()
