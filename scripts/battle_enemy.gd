extends Node2D
signal battle_ended

@export var arrow_scene: PackedScene
@onready var shoot_timer = $ShootTimer
@export var shoot_interval = 2.0
var parry_count: int = 0 
@export var parry_threshold: int = 3 
var battle_end: bool = false
var arrow_pool = []
var max_arrow_count = 6

func _ready():
	shoot_timer.wait_time = shoot_interval
	shoot_timer.start()
	for i in range(max_arrow_count):
		var arrow = arrow_scene.instantiate()
		arrow.visible = false
		arrow.set_physics_process(false)
		get_parent().call_deferred("add_child", arrow)
		arrow_pool.append(arrow)
		arrow.connect("parried", _on_projectile_parried)

func _on_shoot_timer_timeout() -> void:
	if battle_end:
		return
	var player = get_node("../Player2")
	if player:
		var projectile = get_available_arrow()
		if projectile:
			projectile.position = global_position
			projectile.direction = (player.global_position - global_position).normalized()
			projectile.visible = true
			projectile.set_physics_process(true)
			projectile.is_waiting_hit = false
			projectile.sprite.flip_h = projectile.direction.x < 0

func get_available_arrow():
	for arrow in arrow_pool:
		if is_instance_valid(arrow) and not arrow.visible:
			return arrow
	var new_arrow = arrow_scene.instantiate()
	new_arrow.visible = false
	new_arrow.set_physics_process(false)
	new_arrow.connect("parried", _on_projectile_parried)
	get_parent().call_deferred("add_child", new_arrow)
	arrow_pool.append(new_arrow)
	return new_arrow
	
func _on_projectile_parried():
	parry_count += 1
	print("Parried! Count: ", parry_count)
	if parry_count >= parry_threshold:
		# 히트 버튼 활성화
		#var ui = get_tree().current_scene.get_node("UI")
		#if ui:
			#ui.get_node("HitButton").visible = true
			#print("Hit Button Activated!")
		battle_end = true
		shoot_timer.stop()
		# 전투 종료 신호 발송
		emit_signal("battle_ended")
		print("battle_ended")

func _on_tree_exited() -> void:
	for arrow in arrow_pool:
		if is_instance_valid(arrow):
			arrow.queue_free()
	arrow_pool.clear()
