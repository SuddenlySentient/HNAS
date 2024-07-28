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

var direction : Vector2 = Vector2(0, 1)
var speed : int = 200
@export var acceleration : float = 5
@export var turnSpeed : float = 6
@export var preferedSquadSize : int = 4

@export_subgroup("SMG")
@export var DMG : int = 2
@export var AP : int = 3
@export var inaccuracy : float = 5
@export var recoil : float = 5
var revved : float = 0.5

enum States {
Unidle = 0,
Idle = 1,
Move = 2,
Shoot = 3,
Approach = 4
}
var State = States.Move



func _init() :
	await ready
	HP = maxHP
	testTimer.wait_time = randf_range(1.0, 2.0)
	vision = $Flashlight/Vision
	nav = $SUBNavigation

func _physics_process(delta) :
	
	#var debugString : String = "Name = A, isLeader = X inSquad = Y Follower Count = Z"
	#debugString = debugString.replace("A", str(self.name))
	#debugString = debugString.replace("X", str(isLeader))
	#debugString = debugString.replace("Y", str(inSquad))
	#debugString = debugString.replace("Z", str(followers.size()) )
	#$DebugLabel.set_text(debugString)
	#$DebugLabel2.set_text(str(followers))
	
	if isLeader : 
		
		if is_instance_valid(followers[0]) == false :
			followers.remove_at(0)
		
		if followers.size() == 0 : 
			isLeader = false
			inSquad = false
	
	if HP < ((maxHP/4.0) * 3.0) : voice.tryVoice("Injured")
	
	aggroList.clear()
	for thing in checkVision() :
		if thing is Unit :
			if  thing.team != team : 
				if aggroList.has(thing) == false : aggroList.append(thing)
			elif thing is SUBRFL48 : squadLogic(thing)
	
	if aggroList.size() > 0 :
		aggroTarget = aggroList[0]
		if State != States.Shoot and State != States.Approach : 
			voice.tryVoice("FoundEnemies")
			State = States.Shoot
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
	
	if sprite.speed_scale != 0 and sprite.is_playing() == false :
		sprite.play()
	
	if cAni == "Walk" :
		sprite.speed_scale = velocity.length()/100
		Step.volume_db = round(((velocity.length()/speed) * 15) - 30)
		if sprite.speed_scale == 0 :
			sprite.frame = 0
	if cAni == "Shoot" :
		if sprite.is_playing() == false : sprite.play()
		if fireArea.get_overlapping_bodies().any(allies) : 
			State = States.Approach
			revved = 0.25

func allies(node) :
	if node != self :
		if node is Unit and node.team == team :
			return true
	return false

func exchangeTileInfo(node : Unit):
	var nodeTileInfo = node.lastSeenTile
	lastSeenTile.merge(nodeTileInfo)

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

func reachable(positionToTest : Vector2) : #finish this
	var oldNav = nav.target_position
	nav.target_position = positionToTest
	nav.get_next_path_position()
	var value = nav.is_target_reachable()
	nav.target_position = oldNav
	return value

var inSquad : bool = false
var isLeader : bool = false
var leader : SUBRFL48 = null
var followers : Array[SUBRFL48] = []

var avoidenceVelocity : Vector2 = Vector2.ZERO

func actionQuery() :
	
	match inSquad :
		false : #alone logic
			voice.tryVoice("Alone")
		true : 
			match isLeader :
				false : #follower logic, probably ask leader
					
					var leaderPos : Vector2 = leader.global_position
					
					if leader == null or reachable(leaderPos) == false :
						leaveSquad()
					else :
						var leaderFollowers : Array[SUBRFL48] = leader.followers.duplicate()
						
						lastSeenTile = leader.lastSeenTile
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
						if tarPos.distance_to(position) < 256 : speed = leader.speed
						if tarPos.distance_to(position) > 4096 : leaveSquad()
						else : speed = maxSpeed * sqrt(clamp((float(HP)/float(maxHP)), 0.5, 1))
						nav.max_speed = speed
						Selector.inFrontPos = tarPos
						if State == States.Move :
							nav.target_position = tarPos
						nav.avoidance_priority = clampf(((1.0 / leaderFollowers.size()) * (myPlace + 1)), 0, 1)
				true : #leader Logic
					pass
					#var tileToGoTo = getTileToSearch()
					#nav.set_target_position(map.map_to_local(tileToGoTo))

func move(delta) :
	
	cAni = "Walk"
	
	var target = nav.get_next_path_position()
	#print(nav.distance_to_target())
	
	const randoTurn = 0.001
	
	var vectorToTarget = position.direction_to(target)
	
	match State :
		States.Move :
			direction = lerp(direction, vectorToTarget, turnSpeed * delta).normalized()
			direction = direction + Vector2(randf_range(-randoTurn, randoTurn), randf_range(-randoTurn, randoTurn))
			velocity = velocity.lerp((direction * speed) + (avoidenceVelocity * 0.75), acceleration * delta)
		States.Approach :
			if aggroTarget == null : return false
			var distanceToTarget = position.distance_to(aggroTarget.position)
			#if distanceToTarget < 512 : vectorToTarget = vectorToTarget * -1
			vectorToTarget = vectorToTarget * (-1 * (1 - (clamp(distanceToTarget, 0, 512)/256)))
			var vectorToLeader = Vector2.ZERO
			if leader != null : vectorToLeader = position.direction_to(leader.position) * -0.25
			direction = lerp(direction, (vectorToTarget + vectorToLeader).normalized(), turnSpeed * delta).normalized()
			direction = direction + Vector2(randf_range(-randoTurn, randoTurn), randf_range(-randoTurn, randoTurn))
			#print("Direction : ",direction, ", Direction to Target : ", vectorToTarget, ". Direction to Leader : ", vectorToLeader)
			velocity = velocity.lerp((direction * speed) + (avoidenceVelocity * 0.75), acceleration * delta)
			nav.target_position = aggroTarget.position
			if fireArea.overlaps_body(aggroTarget) and fireArea.get_overlapping_bodies().any(allies) == false :
				State = States.Shoot

func idle(delta) :
	velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)

func shoot(delta) :
	velocity = velocity.lerp(Vector2.ZERO, delta)
	testTimer.stop()
	cAni = "Shoot"
	sprite.speed_scale = 1 * revved
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
	
	sprite.set_animation(cAni + directionString)

func roundDirection(toRound : Vector2) :
	return Vector2(round(toRound.x), round(toRound.y)).normalized()

func _on_idle_timer_timeout():
	State = States.Move

func _on_animated_sprite_2d_frame_changed():
	if sprite.animation.contains("Walk") :
		if sprite.frame == 16 or sprite.frame == 0 :
			Step.play()
	if sprite.animation.contains("Shoot") :
		if sprite.frame == 1 :
			Fire.play()
			gunModule.fire(DMG, AP, direction, inaccuracy * revved)
			velocity += (direction * -1) * recoil

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
	if $SUBCollision != null :
		$SUBCollision.free()
	#print(self.name, " : Died to ", source)
	leaveSquad()
	queue_free()

func getKill(_who : Unit) :
	while State == States.Shoot :
		await get_tree().physics_frame
	voice.tryVoice("GetKill")

func indirectDMG(_who : Unit, amount : int) :
	if amount == 0 : voice.tryVoice("NoDMG")
	else : voice.tryVoice("DealDMG")
