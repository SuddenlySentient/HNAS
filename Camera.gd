extends Camera2D

var zipZoom : float = 0.25
@export var zoomSpeed : float


func _process(delta):
	
	zoom.x = lerpf(0.2, 1, zipZoom)
	zoom.y = lerpf(0.2, 1, zipZoom)

func _input(event) :
	
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_WHEEL_UP :
			zipZoom = lerpf(zipZoom, 0, zoomSpeed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN :
			zipZoom = lerpf(zipZoom, 1, zoomSpeed)
		if event.button_index == MOUSE_BUTTON_MIDDLE and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			var newPosition = floor(get_global_mouse_position() / 256) * 256
			newPosition.x = newPosition.x + 128
			newPosition.y = newPosition.y + 128
			position = newPosition
