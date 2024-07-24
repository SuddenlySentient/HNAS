@icon("res://Assets/Facility/FacilityLogo.png")
extends Unit
class_name SUBRFL48

@onready var sprite : AnimatedSprite2D = $SUBSprite
@onready var flashlight : PointLight2D = $Flashlight
@onready var Step : AudioStreamPlayer2D = $Step
@onready var Fire : AudioStreamPlayer2D = $Fire
@onready var Selector : Sprite2D = $"Self Selector"
@onready var testTimer : Timer = $Test
@onready var gunModule : GunModule = $GunModule
@onready var fireArea : Area2D = $Flashlight/FireArea
@onready var test : Timer = $Test
@onready var voice : AudioStreamPlayer2D = $Voice

var direction : Vector2 = Vector2(0, 1)
@export var maxSpeed : int = 200
var speed : int = 200
@export var acceleration : float = 5
@export var turnSpeed : float = 6
@export var preferedSquadSize : int = 4

@export_subgroup("SMG")
@export var DMG : int = 2
@export var AP : int = 3
@export var inaccuracy : float = 5
@export var recoil : float = 5
var revved : float = 0.25

enum States {
Unidle = 0,
Idle = 1,
Move = 2,
Shoot = 3
}
var State = States.Move



func _init():
	await ready
	HP = maxHP
	testTimer.wait_time = randf_range(1.0, 2.0)
	vision = $Flashlight/Vision
	nav = $SUBNavigation

func _physics_process(delta):
	
	if voice.playing == false : voice.tryVoice()
	
	speed = maxSpeed * clamp((float(HP)/float(maxHP)), 0.5, 1)
	if isLeader == false and inSquad and leader != null : speed = getLeader().speed
	 
	aggroList.clear()
	if inSquad and !isLeader : aggroList.append_array(getLeader().aggroList)
	
	for thing in checkVision() :
		if thing is Unit :
			if  thing.team != team : 
				if aggroList.has(thing) == false : aggroList.append(thing)
			elif thing is SUBRFL48 : squadLogic(thing)
	
	if aggroList.size() > 0 : State = States.Shoot
	if State != States.Idle : actionQuery()
	
	velocity = velocity.lerp(Vector2.ZERO, delta)
	
	match State :
		States.Idle : idle(delta)
		States.Move : move(delta)
		States.Shoot : shoot(delta)
	
	flashlight.rotation = direction.angle() - PI/2
	
	if move_and_slide() : 
		var collision = get_last_slide_collision()
		
		if collision.get_collider() is PhysicsBody2D :
			if collision.get_collider() is CharacterBody2D :
					collision.get_collider().velocity + ( velocity * delta) 
			if collision.get_collider() is RigidBody2D :
					collision.get_collider().apply_force(velocity * delta)
	
	nav.max_speed = speed
	
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
			sprite.speed_scale = 0
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
	
	if node != null and node != self and leader != node :
		
		#print(self.name," considering joining ", node.name, "'s squad, ", node.name, "'s isLeader : ", node.isLeader,", inSquad : ", node.inSquad)
		
		match node.isLeader :
			true : 
				if inSquad :
					if isLeader == false :
						if leader.followers.size() + 1 < node.followers.size() + 1 : joinSquad(node) 
					#they are a leader, I am not a leader, I am in a squad, and their squad has more than mine
				else : 
					node.exchangeTileInfo(self)
					joinSquad(node) 
				#they are a leader, and I am not in a squad
			false : 
				match node.inSquad :
					true : squadLogic(node.getLeader())
					#they are not a leader, and they are in a squad
					false :  if inSquad == false : 
						node.exchangeTileInfo(self)
						joinSquad(node)
					#they are not a leader, and they are not in a squad, and I am not in a squad

func joinSquad(node : SUBRFL48) :
	
	if inSquad : leaveSquad()
	
	node.isLeader = true
	node.followers.append(self)
	leader = node
	leader.inSquad = true
	inSquad = true
	
	if isLeader :
		isLeader = false
		for follower in followers :
			if follower != null :
				follower.leader = node
				node.followers.append(follower)
		followers = []
	
	#print(self.name," has joined ", node.name, "'s squad")

func leaveSquad() :
	
	if leader :
		for follower in followers : follower.leaveSquad()
	if inSquad and leader != null :
		leader.followers.erase(self)
		if leader.followers.size() == 0 :
			leader.leaveSquad()
	leader = null
	inSquad = false

func getLeader():
	if leader != null : return leader
	else : 
		#print(self.name, " : ERROR! tried to get leader but I have no leader")
		inSquad = false
		isLeader = false
		return self

func reachable(positionToTest : Vector2) : #finish this
	
	return true

var inSquad : bool = false
var isLeader : bool = false
var leader : SUBRFL48 = null
var followers : Array[SUBRFL48] = []

var avoidenceVelocity : Vector2 = Vector2.ZERO

func actionQuery() :
	
	if leader == null : leaveSquad()
	
	match inSquad :
		false : #alone logic
			pass
		true : 
			match isLeader :
				false : #follower logic, probably ask leader
					lastSeenTile = leader.lastSeenTile
					var leaderPos : Vector2 = leader.global_position
					if reachable(leaderPos) == false :
						leaveSquad()
					else :
						var myPlace = leader.followers.find(self)
						var tarPos : Vector2
						if myPlace == 0 : tarPos = leaderPos
						elif leader.followers[myPlace - 1] != null : tarPos = leader.followers[myPlace - 1].global_position
						Selector.inFrontPos = tarPos
						nav.target_position = tarPos
						nav.avoidance_priority = (1.0 / leader.followers.size()) * (myPlace + 1)
				true : #leader Logic
					pass
					#var tileToGoTo = getTileToSearch()
					#nav.set_target_position(map.map_to_local(tileToGoTo))

func move(delta) :
	var target = nav.get_next_path_position()
	#print(nav.distance_to_target())
	
	const randoTurn = 0.001
	
	direction = lerp(direction, position.direction_to(target), turnSpeed * delta).normalized()
	direction = direction + Vector2(randf_range(-randoTurn, randoTurn), randf_range(-randoTurn, randoTurn))
	velocity = velocity.lerp((direction * speed) + (avoidenceVelocity * 0.75), acceleration * delta)

func idle(delta) :
	velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)

func shoot(delta):
	cAni = "Shoot"
	sprite.speed_scale = 1 * revved
	if aggroList.is_empty() : 
		aggroTarget = null
		revved = 0.25
		goIdle(0, 3)
	else :
		revved += delta / 8
		revved = clampf(revved, 0.25, 2)
		$Fire.pitch_scale = revved / 2
		aggroTarget = aggroList[0]
		nav.target_position = aggroTarget.position
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

func _process(_delta): #if flashlight bugs out, remove the underscore
	
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

func die() :
	leaveSquad()
	queue_free()
