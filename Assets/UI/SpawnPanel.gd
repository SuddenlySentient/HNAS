extends Window

@onready var UI = $"../.."
var mouseHeld = false
@export var postionSnapSpeed = 16
@export var positionSnap = 32
@export var sizeSnap = 64
@onready var unitPanels = [
$Control/ScrollContainer/HBoxContainer/SRPanel,
$Control/ScrollContainer/HBoxContainer/PDPanel,
$Control/ScrollContainer/HBoxContainer/VPPanel,
$Control/ScrollContainer/HBoxContainer/SEPanel,
$Control/ScrollContainer/HBoxContainer/SNPanel,
$Control/ScrollContainer/HBoxContainer/AMBEAPanel,
$Control/ScrollContainer/HBoxContainer/MantisPanel
]
enum units {
None = 0,
SR = 1,
PD = 2,
VP = 3,
SE = 4,
SN = 4,
AMBEA = 5,
MT = 6
}
var selectedUnit : units = units.None
@onready var teamButtons = [
$Control/TeamButtons/R,
$Control/TeamButtons/G,
$Control/TeamButtons/B,
$Control/TeamButtons/Y
]
enum teams {
None = 0,
Red = 1,
Green = 2,
Blue = 3,
Yellow = 4
}
var selectedTeam : teams = teams.None
@onready var unitScenes = [
"res://Assets/SUB-RFL-48/sub_rfl_48.tscn",
"res://Assets/Pillar Demon/PillarDemon.tscn",
"res://Assets/Vampire/Vampire.tscn",
"res://Assets/Seraph/seraph.tscn",
"res://Assets/Sentry/Sentry.tscn",
"res://Assets/AMBEA/AMBEA.tscn",
"res://Assets/Mantis/Mantis.tscn"
]

func _input(_event) :
	dealWithUnitPanels()
	dealWithTeamButtons()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) : mouseHeld = true
	else : mouseHeld = false

func _process(delta):
	if mouseHeld == false :
		position.x = lerp(position.x, snapped(position.x, positionSnap), delta * postionSnapSpeed)
		position.y = lerp(position.y, snapped(position.y, positionSnap), delta * postionSnapSpeed)
		size.x = lerp(size.x, snapped(size.x, sizeSnap), delta * postionSnapSpeed)
		moveIntoFrame()

func dealWithUnitPanels() :
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

func dealWithTeamButtons() :
	var index = 0
	var anyButtonPressed = false
	for button in teamButtons :
		index += 1
		if button.button_pressed :
			anyButtonPressed = true
			if selectedTeam != index :
				@warning_ignore("int_as_enum_without_cast")
				selectedTeam = index
				index = 1
				for button2 in teamButtons :
					if index != selectedTeam :
						button2.button_pressed = false
					index += 1
	if anyButtonPressed == false : selectedTeam = teams.None

func spawnUnit(location : Vector2, unit = unitScenes[selectedUnit - 1]) :
	if $"Spawn Cooldown".is_stopped() == false : return false
	$"Spawn Cooldown".start()
	var newUnit = load(unit).instantiate()
	newUnit.global_position = location
	var team = teams.keys()[selectedTeam]
	if team != "None" : newUnit.team = team
	#print(team)
	UI.tileMap.add_child(newUnit)
	particles(location)
	#print("Spawned : ", newUnit.name)
	return true

@onready var spawnParticles = load("res://Assets/Base/spawnParticles.tscn")

func particles(location : Vector2) :
	var newParticles = spawnParticles.instantiate()
	newParticles.get_child(0).global_position = location
	UI.tileMap.add_child(newParticles)

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
