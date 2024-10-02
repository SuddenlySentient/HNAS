extends Node2D

var spillScale
var initalScale
var initalColor = Color("0dffd7")
var finalColor = Color("12ffd7")

@onready var splatA = $SplatA
@onready var splatB = $SplatA/SubViewport/SplatB

func start(splatScale : float, color : Color) :
	
	
	initalColor = Color.from_hsv(color.h + 0.03, color.s + 0.01, color.v, color.a)
	finalColor = color
	splatA.modulate = initalColor
	
	splatB.rotation = randf_range(0, 2 * PI)
	splatB.frame = randi_range(0, 2)
	
	initalScale = Vector2(splatScale, splatScale) 
	spillScale = Vector2(splatScale, splatScale) * 1.5
	$Timer.start(randf_range(512, 1024))

func _process(delta):
	global_position = snapped(global_position, Vector2(12, 12))
	if splatB.scale.x >= initalScale.x :
		if $Spill.wait_time == 1 : $Spill.start(randf_range(20, 30))
		var spillCompletion = 1 - ($Spill.time_left/$Spill.wait_time)
		splatB.scale = lerp(initalScale, spillScale, spillCompletion)
		var opacity = ($Timer.time_left / $Timer.wait_time)
		opacity = sin(opacity * (PI / 2.0))
		finalColor.a = opacity
		splatA.modulate = lerp(initalColor, finalColor, spillCompletion)
	else :
		splatB.scale = lerp(splatB.scale, initalScale, delta)

func _on_timer_timeout():
	queue_free()
