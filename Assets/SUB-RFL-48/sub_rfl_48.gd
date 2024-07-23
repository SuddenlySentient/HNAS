@icon("res://Assets/Facility/FacilityLogo.png")
extends Unit
class_name SUBRFL48

@onready var sprite : AnimatedSprite2D = $SUBSprite
@onready var flashlight : PointLight2D = $Flashlight
@onready var Step : AudioStreamPlayer2D = $Step
@onready var Selector : Sprite2D = $"Self Selector"
@onready var testTimer : Timer = $Test

var direction : Vector2 = Vector2(0, 1)
@export var maxSpeed : int = 200
@export var acceleration : float = 5
@export var turnSpeed : float = 6

enum States {
Unidle = 0,
Idle = 1,
Move = 2,
Shoot = 3
}
var State = States.Move

@onready var test : Timer =$Test

func _init():
	await ready
	HP = maxHP
	testTimer.wait_time = randf_range(1.0, 2.0)
	vision = $Flashlight/Vision
	nav = $SUBNavigation

func _physics_process(delta):
	
	for thing in checkVision() :
		if thing is Unit :
			if  thing.team != team : pass
			elif thing is SUBRFL48 : squadLogic(thing)
	
	if State != States.Idle : actionQuery()
	
	velocity = velocity.slerp(Vector2.ZERO, delta)
	
	match State :
		States.Idle : idle(delta)
		States.Move : move(delta)
		States.Shoot : pass
	
	nav.max_speed = maxSpeed
	
	if sprite.speed_scale != 0 and sprite.is_playing() == false :
		sprite.play()
	
	if cAni == "Walk" :
		sprite.speed_scale = velocity.length()/100
		Step.volume_db = round(((velocity.length()/maxSpeed) * 15) - 30)
		if sprite.speed_scale == 0 :
			sprite.frame = 0

func exchangeTileInfo(node : Unit):
	var nodeTileInfo = node.lastSeenTile
	lastSeenTile.merge(nodeTileInfo)

func squadLogic(node : SUBRFL48) :
	
	if node != self and leader != node :
		
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
	
	print(self.name," has joined ", node.name, "'s squad")
	#print(node.name, "'s squad : ", node.followers)

func leaveSquad() :
	
	if leader :
		for follower in followers : follower.leaveSquad()
	elif inSquad and leader != null :
		leader.followers.erase(self)
		if leader.followers.size() == 0 :
			leader.leaveSquad()
	leader = null
	inSquad = false

func getLeader():
	if leader != null : return leader
	else : 
		print(self.name, " : ERROR! tried to get leader but I have no leader")
		inSquad = false
		isLeader = false
		return null

func reachable(positionToTest : Vector2) : #finish this
	
	return true

var inSquad : bool = false
var isLeader : bool = false
var leader : SUBRFL48 = null
var followers : Array[SUBRFL48] = []

@export var preferedSquadSize : int = 4

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
						else : tarPos = leader.followers[myPlace - 1].global_position
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
	flashlight.rotation = direction.angle() - PI/2
	velocity = velocity.slerp((direction * maxSpeed) + (avoidenceVelocity * 0.75), acceleration * delta)
	
	if move_and_slide() : 
		var collision = get_last_slide_collision()
		
		if collision.get_collider() is PhysicsBody2D :
			if collision.get_collider() is CharacterBody2D :
					collision.get_collider().velocity + ( velocity * delta) 
			if collision.get_collider() is RigidBody2D :
					collision.get_collider().apply_force(velocity * delta)

func idle(delta) :
	
	velocity = velocity.slerp(Vector2.ZERO, acceleration * delta)
	move_and_slide()

func goIdle() :
	State = States.Idle
	var timer : Timer = $IdleTimer
	timer.wait_time = randf_range(3, 6)
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
	State = States.Unidle

func _on_animated_sprite_2d_frame_changed():
	if sprite.animation.contains("Walk") :
		if sprite.frame == 16 or sprite.frame == 0 :
			Step.pitch_scale = (velocity.length()/maxSpeed * randf_range(0.9, 1.1))
			Step.pitch_scale = clamp(Step.pitch_scale, 0.75, 2)
			Step.play()

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
