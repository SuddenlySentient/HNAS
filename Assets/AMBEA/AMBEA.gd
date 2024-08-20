extends Unit

@onready var sprite = $Sprite
@onready var orb = $Rotate/Orb
@onready var orbParticles = $Rotate/Orb/OrbParticles
@onready var orbLight = $Rotate/Orb/OrbLight
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
	openHalo()

func _physics_process(delta):
	move(delta)
	$Rotate.rotation = direction.angle() - (PI/2)
	if $Rotate/BeamRay.is_colliding() :
		$Rotate/BeamRay/Sprite2D.global_position = $Rotate/BeamRay.get_collision_point()
	if State == States.Ready :
		fireAt(global_position + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)).normalized())

func _process(_delta):
	
	if $Hover.playing == false : $Hover.play()
	var wax
	if cAni.contains("Hover") : 
		var velocityLength = clamp(velocity.length(), 0, 1)
		$Hover.pitch_scale = lerp(1.0, 1.5, velocityLength)
		var spriteComp = ($Sprite.frame + $Sprite.frame_progress) / 24
		wax = lerp(0.0, 4.0, spriteComp)
	else : 
		$Hover.pitch_scale = 1
		wax = 2
	var hoverWax = sin((wax / 4) * PI)
	$Hover.volume_db = lerpf(-7.5, -15, hoverWax)
	
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
	
	if cAni == "Fire" and sprite.frame != 0 : pass
	else : sprite.set_animation(cAni + directionString)
	if sprite.is_playing() == false : sprite.play()

func _on_sprite_frame_changed() -> void :
	match cAni :
		"HaloHover" :
			match sprite.frame :
				4 : $HaloSounds/Scrape.play(randf_range(0.0, 3))
				20 : $HaloSounds/Scrape.stop()
		"Charging" :
			match sprite.frame :
				4 : $HaloSounds/Scrape.play(randf_range(0.0, 3))
				0 : $HaloSounds/Scrape.stop()
		"HaloOpen" :
			match sprite.frame :
				3 : $"HaloSounds/Fae Cast A".play()
				12 : $HaloSounds/MetalSlam.play()
		"Prepare" :
			match sprite.frame :
				0 : 
					$"HaloSounds/Fae Cast B".play()
					$HaloSounds/Scrape.play()
				20 : 
					$"HaloSounds/Fae Cast A".play()
					$HaloSounds/Scrape.play()
				26 : 
					$HaloSounds/MetalSlam.play()
					$HaloSounds/Scrape.stop()
		"Fire" :
			match sprite.frame :
				0 : 
					$"HaloSounds/Fae Unbreak".play()
					$HaloSounds/Scrape.play(randf_range(0.0, 3))
				16 : 
					$"HaloSounds/Fae Shot".play()
					$HaloSounds/Scrape.play(randf_range(0.0, 3))
				32 : 
					$"HaloSounds/Fae Cast B".play()
					$HaloSounds/Scrape.play(randf_range(0.0, 3))
				47 : $HaloSounds/MetalSlam.play()

func openHalo() :
	if cAni != "Hover" : return false
	print("Opening Halo")
	cAni = "HaloOpen"
	await sprite.animation_finished
	print("Done Opening Halo")
	cAni = "HaloHover"

