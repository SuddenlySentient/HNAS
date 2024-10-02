extends Node2D

@onready var line = $CanvasLayer/Plasma
@onready var ray = $Ray
@onready var arcTimer = $ArcTimer

var minPitch = 1
var maxPitch = 2

@export var DMG = 14
@export var AP = 4
var myOwner

var minWidth = 32
var maxWidth = 128
var length = 256000
var arcLength = deg_to_rad(5) / 2
var targetVector = Vector2.LEFT
var firing = false
var hurted = []
var soundCurio : Curiousity



func _enter_tree():
	await ready
	$Start.play()
	$PlasmaRayA.play()
	$PlasmaRayB.play()
	$ArcTimer.start()
	$CanvasLayer/SparksA.show()
	$CanvasLayer/SparksB.show()
	$CanvasLayer/Plasma.show()
	$Saw.pitch_scale = (1.0 /1.1) / $ArcTimer.wait_time
	$Saw.play()
	$HitLight.enabled = true
	if randi_range(0, 1) == 0 : arcLength *= -1
	firing = true
	soundCurio = myOwner.createCurio("Plasma Ray", 0, 32, myOwner)
	myOwner.map.add_child(soundCurio)

func _process(_delta):
	if firing :
		pass
		#line.width = (sin((waxTimer.time_left / waxTimer.wait_time) * PI) * (maxWidth - minWidth)) + minWidth

func _physics_process(delta):
	line.position = global_position
	$CanvasLayer/SparksA.position = global_position
	if firing :
		if ray.is_colliding() :
			var collsionPoint =ray.get_collision_point()
			line.points[1] = collsionPoint - global_position
			soundCurio.global_position = collsionPoint
			$CanvasLayer/SparksB.position = collsionPoint
			$CanvasLayer/SparksB.rotation = ray.get_collision_normal().angle() + (PI / 2)
			$HitLight.global_position = collsionPoint
			$PlasmaRayB.position = collsionPoint
			var hit = ray.get_collider()
			if hit is Unit :
				hit.dealKnockback(16384 * delta, -Vector2.from_angle(ray.rotation - (PI / 2)).normalized())
				if hurted.has(hit) == false :
					hurted.append(hit)
					if hit.damage(DMG, AP, myOwner, "Ray", self) :
						$Damage.global_position = collsionPoint
						$Damage.play()
		var arcTime = arcTimer.time_left / arcTimer.wait_time
		$StartLight.texture_scale = clampf(sin(arcTime * PI) * 6, 3, 6)
		$StartLight.energy = clampf(sin(arcTime * PI) * 5, 3, 5)
		$StartLight.rotate(delta * sin(arcTime * PI))
		#arcTime = (tan( (arcTime - 0.5) * (PI / 2) ) / 2) + 0.5
		var smoothing = lerp(4, 0, clamp((rad_to_deg(arcLength) * 2) / 60.0, 0, 1))
		smoothing = round(smoothing)
		for x in smoothing :
			arcTime = smoothstep(0, 1, arcTime)
		#print("arc length ", rad_to_deg(abs(arcLength * 2)) ," Smooth x", smoothing)
		line.width = (sin(arcTime * PI) * (maxWidth - minWidth)) + minWidth
		$HitLight.rotate(delta * sin(arcTime * PI))
		$PlasmaRayA.pitch_scale = lerpf(minPitch, maxPitch, sin(arcTime * (PI)))
		$PlasmaRayB.pitch_scale = lerpf(minPitch, maxPitch, sin(arcTime * (PI)))
		ray.rotation = lerp_angle(-arcLength, arcLength, arcTime) + targetVector.angle() - (PI /2)

@onready var sparks = load("res://Assets/Seraph/seraph_spark.tscn")

func _on_arc_timer_timeout():
	var newSparks = sparks.instantiate()
	newSparks.location = global_position
	myOwner.add_child(newSparks)
	$End.play()
	$End.reparent(myOwner, true)
	soundCurio.queue_free()
	queue_free()

func _on_plasma_ray_a_finished():
	$PlasmaRayA.play()

func _on_plasma_ray_b_finished():
	$PlasmaRayB.play()
