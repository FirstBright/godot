extends Node2D

@export var enemy_scene: PackedScene
@onready var spawn_timer = $SpawnTimer
@export var spawn_interval: float = 5.0
var enemy_pool = []
var max_enemy_count = 5

func _ready():
	if not enemy_scene:
		push_error("Enemy scene not set in EnemySpawner")
		return
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()
	for i in range(max_enemy_count):
		var enemy = enemy_scene.instantiate()
		enemy.visible = false
		enemy.add_to_group("enemies")
		enemy.connect("body_entered", GameManager._on_enemy_body_entered)
		call_deferred("add_child", enemy)
		enemy_pool.append(enemy)
		print("Enemy added to pool: ", enemy)
	spawn_enemy()

func _on_spawn_timer_timeout():
	spawn_enemy()
func spawn_enemy():
	var player = GameManager.player
	if not player:
		push_error("Player not found for spawning enemy")
		return
	var spawn_x = player.global_position.x + randf_range(200, 500)  # 플레이어 오른쪽
	var spawn_y = player.global_position.y + randf_range(-05, 05)  # 플레이어 Y 근처
	var enemy = get_available_enemy()
	if enemy:
		enemy.global_position = Vector2(spawn_x, spawn_y)
		enemy.visible = true
		var sprite = enemy.get_node("AnimatedSprite2D")
		if sprite:
			sprite.visible = true
			print("Enemy spawned at: ", enemy.global_position, " visible: ", enemy.visible)  # 디버깅
		else:
			push_error("Sprite2D not found in spawned Enemy: ", enemy)

func get_available_enemy():
	for enemy in enemy_pool:
		if is_instance_valid(enemy) and not enemy.visible:
			return enemy
	var new_enemy = enemy_scene.instantiate()
	new_enemy.visible = false
	new_enemy.add_to_group("enemies")
	new_enemy.connect("body_entered", GameManager._on_enemy_body_entered)
	call_deferred("add_child", new_enemy)
	enemy_pool.append(new_enemy)
	var sprite = new_enemy.get_node("Sprite2D")
	if sprite:
		sprite.visible = true
		print("New enemy created: ", new_enemy, " sprite visible: ", sprite.visible)  # 디버깅
	else:
		push_error("Sprite2D not found in new Enemy: ", new_enemy)
	return new_enemy