func fireAt(location : Vector2) :
	if cAni.contains("Halo") == false : 
		if cAni == "Hover" : await openHalo()
		else : return false
	print("Start")
	State = States.Firing
	direction = global_position.direction_to(location)
	cAni = "Prepare"
	await sprite.animation_finished
	cAni = "Charging"
	$StartCharge.play()
	var hpRemaining = float(HP) / float(maxHP)
	$Rotate/Orb/ChargeTimer.start(lerpf(5, 15, hpRemaining))
	
	while charge < 1 :
		charge = 1.0 - ($Rotate/Orb/ChargeTimer.time_left / $Rotate/Orb/ChargeTimer.wait_time)
		charge = charge * charge
		chargingEffects()
		await get_tree().physics_frame
		if aggroTarget != null : direction = global_position.direction_to(aggroTarget.position)
	
	cAni = "Fire"
	while sprite.frame != 22 :
		chargingEffects()
		await sprite.frame_changed
	
	damagedUnits.clear()
	
	$Rotate/BeamA.play()
	#$Rotate/BeamA.volume_db = 0
	$Rotate/BeamA.pitch_scale = 1.5
	
	while sprite.frame < 32 : #fire
		chargingEffects()
		var widthStep = (sprite.frame - 22) / 10.0
		widthStep = sin(widthStep * (PI / 2))
		$Rotate/Line.width = lerpf(0, 192, widthStep)
		hitBeam()
		if $Rotate/BeamA.playing == false : $Rotate/BeamA.play()
		await sprite.frame_changed
	
	while sprite.frame < 47 :
		charge = 1 - (float(sprite.frame - 22) / 24.0)
		charge = sin(charge * (PI / 2))
		$Rotate/Line.width = lerp(0, 192, charge)
		#$Rotate/BeamA.volume_db = lerpf(-20, 0, charge)
		chargingEffects()
		hitBeam()
		if $Rotate/BeamA.playing == false : $Rotate/BeamA.play()
		await sprite.frame_changed
	
	$Rotate/BeamA.stop()
	
	$Rotate/Line.width = 0
	charge = 0
	chargingEffects()
	for loop in loops : loop.stop()
	
	await sprite.animation_finished
	cAni = "HaloHover"
	State = States.Ready
	print("Done")

@onready var Eloop = $Rotate/Orb/ELoop
@onready var TunnelLoop = $Rotate/Orb/TunnelLoop
@onready var burger = $Rotate/Orb/BurgerLoop
@onready var electricLoopA = $Rotate/Orb/ElectricLoopA
@onready var electricLoopB = $Rotate/Orb/ElectricLoopB
@onready var electricLoopC = $Rotate/Orb/ElectricLoopC
@onready var rageLoop = $Rotate/Orb/RageLoop
@onready var StaticLoop = $Rotate/Orb/Static
@onready var LaserLoop = $Rotate/Orb/Lasers
@onready var Choir = $Rotate/Orb/Choir
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
	var direct = abs(direction.dot(Vector2.LEFT)) + 1
	orb.position = orb.position * direct
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

var damagedUnits : Array[Unit] = []
@export var beamDmg : int = 64
@export var beamShake : int = 4

func hitBeam() :
	if $Rotate/BeamRay.is_colliding() :
		$Rotate/BeamA.pitch_scale = lerpf(0.25, 1.5, charge)
		var hit = $Rotate/BeamRay.get_collider()
		var hitLocation = $Rotate/BeamRay.get_collision_point()
		$Rotate/BeamA.global_position = hitLocation
		$Rotate/Line.points[1] = Vector2(0, global_position.distance_to(hitLocation))
		if hit is Unit and damagedUnits.has(hit) == false :
			hit.damage(beamDmg, 256, self, "Instant", self)
			damagedUnits.append(hit)
		if hit is TileMapLayer :
			@warning_ignore("unused_variable")
			var hitTile = map.local_to_map(hitLocation)
			#print(hitTile)
	direction += Vector2.from_angle(randf_range(0, 359)) * get_process_delta_time() * beamShake * charge
	direction = direction.normalized()

@onready var raycasts : Array[RayCast2D] = [
	$RayCast,
	$RayCast2,
	$RayCast3,
	$RayCast4,
	$RayCast5,
	$RayCast6,
	$RayCast7,
	$RayCast8,
	$RayCast9,
	$RayCast10,
	$RayCast11,
	$RayCast12,
	$RayCast13,
	$RayCast14,
	$RayCast15,
	$RayCast16]

func move(delta) :
	
	var swayDirection = Vector2.ZERO
	for raycast in raycasts :
		if raycast.is_colliding() : 
			var distance = getDistanceTo(raycast.get_collision_point())
			var value = (raycast.get_collision_point() - raycast.global_position) * (512 - distance)
			swayDirection += -value
	swayDirection = swayDirection.normalized()
	velocity = lerp(velocity, Vector2.ZERO, delta)
	velocity += swayDirection * maxSpeed * delta
	move_and_slide()
	velocity = get_real_velocity()
