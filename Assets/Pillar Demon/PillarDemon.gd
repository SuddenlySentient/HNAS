extends Unit
class_name PillarDemon

enum States {
Idle = 0,
Swarm = 1,
Wander = 2,
Scatter = 3,
Attack = 4,
GroupUp = 5
}
var State = States.Idle

enum PillarStates {
Pillar = 0,
Emerge = 1,
Standing = 2,
UnEmerge = 3
}

var PillarState = PillarStates.Pillar

@onready var seeable = $Seeable
@onready var sprite : AnimatedSprite2D = $PDSprite
@export var minSize : float = 0.75
@export var maxSize : float = 1.5
@export var accelerate : float = 10
@export var deccelerate : float = 100
@export var runSpeedMult : float = 2
@export var seekOthersDesire : int = 4096
@export var swarmDesire : int = 2048
@export var desiredCompany : int = 2
@export var pointsOnSwarm : int = 3
@export_subgroup("Punch")
@export var DMG : int = 5
@export var AP : int = 1
var recentSeenCheck : bool = false
var thingsInVision
var cAni = "Emerge"



func initUnit() :
	idle()
	$Sniff/SniffTimer.start(randf_range(0, 60))
	vision = $Vision
	nav = $PDNav
	var randSize = randf_range(0, 1)
	randSize = sqrt(randSize)
	var randScale =  ((1 - randSize) + 1)
	$Buzz.pitch_scale = randScale
	$Sniff.pitch_scale = randScale
	$Skitter.pitch_scale = randScale
	$Emerge.pitch_scale = randScale
	$UnEmerge.pitch_scale = randScale
	$Swarm.pitch_scale = randScale
	#maxSpeed *= randScale
	#print(sprite.speed_scale)
	randSize = (randSize * (maxSize - minSize)) + minSize
	#print(randSize)
	maxHP = int(maxHP * randSize)
	HP = maxHP
	scale = Vector2(randSize, randSize)
	var randColor = Color.from_hsv(randf_range(0, 1), randf_range(0, 0.05), randf_range(0.75, 1), 1)
	modulate = randColor
	position += Vector2(randf_range(-64, 64), randf_range(-64, 64))
	$NavTimer.start(randf_range(1, 2))

func getName() :
	var newName = type + " " + "1"
	return newName

func think(delta) :
	
	recentSeenCheck = seenCheck()
	thingsInVision = checkVision(true)
	
	match PillarState :
		PillarStates.Pillar :
			pillarQuery(delta)
		PillarStates.Standing :
			actionQuery(delta)
	move_and_slide()
	velocity = get_real_velocity()

func actionQuery(delta) :
	ARM = 2
	reflectShots = false
	if State != States.Swarm and State != States.Attack and recentSeenCheck : 
		scatter(State != States.Scatter)
	var pillarArray : Array = []
	for thing in thingsInVision :
		if thing is PillarDemon and isFoe(thing) == false : pillarArray.append(thing)
	if pillarArray.size() > 0 :
		for pillar in pillarArray :
			if pillar.State == States.Swarm and pillar.aggroTarget != null :
				swarm(pillar.aggroTarget)
		if pillarArray.size() >= desiredCompany :
			if State == States.Wander or State == States.GroupUp :
				nav.target_position = pillarArray[0].position
				State = States.GroupUp
		elif global_position.distance_to(pillarArray[0].position) > 1024 :
			nav.target_position = pillarArray[0].position
			if pillarArray[0].PillarState == PillarStates.Pillar and pillarArray[0].recentSeenCheck == false :
				pillarArray[0].wander()
	if State == States.Swarm or State == States.Attack :
		$SwarmCooldown.start()
		if aggroList.size() > 0 and (aggroList[0] == null or aggroList[0].canBeSeen == false) : aggroList.remove_at(0)
		if aggroTarget == null : 
			if aggroList.size() > 0 : 
				aggroTarget = aggroList[0]
			else : idle()
		else : nav.target_position = aggroTarget.position
	var target = nav.get_next_path_position()
	var vectorToTarget = position.direction_to(target)
	const randoTurn = 0.001
	match State :
		States.Attack :
			velocity = Vector2.ZERO
			cAni = "Attack"
		States.Wander, States.GroupUp :
			if State == States.GroupUp :
				var distanceTo = global_position.distance_to(nav.target_position)
				if distanceTo < 512 :
					idle()
					return false
			cAni = "Skitter"
			direction = vectorToTarget
			direction += Vector2(randf_range(-randoTurn, randoTurn), randf_range(-randoTurn, randoTurn))
			velocity = lerp(velocity, direction * maxSpeed, delta * accelerate)
		States.Scatter, States.Swarm :
			if State == States.Swarm :
				if aggroTarget == null : return false
				direction = vectorToTarget
				if enemiesInRange([$RotateNode/PunchArea]) and getDistanceTo(nav.target_position) <= 192 : 
					direction = vectorToTarget
					attack()
					return false
			cAni = "Skitter"
			direction = vectorToTarget
			direction += Vector2(randf_range(-randoTurn, randoTurn), randf_range(-randoTurn, randoTurn))
			velocity = lerp(velocity, direction * maxSpeed * runSpeedMult, delta * accelerate)

