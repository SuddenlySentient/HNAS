extends RigidBody2D
class_name Shot

var startPosition : Vector2 = Vector2.ZERO
@export var targetVector : Vector2 = Vector2.UP
var distance : float = 256
@export var speed : float = 4096
@export var DMG : int = 1
@export var AP : int = 1

func _enter_tree():
	#print("BANG")
	startPosition = position
	rotation = targetVector.angle() + PI/2
	linear_velocity = targetVector * speed

func _on_body_entered(body):
	if body is Unit : 
		var DMGDealt = body.damage(DMG, AP)
		#print("Hit ", body.name, " for ", DMGDealt, ", leaving them at ", round((float(body.HP)/float(body.maxHP)) * 100), "%")
		body.velocity += linear_velocity / 64
	queue_free()
