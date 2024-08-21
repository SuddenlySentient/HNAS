@icon("res://Assets/Seraph/Icon.png")
extends Unit
class_name Seraph

@export var lightRotateSpeed : float = 0.25
@onready var sprite : AnimatedSprite2D = $Sprite
@onready var fireball : GunModule = $Fireball
@export var maxStamina : int = 5
@export var staminaRegen : float = 2
var stamina : int
var brightness : float = 0
@export var teleportTimePerTile : float = 0.125

enum States {
Relaxed = 0,
Searching = 1,
Enraged = 2
}
var State = States.Searching



func _init():
	await ready
	stamina = maxStamina
	HP = maxHP
	sprite.play()
	vision = $Vision
	$StaminaRegen.wait_time = staminaRegen
	name = getName()

func getName() :
	var newName = nameList.pick_random() + "-" + str(randi_range(0 , 9))
	var everythingInMap = map.get_children()
	for thing in everythingInMap :
		if thing.name == newName : newName = getName()
	return newName

func _physics_process(delta) :
	
	if is_nan(position.x) : 
		push_error("Seraph Velocity Error")
		global_position = Vector2.ZERO
		velocity = Vector2.ZERO
	
	velocity = lerp(velocity, Vector2.ZERO, delta)
	move_and_slide()
	
	#if velocity != Vector2.ZERO :
	#	direction = velocity.normalized()
	#else : direction = Vector2.DOWN
	
	$CanvasLayer/FireEmbers.position = global_position
	var hpRemaining = 1 - (float(HP) / float(maxHP))
	$Steam.volume_db = lerp(-50, 0, hpRemaining)
	
	
	var recentVision = checkVision()
	
	for thing in recentVision :
		if thing is Unit :
			if isFoe(thing) : aggroList.append(thing)
	
	var newAggroList : Array[Unit] = []
	for thing in aggroList :
		if thing != null and newAggroList.has(thing) == false : newAggroList.append(thing)
	aggroList = newAggroList
	
	if aggroList.size() > 0 : 
		var newAggro = null
		for aggro in aggroList :
			if canSeeTarget(global_position, aggro.global_position) :
				newAggro = aggro
		if newAggro != null : aggroTarget = newAggro
		State = States.Enraged
	else : 
		aggroTarget = null
	
	if aggroTarget == null or aggroTarget.canBeSeen == false :
		aggroTarget = null
		State = States.Searching
	
	#if aggroTarget != null :
	#	$Line2D.points[0] = global_position
	#	$Line2D.points[1] = aggroTarget.global_position
	
	
	match State :
		States.Searching :
			move(delta)
			if HP < maxHP : 
				if useStamina(1) : heal(1)
			if stamina > 4 and $TestTimer.is_stopped() and $TeleportTimer.is_stopped() : 
				$TestTimer.start()
		States.Enraged :
			if stamina > 4 :
				if aggroTarget == null : 
					State = States.Searching
					return false
				match canSeeTarget() :
					false :
						var dodgeTile = getSeeingTile()
						if dodgeTile is Vector2i :
							await teleport(map.map_to_local(dodgeTile))
						else : 
							#aggroTarget = null
							aggroList.erase(aggroTarget)
					true :
						attack()

func _process(delta) :
	brightness = lerpf(brightness, ((float(stamina) / float(maxStamina)) * 0.6) + 0.4, delta)
	$HeavenlyLight.texture_scale = brightness * 6
	$HeavenlyLight.rotate(delta * (lightRotateSpeed / (brightness * brightness)))
	$HeavenlyLight.color = lerp(Color("e63900"), Color("ffeabf"), brightness)
	sprite.modulate = lerp(Color("cccccc"), Color("404040"), brightness)
	$Choir.pitch_scale = brightness * (3.0/4.0)

func teleport(location, dodgeing = false) :
	var cost = 1
	if location is Vector2 == false : return false
	#if getDistanceTo(location) <= 384 : cost = 0.5
	if ($TeleportTimer.is_stopped() or dodgeing) and useStamina(cost) :
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
		#if dodgeing == false : 
		$TeleportTimer.start(teleportTimePerTile * distance)
		await $TeleportTimer.timeout
		#else : await get_tree().process_frame
		#print("Test")
		brightness = 0
		global_position = location
		#print(aggroTarget.name)
		if aggroTarget != null and canSeeTarget() : attack()
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
		return true
	else : 
		#newSpark()
		#$Fail.play()
		return false

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
	direction = Vector2.ZERO
	for raycast in raycasts :
		if raycast.is_colliding() : 
			var distance = getDistanceTo(raycast.get_collision_point())
			var value = (raycast.get_collision_point() - raycast.global_position) * (512 - distance)
			direction += -value
	direction = direction.normalized()
	velocity += direction * maxSpeed * delta
	#$Sprite2D.global_position = (direction * 128) + global_position
	move_and_slide()
	velocity = get_real_velocity()

