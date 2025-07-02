extends Node2D
signal battle_ended

@export var arrow_scene: PackedScene
@export var patterns: Array[Array] = [[0.5, 0.5, 0.5, 1.5], [0.3, 0.3, 0.8, 0.3, 0.3, 0.8, 1.5]]

enum State { SHOOTING, VULNERABLE, DEAD }
var current_state = State.SHOOTING

var arrow_pool = []
var max_arrow_count = 10

var current_pattern_index = 0
var shots_fired_in_pattern = 0
var successful_parries_in_pattern = 0

func _ready():
	for i in range(max_arrow_count):
		var arrow = arrow_scene.instantiate()
		arrow.visible = false
		arrow.set_physics_process(false)
		get_parent().call_deferred("add_child", arrow)
		arrow_pool.append(arrow)
		arrow.connect("parried", _on_projectile_parried)
	
	start_battle()

func _process(delta):
	if current_state == State.VULNERABLE and Input.is_action_just_pressed("ui_accept"):
		kill_enemy()

func start_battle():
	current_state = State.SHOOTING
	current_pattern_index = 0
	execute_current_pattern()

func execute_current_pattern():
	if current_state != State.SHOOTING:
		return

	shots_fired_in_pattern = 0
	successful_parries_in_pattern = 0
	
	var pattern = patterns[current_pattern_index]
	for shot_timing in pattern:
		shoot_projectile()
		shots_fired_in_pattern += 1
		await get_tree().create_timer(shot_timing).timeout
	
	# Pattern finished, check for success
	if successful_parries_in_pattern >= shots_fired_in_pattern:
		become_vulnerable()
	else:
		# Move to the next pattern or repeat
		current_pattern_index = (current_pattern_index + 1) % patterns.size()
		execute_current_pattern()

func shoot_projectile():
	var player = get_node_or_null("../Player2")
	if player:
		var projectile = get_available_arrow()
		if projectile:
			var start_pos = global_position
			var direction = (player.global_position - global_position).normalized()
			projectile.setup(start_pos, direction)

func _on_projectile_parried():
	successful_parries_in_pattern += 1
	print("Parried! Count in pattern: ", successful_parries_in_pattern)

func become_vulnerable():
	current_state = State.VULNERABLE
	print("Enemy is vulnerable! Press 'W' to kill.")
	# You can add a visual indicator here, like an animation or a UI prompt

func kill_enemy():
	if current_state == State.VULNERABLE:
		current_state = State.DEAD
		print("Enemy defeated!")
		emit_signal("battle_ended")

func is_in_vulnerable_state():
	return current_state == State.VULNERABLE

func get_available_arrow():
	for arrow in arrow_pool:
		if is_instance_valid(arrow) and not arrow.visible:
			return arrow
	# This part is reached if we run out of arrows in the pool.
	var new_arrow = arrow_scene.instantiate()
	new_arrow.visible = false
	new_arrow.set_physics_process(false)
	new_arrow.connect("parried", _on_projectile_parried)
	get_parent().call_deferred("add_child", new_arrow)
	arrow_pool.append(new_arrow)
	return new_arrow

func _on_tree_exited() -> void:
	for arrow in arrow_pool:
		if is_instance_valid(arrow):
			arrow.queue_free()
	arrow_pool.clear()
