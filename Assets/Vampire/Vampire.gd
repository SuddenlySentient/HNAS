@icon("res://Assets/Vampire/VampireIcon.png")
extends Unit
class_name Vampire

@onready var deflectSound : AudioStreamPlayer2D = $Deflect
@onready var sprite : AnimatedSprite2D = $VampireSprite

var cAni = "Walk"
var direction : Vector2 = Vector2.RIGHT
const minDeflectPitch : float = 1
const maxDeflectPitch : float = 3
const minCombo = 50
var deflectCombo = 0
@export var turnSpeed : float = 3

@export_subgroup("Prime Sword")
@export var JabDMG : int = 6
@export var SwingDMG : int = 9
@export var SwordAP : int = 4
@export var knockback : int = 1024

enum States {
Ready = 0,
Deflect = 1,
Attack = 2,
Move = 3,
Approach = 4
}
var State = States.Ready

func _physics_process(delta) :
	
	aggroList.clear()
	var currentVision : Array = checkVision()
	
	if State != States.Deflect and State != States.Attack :
		for thing in currentVision :
			if thing is Unit :
				if  thing.team != team : 
					if aggroList.has(thing) == false : aggroList.append(thing)
		if aggroList.is_empty() == false and aggroList[0] != null :
			aggroTarget = aggroList[0]
		if aggroTarget != null  :
			if $RotateNode/ThrustArea.overlaps_body(aggroTarget) : 
				State = States.Attack
			else : 
				State = States.Approach
		else :
			if State != States.Move :
				State = States.Move
				nav.target_position = map.map_to_local(getTileToSearch())
	
	match State :
		States.Attack :
			cAni = "Attack"
			sprite.play()
			$NavTimer.stop()
		States.Approach :
			cAni = "Walk"
			sprite.play()
			$NavTimer.stop()
			nav.target_position = aggroTarget.position
			var desiredDirection = global_position.direction_to(nav.get_next_path_position())
			direction = lerp(direction, desiredDirection, turnSpeed * delta).normalized()
			direction = direction + Vector2(randf_range(-0.001, 0.001), randf_range(-0.001, 0.001))
			var roundedDirection = Vector2(round(direction.x), round(direction.y))
			var roundedDesiredDirection = Vector2(round(desiredDirection.x), round(desiredDirection.y))
			if roundedDirection == roundedDesiredDirection : 
				velocity = (direction * maxSpeed)
			else :
				velocity = velocity.lerp(Vector2.ZERO, delta)
		States.Move :
			cAni = "Walk"
			if $NavTimer.is_stopped() : $NavTimer.start()
			sprite.play()
			var desiredDirection = global_position.direction_to(nav.get_next_path_position())
			direction = lerp(direction, desiredDirection, turnSpeed * delta).normalized()
			direction = direction + Vector2(randf_range(-0.001, 0.001), randf_range(-0.001, 0.001))
			var roundedDirection = Vector2(round(direction.x), round(direction.y))
			var roundedDesiredDirection = Vector2(round(desiredDirection.x), round(desiredDirection.y))
			if roundedDirection == roundedDesiredDirection : 
				velocity = (direction * maxSpeed)
			else :
				velocity = velocity.lerp(Vector2.ZERO, delta)
	
	velocity = velocity.lerp(Vector2.ZERO, delta)
	
	if round(velocity.length()) < 64 and cAni == "Walk" : 
		sprite.speed_scale = 0
	else : sprite.speed_scale = 1
	
	move_and_slide()

func _init() :
	await ready
	HP = maxHP
	vision = $RotateNode/Vision
	nav = $VPNav
	$ComboCanvas.show()

func damage(DMG : int, AP : int, dealer : Unit, source : Node = null) :
	
	var reduction = clampf( float(AP) / float(ARM), 0, ARM)
	var DMGDealt : int = DMG * reduction
	
	if source is Shot :
		
		direction = position.direction_to(source.position)
		
		deflect()
		source.changeColor(Color.from_hsv(0, 0.9, 1, 1))
		DMGDealt = 0
		dealer.indirectDMG(self, 0)
	
	HP -= DMGDealt
	
	if HP <= 0 : die(source.name)
	if DMGDealt > 0 : 
		emit_signal("hurt", DMGDealt)
		print(DMGDealt, " DMG, ", round( (float(HP) / float(maxHP) ) * 100), "% HP")
	return DMGDealt

