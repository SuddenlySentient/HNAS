extends Effect

@onready var particles = $CanvasLayer/FireParticles
@onready var startBurning = $CanvasLayer/FireParticles/StartBurning
@onready var smallBurning = $CanvasLayer/FireParticles/SmallBurning
@onready var bigBurning = $CanvasLayer/FireParticles/BigBurning


func doEffect(_delta) :
	level = timer.time_left / 2.0
	
	if $DMGCooldown.is_stopped() :
		$DMGCooldown.start()
		@warning_ignore("narrowing_conversion")
		var DMG = affected.damage(ceil(level) , 1, dealer, "Effect", self)
		if DMG == 0 :
			duration = timer.time_left - affected.ARM
			timer.start(duration)

func _process(_delta: float) -> void:
	
	smallBurning.volume_db = lerpf(-5, 5, clamp(level / 2.0, 0, 1))
	bigBurning.volume_db = lerpf(-15, 10, clamp(level / 4.0, 0, 1))
	
	if smallBurning.playing == false : smallBurning.play()
	if bigBurning.playing == false : bigBurning.play()
	
	particles.amount_ratio = clamp((duration * 0.25), 0.25, 1)
	particles.speed_scale = clamp(duration / 2.0, 1.5, 3.0)
	particles.global_position = affected.global_position

func initEffect() :
	#level = level / float(affected.ARM)
	if duration != -1 : duration = level + 1
	timer.start(duration)
	startBurning.pitch_scale = lerpf(1.5 - (level / 4 ), 0.5, 1.5)
	startBurning.play()

func increment(effect : Effect) :
	effect.level = effect.level / float(affected.ARM)
	if level < effect.level : 
		level = effect.level
	else : 
		#print("Added : ", effect.level / level)
		level += effect.level / level
	if duration != -1 : 
		duration = level + 1
		timer.start(duration)
