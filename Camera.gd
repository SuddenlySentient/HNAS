extends Camera2D

const TILEMAP_COORDINATE: float = 256
const TILE_CENTER: Vector2 = Vector2(128, 128)
var zipZoom : float = 0.25
@export var zoomSpeed : float

var desiredPosition = Vector2(128, 128)
var previousTile : Vector2i
var panSpeed = 256

func _process(_delta) :
	
	var timerProgress = 1 - ($Timer.time_left / $Timer.wait_time)
	timerProgress = sin(timerProgress * PI / 2)
	position = position.lerp(desiredPosition, timerProgress)
	
	var newTile : Vector2i = floor(global_position / TILEMAP_COORDINATE)
	
	if newTile != previousTile :
		#print("Click!")
		$Click.pitch_scale = lerp(0.8, 1.25, timerProgress)
		$Click.play()
		previousTile = newTile
	
	zoom.x = lerpf(0.125, 1, zipZoom)
	zoom.y = lerpf(0.125, 1, zipZoom)

func _input(_event) :
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP) :
		zipZoom = lerpf(zipZoom, 0, zoomSpeed)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN) :
		zipZoom = lerpf(zipZoom, 1, zoomSpeed)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) :
		var newPosition = floor(get_global_mouse_position() / TILEMAP_COORDINATE) * TILEMAP_COORDINATE
		desiredPosition = newPosition + TILE_CENTER
		$Timer.start()
