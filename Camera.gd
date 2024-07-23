extends Camera2D

const TILEMAP_COORDINATE: int = 256
const TILE_CENTER: Vector2 = Vector2(128, 128)
const MIN_ZOOM: int = 0
const MAX_ZOOM: int = 1

var zipZoom : float = 0.25
@export var zoomSpeed : float

func _process(delta):
	
	zoom.x = lerpf(0.2, 1, zipZoom)
	zoom.y = lerpf(0.2, 1, zipZoom)

func _input(event) :
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP) :
		zipZoom = lerpf(zipZoom, MIN_ZOOM, zoomSpeed)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN) :
		zipZoom = lerpf(zipZoom, MAX_ZOOM, zoomSpeed)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) :
		var newPosition = floor(get_global_mouse_position() / TILEMAP_COORDINATE) * TILEMAP_COORDINATE
		position = newPosition + TILE_CENTER
