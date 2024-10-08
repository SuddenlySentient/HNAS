@icon("res://Assets/Facility/FacilityLogo.png")
extends Unit
class_name SUBRFL48

@onready var sprite : AnimatedSprite2D = $SUBSprite
@onready var flashlight : PointLight2D = $Flashlight
@onready var Step : AudioStreamPlayer2D = $Step
@onready var Fire : AudioStreamPlayer2D = $Fire
@onready var Selector : Sprite2D = $"CanvasLayer/Self Selector"
@onready var testTimer : Timer = $Test
@onready var gunModule : GunModule = $GunModule
@onready var fireArea : Area2D = $Flashlight/FireArea
@onready var test : Timer = $Test
@onready var voice : AudioStreamPlayer2D = $Voice

var speed : int = 200
@export var acceleration : float = 5
@export var turnSpeed : float = 6
@export var preferedSquadSize : int = 4
@export var pointsOnSplit : int = 10

enum Weapons {
SMG = 0,
Shotgun = 1
}
@export var weapon : Weapons = Weapons.SMG

@export_subgroup("SMG")
@export var SMGDMG : int = 2
@export var SMGAP : int = 3
@export var SMGInaccuracy : float = 5
@export var SMGRecoil : float = 5
var revved : float = 0.5

@export_subgroup("Shotgun")
@export var ShotgunDMG : int = 2
@export var ShotgunAP : int = 2
@export var ShotgunInaccuracy : float = 30
@export var ShotgunRecoil : float = 64
@export var ShotgunMaxPellets : int = 8
@export var ShotgunMinPellets : int = 4

enum States {
Unidle = 0,
Idle = 1,
Move = 2,
Shoot = 3,
Approach = 4
}
var State = States.Move



func initUnit() :
	testTimer.wait_time = randf_range(1.0, 2.0)
	vision = $Flashlight/Vision
	nav = $SUBNavigation
	var randWeapon = randi_range(0, 2)
	match randWeapon :
		0, 1 : weapon = Weapons.SMG
		2 : weapon = Weapons.Shotgun

func getName() :
	var newName = type + "-" + str(randi_range(0 , 9)) + str(randi_range(0 , 9)) + str(randi_range(0 , 9))
	var everythingInMap = map.get_children()
	for thing in everythingInMap :
		if thing.name == newName : newName = getName()
	return newName

func think(delta) :
	
	if isLeader and followers.size() == 0 : 
		isLeader = false
		inSquad = false
	
	if HP < ((maxHP/4.0) * 3.0) : voice.tryVoice("Injured")
	
	aggroList.clear()
	for thing in checkVision() :
		if thing is Unit :
			if isFoe(thing) : 
				if aggroList.has(thing) == false : aggroList.append(thing)
			elif thing is SUBRFL48 : squadLogic(thing)
	
	if aggroList.size() > 0 :
		aggroTarget = aggroList[0]
		if State != States.Shoot and State != States.Approach : 
			voice.tryVoice("FoundEnemies")
			State = States.Shoot
	else : aggroTarget = null 
	#elif State == States.Shoot or State == States.Approach : State = States.Idle
	
	if State != States.Idle : actionQuery()
	
	velocity = velocity.lerp(Vector2.ZERO, delta)
	
	match State :
		States.Idle : idle(delta)
		States.Move : move(delta)
		States.Approach : move(delta)
		States.Shoot : shoot(delta)
	
	flashlight.rotation = direction.angle() - PI/2
	
	move_and_slide()
	velocity = get_real_velocity()
	
	if sprite.speed_scale != 0 and sprite.is_playing() == false :
		sprite.play()
	
	if cAni == "Walk" :
		var moveDirection = velocity.normalized()
		if moveDirection.dot(direction) > 0.5 :
			sprite.speed_scale = velocity.length()/100
			Step.volume_db = round(((velocity.length()/speed) * 15) - 30)
		else :  sprite.speed_scale = 0
		if sprite.speed_scale == 0 :
			sprite.frame = 0
	if cAni == "Shoot" :
		if sprite.is_playing() == false : sprite.play()
		if fireArea.get_overlapping_bodies().any(allies) : 
			State = States.Approach
			revved = 0.25

