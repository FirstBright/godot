extends "res://scripts/projectile.gd"

func _ready():
	sprite.flip_h = direction.x < 0
