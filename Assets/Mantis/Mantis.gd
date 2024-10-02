extends Unit
class_name Mantis

var inVision = []
@export var crawlSpeed : float = 1.8
@export var turnSpeed : float = 8
@export var knockback : int = 64
@export var retreatHP : float = 0.5
@export var maxShield : int = 16
var shield : int = 16
@export_group("Slice A")
@export var sliceADMG : int = 6
@export var sliceAAP : int = 3
@export_group("Slice B")
@export var sliceBDMG : int = 11
@export var sliceBAP : int = 4
var crawling : bool = false
var cAni = "Walk"
@onready var sprite = $Sprite
var combo : int = 0
enum States {
Wander = 0,
Approach = 1,
Attack = 2,
Retreat = 3
}
var State : States = States.Wander



func initUnit() :
	vision = $Vision
	nav = $nav
	nav.target_position = map.map_to_local(getTileToSearch())
	shield = maxShield

func think(delta) :
	
	dealVision()
	for thing in inVision :
		if thing is Unit :
			if isFoe(thing) : aggroList.append(thing)
	
	dealAggro()
	assignState()
	doState()
	
	move(delta)
	$RotateNode.rotation = direction.angle() - PI/2

func assignState() :
	
	var prevState = State
	
	if State == States.Retreat : return false
	if attacking : return false
	
	if aggroTarget == null :
		State = States.Wander
	else :
		var HPpercentage = float(HP) / maxHP
		if HPpercentage >= retreatHP :
			var distanceToTarget = getDistanceTo(aggroTarget.global_position)
			if distanceToTarget > 256 : State = States.Approach
			else : State = States.Attack
		else : 
			State = States.Retreat
			aggroList.clear()
			aggroTarget = null
			nav.target_position = map.map_to_local(getTileToSearch(1, -1, -1))
	
	if prevState != State :
		if State == States.Approach and prevState != States.Attack : scream()

func doState() :
	
	match State :
		States.Wander :
			if crawling : 
				exitCrawl()
				return false
		States.Approach :
			if crawling == false : enterCrawl()
			if round(nav.target_position) != round(aggroTarget.global_position) :
				nav.target_position = aggroTarget.global_position
		States.Attack :
			if crawling : 
				exitCrawl()
				return false
			if aggroTarget == null : return false
			if round(nav.target_position) != round(aggroTarget.global_position) :
				nav.target_position = aggroTarget.global_position
			attack()
		States.Retreat :
			if crawling == false : enterCrawl()

func dealAggro() :
	var newAggroList : Array[Unit] = []
	for thing in aggroList :
		if (thing == null) == false and thing.canBeSeen and newAggroList.has(thing) == false : newAggroList.append(thing)
	aggroList = newAggroList
	if aggroList.size() > 0 : aggroTarget = aggroList[0]
	else : aggroTarget = null

func getDirectionToTarget() :
	return global_position.direction_to(nav.get_next_path_position())

func move(delta) :
	var dot = direction.dot(velocity.normalized())
	var multi = 1
	var goalVelocity = Vector2.ZERO
	match cAni :
		"Walk", "Crawl" :
			match cAni :
				"Walk" : sprite.speed_scale = (velocity.length() / 150) * dot
				"Crawl" : 
					multi = crawlSpeed
					sprite.speed_scale = (velocity.length() / 200) * dot
			goalVelocity = direction * maxSpeed * multi
			var directionToTarget = getDirectionToTarget()
			direction = direction.slerp(directionToTarget, delta * multi * turnSpeed).normalized()
			if sprite.speed_scale == 0 : sprite.frame = 0
		_ : multi = 2
	
	velocity = velocity.lerp(goalVelocity, delta * 4) + avoidenceVeloicity
	
	move_and_slide()
	velocity = get_real_velocity()

func dealVision() :
	inVision.clear()
	var seen = checkVision()
	for x in seen : 
		if x is Unit and canHear(x) : 
			inVision.append(x)
	var fixArray = []
	for x in inVision : if x != null and fixArray.has(x) == false : 
		fixArray.append(x)
	inVision = fixArray

func getName() :
	var newName = type + " " + char(65 + randi_range(0, 25)) + char(65 + randi_range(0, 25)) + str(randi_range(0, 8))
	return newName

