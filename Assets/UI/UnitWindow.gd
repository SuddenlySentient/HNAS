extends Window

@onready var UI = $"../.."

var observedUnit : Unit

@onready var healthBar : ProgressBar = $VBoxContainer/VBoxContainer2/HBoxContainer/Health
@onready var healthBarLabel : Label = $VBoxContainer/VBoxContainer2/HBoxContainer/Health/Label
@export var updateHPSpeed = 16
@onready var adjustParticles = load("res://Assets/Base/Adjust/adjustParticles.tscn")

var mouseHeld = false
var closing = false
@export var postionSnapSpeed = 16
@export var positionSnap = 32

var type = ""



func _enter_tree():
	await ready
	$Open.play()
	
	type = observedUnit.type
	match type :
		"SUB-RFL-48"  :
			$VBoxContainer/VBoxContainer/SR.show()
			$VBoxContainer/VBoxContainer/SRWeapon.show()
			match observedUnit.weapon :
				observedUnit.Weapons.SMG :
					$VBoxContainer/VBoxContainer/SRWeapon/SMG.show()
					$VBoxContainer/VBoxContainer/SRWeapon/WeaponBox.value = 0
				observedUnit.Weapons.Shotgun :
					$VBoxContainer/VBoxContainer/SRWeapon/Shotgun.show()
					$VBoxContainer/VBoxContainer/SRWeapon/WeaponBox.value = 1
			
		"Pillar Demon"  :
			$VBoxContainer/VBoxContainer/PD.show()
		"Seraph"  :
			$VBoxContainer/VBoxContainer2/SeraphStamina.show()
		"Vampire"  :
			$VBoxContainer/VBoxContainer2/VampireBlood.show()
		"AMBEA"  :
			$"VBoxContainer/VBoxContainer2/AMBEACharge".show()
		_ :
			push_warning("Weird unit type ''", type, "'' ")
	
	const maxRand = int(512)
	position += Vector2i(int(randf_range(-1, 1) * maxRand), int(randf_range(-1, 1) * maxRand))

