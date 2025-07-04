extends Node2D
signal battle_ended

@export var arrow_scene: PackedScene
@export var patterns: Array[Array] = [[0.5, 0.5, 0.5, 1.5], [0.3, 0.3, 0.8, 0.3, 0.3, 0.8, 1.5]]

enum State { IDLE, SHOOTING, VULNERABLE, DEAD }
var current_state = State.IDLE

var arrow_pool = []
var max_arrow_count = 10

var current_pattern_index = 0
var shots_fired_in_pattern = 0
var successful_parries_in_pattern = 0

var vulnerability_timer: Timer
@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var vulnerability_indicator = $VulnerabilityIndicator

func _ready():
	for i in range(max_arrow_count):
		var arrow = arrow_scene.instantiate()
		arrow.visible = false
		arrow.set_physics_process(false)
		get_parent().call_deferred("add_child", arrow)
		arrow_pool.append(arrow)
		arrow.connect("parried", _on_projectile_parried)

	vulnerability_timer = Timer.new()
	vulnerability_timer.wait_time = 2.0
	vulnerability_timer.one_shot = true
	vulnerability_timer.connect("timeout", _on_vulnerability_timer_timeout)
	add_child(vulnerability_timer)

	if vulnerability_indicator:
		vulnerability_indicator.visible = false

func _process(_delta):
	if current_state == State.VULNERABLE:
		if vulnerability_indicator and vulnerability_timer.time_left > 0:
			vulnerability_indicator.value = vulnerability_timer.time_left / vulnerability_timer.wait_time
		if Input.is_action_just_pressed("kill"):
			kill_enemy()

func start_battle():
	current_state = State.SHOOTING
	current_pattern_index = 0
	animation_player.play("idle") # Ensure enemy starts in idle animation
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

	await get_tree().create_timer(1.0).timeout

	if successful_parries_in_pattern == shots_fired_in_pattern:
		become_vulnerable()
	else:
		current_pattern_index = (current_pattern_index + 1) % patterns.size()
		execute_current_pattern()

func shoot_projectile():
	if not arrow_scene:
		push_error("Arrow scene not assigned in battle_enemy.gd!")
		return
	var player = get_node_or_null("../Player2")
	if player:
		var projectile = get_available_arrow()
		if projectile:
			var start_pos = global_position
			var direction = (player.global_position - global_position).normalized()
			projectile.setup(start_pos, direction)

func _on_projectile_parried():
	successful_parries_in_pattern += 1

func become_vulnerable():
	current_state = State.VULNERABLE
	vulnerability_timer.start()
	if animation_player:
		animation_player.play("vulnerable")
	if vulnerability_indicator:
		vulnerability_indicator.visible = true
		vulnerability_indicator.value = 1.0

func _on_vulnerability_timer_timeout():
	if current_state == State.VULNERABLE:
		current_state = State.SHOOTING
		if animation_player:
			animation_player.play("idle")
		if vulnerability_indicator:
			vulnerability_indicator.visible = false
		current_pattern_index = (current_pattern_index + 1) % patterns.size()
		execute_current_pattern()

func kill_enemy():
	if current_state == State.VULNERABLE:
		print("battle_enemy: kill_enemy called. Current state: ", current_state)
		current_state = State.DEAD
		vulnerability_timer.stop()
		if is_instance_valid(animation_player):
			print("battle_enemy: Playing death animation.")
			animation_player.play("death")
			await animation_player.animation_finished # Wait for death animation to finish
		else:
			print("battle_enemy: AnimationPlayer is not valid.")
		if vulnerability_indicator:
			vulnerability_indicator.visible = false
		emit_signal("battle_ended")
		print("battle_enemy: battle_ended signal emitted.")

func is_in_vulnerable_state():
	return current_state == State.VULNERABLE

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

func _on_tree_exited():
	for arrow in arrow_pool:
		if is_instance_valid(arrow):
			arrow.queue_free()
	arrow_pool.clear()
