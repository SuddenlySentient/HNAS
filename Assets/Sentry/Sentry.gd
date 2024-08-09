extends Unit
class_name Sentry

enum States {
Rest = 0,
Awake = 1,
Ready = 2,
Walk = 3,
Approach = 4,
Attack = 5,
PrepareThrust = 6,
Thrust = 7,
Knocked = 8
}
var State : States = States.Rest
var vulnerable = false

@export_group("Sword")
@export_subgroup("Slice")
@export var sliceDMG : int = 5
@export var sliceAP : int = 2
@export_subgroup("Stab")
@export var stabDMG : int = 5
@export var stabAP : int = 3
@export_subgroup("Thrust")
@export var thrustDMG : int = 7
@export var thrustAP : int = 3
@onready var sprite = $Sprite
var cAni : String = "Awake"
var cType : String = "Sword"



func _init() :
	await ready
	HP = maxHP
	name = getName()
	vision = $Rotate/Vision
	nav = $nav

func getName() :
	var newName = type + " " + "1"
	return newName

func _physics_process(delta) :
	
	const weight = 4
	
	#print(str(State))
	
	velocity = velocity.lerp(Vector2.ZERO, delta * weight)
	move_and_slide()
	
	dealAggro()
	
	match cAni :
		"Walk" :
			@warning_ignore("integer_division")
			var sped = velocity.length() / (maxSpeed / 2)
			sped = sped * velocity.normalized().dot(direction)
			sprite.speed_scale = sped
		_ :
			sprite.speed_scale = lerp(sprite.speed_scale, 1.0, delta)
	
	match State :
		States.Walk :
			cAni = "Walk"
		States.Approach :
			cAni = "Walk"
			var aggroPos = aggroTarget.position
			nav.target_position = aggroPos
			var distranceToTarget = getDistanceTo(aggroPos)
			if canSeeTarget() : direction = global_position.direction_to(aggroPos)
			else : direction = global_position.direction_to(nav.get_next_path_position())
			#print(distranceToTarget)
			var dodgeTime = $DodgeTimer.time_left / $DodgeTimer.wait_time
			if distranceToTarget < 128 :
				if dodgeTime <= 0.5 :
					match randi_range(0, 3) :
						0 : thrustAttack()
						1, 2 : standardAttack()
						3 : dodge()
			elif dodgeTime <= 0.5 :
				var offsetDirection = direction.rotated(PI / 2.0)
				var dooply = clamp(distranceToTarget, 0, 256) / 256.0
				offsetDirection = (offsetDirection * (1 - dooply)) + (direction * dooply) 
				velocity = lerp(velocity, offsetDirection * maxSpeed , delta * weight)

func _process(_delta) :
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
	
	$Rotate.rotation = altDirection.normalized().angle() - PI/2
	
	sprite.set_animation(cType + cAni + directionString)
	if sprite.animation.contains("Thrust") or sprite.animation.contains("Knocked") or sprite.animation.contains("Attack") or sprite.animation.contains("Walk") :
		if sprite.is_playing() == false : sprite.play()
	if sprite.animation.contains("Awake") and State == States.Awake :
		if sprite.is_playing() == false : sprite.play()

func _on_sprite_animation_finished():
	match cAni :
		"Awake", "Thrust", "Knocked", "Attack" :
			State = States.Ready
			canBeSeen = true
		"ThrustPrepare" :
			cAni = "Thrust"

func dodge() :
	#print("Dodge")
	if $DodgeTimer.is_stopped() :
		$DodgeTimer.start()
		var randAng = ((randi_range(0, 1) * 2) - 1)  * (PI / 2.0)
		velocity += direction.rotated(randAng) * -1024

func standardAttack() :
	State = States.Attack
	cAni = "Attack"

func thrustAttack() :
	State = States.PrepareThrust
	cAni = "ThrustPrepare"
	velocity = direction * -256

func dealAggro() :
	
	var recentVision = checkVision()
	
	for thing in recentVision :
		if thing is Unit :
			if isFoe(thing) : aggroList.append(thing)
	
	var newAggroList : Array[Unit] = []
	for thing in aggroList :
		if thing != null and newAggroList.has(thing) == false : newAggroList.append(thing)
	aggroList = newAggroList
	
	if aggroList.size() > 0 : 
		aggroTarget = aggroList[0]
		match State :
			States.Ready, States.Walk : State = States.Approach
			States.Rest : awake()
	else : 
		aggroTarget = null
		if State == States.Approach : State = States.Ready

func awake() :
	State = States.Awake
	cAni = "Awake"

func setVulnerable(setV : bool) :
	vulnerable = setV
	if setV :
		pass
	else :
		pass

func adjustDMG(DMGDealt : int, dealer : Unit, DMGtype : String, source : Node = null) :
	if DMGtype == "Melee" :
		var percentageHP = float(DMGDealt) / float(maxHP)
		if dealer.direction.dot(direction) < -0.5 :
			if vulnerable and percentageHP >= 0.25 : 
				direction = global_position.direction_to(source.global_position)
				knocked()
			else :
				$Parry.play()
				hitmarker("PARRIED", 1, Color.from_hsv(0.3, 0.8, 1, 1))
				State = States.Ready
				sprite.stop()
				sprite.speed_scale = clamp(1 - percentageHP, 0.5, 1)
				DMGDealt -= 6
				#vulnerable = true
				if DMGDealt < 0 : DMGDealt = 0
				velocity = direction * -96 * percentageHP
		else : 
			direction = -dealer.direction
			knocked()
	elif DMGtype == "Projectile" : 
		velocity += direction * 256
		dodge()
	return DMGDealt

func knocked() :
	sprite.speed_scale = sprite.speed_scale / 2
	hitmarker("KNOCKED", 1, Color.from_hsv(0.05, 0.8, 1, 1))
	$Knocked.play()
	State = States.Knocked
	cAni = "Knocked"
	velocity = -direction * 96

func _on_sprite_frame_changed():
	match cAni :
		"Thrust" :
			match sprite.frame :
				1 :
					$Thrust.play()
					$Sword.play()
					velocity = direction * 512
				26 : setVulnerable(false)
				3 : 
					var thrustArea = $Rotate/Thrust.get_overlapping_bodies()
					for thing in thrustArea :
						if thing is Unit and isFoe(thing) :
							thing.damage(thrustDMG, thrustAP, self, "Melee", self)
		"ThrustPrepare" :
			match sprite.frame :
				1 :
					$Crank.pitch_scale = 1
					$Crank.play()
				4 : setVulnerable(true)
		"Attack" :
			match sprite.frame :
				2, 12 : setVulnerable(true)
				28 : setVulnerable(false)
				1, 14 :
					$Crank.pitch_scale = 1.25
					$Crank.play()
				8, 18 :
					if sprite.frame == 8 : setVulnerable(false)
					$Sword.play()
					if sprite.frame == 18 : $Thrust.play()
				10 : 
					var sliceArea = $Rotate/Slice.get_overlapping_bodies()
					for thing in sliceArea :
						if thing is Unit and isFoe(thing) :
							thing.damage(sliceDMG, sliceAP, self, "Melee", self)
				19 : 
					var thrustArea = $Rotate/Thrust.get_overlapping_bodies()
					for thing in thrustArea :
						if thing is Unit and isFoe(thing) :
							thing.damage(stabDMG, stabAP, self, "Melee", self)
		"Walk" :
			setVulnerable(false)
			if $Creaking.playing == false : $Creaking.play()
			match sprite.frame :
				8, 24 :
					$Step.play()