func getSeeingTile():
	
	var target = aggroTarget.global_position
	
	var tilesCoords : Array[Vector2i] = map.get_used_cells()
	var tileValue : Array = []
	var theOne = null
	const maxSearchDistance = 2048
	
	for tile in tilesCoords :
		var distanceTo = getDistanceTo(target)
		var distanceToTile = getDistanceTo(map.map_to_local(tile))
		if distanceToTile <= maxSearchDistance and getTileNavigable(tile) and canSeeTarget(map.map_to_local(tile)) :
			var newEntry = -distanceTo
			tileValue.append(newEntry)
			tileValue.sort()
			#tileValue.reverse()
			if newEntry == tileValue[0] : 
				theOne = tile
	
	#if theOne == null :
	#	aggroList.erase(aggroTarget)
	#	aggroTarget = null
	
	return theOne

@export_subgroup("Fireball")
@export var fireballDMG : int = 12
@export var fireballAP : int = 3
@export var fireballInaccuracy : float = 0

@export_subgroup("PlasmaRay")
@export var plasmaRayDMG : int = 14
@export var plasmaRayAP : int = 4
@export var plasmaRayMaxArc : float = 90
@export var plasmaRayMinArc : float = 5

@onready var plasmaRay = load("res://Assets/Base/PlasmaRay/PlasmaRay.tscn")

func attack() :
	var aggroTargetPos = aggroTarget.position
	var randNum = randi_range(0, 1)
	match randNum :
		0 :
			fireFireball(aggroTargetPos)
		1 :
			firePlasmaRay(aggroTargetPos)

func firePlasmaRay(location : Vector2) :
	if useStamina(1) :
		var vectorToTarget = global_position.direction_to(location)
		var distanceToTarget = global_position.distance_to(location)
		distanceToTarget = clampf(distanceToTarget / 4096, 0, 1)
		var newPlasmaRay = plasmaRay.instantiate()
		newPlasmaRay.DMG = plasmaRayDMG
		newPlasmaRay.AP = plasmaRayAP
		newPlasmaRay.targetVector = vectorToTarget
		var arc = lerpf(plasmaRayMaxArc, plasmaRayMinArc, distanceToTarget)
		newPlasmaRay.arcLength = deg_to_rad(arc) / 2.0
		newPlasmaRay.myOwner = self
		add_child(newPlasmaRay)
		newPlasmaRay.global_position = global_position + (vectorToTarget * 256)

func fireFireball(location : Vector2) :
	if useStamina(1) :
		var vectorToTarget = global_position.direction_to(location)
		fireball.fire(fireballDMG, fireballAP, vectorToTarget, fireballInaccuracy, 384, 64)
		velocity += vectorToTarget * -128

func useStamina(amount : int) :
	
	if stamina >= amount :
		stamina -= amount
		$StaminaRegen.start()
		return true
	else : 
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
	else : return map.local_to_map(global_position)

func adjustDMG(DMGDealt : int, dealer : Unit, DMGtype : String, source : Node = null) :
	if dealer != self :
		aggroList.append(dealer)
		aggroTarget = dealer
	
	if stamina >= 1 and DMGDealt > 0 and DMGtype != "Instant" and DMGtype != "Effect" : 
		var teleportTarget = map.map_to_local(getNearTile())
		if aggroTarget != null : 
			var seeingTile = getSeeingTile()
			if seeingTile is Vector2i :
				teleportTarget = map.map_to_local(seeingTile)
		if teleportTarget is Vector2 :
			teleport(teleportTarget, true)
			hitmarker("AVOIDED", 2, Color.from_hsv(0.1, 0.8, 1, 1))
			DMGDealt = 0
	
	if DMGtype == "Effect" :
		if source.type == "Burning" : 
			heal(DMGDealt)
			DMGDealt = 0
			source.cease()
	
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
		$Regen.pitch_scale = (maxRegenPitch / float(maxStamina)) * stamina
		$Regen.play()

func _on_test_timer_timeout():
	teleport(map.map_to_local(getTileToSearch(-1, 0.125)))

func die(_cause : String) :
	newSpark()
	queue_free()