func allies(node) :
	if node != self :
		if node is Unit and isFoe(node) == false :
			return true
	return false

func squadLogic(node : SUBRFL48) :
	
	var notTnMySquad : bool = true
	if inSquad and isLeader == false :
		for follower in leader.followers : 
			if follower == node : notTnMySquad = false
	
	if node != null and node != self and leader != node and notTnMySquad :
		
		match node.isLeader :
			true : 
				if inSquad :
					if isLeader == false :
						if leader.followers.size() + 1 == preferedSquadSize : pass
						elif leader.followers.size() + 1 <= node.followers.size() + 1 : joinSquad(node) 
					#they are a leader, I am not a leader, I am in a squad, and their squad has more than mine
				else : 
					joinSquad(node) 
				#they are a leader, and I am not in a squad
			false : 
				match node.inSquad :
					true : 
						squadLogic(node.leader)
					#they are not a leader, and they are in a squad
					false :  if inSquad == false : 
						joinSquad(node)
					#they are not a leader, and they are not in a squad, and I am not in a squad

func joinSquad(node : SUBRFL48) :
	
	if inSquad : leaveSquad()
	
	if node != self and node != null and node != leader :  
		node.isLeader = true
		node.followers.append(self)
		leader = node
		leader.inSquad = true
		inSquad = true
		isLeader = false
		#print(self.name," : Joined ", node.name, "'s squad")

func leaveSquad() :
	
	if isLeader :
		#print(self.name, " : Leaving my Squad")
		var firstFollower = followers[0]
		for follower in followers : 
			if follower == null : 
				pass
				#print(self.name, " : Follower Is null")
			else :
				#print(self.name, " : Removing ",follower.name, " from my squad")
				follower.leader = null
				follower.inSquad = false
				follower.joinSquad(firstFollower)
		followers = []
	if inSquad and leader != null :
		leader.followers.erase(self)
		#print(self.name, " : Leaving ", leader.name, "'s Squad")
		if leader.followers.size() == 0 :
			leader.isLeader = false
			leader.inSquad = false
	leader = null
	isLeader = false
	inSquad = false

func reachable(_positionToTest : Vector2) : #finish this
	return true
	#var oldNav = nav.target_position
	#nav.target_position = positionToTest
	#nav.get_next_path_position()
	#var value = nav.is_target_reachable()
	#nav.target_position = oldNav
	#return value

var inSquad : bool = false
var isLeader : bool = false
var leader : SUBRFL48 = null
var followers : Array[SUBRFL48] = []

var avoidenceVelocity : Vector2 = Vector2.ZERO

func actionQuery() :
	match inSquad :
		false : #alone logic
			if State != States.Shoot and State != States.Approach : voice.tryVoice("Alone")
		true : 
			match isLeader :
				false : #follower logic, probably ask leader
					
					if leader == null :
						leaveSquad()
					else :
						
						var leaderPos : Vector2 = leader.global_position
						var leaderFollowers : Array[SUBRFL48] = leader.followers.duplicate()
						
						match State :
							States.Move :
								voice.tryVoice("Search")
							States.Shoot :
								if leaderFollowers.size() > aggroList.size() :
									voice.tryVoice("Outnumber")
							States.Approach :
								if aggroTarget != null : nav.target_position = aggroTarget.position
						var tarPos : Vector2 
						var myPlace = leaderFollowers.find(self)
						if myPlace == 0 : tarPos = leaderPos
						else : 
							while leaderFollowers[myPlace - 1] == null : 
								leaderFollowers.remove_at(myPlace - 1)
							tarPos = leaderFollowers[myPlace - 1].global_position
						#if tarPos.distance_to(position) < 256 : speed = leader.speed
						if tarPos.distance_to(position) > 4096 : leaveSquad()
						#else : speed = int(maxSpeed * sqrt(clamp((float(HP)/float(maxHP)), 0.5, 1)))
						#nav.max_speed = speed
						Selector.inFrontPos = tarPos
						if State == States.Move :
							nav.target_position = tarPos
						nav.avoidance_priority = clampf(((1.0 / leaderFollowers.size()) * (myPlace + 1)), 0, 1)
				true : #leader Logic
					
					var newFollowerList : Array[SUBRFL48] = []
					for thing in followers :
						#if thing == null : print("purged")
						if thing != null and newFollowerList.has(thing) == false : newFollowerList.append(thing)
					followers = newFollowerList
					
					if followers.size() + 1 >= preferedSquadSize * 2 :
						if followers[0] == null : 
							followers.remove_at(0)
							return false
						var secondLeader = followers[0]
						secondLeader.leaveSquad()
						for x in preferedSquadSize - 1 :
							followers[x + 1].joinSquad(secondLeader)
						print(name, " : split squad")
						givePoints(pointsOnSplit, "Squad Split")

