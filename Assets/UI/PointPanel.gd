extends Window

var mouseHeld = false
@export var postionSnapSpeed = 16
@export var positionSnap = 32
@export var sizeSnap = 64
var score : int = 0
@export var scoreCap : int = 6
@export var disabled : bool = false
@onready var beep = $VBoxContainer/HBoxContainer/Ticker/Beep
@onready var maxReached = $VBoxContainer/HBoxContainer/Ticker/MaxReached
@onready var consoleText = $VBoxContainer/Console/MarginContainer/Label
@onready var digits = [
	$VBoxContainer/HBoxContainer/Ticker/Container/Digit5,
	$VBoxContainer/HBoxContainer/Ticker/Container/Digit4,
	$VBoxContainer/HBoxContainer/Ticker/Container/Digit3,
	$VBoxContainer/HBoxContainer/Ticker/Container/Digit2,
	$VBoxContainer/HBoxContainer/Ticker/Container/Digit1,
	$VBoxContainer/HBoxContainer/Ticker/Container/Digit0
	]
@onready var multDigits = [
	$VBoxContainer/HBoxContainer/Multiplier/HBoxContainer/Control/Container/Digit2,
	$VBoxContainer/HBoxContainer/Multiplier/HBoxContainer/Control/Container/Digit1,
	$VBoxContainer/HBoxContainer/Multiplier/HBoxContainer/Control2/Digit0,
	]
@onready var coloredText = [
	$VBoxContainer/HBoxContainer/Ticker/Container,
	$VBoxContainer/HBoxContainer/Multiplier/HBoxContainer/Control2/DigitDot,
	$VBoxContainer/HBoxContainer/Multiplier/HBoxContainer/Control2/Digit0,
	$VBoxContainer/HBoxContainer/Multiplier/HBoxContainer/Control/Container
	]
var multiplier : float = 1 
signal doneTyping()
signal donePointing()
var capped = false
var pointing = false
var typing = false
var queue = 0

func _init() :
	await ready
	updateCap(3)

func _process(delta):
	
	var wane = $WaneTimer.time_left / $WaneTimer.wait_time
	wane = sin(wane * PI)
	var newColor = lerp(Color("ff7000"), Color("ff9000"), wane)
	for thing in coloredText :
		thing.modulate = newColor
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) : mouseHeld = true
	else : mouseHeld = false
	if mouseHeld == false :
		position.x = lerp(position.x, snapped(position.x, positionSnap), delta * postionSnapSpeed)
		position.y = lerp(position.y, snapped(position.y, positionSnap), delta * postionSnapSpeed)
		size.x = lerp(size.x, snapped(size.x, sizeSnap), delta * postionSnapSpeed)
		size.y = lerp(size.y, snapped(size.y, sizeSnap), delta * postionSnapSpeed)
		moveIntoFrame()

func givePoints(amount : int, reason : String, period : float = 1) :
	
	if disabled : return false
	
	var originalAmount = amount
	if multiplier != 1 and sign(amount) == 1 :
		amount = int(amount * multiplier)
		if multiplier < 1 and amount == 0 : amount = 1
	
	var amountSign = "+"
	if sign(amount) == -1 : amountSign = ""
	
	var outputText = amountSign + str(amount) + "p"
	if multiplier != 1 and sign(amount) == 1 : outputText += " (" + str(originalAmount) + "p x" + str(multiplier) + ")"
	else : outputText += "\t"
	outputText += "\t: " + reason + "\n" 
	
	if typing : 
		queue += 1
		for x in queue : await doneTyping
		queue -= 1
	
	consoleText.visible_characters = consoleText.text.length()
	consoleText.text += outputText
	
	cappedAmount = consoleText.visible_characters + consoleText.text.length()
	$TypeTimer.start()
	typing = true
	await doneTyping
	typing = false
	
	if queue == 0 : typingTime = 0
	
	if pointing : await donePointing
	pointing = true
	
	if period == 0 : increment(amount)
	else :
		var givenPoints = 0
		var time = period / float(abs(amount))
		while givenPoints < abs(amount) :
			if capped and sign(amount) == 1 :
				emit_signal("donePointing")
				pointing = false
				return false
			await get_tree().create_timer(time).timeout
			increment(sign(amount))
			givenPoints += 1
	pointing = false
	emit_signal("donePointing")

func increment(amount : int) :
	var oldScore = score
	score += amount
	
	if amount < 0 :
		#print("borp")
		capped = false
		if score < 0 : 
			score = 0
		if score < oldScore :
			updateTicker()
			beep.pitch_scale = beep.pitch_scale / 1.75
			beep.play()
	else :
		#print("beep")
		var maxA = 1
		for x in scoreCap : maxA = maxA * 10
		maxA -= 1
		if score > maxA : 
			score = maxA
			updateTicker()
			if capped == false : 
				maxReached.play()
				capped = true
		else :
			updateTicker()
			beep.pitch_scale *= multiplier
			beep.play()
			capped = false

func updateTicker() :
	var scoreText = str(score)
	while scoreText.length() < digits.size() : scoreText = "0" + scoreText
	var length = scoreText.length()
	for y in length :
		var x = length - y - 1
		var numbToSet = int(scoreText[y])
		var currentPlace = digits[x].texture.region.position.y / 20
		beep.pitch_scale = lerp(0.5, 1.0, currentPlace / 6.0)
		digits[x].texture.region.position.y = numbToSet * 20

func setMultiplier(value : float) :
	multiplier = snappedf(value, 0.01)
	var scoreText = str(multiplier).replace(".", "")
	while scoreText.length() < 3 : 
		scoreText += "0"
	for y in 3 :
		var numbToSet = int(scoreText[y])
		multDigits[2 - y].texture.region.position.y = numbToSet * 20

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

func updateCap(newCap : int) :
	for z in digits.size() :
		digits[z].self_modulate = Color("ffffff00")
	for y in newCap :
		var x = newCap - y - 1
		digits[x].self_modulate = Color("ffffff")
	scoreCap = newCap

@export var typingSpeed = 1
var typingTime : float = 0
var cappedAmount = 0

func _on_type_timer_timeout():
	if consoleText.visible_characters < consoleText.text.length() :
		$KeyStroke.play()
		consoleText.visible_characters += ceil(typingSpeed * typingTime)
		consoleText.visible_characters = clamp(consoleText.visible_characters, 0, cappedAmount)
		typingTime += 0.25
		$TypeTimer.start()
	else : 
		emit_signal("doneTyping")
