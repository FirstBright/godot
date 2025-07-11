extends CanvasLayer

signal regame_requested
signal exit_requested
signal restart_requested

@onready var health_bar = $HealthBar
@onready var game_over_screen = $GameOverScreen
@onready var regame_button = $GameOverScreen/VBoxContainer/RegameButton
@onready var restart_button = $GameOverScreen/VBoxContainer/RestartButton
@onready var exit_button = $GameOverScreen/VBoxContainer/ExitButton
@onready var floor_label = $FloorLabel

func _ready():
	if not floor_label:
		push_error("FloorLabel node not found in UI")
	PlayerStats.health_changed.connect(_on_health_changed)
	health_bar.max_value = PlayerStats.max_health
	health_bar.value = PlayerStats.current_health
	regame_button.pressed.connect(_on_regame_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	# Set focus neighbors for navigation
	regame_button.focus_neighbor_bottom = restart_button.get_path()
	restart_button.focus_neighbor_top = regame_button.get_path()
	restart_button.focus_neighbor_bottom = exit_button.get_path()
	exit_button.focus_neighbor_top = restart_button.get_path()

func _on_health_changed(new_health):
	health_bar.value = new_health

func show_game_over_screen():
	game_over_screen.visible = true
	regame_button.grab_focus()
	get_tree().paused = true

func hide_game_over_screen():
	game_over_screen.visible = false
	get_tree().paused = false

func _on_regame_button_pressed():
	emit_signal("regame_requested")

func _on_restart_button_pressed():
	emit_signal("restart_requested")

func _on_exit_button_pressed():
	emit_signal("exit_requested")

func update_floor_label(floor_number: int):
	if floor_label:
		floor_label.text = "Floor: %d" % floor_number
	else:
		push_error("FloorLabel not found when updating floor")