func move(delta) :
	
	cAni = "Walk"
	
	var target = nav.get_next_path_position()
	#print(nav.distance_to_target())
	
	const randoTurn = 0.001
	
	var vectorToTarget = global_position.direction_to(target)
	
	match State :
		States.Move :
			direction = lerp(direction, vectorToTarget, turnSpeed * delta).normalized()
			direction = direction + Vector2(randf_range(-randoTurn, randoTurn), randf_range(-randoTurn, randoTurn))
			velocity = velocity.lerp((direction * speed) + (avoidenceVelocity * 0.75), acceleration * delta)
		States.Approach :
			match weapon :
				Weapons.SMG :
					$Flashlight/FireArea/SMGFireCollision.disabled = false
					$Flashlight/FireArea/ShotgunFireCollision.disabled = true
				Weapons.Shotgun :
					$Flashlight/FireArea/SMGFireCollision.disabled = true
					$Flashlight/FireArea/ShotgunFireCollision.disabled = false
			
			if aggroTarget == null : 
				State = States.Move
				return false
			var distanceToTarget = global_position.distance_to(aggroTarget.position)
			var vectorToLeader = Vector2.ZERO
			if leader != null : vectorToLeader = global_position.direction_to(leader.position) * -0.25
			direction = lerp(direction, vectorToTarget.normalized(), turnSpeed * delta).normalized()
			direction = direction + Vector2(randf_range(-randoTurn, randoTurn), randf_range(-randoTurn, randoTurn))
			vectorToTarget = vectorToTarget * (-1 * (1 - (clamp(distanceToTarget, 0, 512)/256)))
			velocity = velocity.lerp(((direction + vectorToTarget + vectorToLeader).normalized() * speed) + (avoidenceVelocity * 0.75), acceleration * delta)
			nav.target_position = aggroTarget.position
			if fireArea.overlaps_body(aggroTarget) and fireArea.get_overlapping_bodies().any(allies) == false :
				State = States.Shoot

func idle(delta) :
	velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)

func shoot(delta) :
	velocity = velocity.lerp(Vector2.ZERO, delta) + avoidenceVelocity
	testTimer.stop()
	cAni = "Shoot"
	
	match weapon :
		Weapons.SMG : 
			$Flashlight/FireArea/SMGFireCollision.disabled = false
			$Flashlight/FireArea/ShotgunFireCollision.disabled = true
			sprite.speed_scale = 1 * revved
		Weapons.Shotgun : 
			$Flashlight/FireArea/SMGFireCollision.disabled = true
			$Flashlight/FireArea/ShotgunFireCollision.disabled = false
			sprite.speed_scale = (0.5 / revved) + 0.25
	
	if aggroList.is_empty() : 
		aggroTarget = null
		revved = 0.5
		goIdle(0, 3)
	else :
		revved += delta / 8
		revved = clampf(revved, 0.5, 2)
		$Fire.pitch_scale = revved / 2
		aggroTarget = aggroList[0]
		if fireArea.overlaps_body(aggroTarget) == false :
			State = States.Approach
		direction = lerp(direction, position.direction_to(aggroTarget.position), turnSpeed * delta).normalized()
		if sprite.speed_scale == 0 : velocity.lerp((aggroTarget.position.direction_to(position) * speed), acceleration * delta)

