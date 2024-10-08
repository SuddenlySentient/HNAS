@icon("res://Assets/Facility/Mine/MineIcon.png")
extends RigidBody2D
class_name Mine

@onready var beep : AudioStreamPlayer2D = $Beep
@onready var buzzer : AudioStreamPlayer2D = $Buzzer
@onready var explosionSound : AudioStreamPlayer2D = $ExplosionSound
@onready var timer : Timer = $Timer
@onready var explosionTimer : Timer = $ExplostionTimer
@onready var destroyTimer : Timer = $DestroyTimer
@onready var light : PointLight2D = $Light
@onready var explosionSprite : AnimatedSprite2D = $ExplosionSprite
@onready var explosionArea : Area2D = $ExplosionArea
@onready var mineSprite : Sprite2D = $MineSprite
@onready var ExplosionObstacle : NavigationObstacle2D = $ExplosionObstacle
@onready var detectionArea : Area2D = $DetectionArea
@onready var explosionLight : PointLight2D = $ExplosionLight
@onready var ExplosionParticles : GPUParticles2D = $ExplosionParticles

@export var DMG : int = 16
@export var AP : int = 5

@warning_ignore("unused_signal")
signal exploded
@warning_ignore("unused_signal")
signal steppedOn
var detonating : bool = false
var steppedOff : bool = false

func _init():
	await ready
	beep.pitch_scale = randf_range(0.75, 1.25)
	timer.wait_time = randf_range(1, 2.5)
	position += Vector2(randi_range(-64, 64), randi_range(-64, 64))

func _process(_delta):
	
	light.energy = timer.time_left/timer.wait_time
	
	if steppedOff : beep.pitch_scale = lerpf(0.75, 2.5, clamp(1 - explosionTimer.time_left, 0, 1))
	
	var preSquare = clamp(destroyTimer.time_left - 2, 0, 1)
	preSquare = preSquare * preSquare
	explosionLight.energy = preSquare * 8

func _on_timer_timeout():
	beep.play()

func _on_detection_area_body_entered(body):
	if detonating == false :
		if body is Unit and (body.tags.has("Hover") or body.tags.has("LightFoot")) : return false 
		detonating = true
		emit_signal("steppedOn")
		#print(body.name)
		timer.stop()
		beep.volume_db = 10
		beep.max_distance = 4096
		beep.attenuation = 2
		buzzer.play()
		ExplosionObstacle.avoidance_enabled = true
		await detectionArea.body_exited
		if body is SUBRFL48 : body.voice.tryVoice("UhOh")
		steppedOff = true
		timer.start(0.125)
		explosionTimer.start()

func _on_explostion_timer_timeout():
	explode()

func explode():
	#print("Mine")
	emit_signal("exploded")
	explosionLight.enabled = true
	timer.stop()
	explosionSound.pitch_scale = randf_range(0.75, 1.25)
	explosionSound.play()
	explosionSprite.show()
	explosionSprite.play()
	ExplosionParticles.restart()
	var explosionCuiro : Curiousity = createCurio("Mine Explosion", 0, 64, null, 4)
	explosionCuiro.global_position = global_position
	for unit in explosionArea.get_overlapping_bodies() :
		var falloff = sqrt(1.0 - (position.distance_to(unit.position)/384))
		#print("Falloff : ", falloff)
		var DMGDealt = round(DMG * falloff)
		var APDealt = round(AP * falloff)
		#print("DMG : ", DMGDealt, " AP : ", APDealt)
		unit.damage(DMGDealt, APDealt, unit, "AOE", self)
	destroyTimer.start()
	explosionLight.show()
	mineSprite.hide()

func _on_destroy_timer_timeout():
	queue_free()

@onready var map : TileMapLayer = $".."
@onready var curio = load("res://Assets/Base/Curiosity/Curiousity.tscn")
func createCurio(setCurioName : String, setCuriousityType, setStrength : float, setSource : Unit = null, setDuration : float = -1) :
	var newCurio = curio.instantiate()
	newCurio.createCuriousity(setCurioName, setCuriousityType, setStrength, setSource, setDuration)
	$"../../Main".add_child(newCurio)
	return newCurio
