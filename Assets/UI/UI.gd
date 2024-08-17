extends CanvasLayer

@onready var world = $".."
@onready var tileMap = $"../Main"
@onready var detector = $"../Detector"
@onready var control = %Control
@onready var spawnPanel = %SpawnPanel
@onready var pointPanel = %PointPanel
@onready var unitWindow = load("res://Assets/UI/UnitWindow.tscn")
var unitWindows = []   



func _input(_event) :
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) :
		detectorToMousePos()
		var overlaping = detector.get_overlapping_bodies()
		for thing in overlaping :
			if thing is Unit and checkWindowsForUnit(thing) :
				var newUnitWindow = unitWindow.instantiate()
				newUnitWindow.observedUnit = thing
				unitWindows.append(newUnitWindow)
				control.add_child(newUnitWindow)
				newUnitWindow.position = control.get_global_mouse_position()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) :
		if spawnPanel.selectedUnit != spawnPanel.units.None :
			detectorToMousePos()
			if detector.get_overlapping_bodies().size() == 0 :
				var tileToSpawnOn = tileMap.local_to_map(world.get_global_mouse_position())
				var tileData = tileMap.get_cell_tile_data(tileToSpawnOn)
				if tileData != null and tileData.get_custom_data("Navigable") :
					spawnPanel.spawnUnit(tileMap.map_to_local(tileToSpawnOn))

func checkWindowsForUnit(unitToCheck : Unit) :
	for window in unitWindows :
		if window.observedUnit == unitToCheck : return false
	return true

func detectorToMousePos() :
	var mousePos = world.get_global_mouse_position()
	detector.global_position = mousePos

func givePoints(amount : int, reason : String, period : float = 1) :
	pointPanel.givePoints(amount, reason, period)