func goIdle(lowerRange : float = 3, UpperRange : float = 6) :
	#print("Going Idle")
	cAni = "Walk"
	State = States.Idle
	var timer : Timer = $IdleTimer
	timer.wait_time = randf_range(lowerRange, UpperRange)
	timer.start()

var cAni : String = "Walk"
var prevAni = ""
var prevCAni = ""

func _process(_delta):
	
	if inSquad and isLeader == false : 
		flashlight.enabled = false
		flashlight.shadow_enabled = false
	else : 
		flashlight.enabled = true
		flashlight.shadow_enabled = true
	flashlight.energy = (flashlight.energy + randf_range(float(HP)/float(maxHP), 0.8))/2
	
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
	
	var weaponString : String
	match weapon :
		Weapons.SMG : weaponString = "SMG"
		Weapons.Shotgun : weaponString = "Shotgun"
	
	var frame = sprite.frame
	sprite.set_animation(weaponString + cAni + directionString)
	if prevAni != sprite.animation and cAni == prevCAni :
		sprite.frame = frame
		prevAni = sprite.animation
	prevCAni = cAni

func roundDirection(toRound : Vector2) :
	return Vector2(round(toRound.x), round(toRound.y)).normalized()

func _on_idle_timer_timeout():
	State = States.Move

func _on_animated_sprite_2d_frame_changed():
	if sprite.animation.contains("Walk") :
		if sprite.frame == 16 or sprite.frame == 0 :
			Step.play()
	if sprite.animation.contains("Shoot") :
		match weapon :
			Weapons.SMG :
				if sprite.frame == 1 :
					Fire.play()
					gunModule.fire(SMGDMG, SMGAP, direction, SMGInaccuracy * revved, 64)
					velocity += (direction * -1) * SMGRecoil
			Weapons.Shotgun :
				match sprite.frame :
					8 : $PumpB.play()
					10 : $PumpA.play()
					1 :
						$ShotgunA.play()
						$ShotgunB.play()
						var ShotgunPellets = randi_range(ShotgunMinPellets, ShotgunMaxPellets)
						var accuracy = (ShotgunInaccuracy / 2) + ((ShotgunInaccuracy / 2) / revved)
						for x in ShotgunPellets :
							gunModule.fire(ShotgunDMG, ShotgunAP, direction, accuracy, 192, randf_range(8192, 16384))
						velocity += (direction * -1) * ShotgunRecoil

func _on_sub_navigation_navigation_finished():
	
	if isLeader or (inSquad == false) :
		var currentTile = map.local_to_map(nav.target_position)
		trySeeTile(currentTile)
		
		if trySeeTile(map.local_to_map(nav.target_position)) :
			var tileToGoTo = getTileToSearch()
			nav.set_target_position(map.map_to_local(tileToGoTo))
			#print(self.name, " : searching ", tileToGoTo)

func _on_test_timeout():
	if isLeader or (inSquad == false) :
		#print("begin")
		var tileToGoTo = getTileToSearch()
		nav.set_target_position(map.map_to_local(tileToGoTo))
		#print(self.name, " : searching ", tileToGoTo)

func _on_sub_navigation_velocity_computed(safe_velocity): 
	avoidenceVelocity = safe_velocity

func die(_source : String) :
	#if $SUBCollision != null :
	#	$SUBCollision.free()
	#print(self.name, " : Died to ", source)
	leaveSquad()
	queue_free()

func getKill(_who : Unit) :
	while State == States.Shoot or State == States.Approach :
		await get_tree().physics_frame
	voice.tryVoice("GetKill")

func indirectDMG(_who : Unit, amount : int) :
	if amount == 0 : voice.tryVoice("NoDMG")
	else : voice.tryVoice("DealDMG")

func _on_hurt(_DMG, DMGtype) :
	
	voice.tryVoice("Hurt")
	
	match DMGtype :
		"Melee" :
			revved = 0.5
		_ :
			revved = revved / 1.5

func _on_unseen_sense(sensedThing: Dictionary) :
	if sensedThing["Type"] == 0 and sensedThing["Strength"] > 0.25 :
		if randi_range(1, round((1.0 - sensedThing["Strength"]) * 100)) == 1 :
			voice.tryVoice("Hear")
