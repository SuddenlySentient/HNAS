extends PointLight2D

const flickerness = 1
const minEnergy = 1.25
const maxEnergy = 1.75

func _process(delta):
	var flick = energy + randf_range(-flickerness * delta, flickerness * delta)
	flick =  clamp(flick, minEnergy, maxEnergy)
	energy = flick
	scale = Vector2(flick/4 + 1.125, flick/4 + 1.125)
