extends Node2D

@onready var sprite = $DoorSprite
@onready var collision = $DoorCollision
@onready var sidewaysCollision = $SidewaysDoorCollision
@onready var nav = $Node2D/NavigationRegion2D
@onready var navLink = $Node2D/NavigationLink
@onready var sensor = $Node2D/UnitSensor
@onready var closedTimer = $CloseTimer
@onready var lightTimer = $LightTimer
@onready var map : TileMapLayer = $".."
@onready var doorLight = $DoorLight
@onready var button = $Node2D2/CanvasLayer/Button
@export var closed = true
var sideways = false
@export var scaleSpeed = 2
var locked = false
var curio = load("res://Assets/Base/Curiosity/Curiousity.tscn")



func _ready():
	
	button.position = global_position + Vector2(-96, -96 -128)
	$Node2D2/CanvasLayer.show()
	var randPitch = randf_range(0.8, 1.25)
	$Working.pitch_scale = randPitch
	$Open.pitch_scale = randPitch
	$Close.pitch_scale = randPitch
	
	getIfSideways()
	if sideways : 
		sprite.hide()
		$DoorOccluder.hide()
		$DoorCollision.set_deferred("disabled", true)
		$DoorCollisionLeft.set_deferred("disabled", true)
		$DoorCollisionRight.set_deferred("disabled", true)
		$Node2D.rotation_degrees = 90
	else :
		$SidewaysSprite.hide()
		$SidewaysDoorOccluder.hide()
		$SidewaysDoorCollision.set_deferred("disabled", true)
		$SidewaysDoorCollisionLeft.set_deferred("disabled", true)
		$SidewaysDoorCollisionRight.set_deferred("disabled", true)
	if closed : sprite.frame = 0
	else : sprite.frame = 15

func _physics_process(delta):
	
	if button.visible : 
		button.position = lerp(button.position, global_position + Vector2(-96, -96 -384), delta * scaleSpeed)
		if locked : 
			button.scale = lerp(button.scale, Vector2(1, 1), delta * scaleSpeed)
		else :
			button.scale = lerp(button.scale, Vector2(0.75, 0.75), delta * scaleSpeed)
	else : 
		button.scale = Vector2.ZERO
		button.position = lerp(button.position, global_position + Vector2(-96, -96 -128), delta * scaleSpeed)
	
	doorLight.energy = sin((lightTimer.time_left / lightTimer.wait_time) * PI)
	
	if locked == false :
		var sensing = sensor.get_overlapping_bodies()
		var sensed = false
		if sensing.size() > 0 :
			for thing in sensing : if thing is Unit and thing.canBeSeen : sensed = true
		if sensed and closed : 
			open()
			closedTimer.stop()
		if sensed == false and closed == false : 
			if closedTimer.is_stopped() : 
				closedTimer.start()
	else : close()

func open() :
	if sprite.is_playing() == false and locked == false : 
		#print("OPEN")
		var newCurio = curio.instantiate()
		newCurio.createCuriousity("Door Open", 0, 12, null, 4)
		map.add_child(newCurio)
		lightTimer.start()
		doorLight.color = Color("66ff66")
		sprite.play("Door")
		nav.enabled = true

func close() :
	if sprite.is_playing() == false and closed == false : 
		#print("CLOSE")
		lightTimer.start()
		doorLight.color = Color("ff6666")
		sprite.play_backwards("Door")
		nav.enabled = false

func getIfSideways() :
	var myTileCoords = map.local_to_map(global_position - Vector2(0, 128))
	var topTile = map.get_neighbor_cell(myTileCoords, TileSet.CELL_NEIGHBOR_TOP_SIDE)
	var bottomTile = map.get_neighbor_cell(myTileCoords, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
	var leftTile = map.get_neighbor_cell(myTileCoords, TileSet.CELL_NEIGHBOR_LEFT_SIDE)
	var rightTile = map.get_neighbor_cell(myTileCoords, TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
	
	if getTileNavigable(bottomTile) and getTileNavigable(topTile) : 
		#print("Door at ", myTileCoords, " is not sideways")
		sideways = false
	elif getTileNavigable(rightTile) and getTileNavigable(leftTile) : 
		#print("Door at ", myTileCoords, " is sideways")
		sideways = true
	else : push_error("Error! Door at ", myTileCoords, " is placed weird!")

func getTileNavigable(tileCoord : Vector2i):
	var data = map.get_cell_tile_data(tileCoord)
	if data == null : return false
	else : return data.get_custom_data("Navigable")

func _on_door_sprite_frame_changed():
	if sprite.is_playing() :
		if $Working.playing == false : $Working.play()
	else : $Working.stop()

func _on_door_sprite_animation_finished():
	match sprite.frame :
		15 :
			if sideways : sidewaysCollision.set_deferred("disabled", true)
			else : collision.set_deferred("disabled", true)
			nav.enabled = true
			navLink.enabled = false
			$Open.play()
			#print("FULLY OPEN")
			closed = false
		0 : 
			if sideways : sidewaysCollision.set_deferred("disabled", false)
			else : collision.set_deferred("disabled", false)
			nav.enabled = false
			if locked == false :
				navLink.enabled = true
			$Close.play()
			#print("FULLY CLOSED")
			closed = true

func _on_close_timer_timeout():
	if closed == false : close()

func _on_node_2d_2_screen_entered():
	#print("Show")
	$Node2D2/CanvasLayer/Button.show()

func _on_node_2d_2_screen_exited():
	#print("Hide")
	$Node2D2/CanvasLayer/Button.hide()

func _on_button_toggled(toggled_on):
	if toggled_on : 
		$Lock.pitch_scale = 0.5
		$Lock.play()
		navLink.enabled = false
		locked = true
	else : 
		$Lock.pitch_scale = 1
		$Lock.play()
		if closed : navLink.enabled = true
		locked = false
