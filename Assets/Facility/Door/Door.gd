extends Node2D

@onready var sprite = $DoorSprite
@onready var collision = $DoorCollision
@onready var sidewaysCollision = $SidewaysDoorCollision
@onready var nav = $Node2D/NavigationRegion2D
@onready var navLink = $Node2D/NavigationLink
@onready var sensor = $Node2D/UnitSensor
@onready var closedTimer = $CloseTimer
@onready var lightTimer = $LightTimer
@onready var map : TileMap = $".."
@onready var doorLight = $DoorLight
@export var closed = true
var sideways = false

func _ready():
	
	collision.set_deferred("disabled", true)
	sidewaysCollision.set_deferred("disabled", true)
	
	var randPitch = randf_range(0.8, 1.25)
	$Working.pitch_scale = randPitch
	$Open.pitch_scale = randPitch
	$Close.pitch_scale = randPitch
	
	getIfSideways()
	if sideways : 
		sprite.hide()
		$DoorOccluder.hide()
		$DoorCollisionLeft.set_deferred("disabled", true)
		$DoorCollisionRight.set_deferred("disabled", true)
		$Node2D.rotation_degrees = 90
	else :
		$SidewaysSprite.hide()
		$SidewaysDoorCollisionLeft.set_deferred("disabled", true)
		$SidewaysDoorCollisionRight.set_deferred("disabled", true)
	if closed : sprite.frame = 0
	else : sprite.frame = 15

func _physics_process(_delta):
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
	doorLight.energy = sin((lightTimer.time_left / lightTimer.wait_time) * PI)

func open() :
	if sprite.is_playing() == false : 
		#print("OPEN")
		lightTimer.start()
		doorLight.color = Color("66ff66")
		sprite.play("Door")

func close() :
	if sprite.is_playing() == false : 
		#print("CLOSE")
		lightTimer.start()
		doorLight.color = Color("ff6666")
		sprite.play_backwards("Door")

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
	else : print("Error! Door at ", myTileCoords, " is placed weird!")

func getTileNavigable(tileCoord : Vector2i):
	var data = map.get_cell_tile_data(0, tileCoord)
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
			navLink.enabled = true
			$Close.play()
			#print("FULLY CLOSED")
			closed = true

func _on_close_timer_timeout():
	if closed == false : close()