func canHear(testo : Unit) :
	var hearList = []
	for thing in curios :
		if thing["Type"] == 0 and (thing["Source"] == null) == false and thing["Source"] is Unit and hearList.has(thing["Source"]) == false :
			if thing["Strength"] > 0.125 :
				hearList.append(thing["Source"])
	return hearList.has(testo)

func checkVision(ignoreHiding : bool = false):
	var inRange = vision.get_overlapping_bodies()
	var seen : Array = []
	for thing in inRange :
		if thing is Unit and thing != self :
			if thing.canBeSeen or ignoreHiding : seen.append(thing)
	return seen

var prevAni = ""
var prevCAni = ""

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
	
	var frame = sprite.frame
	var frameProg = sprite.frame_progress
	sprite.set_animation(cAni + directionString)
	if sprite.is_playing() == false : sprite.play()
	if prevAni != sprite.animation and cAni == prevCAni :
		sprite.frame = frame
		sprite.frame_progress = frameProg
		prevAni = sprite.animation
	prevCAni = cAni

func enterCrawl() :
	sprite.speed_scale = 0.5
	cAni = "IntoCrawl"
	await sprite.animation_changed
	await sprite.animation_finished
	moveNoise = 8
	crawling = true
	cAni = "Crawl"

func exitCrawl() :
	sprite.speed_scale = -1
	cAni = "IntoCrawl"
	await sprite.animation_changed
	await sprite.animation_finished
	moveNoise = 1
	crawling = false
	cAni = "Walk"

var attacksArray : Array[int] = [0, 1, 2]

func attack() :
	if attacking : return false
	attacking = true
	if crawling : await exitCrawl()
	sprite.speed_scale = clamp((pow(combo, 1.0 / float(combo)) + pow(combo, 0.25)) / 2.5, 1, 3)
	$ComboTimer.paused = true
	var fromArray = attacksArray[randi_range(0, 1)]
	attacksArray.erase(fromArray)
	attacksArray.push_back(fromArray)
	match fromArray :
		0 : await sliceA()
		1 : await sliceB()
		2 : await sliceC()
	attacking = false
	combo += 1
	$ComboTimer.paused = false
	$ComboTimer.start()
	cAni = "Walk"

var attacking = false

func sliceA() :
	cAni = "SliceA"
	await sprite.animation_finished

func sliceB() :
	cAni = "SliceB"
	await sprite.animation_finished

func sliceC() :
	cAni = "SliceC"
	await sprite.animation_finished

var hitTargets = []

func _on_sprite_frame_changed():
	$Slice.pitch_scale = clamp(sprite.speed_scale, 0.75, 2)
	match cAni :
		"Walk" :
			match sprite.frame :
				1, 16 : 
					$FootstepA.play()
					$FootstepB.play()
		"Crawl" :
			match sprite.frame :
				4, 12 : 
					$Spike.play()
					$FootstepB.play()
					
					$FootstepA.play()
					$FootstepB.play()
		"SliceA" :
			match sprite.frame :
				1 : direction = getDirectionToTarget()
				16 : 
					velocity = direction * maxSpeed * 2 * sprite.speed_scale
					$Slice.play()
				17, 18, 19, 20 : 
					velocity = direction * maxSpeed * 2 * sprite.speed_scale
					var sliceArea = $RotateNode/SliceArea.get_overlapping_bodies()
					for thing in sliceArea :
						if thing is Unit and isFoe(thing) :
							if hitTargets.has(thing) == false :
								hitTargets.append(thing)
								thing.damage(sliceADMG, sliceAAP, self, "Melee", self)
							thing.dealKnockback(knockback, global_position.direction_to(thing.position))
				32 : hitTargets.clear()
		"SliceB" :
			var pseudo = sprite.speed_scale * (1.0 / 30.0)
			match sprite.frame :
				1 : 
					direction = getDirectionToTarget()
					velocity = direction * -maxSpeed
				16 : 
					direction = direction.slerp(getDirectionToTarget(), pseudo * turnSpeed).normalized()
					velocity = direction * maxSpeed * 3 * sprite.speed_scale
					$Slice.play()
					$Slice.play()
				17, 18, 19, 20 : 
					direction = direction.slerp(getDirectionToTarget(), pseudo * turnSpeed).normalized()
					velocity = direction * maxSpeed * 3 * sprite.speed_scale
					var sliceArea = $RotateNode/SliceArea.get_overlapping_bodies()
					for thing in sliceArea :
						if thing is Unit and isFoe(thing) :
							if hitTargets.has(thing) == false :
								hitTargets.append(thing)
								thing.damage(sliceBDMG, sliceBAP, self, "Melee", self)
							thing.dealKnockback(knockback, global_position.direction_to(thing.position))
				31 : hitTargets.clear()
		"SliceC" :
			match sprite.frame :
				1 : direction = getDirectionToTarget()
				16 : 
					velocity = direction * maxSpeed * 2 * sprite.speed_scale
					$Slice.play()
				17, 18, 19, 20 : 
					velocity = direction * maxSpeed * 2 * sprite.speed_scale
					var sliceArea = $RotateNode/SliceArea.get_overlapping_bodies()
					for thing in sliceArea :
						if thing is Unit and isFoe(thing) :
							if hitTargets.has(thing) == false :
								hitTargets.append(thing)
								thing.damage(sliceADMG, sliceAAP, self, "Melee", self)
							thing.dealKnockback(knockback, global_position.direction_to(thing.position))
				30 : 
					direction = getDirectionToTarget()
					hitTargets.clear()
				36 : 
					$Slice.play()
				37, 38, 39, 40 : 
					velocity = direction * maxSpeed * 2 * sprite.speed_scale
					var sliceArea = $RotateNode/SliceArea.get_overlapping_bodies()
					for thing in sliceArea :
						if thing is Unit and isFoe(thing) :
							if hitTargets.has(thing) == false :
								hitTargets.append(thing)
								thing.damage(sliceADMG, sliceAAP, self, "Melee", self)
							thing.dealKnockback(knockback, global_position.direction_to(thing.position))
				47 : hitTargets.clear()