func pillarQuery(delta) :
	ARM = 8
	reflectShots = true
	velocity = lerp(velocity, Vector2.ZERO, delta * deccelerate)
	var pillarArray : Array[Unit] = []
	var enemyArray : Array[Unit] = []
	for thing in thingsInVision :
		if thing is Unit :
			if thing is PillarDemon and isFoe(thing) == false : 
				if global_position.distance_to(thing.position) < 1024 :
					pillarArray.append(thing)
			elif isFoe(thing) : enemyArray.append(thing)
	
	if pillarArray.size() > 0 :
		for pillar in pillarArray :
			if pillar.State == States.Swarm and (pillar.aggroTarget == null) == false :
				swarm(pillar.aggroTarget)
	
	if enemyArray.size() > 0 :
		var ourStrength : float = HP
		var theirStrength : float = 0
		for pillar in pillarArray : ourStrength += pillar.HP
		for enemy in enemyArray : theirStrength += enemy.HP
		if ourStrength > theirStrength :
			var strengthRatio = theirStrength / ourStrength
			for enemy in enemyArray :
				if aggroList.has(enemy) == false :
					aggroList.append(enemy)
				$Swarm.volume_db = -30
				if $Swarm.playing == false : $Swarm.play()
			while aggroList.has(null) : aggroList.erase(null)
			if aggroList.size() > 0 and aggroList[0] != null and randi_range(1, swarmDesire * strengthRatio) == 1 :
				swarm(aggroList[0])
	
	if pillarArray.size() < desiredCompany and enemyArray.size() == 0 :
		if randi_range(1, seekOthersDesire) == 1 :
			wander()

func seenCheck() :
	var observers = seeable.get_overlapping_areas()
	var seen = false
	if observers.size() > 0 : 
		for observer in observers :
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(global_position, observer.owner.position, 1)
			var result = space_state.intersect_ray(query)
			if result and result.collider is Unit :
				if isFoe(result.collider) : seen = true
	return seen

func scatter(new : bool):
	if PillarState == PillarStates.Pillar : emerge()
	if new :
		nav.target_position = map.map_to_local(getTileToSearch(0, -1))
	if $Buzz.playing == false : $Buzz.play()
	$ScatterTimer.stop()
	State = States.Scatter
	if PillarState == PillarStates.Pillar : PillarState = PillarStates.Emerge

func idle() :
	#print("Going Idle")
	State = States.Idle
	if PillarState != PillarStates.Pillar : unEmerge()

func wander() :
	#print("Wandering")
	State = States.Wander
	nav.target_position = map.map_to_local(getTileToSearch())
	if PillarState == PillarStates.Pillar : emerge()

