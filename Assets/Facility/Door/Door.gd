extends Node2D

@onready var sprite = $DoorSprite
@onready var collision = $DoorCollision
@onready var nav = $NavigationRegion2D
@onready var navLink = $NavigationLink
@onready var sensor = $UnitSensor
@onready var closedTimer = $CloseTimer
@export var closed = true
var sideways = false

func _ready():
	if sideways : 
		sprite.hide()
		collision.disabled = true
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

func open() :
	if sprite.is_playing() == false : 
		#print("OPEN")
		sprite.play("Door")

func close() :
	if sprite.is_playing() == false : 
		#print("CLOSE")
		sprite.play_backwards("Door")

func _on_door_sprite_frame_changed():
	if sprite.is_playing() :
		if $Working.playing == false : $Working.play()
	else : $Working.stop()

func _on_door_sprite_animation_finished():
	match sprite.frame :
		15 :
			collision.set_deferred("disabled", true)
			nav.enabled = true
			navLink.enabled = false
			$Open.play()
			#print("FULLY OPEN")
			closed = false
		0 : 
			collision.set_deferred("disabled", false)
			nav.enabled = false
			navLink.enabled = true
			$Close.play()
			#print("FULLY CLOSED")
			closed = true

func _on_close_timer_timeout():
	if closed == false : close()
