extends Resource
class_name TimedAttackPattern

@export var attack_sound: AudioStream

# An animation to play as a "tell" before the main attack.
@export var startup_animation: String = ""

# The delay before the attack animation starts. (Used if no startup_animation is set)
@export var startup_delay: float = 0.5

# The duration of the attack's active hitbox.
@export var active_duration: float = 0.2

# The animation to play on the enemy sprite (e.g., "slash", "stomp").
@export var animation_name: String = "attack"

# The size of the area to check for the player.
@export var area_size: Vector2 = Vector2(50, 50)
