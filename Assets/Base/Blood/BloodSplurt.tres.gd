extends Node2D



func start(amount : float, color : Color, rotateDirection : float) :
	
	global_position = snapped(global_position, Vector2(12, 12))
	
	$Splurt.modulate = color
	$Pools.modulate = color
	$Splurt/SubViewport/Splurt.rotation = rotateDirection
	$Splurt/SubViewport/Splurt.amount_ratio = amount
	$Splurt/SubViewport/Splurt.restart()

func _on_timer_timeout() -> void:
	queue_free()
