extends Node
class_name GunModule

@export var shot = load("res://Assets/Base/Shot.tscn")

func fire(DMG : int, AP : int, targetVector : Vector2, angleRange : float = 0, shooterDistance : float = 256, speed : float = 16384):
	
	var newShot : Shot = shot.instantiate()
	newShot.DMG = DMG
	newShot.AP = AP
	newShot.distanceFromShooter = shooterDistance
	newShot.targetVector = targetVector.rotated(deg_to_rad(randf_range(-angleRange, angleRange)))
	newShot.speed = speed
	newShot.global_position = $"..".global_position
	newShot.shooter = $".."
	$".".add_child(newShot)
