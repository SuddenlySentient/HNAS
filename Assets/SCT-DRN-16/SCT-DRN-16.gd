extends Unit
class_name SCTDRN16



func initUnit() :
	vision = $Rotate/Vision
	#nav = $SUBNavigation

func think(delta) :
	
	scanLight(delta)
	$Rotate.rotation = sin(($LookTimer.time_left / $LookTimer.wait_time) * PI * 2.0) * PI / 8.0


var collisionDistance = 0.0
func scanLight(delta) :
	
	var raycast = $Rotate/RayCast2D
	var newCollisionDistance = raycast.target_position.y
	if raycast.is_colliding() : 
		newCollisionDistance = raycast.global_position.distance_to(raycast.get_collision_point())
	
	collisionDistance = lerp(collisionDistance, newCollisionDistance, delta * 8.0)
	
	$Rotate/Sprite2D/SubViewport.size.y = collisionDistance / 4.0
	$Rotate/Sprite2D.position.y = (collisionDistance / 2.0)
