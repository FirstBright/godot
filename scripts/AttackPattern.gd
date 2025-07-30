extends Resource
class_name AttackPattern

# The timings between shots
@export var timings: Array[float] = [0.5, 0.5, 0.5]

# What kind of projectile to fire?
@export var projectile_scene: PackedScene
