extends Node2D
class_name Curiousity

var fullStrength = 16
@export var curioName = "Unnamed Curio"
@export var strength = 16
@export var duration = 16
@export var doDecay = true
@export var sourceTeam : String = "Null"
@export var curiousityType : curiousityTypes
enum curiousityTypes {
Sound = 0,
Smell = 1,
Magic = 2
}

func createCuriousity(setCurioName, setCuriousityType, setStrength : float = 16, setDuration : float = 16, setSourceTeam : String = "Null") :
	curioName = setCurioName
	curiousityType = setCuriousityType
	strength = setStrength
	fullStrength = strength
	duration = setDuration
	sourceTeam = setSourceTeam

func _enter_tree() -> void :
	await ready
	if duration != -1 : $Timer.start()
	$Canvas.offset = global_position
	match curiousityType :
		curiousityTypes.Sound :
			$Canvas/SoundParticles.show()
			$Canvas/SoundParticles.speed_scale = lerp(0.2, 0.6, clamp(strength, 512, 4096) / 4096.0)

func _physics_process(_delta: float) -> void :
	if doDecay :
		var decayTime = sqrt($Timer.time_left / $Timer.wait_time)
		strength = lerpf(0, fullStrength, decayTime)
		$Canvas/SoundParticles.modulate = lerp(Color.WHITE, Color.TRANSPARENT, decayTime)

func _on_timer_timeout() -> void :
	queue_free()
