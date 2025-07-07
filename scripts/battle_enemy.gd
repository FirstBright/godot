extends Node2D
signal battle_ended

@export var arrow_scene: PackedScene

# --- Pattern Difficulty Tiers ---
var easy_patterns = [
	[0.6, 0.6, 0.6, 0.6, 2.0], # 4/4 Quarter notes
	[0.8, 0.4, 0.4, 1.5]  # 3/4 Waltz
]
var medium_patterns = [
	[0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 2.0], # 4/4 Eighth notes
	[0.6, 0.3, 0.3, 0.6, 0.3, 0.3, 1.5], # Syncopated
	[0.4, 0.8, 0.4, 1.5] # Displaced Waltz
]
var hard_patterns = [
	[1.0, 0.2, 0.2, 1.0, 0.2, 0.2, 2.0], # Slow start, fast burst
	[0.2, 0.2, 1.2, 0.2, 0.2, 1.2, 2.0], # Double shot, long pause
	[0.18, 0.18, 0.18, 0.18, 1.5] # 16th note stream
]

enum State { IDLE, SHOOTING, VULNERABLE, DEAD }
var current_state = State.IDLE

var arrow_pool = []
var max_arrow_count = 10

var patterns_cleared_count = 0
var current_pattern_index = 0
var current_shot_index = 0
var successful_parries_in_pattern = 0

var vulnerability_timer: Timer
var shot_timer: Timer

@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var vulnerability_indicator = $VulnerabilityIndicator

func _ready():
	randomize()
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

	shot_timer = Timer.new()
	shot_timer.one_shot = true
	shot_timer.connect("timeout", _fire_next_shot_in_pattern)
	add_child(shot_timer)

	if vulnerability_indicator:
		vulnerability_indicator.visible = false

func _process(_delta):
	if current_state == State.VULNERABLE:
		if vulnerability_indicator and vulnerability_timer.time_left > 0:
			vulnerability_indicator.value = vulnerability_timer.time_left / vulnerability_timer.wait_time
		if Input.is_action_just_pressed("kill"):
			kill_enemy()

func start_battle():
	patterns_cleared_count = 0
	current_state = State.SHOOTING
	animation_player.play("idle")
	execute_current_pattern()

func execute_current_pattern():
	if current_state != State.SHOOTING:
		return

	var available_patterns = get_available_patterns()
	var pattern_data = available_patterns[randi() % available_patterns.size()]
	current_pattern_index = pattern_data["index"]
	
	current_shot_index = 0
	successful_parries_in_pattern = 0
	_fire_next_shot_in_pattern()

func get_available_patterns():
	var available = []
	for i in easy_patterns.size(): available.append({"pattern": easy_patterns[i], "index": i})

	if patterns_cleared_count >= 1:
		for i in medium_patterns.size(): available.append({"pattern": medium_patterns[i], "index": i + easy_patterns.size()})
	if patterns_cleared_count >= 2:
		for i in hard_patterns.size(): available.append({"pattern": hard_patterns[i], "index": i + easy_patterns.size() + medium_patterns.size()})
	
	return available

func get_pattern_by_global_index(index):
	if index < easy_patterns.size():
		return easy_patterns[index]
	index -= easy_patterns.size()
	if index < medium_patterns.size():
		return medium_patterns[index]
	index -= medium_patterns.size()
	return hard_patterns[index]

func _fire_next_shot_in_pattern():
	var pattern = get_pattern_by_global_index(current_pattern_index)
	if current_shot_index >= pattern.size():
		if successful_parries_in_pattern == pattern.size():
			become_vulnerable()
		else:
			execute_current_pattern()
		return

	shoot_projectile()
	var next_shot_delay = pattern[current_shot_index]
	shot_timer.start(next_shot_delay)
	current_shot_index += 1

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
	shot_timer.paused = true
	await get_tree().create_timer(0.3).timeout
	shot_timer.paused = false

func become_vulnerable():
	patterns_cleared_count += 1
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
		execute_current_pattern()

func kill_enemy():
	if current_state == State.VULNERABLE:
		current_state = State.DEAD
		vulnerability_timer.stop()
		shot_timer.stop()
		if is_instance_valid(animation_player):
			animation_player.play("death")
			await animation_player.animation_finished
		if vulnerability_indicator:
			vulnerability_indicator.visible = false
		emit_signal("battle_ended")

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
