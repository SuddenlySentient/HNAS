@icon("res://Assets/Vampire/VampireIcon.png")
extends Unit
class_name Vampire

@onready var deflectSound : AudioStreamPlayer2D = $Deflect
@onready var sprite : AnimatedSprite2D = $VampireSprite

var cAni = "Walk"
const minDeflectPitch : float = 1
const maxDeflectPitch : float = 3
const minCombo = 50
var deflectCombo : int = 0
var healthRemaining : float = 1
@export var turnSpeed : float = 3
@export var bloodTankMax : int = 16
var bloodTank : int = 0
@export var deflectPointMult = 1.5
@export var pointsOnTankFill = 20

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
	
	healthRemaining = float(HP) / float(maxHP)
	
	aggroList.clear()
	var currentVision : Array = checkVision()
	
	if State != States.Deflect and State != States.Attack :
		for thing in currentVision :
			if thing is Unit :
				if isFoe(thing) :
					if aggroList.has(thing) == false : aggroList.append(thing)
		if aggroList.is_empty() == false and (aggroList[0] != null and aggroList[0].canBeSeen) :
			aggroTarget = aggroList[0]
		if aggroTarget != null and aggroTarget.canBeSeen :
			if $RotateNode/ThrustArea.overlaps_body(aggroTarget) : 
				State = States.Attack
			else : 
				State = States.Approach
		else :
			aggroTarget = null
			if State != States.Move :
				State = States.Move
	
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
			
			var extraSpeed = lerpf(2, 1, sqrt(healthRemaining))
			#print("Speed : ",extraSpeed)
			
			direction = lerp(direction, desiredDirection, turnSpeed * extraSpeed * delta).normalized()
			direction = direction + Vector2(randf_range(-0.001, 0.001), randf_range(-0.001, 0.001))
			var roundedDirection = Vector2(round(direction.x), round(direction.y))
			var roundedDesiredDirection = Vector2(round(desiredDirection.x), round(desiredDirection.y))
			if roundedDirection == roundedDesiredDirection : velocity = direction * maxSpeed * extraSpeed
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
	else : sprite.speed_scale = velocity.length()/200
	if cAni == "Attack" : 
		var extraSpeed = lerpf(3, -1.5, clamp(sqrt(healthRemaining), 0, 0.5))
		#print("Attack : ", extraSpeed)
		sprite.speed_scale = extraSpeed
	
	move_and_slide()
	velocity = get_real_velocity()

func _init() :
	await ready
	HP = maxHP
	vision = $RotateNode/Vision
	nav = $VPNav
	$ComboCanvas.show()
	name = getName()

func adjustDMG(DMGDealt : int, dealer : Unit, _DMGtype : String, source : Node = null) :
	if source is Shot :
		var deflectChance = floor(lerp(1, 16, healthRemaining * healthRemaining))
		#print("HP : ", healthRemaining, " Deflect Chance : ", deflectChance)
		if randi_range(1, deflectChance) == 1 or deflectCombo < 1 :
			direction = position.direction_to(source.position)
			deflect()
			source.changeColor(Color.from_hsv(0, 0.9, 1, 1))
			DMGDealt = 0
			dealer.indirectDMG(self, 0)
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
		@warning_ignore("narrowing_conversion")
		givePoints(sqrt(deflectCombo * deflectPointMult), "Deflection Combo x" + str(deflectCombo))
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
					var dealt = unit.damage(JabDMG, SwordAP, self, "Melee", self)
					if unit.tags.has("HasBlood") : addToTank(dealt / 2)
					unit.dealKnockback(knockback, global_position.direction_to(unit.position))
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
					var dealt = unit.damage(SwingDMG, SwordAP, self, "Melee", self)
					if unit.tags.has("HasBlood") : addToTank(dealt / 2)
					unit.dealKnockback(knockback, global_position.direction_to(unit.position))

func _on_vampire_sprite_animation_finished():
	if cAni == "Attack" :
		State = States.Ready

func _on_nav_timer_timeout():
	if State == States.Approach :
		nav.target_position = aggroTarget.position
	if State == States.Move :
		nav.target_position = map.map_to_local(getTileToSearch())

func _on_engine_finished():
	$Engine.play()

func addToTank(amount : int) :
	
	match amount > 0 :
		true :
			if bloodTank != bloodTankMax : 
				$FillTank.play()
				var oldTank = bloodTank
				bloodTank += amount
				if bloodTank >= bloodTankMax : 
					bloodTank = bloodTankMax
					if bloodTank != oldTank and $FillCooldown.is_stopped() : 
						givePoints(pointsOnTankFill, "Blood Tank Filled")
						$FillCooldown.start()
		false :
			if bloodTank != 0 : 
				bloodTank += amount
				if bloodTank < 0 : bloodTank = 0

func _on_heal_timer_timeout():
	if bloodTank > 0 and HP < maxHP :
		bloodTank -= 1
		heal(1)
		$Heal.pitch_scale = lerpf(0.5, 1.5, sqrt(healthRemaining))
		$Heal.play()
