extends Unit

@onready var deflectSound : AudioStreamPlayer2D = $Deflect
@onready var sprite : AnimatedSprite2D = $VampireSprite


func damage(DMG : int, AP : int, source : Node = null) :
	
	var reduction = clampf( float(AP) / float(ARM), 0, ARM)
	var DMGDealt : int = DMG * reduction
	
	if source is Shot : 
		#Deflect
		sprite.animation = "DeflectDown"
		sprite.frame = randi_range(0, 3)
		source.changeColor(Color.from_hsv(0, 0.9, 1, 1))
		deflectSound.play()
		DMGDealt = 0
	
	HP -= DMGDealt
	
	if HP <= 0 : die()
	if DMGDealt > 0 : 
		emit_signal("hurt", DMGDealt)
		print(DMGDealt, " DMG, ", round( (float(HP) / float(maxHP) ) * 100), "% HP")
	return DMGDealt
