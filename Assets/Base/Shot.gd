extends RigidBody2D
class_name Shot

@export var targetVector : Vector2 = Vector2.UP
var distance : float = 256
@export var speed : float = 4096
@export var DMG : int = 1
@export var AP : int = 1
var shooter : Unit
var distanceFromShooter = 192
var over = false

@onready var sparks = load("res://Assets/Base/SparkParticle.tscn")

func _physics_process(_delta):
	if linear_velocity.length() < (speed/16) : queue_free()
	rotation = linear_velocity.angle() + PI/2
	scale.y = linear_velocity.length() / speed

func _enter_tree():
	#print("BANG")
	global_position += targetVector * distanceFromShooter
	rotation = targetVector.angle() + PI/2
	linear_velocity = targetVector * speed

func changeColor(newColor : Color):
	$Shot.modulate = newColor * 2
	$PointLight2D.color = newColor

func _on_body_entered(body):
	var newSparks = sparks.instantiate()
	newSparks.position = global_position
	newSparks.rotation = rotation + PI/2
	$"..".add_child(newSparks)
	newSparks.restart()
	
	if body is Unit : 
		var DMGDealt = body.damage(DMG, AP, shooter, "Projectile",  self)
		if DMGDealt == 0 and body.reflectShots : 
			$Ricochet.play()
			targetVector = targetVector.rotated(deg_to_rad(randf_range(-45, 45) + 180))
			global_position += targetVector * 192
			rotation = targetVector.angle() + PI/2
			linear_velocity = targetVector * speed
		elif DMGDealt != -1 : endShot()
	else : endShot()

func endShot():
	if over == false :
		$CollisionShape2D.free()
		over = true
		hide()
		$Impact.play()
		await $Impact.finished
		queue_free()

func _on_timer_timeout():
	queue_free()