func _process(delta) :
	
	reset_size()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) : mouseHeld = true
	else : mouseHeld = false
	if mouseHeld == false :
		position.x = lerp(position.x, snapped(position.x, positionSnap), delta * postionSnapSpeed)
		position.y = lerp(position.y, snapped(position.y, positionSnap), delta * postionSnapSpeed)
		moveIntoFrame()
	
	if observedUnit == null :
		#print("No Observed Unit")
		if closing == false : close()
		return false
	
	title = observedUnit.name
	
	healthBar.max_value = observedUnit.maxHP
	healthBar.value = lerp(healthBar.value, float(observedUnit.HP), delta * updateHPSpeed)
	healthBarLabel.text = str(observedUnit.HP) + " / " + str(observedUnit.maxHP)
	
	match type :
		"SUB-RFL-48" :
			if observedUnit.inSquad : 
				$VBoxContainer/VBoxContainer/SR/Alone.hide()
				$VBoxContainer/VBoxContainer/SR/InSquad.show()
				if observedUnit.isLeader :
					$VBoxContainer/VBoxContainer/SR/Leader.show()
					$VBoxContainer/VBoxContainer/SR/NotALeader.hide()
				else :
					$VBoxContainer/VBoxContainer/SR/Leader.hide()
					$VBoxContainer/VBoxContainer/SR/NotALeader.show()
			else :
				$VBoxContainer/VBoxContainer/SR/Alone.show()
				$VBoxContainer/VBoxContainer/SR/InSquad.hide()
				$VBoxContainer/VBoxContainer/SR/Leader.hide()
				$VBoxContainer/VBoxContainer/SR/NotALeader.show()
			
			$VBoxContainer/VBoxContainer/States/WanderingPanel.hide()
			$VBoxContainer/VBoxContainer/States/AttackingPanel.hide()
			$VBoxContainer/VBoxContainer/States/ApproachingPanel.hide()
			
			#Unidle = 0,
			#Idle = 1,
			#Move = 2,
			#Shoot = 3,
			#Approach = 4
			match observedUnit.State :
				3 : 
					$VBoxContainer/VBoxContainer/States/AttackingPanel.show()
				2 :
					$VBoxContainer/VBoxContainer/States/WanderingPanel.show()
				4 :
					$VBoxContainer/VBoxContainer/States/ApproachingPanel.show()
		"Pillar Demon" :
			$VBoxContainer/VBoxContainer/States/PDSwarmPanel.hide()
			$VBoxContainer/VBoxContainer/States/WanderingPanel.hide()
			$VBoxContainer/VBoxContainer/States/PDScatterPanel.hide()
			$VBoxContainer/VBoxContainer/PD/PDPillar.hide()
			$VBoxContainer/VBoxContainer/PD/PDEmerged.hide()
			
			#Pillar = 0
			#Emerge = 1
			#Standing = 2
			#UnEmerge = 3
			match observedUnit.PillarState :
				0 :
					$VBoxContainer/VBoxContainer/PD/PDPillar.show()
				_ :
					$VBoxContainer/VBoxContainer/PD/PDEmerged.show()
					#Idle = 0,
					#Swarm = 1,
					#Wander = 2,
					#Scatter = 3,
					#Attack = 4,
					#GroupUp = 5
					match observedUnit.State :
						1, 4 :
							$VBoxContainer/VBoxContainer/States/PDSwarmPanel.show()
						2, 5 :
							$VBoxContainer/VBoxContainer/States/WanderingPanel.show()
						3 :
							$VBoxContainer/VBoxContainer/States/PDScatterPanel.show()
		"Seraph" :
			var staminaBar = $VBoxContainer/VBoxContainer2/SeraphStamina
			staminaBar.max_value = observedUnit.maxStamina
			staminaBar.value = lerp(staminaBar.value, float(observedUnit.stamina), delta * updateHPSpeed)
			if observedUnit.stamina < 1 : staminaBar.value = 0
			var staminaBarLabel = $VBoxContainer/VBoxContainer2/SeraphStamina/Label
			staminaBarLabel.text = str(observedUnit.stamina) + " / " + str(observedUnit.maxStamina)
			
			$VBoxContainer/VBoxContainer/States/WanderingPanel.hide()
			$VBoxContainer/VBoxContainer/States/AttackingPanel.hide()
			
			#Relaxed = 0
			#Searching = 1
			#Enraged = 2
			match observedUnit.State :
				1, 0 :
					$VBoxContainer/VBoxContainer/States/WanderingPanel.show()
				2 : 
					$VBoxContainer/VBoxContainer/States/AttackingPanel.show()
		"Vampire" :
			var bloodTank = $VBoxContainer/VBoxContainer2/VampireBlood
			bloodTank.max_value = observedUnit.bloodTankMax
			bloodTank.value = lerp(bloodTank.value, float(observedUnit.bloodTank), delta * updateHPSpeed)
			if observedUnit.bloodTank < 1 : bloodTank.value = 0
			var bloodTankLabel = $VBoxContainer/VBoxContainer2/VampireBlood/Label
			bloodTankLabel.text = str(observedUnit.bloodTank) + " / " + str(observedUnit.bloodTankMax)
			
			$VBoxContainer/VBoxContainer/States/WanderingPanel.hide()
			$VBoxContainer/VBoxContainer/States/AttackingPanel.hide()
			$VBoxContainer/VBoxContainer/States/VPDeflectPanel.hide()
			$VBoxContainer/VBoxContainer/States/ApproachingPanel.hide()
			
			#Ready = 0,
			#Deflect = 1
			#Attack = 2
			#Move = 3
			#Approach = 4
			match observedUnit.State :
				1 : 
					$VBoxContainer/VBoxContainer/States/VPDeflectPanel.show()
				2 : 
					$VBoxContainer/VBoxContainer/States/AttackingPanel.show()
				3 :
					$VBoxContainer/VBoxContainer/States/WanderingPanel.show()
				4 :
					$VBoxContainer/VBoxContainer/States/ApproachingPanel.show()
		"AMBEA"  :
			var ChargeMeter = $VBoxContainer/VBoxContainer2/AMBEACharge
			ChargeMeter.value = lerp(ChargeMeter.value, float(observedUnit.charge), delta * updateHPSpeed)
			var ChargeMeterLabel = $VBoxContainer/VBoxContainer2/AMBEACharge/Label
			ChargeMeterLabel.text = str(floor(observedUnit.charge * 100)) + "%"
			const shakeIntensity = 4
			var shake : Vector2i = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shakeIntensity * observedUnit.charge
			position += shake
			
			#Ready = 0,
			#Wander = 1,
			#Found = 2,
			#Firing = 3,
			#Napalm = 4
			
			$VBoxContainer/VBoxContainer/States/WanderingPanel.hide()
			$VBoxContainer/VBoxContainer/States/ApproachingPanel.hide()
			$VBoxContainer/VBoxContainer/States/AttackingPanel.hide()
			
			match observedUnit.State :
				1 :
					$VBoxContainer/VBoxContainer/States/WanderingPanel.show()
				2 :
					$VBoxContainer/VBoxContainer/States/ApproachingPanel.show()
				3, 4 : 
					$VBoxContainer/VBoxContainer/States/AttackingPanel.show()
		"Sentry"  :
			
			#Rest = 0,
			#Awake = 1,
			#Ready = 2,
			#Walk = 3,
			#Approach = 4,
			#Attack = 5,
			#PrepareThrust = 6,
			#Thrust = 7,
			#Knocked = 8
			
			$VBoxContainer/VBoxContainer/States/WanderingPanel.hide()
			$VBoxContainer/VBoxContainer/States/ApproachingPanel.hide()
			$VBoxContainer/VBoxContainer/States/AttackingPanel.hide()
			
			match observedUnit.State :
				1 :
					$VBoxContainer/VBoxContainer/States/WanderingPanel.show()
				4 :
					$VBoxContainer/VBoxContainer/States/ApproachingPanel.show()
				5, 6, 7 : 
					$VBoxContainer/VBoxContainer/States/AttackingPanel.show()

