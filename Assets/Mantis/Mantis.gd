extends Unit


var inVision = []
@export var crawlSpeed : float = 1.8
var crawling : bool = false



func _init() :
	await ready
	HP = maxHP
	vision = $RotateNode/Vision
	nav = $nav
	name = getName()
	nav.target_position = newRandomPos() + global_position

func think(delta) :
	dealVision()
	
	move(delta)

func move(delta) :
	var dot = direction.dot(velocity)
	match cAni :
		"Walk", "Crawl" :
			match cAni :
				"Walk" : sprite.speed_scale = (velocity / 350).length() * dot
				"Crawl" : sprite.speed_scale = (velocity / 350).length() * dot
			if sprite.speed_scale == 0 : sprite.frame = 0
			velocity = velocity.lerp(Vector2.ZERO, delta * -clamp(dot, -1, 0)  )
		_ :
			velocity = velocity.lerp(Vector2.ZERO, delta)
	var directionToTarget = global_position.direction_to(nav.get_next_path_position())
	var multi
	match crawling :
		true :
			multi = crawlSpeed
		false :
			multi = 1
	
	direction = direction.slerp(directionToTarget, delta * multi)
	velocity = velocity.lerp(direction * maxSpeed * multi, delta)
	
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

var cAni = "Walk"
@onready var sprite = $Sprite

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
	
	sprite.set_animation(cAni + directionString)
	if sprite.is_playing() == false : sprite.play()