func deflect() :
	State = States.Deflect
	cAni = "Deflect"
	sprite.frame = randi_range(0, 3)
	deflectSound.pitch_scale = clamp(deflectSound.pitch_scale + 0.0025, minDeflectPitch, maxDeflectPitch) 
	deflectSound.play()
	$DeflectTimer.start()
	deflectCombo += 1

func _process(_delta):
	
	$RotateNode/Slice.energy = $RotateNode/Slice/SliceTimer.time_left * 20 
	$RotateNode/Jab.energy = $RotateNode/Jab/JabTimer.time_left * 20
	$RotateNode/DeflectLight.energy = clamp($DeflectTimer.time_left - 0.375, 0, 0.125)  * 32 * $Deflect.pitch_scale
	if $RotateNode/Slice.energy == 0 : $RotateNode/Slice.enabled = false
	else : $RotateNode/Slice.enabled = true
	if $RotateNode/Jab.energy == 0 : $RotateNode/Jab.enabled = false
	else : $RotateNode/Jab.enabled = true
	if $RotateNode/DeflectLight.energy == 0 : $RotateNode/DeflectLight.enabled = false
	else : $RotateNode/DeflectLight.enabled = true
	
	$ComboCanvas/Label.position = global_position + Vector2(-374.5, 96)
	var comboScale
	if $ComboCanvas/GoAway.time_left <= 1 : 
		comboScale = $ComboCanvas/GoAway.time_left
	else : comboScale = 2 - $ComboCanvas/GoAway.time_left
	$ComboCanvas/Label.scale.x = sqrt(comboScale)
	$ComboCanvas/Label.scale.y = sqrt(comboScale)
	
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
	$RotateNode.rotation = altDirection.normalized().angle() - PI/2
	
	#if sprite.is_playing() == false and cAni != "Deflect" : sprite.play()
	
	if sprite.animation == "Deflect" : 
		var currentFrame = sprite.frame
		sprite.set_animation(cAni + directionString)
		sprite.frame = currentFrame
	else :
		sprite.set_animation(cAni + directionString)

func _on_deflect_timer_timeout():
	State = States.Ready
	if deflectCombo >= minCombo :
		$DeflectionSpree.pitch_scale = deflectSound.pitch_scale
		$DeflectionSpree.play()
		$ComboCanvas/Label.show()
		$ComboCanvas/Label/Combo.text = str(deflectCombo)
		$ComboCanvas/GoAway.start()
		print("Deflect Combo : ", deflectCombo)
	deflectSound.pitch_scale = minDeflectPitch
	deflectCombo = 0

func _on_vp_nav_navigation_finished():
	if State == States.Move :
		State = States.Ready

func _on_vampire_sprite_frame_changed():
	if cAni == "Walk" :
		if sprite.frame == 0 or sprite.frame == 16  :
			$Step.play()
	if cAni == "Attack" :
		if sprite.frame == 0 or sprite.frame == 16 or sprite.frame == 24 or sprite.frame == 40 or sprite.frame == 48 or sprite.frame == 64  :
			$Pull.play()
		if sprite.frame == 8 or sprite.frame == 32 or sprite.frame == 56  :
			$Release.play()
		if sprite.frame == 10 or sprite.frame == 58  :
			var swungAt : Array = $RotateNode/ThrustArea.get_overlapping_bodies()
			swungAt.erase(self)
			$SwordSwingA.play()
			$SwordSwingB.play()
			$RotateNode/Jab/JabTimer.start()
			for unit in swungAt :
				if unit is Unit :
					unit.damage(JabDMG, SwordAP, self, self)
					unit.velocity += global_position.direction_to(unit.position) * knockback
		if sprite.frame == 34 :
			var swungAt : Array = $RotateNode/ThrustArea.get_overlapping_bodies()
			for unit in $RotateNode/SweepArea.get_overlapping_bodies() :
				if swungAt.has(unit) == false : swungAt.append(unit)
			
			swungAt.erase(self)
			$SwordSwingA.play()
			$SwordSwingB.play()
			$RotateNode/Slice/SliceTimer.start()
			for unit in swungAt :
				if unit is Unit :
					unit.damage(SwingDMG, SwordAP, self, self)
					unit.velocity += global_position.direction_to(unit.position) * knockback

func _on_vampire_sprite_animation_finished():
	if cAni == "Attack" :
		State = States.Ready

func _on_nav_timer_timeout():
	if State == States.Approach :
		nav.target_position = aggroTarget.position

func _on_engine_finished():
	$Engine.play()

