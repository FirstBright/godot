extends Node2D

func _ready():
	# Set game scene references in GameManager
	GameManager.set_game_scene_references(self)

	var spawner = get_node("EnemySpawner")
	if spawner:
		spawner.spawn_enemies(GameManager.enemies_per_floor)
