extends CanvasLayer

signal regame_requested
signal exit_requested

@onready var health_bar = $HealthBar
@onready var game_over_screen = $GameOverScreen
@onready var regame_button = $GameOverScreen/VBoxContainer/RegameButton
@onready var exit_button = $GameOverScreen/VBoxContainer/ExitButton

func _ready():
	PlayerStats.health_changed.connect(_on_health_changed)
	# Set the initial health bar value
	health_bar.max_value = PlayerStats.max_health
	health_bar.value = PlayerStats.current_health

	regame_button.pressed.connect(_on_regame_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

	# Set focus neighbors
	regame_button.focus_neighbor_bottom = exit_button.get_path()
	exit_button.focus_neighbor_top = regame_button.get_path()

func _on_health_changed(new_health):
	health_bar.value = new_health

func show_game_over_screen():
	game_over_screen.visible = true
	regame_button.grab_focus()
	get_tree().paused = true # Pause the game when game over screen is shown

func hide_game_over_screen():
	game_over_screen.visible = false
	get_tree().paused = false # Unpause the game when game over screen is hidden

func _on_regame_button_pressed():
	emit_signal("regame_requested")

func _on_exit_button_pressed():
	emit_signal("exit_requested")
