@icon("res://Assets/Seraph/Icon.png")
extends Unit
class_name Seraph

@export var lightRotateSpeed : float = 0.25
@onready var sprite : AnimatedSprite2D = $Sprite
@export var maxStamina : int = 3
var stamina : float
var brightness : float = 0
@export var teleportTimePerTile : float = 0.125

enum States {
Relaxed = 0,
Searching = 1,
Enraged = 2
}
var State = States.Relaxed



func _init():
	await ready
	stamina = maxStamina
	print("START")
	HP = maxHP
	sprite.play()
	vision = $Vision

func _physics_process(delta) :
	
	velocity = lerp(velocity, Vector2.ZERO, delta)
	move(delta)
	move_and_slide()
	
	$CanvasLayer/FireEmbers.position = global_position
	
	match State :
		States.Searching :
			if stamina > 2 and $TestTimer.is_stopped() and $TeleportTimer.is_stopped() : 
				$TestTimer.start()

func _process(delta) :
	brightness = lerpf(brightness, ((float(stamina) / float(maxStamina)) * (3.0 / 5.0)) + 0.4, delta)
	$HeavenlyLight.texture_scale = brightness * 6
	$HeavenlyLight.rotate(delta * (lightRotateSpeed / (brightness * brightness)))
	$HeavenlyLight.color = lerp(Color("e63900"), Color("ffeabf"), brightness)
	sprite.modulate = lerp(Color("cccccc"), Color("404040"), brightness)
	$Choir.pitch_scale = brightness * (3.0/4.0)
	#print(brightness)

func teleport(location : Vector2) :
	
	var cost = 1
	if getDistanceTo(location) <= 384 : cost = 0.5
	if useStamina(cost) and $TeleportTimer.is_stopped() :
		$Choir/ChoirTimer.stop()
		$Choir.stop()
		newSpark()
		$Poof.play()
		$CanvasLayer/FireEmbers.hide()
		canBeSeen = false
		$Collision.set_deferred("disabled", true)
		sprite.hide()
		$HeavenlyLight.hide()
		var distance = (global_position.distance_to(location))/256
		$TeleportTimer.start(teleportTimePerTile * distance)
		await $TeleportTimer.timeout
		brightness = 0
		global_position = location
		velocity = Vector2.ZERO
		getTileToSearch(-1, 0.125)
		newSpark()
		sprite.show()
		$Choir/ChoirTimer.start()
		$HeavenlyLight.show()
		$CanvasLayer/FireEmbers.restart()
		$CanvasLayer/FireEmbers.show()
		$Collision.set_deferred("disabled", false)
		canBeSeen = true
		$Teleport.play()
	else : $Fail.play()

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
	$RayCast16
]

func move(delta) :
	
	var direction : Vector2 = Vector2.ZERO
	
	#print(raycast.rotation_degrees, " : ", Vector2.from_angle(raycast.rotation))
	
	for raycast in raycasts :
		
		if raycast.is_colliding() : 
			var distance = getDistanceTo(raycast.get_collision_point())
			var value = (raycast.get_collision_point() - raycast.global_position) * (512 - distance)
			direction += -value
	
	direction = direction.normalized()
	velocity += direction * maxSpeed * delta
	#$Sprite2D.global_position = (direction * 128) + global_position
	
	move_and_slide()

func useStamina(amount : float) :
	
	$StaminaRegen.start()
	
	if stamina >= amount :
		stamina -= amount
		print(stamina)
		return true
	else : 
		print(stamina)
		return false

@onready var sparks = load("res://Assets/Seraph/seraph_spark.tscn")

func newSpark() :
	var newSparks = sparks.instantiate()
	newSparks.location = global_position
	map.add_child(newSparks)

func getNearTile() :
	var adjTiles = map.get_surrounding_cells(map.local_to_map(global_position))
	var potentialTiles = [] 
	#print(map.local_to_map(global_position))
	for adjTile in adjTiles :
		#print(adjTile)
		if getTileNavigable(adjTile) and trySeeTile(adjTile) :
			potentialTiles.append(adjTile)
	if potentialTiles.size() > 0 : return potentialTiles.pick_random()
	else : return false

func damage(DMG : int, AP : int, dealer : Unit, source : Node = null) :
	
	var reduction = clampf( float(AP) / float(ARM), 0, 1)
	var DMGDealt = DMG * reduction
	var remainder = fmod(DMGDealt, 1)
	if remainder != 0 :
		DMGDealt = floor(DMGDealt)
		var chance = round((remainder * 100))
		if randi_range(1, 100) < chance : DMGDealt += 1
	
	if stamina > 0 : 
		var teleportHere = getNearTile()
		if teleportHere is Vector2i :
			teleport(map.map_to_local(teleportHere)) 
			DMGDealt = -1
	
	if DMGDealt > 0 : HP -= DMGDealt
	if source != dealer :
		dealer.indirectDMG(self, DMGDealt)
	if HP <= 0 : 
		dealer.getKill(self)
		die(source.name)
	
	if DMGDealt > 0 : 
		emit_signal("hurt", DMGDealt)
		var markSize = sqrt(float(DMGDealt) / 2.0)
		hitmarker(str(DMGDealt), markSize)
		print(name, " : ", DMGDealt, " DMG, ", round( (float(HP) / float(maxHP) ) * 100), "% HP")
	elif DMGDealt == 0 : hitmarker("0", 1, Color.from_hsv(0.6, 0.8, 1, 1))
	return DMGDealt



func _on_choir_timer_timeout():
	$Choir.play()

func _on_steam_finished():
	$Steam.play()

func _on_burning_a_finished():
	$BurningA.play()

func _on_burning_b_finished():
	$BurningB.play()

const maxRegenPitch : float = 2
func _on_stamina_regen_timeout():
	if stamina < maxStamina : 
		stamina += 1
		if stamina > maxStamina : stamina = maxStamina
		$StaminaRegen/Regen.pitch_scale = (maxRegenPitch / float(maxStamina)) * stamina
		$StaminaRegen/Regen.play()

func _on_test_timer_timeout():
	teleport(map.map_to_local(getTileToSearch(-1, 0.125)))