func _on_close_requested() :
	close()

func close() :
	closing = true
	UI.unitWindows.erase(self)
	hide()
	$Close.play()
	await $Close.finished
	queue_free()

func _on_zoom_to_button_pressed():
	var camera = UI.world.get_children()[2]
	camera.moveTo(observedUnit.position)

func moveIntoFrame() :
	var window : Rect2i = Rect2i(position, size)
	var frame : Rect2i = $"..".get_rect()
	frame.position += Vector2i(16, 32)
	frame.size -= Vector2i(16, 32)
	var fullsize = frame.size
	var maxX = fullsize.x - window.size.x
	var maxY = fullsize.y - window.size.y
	
	#print("Pos : ", position, " Frame : ", frame.position)
	if frame.encloses(window) == false :
		#print("Pos : ", position, " Frame : ", frame.position)
		if position.x < frame.position.x : position.x = frame.position.x
		elif position.x > maxX : position.x = maxX
		if position.y < frame.position.y : position.y = frame.position.y
		elif position.y > maxY : position.y = maxY
		$IntoFrame.play()

func _on_weapon_box_value_changed(value: float) -> void:
	adjustPart()
	match value :
		0.0 :
			$VBoxContainer/VBoxContainer/SRWeapon/SMG.show()
			$VBoxContainer/VBoxContainer/SRWeapon/Shotgun.hide()
			observedUnit.weapon = observedUnit.Weapons.SMG
		1.0 :
			$VBoxContainer/VBoxContainer/SRWeapon/SMG.hide()
			$VBoxContainer/VBoxContainer/SRWeapon/Shotgun.show()
			observedUnit.weapon = observedUnit.Weapons.Shotgun

func adjustPart() :
	var newParticles = adjustParticles.instantiate()
	newParticles.get_child(0).global_position = observedUnit.global_position
	observedUnit.add_child(newParticles)
