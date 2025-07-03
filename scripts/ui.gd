extends CanvasLayer

@onready var health_bar = $HealthBar

func _ready():
	PlayerStats.health_changed.connect(_on_health_changed)
	# Set the initial health bar value
	health_bar.max_value = PlayerStats.max_health
	health_bar.value = PlayerStats.current_health

func _on_health_changed(new_health):
	health_bar.value = new_health
