extends Unit
class_name Mantis

var inVision = []
@export var crawlSpeed : float = 1.8
@export var turnSpeed : float = 8
var crawling : bool = false
var cAni = "Walk"
@onready var sprite = $Sprite
var combo : int = 0



func _init() :
	await ready
	HP = maxHP
	vision = $RotateNode/Vision
	nav = $nav
	name = getName()
	nav.target_position = newRandomPos() + global_position

func think(delta) :
	dealVision()
	print(getCuriosities())
	attack()
	#if randi_range(1, 256) == 1 : 
	#	if crawling : exitCrawl()
	#	else : enterCrawl()
	move(delta)

func getDirectionToTarget() :
	return global_position.direction_to(nav.get_next_path_position())

func move(delta) :
	var dot = direction.dot(velocity.normalized())
	var multi = 1
	var goalVelocity = Vector2.ZERO
	match cAni :
		"Walk", "Crawl" :
			match cAni :
				"Walk" : sprite.speed_scale = (velocity.length() / (maxSpeed / 2.0)) * dot
				"Crawl" : 
					multi = crawlSpeed
					sprite.speed_scale = (velocity.length() / (maxSpeed / 1.5)) * dot
			goalVelocity = direction * maxSpeed * multi
			var directionToTarget = getDirectionToTarget()
			direction = direction.slerp(directionToTarget, delta * multi * turnSpeed).normalized()
			if sprite.speed_scale == 0 : sprite.frame = 0
		_ : multi = 2
	
	velocity = velocity.lerp(goalVelocity, delta * pow(multi, 2) * (1 -clamp(goalVelocity.dot(velocity.normalized()), -1, 0)))
	
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
	var velo : float = testo.velocity.length()
	var distance = clamp(1 - sqrt(testo.global_position.distance_to(global_position) / 4096.0), 0, 1)
	#print(velo * distance)
	return (velo * distance) > 50

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
	sprite.speed_scale = 1
	cAni = "IntoCrawl"
	await sprite.animation_changed
	await sprite.animation_finished
	crawling = true
	cAni = "Crawl"

func exitCrawl() :
	sprite.speed_scale = -1
	cAni = "IntoCrawl"
	await sprite.animation_changed
	await sprite.animation_finished
	crawling = false
	cAni = "Walk"

var attacksArray : Array[int] = [0, 1, 2]

func attack() :
	if attacking : return false
	attacking = true
	if crawling : await exitCrawl()
	sprite.speed_scale = clamp((pow(combo, 1.0 / float(combo)) + pow(combo, 0.25)) / 2.5, 0.75, 3)
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
				17, 18, 19, 20 : velocity = direction * maxSpeed * 2 * sprite.speed_scale
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
		"SliceC" :
			match sprite.frame :
				1 : direction = getDirectionToTarget()
				16 : 
					velocity = direction * maxSpeed * 2 * sprite.speed_scale
					$Slice.play()
				17, 18, 19, 20 : velocity = direction * maxSpeed * 2 * sprite.speed_scale
				30 : direction = getDirectionToTarget()
				36 : 
					$Slice.play()
				37, 38, 39, 40 : velocity = direction * maxSpeed * 2 * sprite.speed_scale

func _on_nav_navigation_finished() -> void:
	nav.target_position = newRandomPos()

func _on_combo_timer_timeout() -> void:
	combo = 0
