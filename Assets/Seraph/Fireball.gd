extends Shot

@export var rotationSpeed = 16
var explode = false
var size = 1
var mark = load("res://Assets/Base/explosion_mark.tscn")


func _enter_tree():
	sparks = load("res://Assets/Seraph/seraph_spark.tscn")
	global_position += targetVector * distanceFromShooter
	newSpark()

func _physics_process(delta):
	$CanvasLayer/Sparks.global_position = global_position
	if explode:
		linear_velocity = Vector2.ZERO
		$ExplosionLight.energy = 16 * ($ExplostionTimer.time_left/$ExplostionTimer.wait_time) 
	else :
		size = linear_velocity.length() / 1536.0
		size = 1
		if size < 1 : $Whistle.stop()
		elif $Whistle.playing == false : $Whistle.play()
		$Light.texture_scale = 8 * sqrt(size)
		size = clampf(size, 1, 6)
		$Light.energy = size
		$Sprite.scale = Vector2(size, size)
		$CollisionShape2D.scale = Vector2(size, size)
		$Whistle.pitch_scale = 1 / size
		rotate((linear_velocity.length() / 64) * delta)
		linear_velocity += targetVector * speed
		if is_nan(linear_velocity.length()) : 
			push_error("Fireball Velocity Error")
			queue_free()
			return false
		var rand = 1.0 / size
		targetVector += Vector2(randf_range(-rand, rand), randf_range(-rand, rand)) * delta
		targetVector.normalized()
		if size >= 6 : endShot()

func _on_body_entered(_body):
	var newSparks = sparks.instantiate()
	newSparks.position = global_position
	newSparks.rotation = rotation + PI/2
	$"..".add_child(newSparks)
	newSparks.restart()
	endShot()

func endShot():
	if explode == true : return false
	explode = true
	#print("Exploded")
	createMark()
	$NavigationObstacle2D.avoidance_enabled = false
	$ExplosionLight.enabled = true
	$CollisionShape2D.free()
	$Light.enabled = false
	$Sprite.hide()
	$Impact.play()
	$Explode.play()
	$Whistle.stop()
	$ExplostionTimer.start()
	$Smoke.restart()
	$CanvasLayer/Sparks.emitting = false
	for weakling in $Explosion.get_overlapping_bodies() :
		if weakling is Unit :
			var falloff = sqrt(1.0 - (position.distance_to(weakling.position)/(512 * size)))
			weakling.damage((DMG + size) * falloff, AP, shooter, self)
			var directionTo = global_position.direction_to(weakling.position)
			if weakling != self : weakling.velocity += directionTo * 1024 * falloff
	await $ExplostionTimer.timeout
	queue_free()

func newSpark() :
	var newSparks = sparks.instantiate()
	newSparks.location = global_position
	$"..".add_child(newSparks)

func createMark() :
	var newMark = mark.instantiate()
	newMark.position = global_position
	size = clampf(size, 3, 6)
	newMark.scale = Vector2(size, size) / 1.5
	$"..".add_child(newMark)

func changeColor(_newColor : Color):
	pass
