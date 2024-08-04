extends CanvasLayer

@onready var world = $".."
@onready var detector = $"../Area2D"
@onready var control = $Control
@onready var unitWindow = load("res://Assets/UI/UnitWindow.tscn")
var unitWindows = []



func _input(_event) :
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) :
		var mousePos = world.get_global_mouse_position()
		detector.global_position = mousePos
		var overlaping = detector.get_overlapping_bodies()
		for thing in overlaping :
			if thing is Unit and checkWindowsForUnit(thing) :
				var newUnitWindow = unitWindow.instantiate()
				newUnitWindow.observedUnit = thing
				unitWindows.append(newUnitWindow)
				control.add_child(newUnitWindow)
				newUnitWindow.position = control.get_global_mouse_position()

func checkWindowsForUnit(unitToCheck : Unit) :
	for window in unitWindows :
		if window.observedUnit == unitToCheck : return false
	return true
