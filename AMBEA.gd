extends Unit

@onready var sprite = $Sprite
@onready var orb = $Orb
@onready var orbParticles = $Orb/OrbParticles
@onready var orbLight = $Orb/OrbLight
var cAni = "Hover"
enum States {
Ready = 0,
Wander = 1,
Found = 2,
Firing = 3
}
var State = States.Ready
var charge = 0



func _ready() :
	fireAt(Vector2.ZERO)

func _physics_process(_delta):
	move_and_slide()

func _process(_delta):
	
	#var animationess = sin( (float(sprite.frame) / float(sprite.sprite_frames.get_frame_count(sprite.animation))) * PI )
	
	if cAni == "Hover" : 
		var velocityLength = clamp(velocity.length(), 0, 1)
		$Hover.pitch_scale = lerp(1.0, 1.5, velocityLength)
		if $Hover.playing == false : $Hover.play()
	
	var directionString : String = "Down"
	var altDirection = Vector2(round(direction.x), round(direction.y))
	
	match altDirection :
		Vector2(0, -1) : directionString = "Up"
		Vector2(-1, -1) : directionString = "UpLeft"
		Vector2(1, -1) : directionString = "UpRight"
		Vector2(-1, 0) : directionString = "Left"
		Vector2(1, 0) : directionString = "Right"
		Vector2(0, 1) : directionString = "Down"
		Vector2(-1, 1) : directionString = "DownLeft"
		Vector2(1, 1) : directionString = "DownRight"
	
	sprite.set_animation(cAni + directionString)
	if sprite.is_playing() == false : sprite.play()

func fireAt(location : Vector2) :
	print("Start")
	State = States.Firing
	direction = global_position.direction_to(location)
	cAni = "Prepare"
	await sprite.animation_finished
	cAni = "Charging"
	$StartCharge.play()
	$Orb/ChargeTimer.start()
	while charge < 1 :
		charge = 1.0 - ($Orb/ChargeTimer.time_left / $Orb/ChargeTimer.wait_time)
		charge = charge * charge
		chargingEffects()
		await get_tree().physics_frame
	
	cAni = "Fire"
	while sprite.frame != 22 :
		chargingEffects()
		await sprite.frame_changed
	
	while sprite.frame < 32 :
		chargingEffects()
		await sprite.frame_changed
	
	while sprite.frame < 47 :
		charge = 1 - (float(sprite.frame - 22) / 24.0)
		charge = sin(charge * (PI / 2))
		chargingEffects()
		await sprite.frame_changed
	
	charge = 0
	chargingEffects()
	for loop in loops : loop.stop()
	
	await sprite.animation_finished
	cAni = "HaloHover"
	State = States.Ready
	print("Done")

@onready var Eloop = $Orb/ELoop
@onready var TunnelLoop = $Orb/TunnelLoop
@onready var burger = $Orb/BurgerLoop
@onready var electricLoopA = $Orb/ElectricLoopA
@onready var electricLoopB = $Orb/ElectricLoopB
@onready var electricLoopC = $Orb/ElectricLoopC
@onready var rageLoop = $Orb/RageLoop
@onready var StaticLoop = $Orb/Static
@onready var LaserLoop = $Orb/Lasers
@onready var Choir = $Orb/Choir
@onready var loops = [Eloop, TunnelLoop, burger, electricLoopA, electricLoopB, electricLoopC, rageLoop, StaticLoop, LaserLoop, Choir]


func chargingEffects() :
	
	if cAni == "Charging" : sprite.speed_scale = lerp(0.5, 2.0, charge)
	else : sprite.speed_scale = 1
	var shakeMult = 16
	sprite.position = Vector2(randf_range(-1, 1) * charge * shakeMult, randf_range(-1, 1) * charge * shakeMult)
	var cam = $"../../Camera"
	var camShakeMult = 64 * (1 - sqrt(clamp(getDistanceTo(cam.global_position), 0, 8192) / 8192))
	cam.offset = Vector2(randf_range(-1, 1) * (charge * charge) * camShakeMult, randf_range(-1, 1) * (charge * charge) * camShakeMult)
	
	orb.scale = Vector2(lerp(0, 4, charge), lerp(0, 4, charge))
	orbParticles.amount_ratio = charge
	orbParticles.speed_scale = lerp(1.0, 16.0, charge)
	orb.position = lerp(Vector2(0, 128), Vector2(0, 192), charge) + Vector2(randf_range(-1, 1) * charge * shakeMult, randf_range(-1, 1) * charge * shakeMult)
	
	orbLight.energy = charge
	
	for loop in loops :
		loop.pitch_scale = lerp(0.25, 1.5, charge)
		loop.volume_db = lerp(-15, 5, charge)
		loop.max_distance = lerp(2048, 8192, charge)
		
		match loop.name :
			"BurgerLoop" : 
				loop.pitch_scale = lerp(0.25, 0.75, charge)
				loop.volume_db = lerp(-20.0, -5.0, charge)
				if loop.playing == false : loop.play()
			"Choir" :
				loop.pitch_scale = lerp(0.25, 2.0, charge)
				loop.stream.random_pitch = lerp(1.0, 1.25, charge * charge * charge * charge)
				loop.volume_db = lerp(-30.0, 0.0, charge)
				loop.play()
			_ :
				if loop.playing == false : loop.play()
