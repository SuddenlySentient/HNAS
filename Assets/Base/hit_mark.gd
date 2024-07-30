extends CanvasLayer

@onready var mark = $Mark
@onready var timer = $Timer
var initalPos : Vector2
var size : float = 1
var text : String = "ERROR"
var wait : float = 1
var color : Color = Color.from_hsv(0, 0.8, 1, 1)
var vector : Vector2 = Vector2.UP * 128
var offsetPos : Vector2 = Vector2(-512, -128)

func _enter_tree() :
	await ready
	mark.text = text
	mark.modulate = color
	mark.scale = Vector2(1, 1) * size
	vector = vector / size
	timer.start(wait)
	initalPos += Vector2(randf_range(-64, 64), randf_range(-64, 64))

func _process(delta):
	var completion = timer.time_left/timer.wait_time
	mark.position = lerp(initalPos + vector + offsetPos, initalPos + offsetPos, completion * completion)
	var compe = sqrt(completion)
	mark.scale = Vector2(1, 1) * size * compe

func _on_timer_timeout():
	queue_free()
