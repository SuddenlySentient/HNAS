extends Sprite2D

@onready var SUB : SUBRFL48 = $".."
@onready var line = $"../Line"
@onready var LeaderSelector = $"../Leader Selector"

var inFrontPos : Vector2 = Vector2.ZERO

func _physics_process(delta):
	
	if SUB.isLeader == false and SUB.inSquad :
		show()
		line.show()
		LeaderSelector.show()
		
		var length = global_position.distance_to(inFrontPos)/64
		line.scale.y = length
		line.rotation = global_position.angle_to_point(inFrontPos) - PI/2
		LeaderSelector.position = SUB.leader.position #+ Vector2(
			#randf_range(-SUB.leader.followers.size(), SUB.leader.followers.size()), 
			#randf_range(-SUB.leader.followers.size(), SUB.leader.followers.size())
			#)
		var hueShift = 1.0 / SUB.leader.followers.size()
		var place : int = SUB.leader.followers.find(SUB)
		var selfColor =  Color.from_hsv(hueShift * place, 0.4, 4, 0.8)
		self_modulate = selfColor
		var lineColor =  Color.from_hsv(hueShift * place, 0.6, 4, 0.4)
		line.self_modulate = lineColor
		var leaderColor =  Color.from_hsv(hueShift * place, 0, 4, 0.8)
		LeaderSelector.self_modulate = leaderColor
		
	else :
		hide()
		line.hide()
		LeaderSelector.hide()

