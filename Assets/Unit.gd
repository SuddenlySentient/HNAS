@icon("res://Assets/UnitIcon.png")
extends CharacterBody2D
class_name Unit

@export var team : String = "Unalligned"

var vision : Area2D
func checkVision():
	var inRange = vision.get_overlapping_bodies()
	var seen : Array = []
	seen.clear()
	for thing in inRange :
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, thing.global_position, 1)
		var result = space_state.intersect_ray(query)
		if result and result.collider != self :
			seen.append(result.collider)
	return seen

# HP, ARM, and stuff related to it
#@export_group("Stats")
@export_range(1, 100, 1, "or_greater") var maxHP : int = 1
var HP : int = maxHP
@export_range(1, 100, 1, "or_greater") var ARM : int = 1

func damage(DMG : int, AP : int) :
	
	var reduction = clamp(ARM - AP, 0, ARM)
	var DMGDealt = DMG - reduction
	HP -= DMGDealt
	
	#print(DMGDealt)
	
	if HP <= 0 : die()

func die() :
	queue_free()

# Tile Nonsense
@onready var map : TileMap = $"../TileMap"
var lastSeenTile : Dictionary = {}
var nav : NavigationAgent2D

func trySeeTile(tileCoord : Vector2i):
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, map.map_to_local(tileCoord), 1)
	var result = space_state.intersect_ray(query)
	
	if result :
		#print("can't see ", tileCoord, " last seen ", getLastSearched(tileCoord))
		return false
	else :
		#print("found tile ", tileCoord, " last seen ", getLastSearched(tileCoord))
		lastSeenTile[tileCoord] = Time.get_ticks_msec()
		return true

func getLastSearched(tileCoord : Vector2i):
	
	var lastSeen = lastSeenTile.get(tileCoord)
	if lastSeen != null : return Time.get_ticks_msec() - lastSeen
	else :
		lastSeenTile[tileCoord] = -1
		return -1

func getTileNavigable(tileCoord : Vector2i):
	
	var data = map.get_cell_tile_data(0, tileCoord)
	return data.get_custom_data("Navigable")

func getTileValue(tileCoord : Vector2i, searchValue : float = -1, distanceValue : float = 1):
	
	var searched = getLastSearched(tileCoord)
	var distance = getNavDistanceTo(map.map_to_local(tileCoord))
	return (searched * searchValue) + (distance * distanceValue)

func getTileToSearch():
	
	var tilesCoords : Array[Vector2i] = map.get_used_cells(0)
	var tileValue : Array = []
	var theOne
	
	for tile in tilesCoords :
		if getTileNavigable(tile) and (trySeeTile(tile) == false) : #this gets rid of walls from the search since walls
			var newEntry = getTileValue(tile)
			tileValue.append(newEntry)
			tileValue.sort()
			#tileValue.reverse()
			if newEntry == tileValue[0] : 
				theOne = tile
	
	return theOne

func getNavDistanceTo(targetPos):
	var pastNav = nav.target_position
	nav.target_position = targetPos
	var value = nav.distance_to_target()
	nav.target_position = pastNav
	return value

func newRandomPos(randDist : int = 1024) : 
	return Vector2(randi_range(-randDist, randDist), randi_range(-randDist, randDist)) + position

