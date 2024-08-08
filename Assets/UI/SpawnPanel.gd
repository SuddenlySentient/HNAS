extends Window

@onready var UI = $"../.."
var mouseHeld = false
@export var postionSnapSpeed = 16
@export var positionSnap = 32
@export var sizeSnap = 64
@onready var unitPanels = [
$ScrollContainer/HBoxContainer/SRPanel,
$ScrollContainer/HBoxContainer/PDPanel,
$ScrollContainer/HBoxContainer/VPPanel,
$ScrollContainer/HBoxContainer/SEPanel,
]
enum units {
None = 0,
SR = 1,
PD = 2,
VP = 3,
SE = 4,
}
var selectedUnit : units = units.None
@onready var unitScenes = [
load("res://Assets/SUB-RFL-48/sub_rfl_48.tscn"),
load("res://Assets/Pillar Demon/PillarDemon.tscn"),
load("res://Assets/Vampire/Vampire.tscn"),
load("res://Assets/Seraph/seraph.tscn"),
]

func _process(delta):
	var index = 0
	var anyButtonPressed = false
	for panel in unitPanels :
		var button : Button = panel.get_children()[2]
		index += 1
		if button.button_pressed :
			anyButtonPressed = true
			#print("A Selected Unit : ", selectedUnit)
			#print("A Index : ", index)
			if selectedUnit != index :
				@warning_ignore("int_as_enum_without_cast")
				selectedUnit = index
				#print("New Unit Selected! : ", selectedUnit)
				index = 1
				for panel2 in unitPanels :
					var button2 : Button = panel2.get_children()[2]
					#print("B Selected Unit : ", selectedUnit)
					#print("B Index : ", index)
					if index != selectedUnit :
						#print("Disabled Old Button : ", index)
						button2.button_pressed = false
					index += 1
	if anyButtonPressed == false : selectedUnit = units.None
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) : mouseHeld = true
	else : mouseHeld = false
	if mouseHeld == false :
		position.x = lerp(position.x, snapped(position.x, positionSnap), delta * postionSnapSpeed)
		position.y = lerp(position.y, snapped(position.y, positionSnap), delta * postionSnapSpeed)
		size.x = lerp(size.x, snapped(size.x, sizeSnap), delta * postionSnapSpeed)

func spawnUnit(location : Vector2, unit = unitScenes[selectedUnit - 1]) :
	if $"Spawn Cooldown".is_stopped() == false : return false
	$"Spawn Cooldown".start()
	var newUnit = unit.instantiate()
	newUnit.global_position = location
	UI.tileMap.add_child(newUnit)
	particles(location)
	print("Spawned : ", newUnit.name)
	return true

@onready var spawnParticles = load("res://Assets/Base/spawnParticles.tscn")

func particles(location : Vector2) :
	var newParticles = spawnParticles.instantiate()
	newParticles.get_child(0).global_position = location
	UI.tileMap.add_child(newParticles)
