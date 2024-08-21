@icon("res://Assets/UnitIcon.png")
extends CharacterBody2D
class_name Unit
@export var type = "None"
@export var team : String = "Unalligned"
var aggroTarget : Unit
var aggroList : Array[Unit] = []
@export var tags : Array[String]
@export var canBeSeen : bool = true
@export var maxSpeed : int= 200
@export var reflectShots : bool = false
@onready var marker = load("res://Assets/Base/hit_mark.tscn")
@warning_ignore("unused_signal")
signal hurt(DMG : int, DMGtype : String)
@export var nameList : Array[StringName] = [
	"Blank",
	"Null",
	"Nunya",
	"Nobody",
	"Unnamed",
	"Something",
	"Someone",
	"A Name",
	"Mother failed to name me, she died",
	"Had a name once",
	"Insert Name",
	"Bartholomew",
	]
var direction : Vector2 = Vector2.DOWN
@export var pointsOnDeath : int = 5 
var effects : Array[Effect] = [] 
var dead = false



func _init():
	await ready
	HP = maxHP
	name = getName()

func getName() :
	var newName = nameList.pick_random()
	var everythingInMap = map.get_children()
	for thing in everythingInMap :
		if thing.name == newName : newName = getName()
	return newName

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

@export_range(1, 256, 1, "or_greater") var maxHP : int = 1
var HP : int = maxHP
@export_range(1, 256, 1, "or_greater") var ARM : int = 1

func damage(DMG : int, AP : int, dealer, DMGtype : String, source : Node = null) :
	
	if dead : return 0
	
	var reduction = clampf( float(AP) / float(ARM), 0, 1)
	var DMGDealt = DMG * reduction
	var remainder = fmod(DMGDealt, 1)
	if remainder != 0 :
		DMGDealt = floor(DMGDealt)
		var chance = round((remainder * 100))
		if randi_range(1, 100) < chance : DMGDealt += 1
	
	DMGDealt = adjustDMG(DMGDealt, dealer, DMGtype, source)
	
	HP -= DMGDealt
	if source != dealer and dealer != null :
		dealer.indirectDMG(self, DMGDealt)
	if HP <= 0 : 
		if dealer != null : dealer.getKill(self)
		if dealer == self : givePoints(pointsOnDeath * 2, "Self Kill")
		elif dealer != null and isFoe(dealer) == false : 
			givePoints(pointsOnDeath * 2, "Team Kill")
		elif dealer != null and dealer.type == type : 
			@warning_ignore("narrowing_conversion")
			givePoints(pointsOnDeath * 1.5, "Infighting")
		else : givePoints(pointsOnDeath, "Kill")
		die(source.name)
	
	if DMGDealt > 0 : 
		emit_signal("hurt", DMGDealt, DMGtype)
		var markSize = sqrt(float(DMGDealt) / 2.0)
		hitmarker(str(DMGDealt), markSize)
		#print(name, " : ", DMGDealt, " DMG, ", round( (float(HP) / float(maxHP) ) * 100), "% HP")
	elif DMGDealt == 0 : hitmarker("0", 1, Color.from_hsv(0.6, 0.8, 1, 1))
	return DMGDealt

func adjustDMG(DMGDealt : int, _dealer, _DMGtype : String, _source : Node = null) :
	return DMGDealt

func heal(amount : int) :
	HP += amount
	if HP > maxHP : 
		HP = maxHP
	else : 
		var markSize = sqrt(float(amount)) * 2
		hitmarker(str(amount), markSize, Color.from_hsv(0.3, 0.8, 1, 1))

func die(_cause : String) :
	dead = true
	queue_free()

# Tile Nonsense
@onready var map : TileMapLayer = $".."
var lastSeenTile : Dictionary = {}
var nav : NavigationAgent2D

func trySeeTile(tileCoord : Vector2i):
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, map.map_to_local(tileCoord), 3)
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
	var data = map.get_cell_tile_data(tileCoord)
	if data == null : return false
	else : return data.get_custom_data("Navigable")

func getTileValue(tileCoord : Vector2i, searchValue : float = -1, distanceValue : float = 1):
	
	var searched = getLastSearched(tileCoord)
	var distance = getDistanceTo(map.map_to_local(tileCoord))
	return (searched * searchValue) + (distance * distanceValue)

func isFoe(thing : Unit) :
	if thing != self :
		if thing.team != team : 
			#print(thing.team, " VS ", team)
			return true
		elif team == "Unalligned" : 
			#print(name)
			return true
	return false

func getTileToSearch(searchValue : float = -1, distanceValue : float = 1):
	
	var myTile = map.local_to_map(global_position)
	var tilesCoords : Array[Vector2i] = map.get_used_cells()
	var tileValue : Array = []
	var theOne = Vector2.ZERO
	
	var maxSearchDistance = 2048
	@warning_ignore("unused_variable")
	var tilesSearched = 0
	@warning_ignore("unused_variable")
	var allTiles = 0
	
	for tile in tilesCoords :
		allTiles += 1
	
	var newTileCoords : Array[Vector2i] = []
	while newTileCoords.size() == 0 :
		for tile in tilesCoords :
			var distanceToTile = getDistanceTo(map.map_to_local(tile))
			if distanceToTile <= maxSearchDistance and tile != myTile and getTileNavigable(tile) and trySeeTile(tile) == false : 
				newTileCoords.append(tile)
		if newTileCoords.size() == 0 : 
			maxSearchDistance += 1024
			print("Increasing Search Size")
	
	tilesCoords = newTileCoords
	
	for tile in tilesCoords :
		tilesSearched += 1
		var newEntry = getTileValue(tile, searchValue, distanceValue)
		tileValue.append(newEntry)
		tileValue.sort()
		#tileValue.reverse()
		if newEntry == tileValue[0] : 
			theOne = tile
	
	#print("All Tiles : ", allTiles)
	#print("Tiles Searched : ", tilesSearched)
	#print("Tiles Search Percent : ", round((float(tilesSearched) / float(allTiles)) * 100), "%")
	
	return theOne

func getDistanceTo(targetPos):
	return global_position.distance_to(targetPos)

func newRandomPos(randDist : int = 1024) : 
	return Vector2(randi_range(-randDist, randDist), randi_range(-randDist, randDist)) + position

func getKill(_who : Unit) :
	pass

func indirectDMG(_who : Unit, _amount : int) :
	pass

func hitmarker(text : String = "NULL", size : float = 1, color : Color = Color.from_hsv(0, 0.8, 1, 1)) :
	var mark = marker.instantiate()
	mark.hide()
	mark.initalPos = global_position
	mark.vector += velocity
	mark.text = text
	mark.color = color
	mark.size = size
	map.add_child(mark)
	mark.show()

func canSeeTarget(testPosition : Vector2 = global_position, targPosition : Vector2 = aggroTarget.global_position) :
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(targPosition, testPosition, 3)
	var result = space_state.intersect_ray(query)
	
	if result  :
		return false
	else :
		return true

func enemiesInRange(areas : Array[Area2D]) :
	for area in areas :
		for thing in area.get_overlapping_bodies() :
			if thing is Unit and isFoe(thing) : 
				return true
	return false

@onready var UI = $"../../UI"

func givePoints(amount : int, reason : String, period : float = 1) :
	reason += " : " + name
	UI.givePoints(amount, reason, period)

@export var weight : float = ARM / 2.0

func dealKnockback(amount : float, knockDirection : Vector2) :
	velocity += knockDirection * (amount / weight)
