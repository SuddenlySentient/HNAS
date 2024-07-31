extends Unit
class_name Seraph

@export var lightRotateSpeed = 0.25
@onready var sprite : AnimatedSprite2D = $Sprite


func _init():
	await ready
	HP = maxHP
	sprite.play()

func _process(delta):
	$HeavenlyLight.rotate(delta * lightRotateSpeed)
