extends Window

@onready var UI = $"../.."

var observedUnit : Unit

@onready var healthBar : ProgressBar = $VBoxContainer/VBoxContainer2/HBoxContainer/Health
@onready var healthBarLabel : Label = $VBoxContainer/VBoxContainer2/HBoxContainer/Health/Label
@export var updateHPSpeed = 16

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
		"Pillar Demon"  :
			$VBoxContainer/VBoxContainer/PD.show()
		"Seraph"  :
			$VBoxContainer/VBoxContainer2/SeraphStamina.show()
		"Vampire"  :
			$VBoxContainer/VBoxContainer2/VampireBlood.show()
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
