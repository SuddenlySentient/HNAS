extends Node2D
class_name Curiousity

var fullStrength = 16
@export var curioName = "Unnamed Curio"
@export var strength = 16
@export var duration = 16
@export var doDecay = false
@export var curiousityType : curiousityTypes
var source : Unit
static var IDCounter : int = 0
var ID : int
enum curiousityTypes {
Sound = 0,
Smell = 1,
Magic = 2
}
@onready var soundParticles = $Sprite2D/SubViewport/SoundParticles
@onready var smellParticles = $Sprite2D/SubViewport/SmellParticles
@export var curioColor : Color = Color.GRAY 



func createCuriousity(setCurioName : String, setCuriousityType, setStrength : float, setSource : Unit = null, setDuration : float = -1) :
	curioName = setCurioName
	curiousityType = setCuriousityType
	strength = setStrength
	fullStrength = strength
	source = setSource
	duration = setDuration
	IDCounter += 1
	ID = IDCounter

var bound = false
var boundTo : Unit

func bindToUnit(who : Unit) :
	bound = true
	boundTo = who
	position = boundTo.global_position

func resume() :
	strength = fullStrength

func pause() :
	strength = 0

func _enter_tree() -> void :
	await ready
	changeColor(curioColor)
	if duration != -1 : $Timer.start()
	match curiousityType :
		curiousityTypes.Sound :
			soundParticles.show()
		curiousityTypes.Smell :
			smellParticles.show()

func _physics_process(_delta: float) -> void :
	
	var visibility = pow(strength / 128.0, 1.0 / 2.0)
	#visibility = clamp(visibility -0.5, 0, 0.5) * 2
	visibility = clamp(visibility, 0, 1)
	if visibility > 0:
		smellParticles.amount_ratio = clamp(visibility - 0.25, 0, 0.75) * (1.0 / 0.75)
		soundParticles.speed_scale = lerp(0.2, 0.6, sin((clamp(strength, 0, 384) / 256) * PI * (2.0 / 3.0)))
		soundParticles.modulate = lerp(Color.TRANSPARENT, Color.WHITE, visibility)
		visibility = clamp(visibility, 0.0625, 1)
		$Sprite2D/SubViewport.size = Vector2(visibility * 512.0, visibility * 512.0)
	else :
		smellParticles.amount_ratio = 0
		soundParticles.speed_scale = 0
		soundParticles.modulate = Color.TRANSPARENT
	
	if bound :
		if (boundTo == null) == false :
			position = boundTo.global_position
		else : queue_free()
	if doDecay :
		var decayTime = sqrt($Timer.time_left / $Timer.wait_time)
		strength = lerpf(0, fullStrength, decayTime)

func _on_timer_timeout() -> void :
	queue_free()

func changeColor(newColor : Color) :
	curioColor = newColor
	soundParticles.self_modulate = curioColor
	smellParticles.self_modulate = curioColor