func swarm(target : Unit) :
	#print("Swarming")
	if $Swarm.playing == false : $Swarm.play()
	$Swarm.volume_db = -10
	aggroTarget = target
	if State != States.Swarm and $SwarmCooldown.is_stopped() : 
		$SwarmCooldown.start()
		givePoints(pointsOnSwarm, "Swarm")
	State = States.Swarm
	nav.target_position = aggroTarget.position
	if PillarState == PillarStates.Pillar : emerge()

func attack() :
	sprite.speed_scale = 1
	State = States.Attack
	cAni = "Attack"

func emerge() :
	canBeSeen = true
	cAni = "Emerge"
	sprite.play()
	$Emerge.play()
	PillarState = PillarStates.Emerge

func unEmerge() :
	$Skitter.stop()
	cAni = "Emerge"
	sprite.play_backwards()
	$UnEmerge.play()
	PillarState = PillarStates.UnEmerge

func _process(_delta):
	
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
	$RotateNode.rotation = altDirection.normalized().angle() - PI/2
	sprite.set_animation(cAni + directionString)
	
	if cAni == "Attack" : sprite.play()
	elif cAni == "Skitter" : 
		if $Skitter.playing == false : $Skitter.play()
		sprite.play()
		var moveDirection = velocity.normalized()
		if moveDirection.dot(direction) > 0.5 :
			sprite.speed_scale = (velocity.length() / 250) / scale.x
		else : sprite.speed_scale = 0
	else : sprite.speed_scale = 1

func _on_sniff_timer_timeout():
	$Sniff.play()
	var randTime = sqrt(randf_range(0, 1))
	randTime = randTime * 60
	if recentSeenCheck : randTime *= 4
	randTime = round(randTime)
	$Sniff/SniffTimer.start(randTime)
	if PillarState == PillarStates.Pillar and HP < maxHP : 
		#print(PillarState)
		heal(1)

func _on_hurt(_DMG, _DMGtype):
	if State != States.Swarm and State != States.Attack : scatter(false)

func _on_pd_sprite_animation_finished():
	if sprite.animation.contains("Emerge") :
		match PillarState :
			PillarStates.Emerge :
				PillarState = PillarStates.Standing
			PillarStates.UnEmerge :
				canBeSeen = false
				PillarState = PillarStates.Pillar
	elif sprite.animation.contains("Attack") :
		State = States.Swarm

func _on_pd_nav_navigation_finished():
	match State :
		States.Scatter :
			$ScatterTimer.stop()
			idle()
		States.Wander : 
			if trySeeTile(map.local_to_map(nav.target_position)) :
				nav.target_position = map.map_to_local(getTileToSearch())
		States.GroupUp, States.Swarm :
			idle()
			if State == States.Swarm and aggroTarget.canBeSeen == false : aggroTarget = null

func _on_nav_timer_timeout():
	match State :
		States.Scatter : 
			if recentSeenCheck :
				nav.target_position = map.map_to_local(getTileToSearch(0, -1))
				$ScatterTimer.stop()
			elif $ScatterTimer.is_stopped() : $ScatterTimer.start(randf_range(4, 16))
		States.Wander : 
			nav.target_position = map.map_to_local(getTileToSearch())

func _on_scatter_timer_timeout():
	idle()
	#print("Scatter Timer Ran Out")

func _on_swarm_finished():
	if State == States.Swarm : $Swarm.play()

@export var knockback : int = 128

func _on_pd_sprite_frame_changed():
	if cAni == "Attack" and sprite.frame == 9 :
		$Punch.play()
		var punching = $RotateNode/PunchArea.get_overlapping_bodies()
		for punched in punching :
			if punched is Unit and isFoe(punched) :
				punched.damage(DMG, AP, self, "Melee", self)
				punched.dealKnockback(knockback, global_position.direction_to(punched.position))

var death = load("res://Assets/Pillar Demon/pd_remains.tscn")

func die(_cause : String) :
	var newDeath = death.instantiate()
	newDeath.thisScale = $Sniff.pitch_scale
	newDeath.global_position = position
	newDeath.scale = scale
	map.add_child(newDeath)
	queue_free()
