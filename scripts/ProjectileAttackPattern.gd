extends Resource
class_name ProjectileAttackPattern

@export var attack_sound: AudioStream

# An animation to play as a "tell" before the first projectile is fired.
@export var startup_animation: String = ""

# A delay before the first projectile is fired. (Used if no startup_animation is set)
@export var startup_delay: float = 0.0

# The timings between subsequent shots.
@export var timings: Array[float] = [0.5, 0.5, 0.5]

# What kind of projectile to fire?
@export var projectile_scene: PackedScene

# How fast the projectile will travel.
@export var projectile_speed: float = 500.0
