extends Window

var mouseHeld = false
@export var postionSnapSpeed = 16
@export var positionSnap = 32
@export var sizeSnap = 64
var score : int = 0
@export var scoreCap : int = 999999
@onready var beep = $VBoxContainer/Ticker/Beep
@onready var maxReached = $VBoxContainer/Ticker/MaxReached
@onready var digits = [
	$VBoxContainer/Ticker/Container/Digit5,
	$VBoxContainer/Ticker/Container/Digit4,
	$VBoxContainer/Ticker/Container/Digit3,
	$VBoxContainer/Ticker/Container/Digit2,
	$VBoxContainer/Ticker/Container/Digit1,
	$VBoxContainer/Ticker/Container/Digit0
	]
var multiplier : float = 1 


func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) : mouseHeld = true
	else : mouseHeld = false
	if mouseHeld == false :
		position.x = lerp(position.x, snapped(position.x, positionSnap), delta * postionSnapSpeed)
		position.y = lerp(position.y, snapped(position.y, positionSnap), delta * postionSnapSpeed)
		size.x = lerp(size.x, snapped(size.x, sizeSnap), delta * postionSnapSpeed)
		size.y = lerp(size.y, snapped(size.y, sizeSnap), delta * postionSnapSpeed)
		moveIntoFrame()

func increment(amount : int) :
	amount = int(amount * multiplier)
	var oldScore = score
	score += amount
	if score > scoreCap : 
		score = scoreCap
		if oldScore != scoreCap : maxReached.play()
	if score > oldScore :
		updateTicker()
		beep.play()

func updateTicker() :
	var scoreText = str(score)
	#print(scoreText)
	var length = scoreText.length()
	for y in length :
		var x = length - y - 1
		var numbToSet = int(scoreText[y])
		var currentPlace = digits[x].texture.region.position.y / 20
		beep.pitch_scale = lerp(0.5, 1.0, currentPlace / 6.0)
		digits[x].texture.region.position.y = numbToSet * 20
		#print("Set ", x, " to ", numbToSet)

func setMultiplier(value : float) :
	pass
	multiplier = value

func _on_timer_timeout():
	increment(1)

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
