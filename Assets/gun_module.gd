extends Node
class_name GunModule

@onready var shot = load("res://Assets/Shot.tscn")

func fire(DMG : int, AP : int, targetVector : Vector2, angleRange : float = 0, speed : float = 8192):
	
	var newShot : Shot = shot.instantiate()
	newShot.DMG = DMG
	newShot.AP = AP
	newShot.targetVector = targetVector.rotated(deg_to_rad(randf_range(-angleRange, angleRange)))
	newShot.speed = speed
	newShot.global_position = $"..".global_position
	newShot.global_position += targetVector * 128
	add_child(newShot)
