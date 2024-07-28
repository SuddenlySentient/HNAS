@icon("res://Assets/UnitIcon.png")
extends CharacterBody2D
class_name Unit

@export var team : String = "Unalligned"
var aggroTarget : Unit
var aggroList : Array[Unit] = []

@export var canBeSeen : bool = true
@export var maxSpeed : int= 200
@export var reflectShots : bool = false
signal hurt(DMG : int)



func _init():
	await ready
	HP = maxHP

var vision : Area2D
func checkVision(ignoreHiding : bool = false):
	var inRange = vision.get_overlapping_bodies()
	var seen : Array = []
	seen.clear()
	for thing in inRange :
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, thing.global_position, 1)
		var result = space_state.intersect_ray(query)
		if result and result.collider != self :
			if result.collider is Unit : 
				if result.collider.canBeSeen or ignoreHiding : seen.append(result.collider)
			else : seen.append(result.collider)
	return seen

# HP, ARM, and stuff related to it
#@export_group("Stats")
@export_range(1, 100, 1, "or_greater") var maxHP : int = 1
var HP : int = maxHP
@export_range(1, 100, 1, "or_greater") var ARM : int = 1

func damage(DMG : int, AP : int, dealer : Unit, source : Node = null) :
	
	var reduction = clampf( float(AP) / float(ARM), 0, 1)
	var DMGDealt = DMG * reduction
	var remainder = fmod(DMGDealt, 1)
	if remainder != 0 :
		DMGDealt = floor(DMGDealt)
		var chance = round((remainder * 100))
		if randi_range(1, 100) < chance : DMGDealt += 1
	
	HP -= DMGDealt
	if source != dealer :
		dealer.indirectDMG(self, DMGDealt)
	if HP <= 0 : 
		dealer.getKill(self)
		die(source.name)
	
	if DMGDealt > 0 : 
		emit_signal("hurt", DMGDealt)
		print(DMGDealt, " DMG, ", round( (float(HP) / float(maxHP) ) * 100), "% HP")
	return DMGDealt

func die(_cause : String) :
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
	var distance = getDistanceTo(map.map_to_local(tileCoord))
	return (searched * searchValue) + (distance * distanceValue)

func getTileToSearch(searchValue : float = -1, distanceValue : float = 1):
	
	var tilesCoords : Array[Vector2i] = map.get_used_cells(0)
	var tileValue : Array = []
	var theOne
	
	for tile in tilesCoords :
		if getTileNavigable(tile) and (trySeeTile(tile) == false) : #this gets rid of walls from the search since walls
			var newEntry = getTileValue(tile, searchValue, distanceValue)
			tileValue.append(newEntry)
			tileValue.sort()
			#tileValue.reverse()
			if newEntry == tileValue[0] : 
				theOne = tile
	
	return theOne

func getDistanceTo(targetPos):
	return global_position.distance_to(targetPos)

func newRandomPos(randDist : int = 1024) : 
	return Vector2(randi_range(-randDist, randDist), randi_range(-randDist, randDist)) + position

func getKill(_who : Unit) :
	pass

func indirectDMG(_who : Unit, _amount : int) :
	pass
