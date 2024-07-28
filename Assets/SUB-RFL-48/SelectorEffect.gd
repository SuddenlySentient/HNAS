extends Sprite2D

@onready var SUB : SUBRFL48 = $"../.."
@onready var line = $"../Line"
@onready var LeaderSelector = $"../Leader Selector"

var inFrontPos : Vector2 = Vector2.ZERO

func _physics_process(_delta):
	
	if SUB.isLeader == false and SUB.inSquad :
		show()
		line.show()
		LeaderSelector.show()
		
		var length = global_position.distance_to(inFrontPos)/64
		line.scale.y = length
		line.rotation = global_position.angle_to_point(inFrontPos) - PI/2
		LeaderSelector.position = SUB.leader.position
		line.position = SUB.global_position
		$".".position = SUB.global_position
		var hueShift = 1.0 / SUB.leader.followers.size()
		var place : int = SUB.leader.followers.find(SUB)
		var selfColor =  Color.from_hsv(hueShift * place + 0.5, 0.4, 1, 0.4)
		self_modulate = selfColor
		line.self_modulate = selfColor
		var leaderColor =  Color.from_hsv(0, 0, 1, 0.2)
		LeaderSelector.self_modulate = leaderColor
		
	else :
		hide()
		line.hide()
		LeaderSelector.hide()