func _on_nav_navigation_finished() -> void:
	
	match State :
		States.Wander :
			nav.target_position = map.map_to_local(getTileToSearch())
		States.Retreat :
			State = States.Wander
			assignState()
		_ : pass

func _on_combo_timer_timeout() -> void:
	combo = 0

var avoidenceVeloicity = Vector2.ZERO
func _on_nav_velocity_computed(safe_velocity: Vector2) -> void:
	avoidenceVeloicity = safe_velocity

func _on_nav_timer_timeout() -> void:
	if State == States.Wander :
		nav.target_position = map.map_to_local(getTileToSearch())
	$NavTimer.start((pow(randf_range(0, 1), 2) * 15) + 1 )

func _on_heal_timer_timeout() -> void:
	if State == States.Wander :
		heal(1)

func adjustDMG(DMGDealt : int, _dealer, _DMGtype : String, source : Node = null) :
	if (source == null) == false and source is Unit and isFoe(source) :
		if aggroList.has(source) == false :
			aggroList.push_front(source)
	DMGDealt -= shield
	shield = -DMGDealt
	if shield < 0 : shield = 0 
	if DMGDealt < 0 : DMGDealt = 0 
	return DMGDealt

func getKill(who : Unit) :
	shield += ceil(who.maxHP)
	shield = clamp(shield, 0, maxShield)

func playVoice() :
	$VoiceTimer.start((pow(randf_range(0, 1), 2) * 55) + 5)
	if State == States.Wander :
		$Voice.stream = voiceLines.pick_random()
	else : $Voice.stream = voiceLines[5]
	$Voice.play()
	var voiceCurio : Curiousity = createCurio("Mantis Voice", 0, 8, self, 3)
	bindCurio(voiceCurio)
	voiceCurio.changeColor(Color.CRIMSON)

var voiceLines : Array[AudioStream] = [
load("res://Assets/Mantis/Audio/Voice/Friend.wav"),
load("res://Assets/Mantis/Audio/Voice/hear something.wav"),
load("res://Assets/Mantis/Audio/Voice/helllloooo searching.wav"),
load("res://Assets/Mantis/Audio/Voice/hello!.wav"),
load("res://Assets/Mantis/Audio/Voice/hmmm.wav"),
load("res://Assets/Mantis/Audio/Voice/Laugh.wav"),
load("res://Assets/Mantis/Audio/Voice/tehe.wav")
]

func _on_voice_timer_timeout() -> void:
	playVoice()

func scream() :
	if $ScreamFar.playing == false :
		var newScream : Curiousity = createCurio("Mantis Scream", 0, 32, self, 4)
		bindCurio(newScream)
		newScream.changeColor(Color.CRIMSON)
		$ScreamClose.play()
		$ScreamFar.play()
