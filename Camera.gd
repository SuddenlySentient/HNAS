extends Camera2D

const TILEMAP_COORDINATE: float = 256
const TILE_CENTER: Vector2 = Vector2(128, 128)
var zipZoom : float = 0.25
@export var zoomSpeed : float

var desiredPosition = Vector2(128, 128)
var previousTile : Vector2i
var panSpeed = 256



func _process(delta) :
	
	var timerProgress = 1 - ($Timer.time_left / $Timer.wait_time)
	timerProgress = sin(timerProgress * PI / 2)
	position = position.lerp(desiredPosition, timerProgress)
	
	var newTile : Vector2i = floor(global_position / TILEMAP_COORDINATE)
	
	if newTile != previousTile :
		#print("Click!")
		$Click.pitch_scale = lerp(0.8, 1.25, timerProgress)
		$Click.play()
		previousTile = newTile
	
	var newZoom : Vector2 = Vector2(0.5, 0.5)
	
	newZoom.x = lerpf(0.125, 1, zipZoom)
	newZoom.y = lerpf(0.125, 1, zipZoom)
	
	var boop = clamp(delta * 8, 0, 1)
	
	zoom.x = lerpf(zoom.x, newZoom.x, boop)
	zoom.y = lerpf(zoom.y, newZoom.y, boop)
	
	var unRoundedZoomVelocity = (zoom.x / newZoom.x)
	var zoomVelocity = round(unRoundedZoomVelocity * 1000) / 1000
	
	if zoomVelocity > 1 : 
		var zoomMeasure = unRoundedZoomVelocity - 1
		$ServoIn.pitch_scale = clamp(zoomMeasure * 40, 0.5, 2)
		
		if $ServoIn.playing == false : 
			$ServoIn.play()
			if $ServoOut.playing : $ServoOut.stop()
	elif zoomVelocity < 1 :
		var zoomMeasure = 1 - unRoundedZoomVelocity
		$ServoOut.pitch_scale = clamp(zoomMeasure * 10, 0.5, 2)
		
		if $ServoOut.playing == false : 
			$ServoOut.play()
			if $ServoIn.playing : $ServoIn.stop()
	else : 
		if $ServoIn.playing :
			$StartZoom.play()
		if $ServoOut.playing : 
				$StopZoom.play()
		$ServoIn.stop()
		$ServoOut.stop()

func _input(_event) :
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP) :
		zipZoom = lerpf(zipZoom, 0, zoomSpeed)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN) :
		zipZoom = lerpf(zipZoom, 1, zoomSpeed)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) :
		var newPosition = floor(get_global_mouse_position() / TILEMAP_COORDINATE) * TILEMAP_COORDINATE
		moveTo(newPosition + TILE_CENTER)

func moveTo(location : Vector2) :
	desiredPosition = location + TILE_CENTER
	$Timer.start()
