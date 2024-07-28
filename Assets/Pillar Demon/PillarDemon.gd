extends Unit
class_name PillarDemon

enum States {
Idle = 0,
Swarm = 1,
Wander = 2,
Scatter = 3
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
var isSeen : bool = false
@export var minSize : float = 0.5
@export var maxSize : float = 1.5

var recentSeenCheck


func _init() :
	await ready
	$Sniff/SniffTimer.start(randf_range(0, 60))
	vision = $Vision
	nav = $PDNav
	var randSize = randf_range(0, 1)
	randSize = sqrt(randSize)
	sprite.speed_scale = ((1 - randSize) + 1)
	#print(sprite.speed_scale)
	randSize = (randSize * (maxSize - minSize)) + minSize
	#print(randSize)
	maxHP = maxHP * randSize
	HP = maxHP
	scale = Vector2(randSize, randSize)
	position += Vector2(randf_range(-128, 128), randf_range(-128, 128))

func _physics_process(delta) :
	
	recentSeenCheck = seenCheck()
	if recentSeenCheck != isSeen :
		print(recentSeenCheck)
		isSeen = recentSeenCheck
		if isSeen : sprite.play_backwards("EmergeDown")
		else :sprite.play("EmergeDown")
		#canBeSeen = isSeen
	
	match PillarState :
		PillarStates.Pillar :
			pillarQuery()
		PillarStates.Standing :
			actionQuery()

func actionQuery() :
	if State != States.Swarm and recentSeenCheck : 
		scatter()

func pillarQuery() :
	pass

func seenCheck() :
	var observers = seeable.get_overlapping_areas()
	var seen = false
	if observers.size() > 0 : 
		for observer in observers :
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(global_position, observer.owner.position, 1)
			var result = space_state.intersect_ray(query)
			if result and result.collider is Unit :
				if result.collider is PillarDemon == false : seen = true
	return seen

func scatter():
	State = States.Scatter
	if PillarState == PillarStates.Pillar : PillarState = PillarStates.Emerge

func _on_sniff_timer_timeout():
	$Sniff.play()
	var randTime = sqrt(randf_range(0, 1))
	randTime = randTime * 60
	if isSeen : randTime *= 4
	randTime = round(randTime)
	#print(randTime)
	$Sniff/SniffTimer.start(randTime)

func _on_hurt(DMG):
	scatter()
	nav.target_position = getTileToSearch(1, -1)

func _on_pd_sprite_animation_finished():
	if sprite.animation.contains("Emerge") :
		match PillarState :
			PillarStates.Emerge :
				PillarState = PillarStates.Standing
			PillarStates.UnEmerge :
				PillarState = PillarStates.Pillar
