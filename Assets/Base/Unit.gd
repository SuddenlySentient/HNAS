@icon("res://Assets/UnitIcon.png")
extends CharacterBody2D
class_name Unit
@export var disabled : bool = false
@export var type = "None"
@export var team : String = "Unalligned"
var aggroTarget : Unit
var aggroList : Array[Unit] = []
@export_range(1, 256, 1, "or_greater") var maxHP : int = 1
var HP : int = maxHP
@export_range(1, 256, 1, "or_greater") var ARM : int = 1
@export var maxSpeed : int= 200
@export var pointsOnDeath : int = 5 
@export_group("Details")
@export var tags : Array[String]
@export var canBeSeen : bool = true
@export var reflectShots : bool = false
@onready var marker = load("res://Assets/Base/hit_mark.tscn")
@onready var curio = load("res://Assets/Base/Curiosity/Curiousity.tscn")
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
var effects : Array[Effect] = [] 
var dead = false
@export var weight : float = ARM / 2.0
@export_subgroup("Curio")
@export var senses : Dictionary = {
	"Sound": 1.0,
	"Smell": 0.75,
	"Magic": 0.125
}
@warning_ignore("unused_signal")
signal sensedSomething(sensedThing : Dictionary)
@warning_ignore("unused_signal")
signal unseenSense(sensedThing : Dictionary)
@export var doMoveNoise : bool = true
@export var moveNoise : float = 2
var moveNoiseCurio : Curiousity
@export_subgroup("Bleeding")
@export var bleeding : bool = false
@export var bloodColor : Color = Color("ff1212")
@export var bleedResistance : float = 0.2
@export var splatResistance : float = 0.75
@onready var splat = load("res://Assets/Base/Blood/BloodSplat.tscn")
@onready var splurt = load("res://Assets/Base/Blood/BloodSplurt.tscn")



func _physics_process(delta) :
	if get_tree().get_frame() == 1 : return false
	if disabled == false : 
		getCurios()
		think(delta)
		if doMoveNoise :
			if moveNoiseCurio == null :
				var cuiroName = type + " Moving"
				moveNoiseCurio = createCurio(cuiroName, 0, moveNoise, self)
				moveNoiseCurio.bindToUnit(self)
			var velo = velocity.length()
			if velo > 0.1 :
				moveNoiseCurio.strength = clamp(velo / maxSpeed, 0.25, 1) * moveNoise
			else :
				moveNoiseCurio.strength = 0

func think(_delta) : pass

func _init():
	await ready
	HP = maxHP
	name = getName()
	initUnit()
	bloodColor = Color.from_hsv(bloodColor.h + 0.5, bloodColor.s, bloodColor.v)

func initUnit() :
	pass

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

var curios : Array = []

func getCurios() :
	
	var curioList : Array[Dictionary] = []
	for x in map.get_children() :
		if x is Curiousity :
			var newCurio = getCurioDic(x)
			curioList.append(newCurio)
	
	var idList = []
	for z in curios :
		idList.append(z["ID"])
	
	for y in curioList :
		
		var dupe = false
		var duped
		
		if idList.has(y["ID"]) :
			dupe = true
			duped = curios[idList.find(y["ID"])]
		
		if dupe :
			var seen = duped["Seen"]
			var index = curios.find(duped)
			curios[index].merge(y, true)
			if seen : curios[index]["Seen"] = true
		else : 
			curios.append(y)
			emit_signal("sensedSomething", y)
		
		if y["Seen"] == false :
			emit_signal("unseenSense", y)
	
	return curios

func getCurioDic(toValue : Curiousity) :
	var sensitivity : float = senses[toValue.curiousityTypes.keys()[toValue.curiousityType]]
	var curioTile = map.local_to_map(toValue.global_position)
	var distanceTo : float = ceil(getDistanceTo(map.map_to_local(curioTile)))
	if distanceTo < 1 : distanceTo = 1
	var seen = false
	
	#print("Beep")
	
	var cuiroStrength : float
	if sensitivity > 0 and toValue.strength > 0 :
		var midStep = pow(((1.0 / 4096.0) * distanceTo) * (1.0 / (toValue.strength / 16.0) ), 1.0 / sensitivity)
		cuiroStrength = ( (midStep + 1.5) / (2 * ((midStep + 1.5) - 1)) ) - 0.5
		cuiroStrength = clamp(cuiroStrength, 0, 1)
		if trySeeTile(curioTile) == false : 
			cuiroStrength = pow(cuiroStrength, 2)
		else :
			var visionArea : CollisionShape2D = vision.get_child(0)
			if distanceTo <= visionArea.shape.radius : seen = true
	else : 
		#print("Whu-oh! 0! : ", sensitivity, " : ", toValue.strength)
		cuiroStrength = 0
	
	if is_nan(cuiroStrength) : 
		print("Whu-oh! NAN!")
	
	var newCurio : Dictionary = {
		"ID" : toValue.ID,
		"Seen" : seen,
		"Name" : toValue.curioName,
		"Type" : toValue.curiousityType,
		"Source" : toValue.source,
		"Strength" : cuiroStrength,
		"Tile" : curioTile
		}
	return newCurio

func createCurio(setCurioName : String, setCuriousityType, setStrength : float, setSource : Unit = null, setDuration : float = -1) :
	var newCurio = curio.instantiate()
	newCurio.createCuriousity(setCurioName, setCuriousityType, setStrength, setSource, setDuration)
	map.add_child(newCurio)
	return newCurio

func bindCurio(boundCurio : Curiousity) :
	boundCurio.bindToUnit(self)
	return boundCurio

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
	
	var hpLost = float(DMGDealt) / float(maxHP)
	
	var bleedAmount = 0.1 * clamp(DMGDealt, 0, maxHP)
	var splurtDirection = -direction
	if hpLost >= bleedResistance :
		if (source == null) == false : splurtDirection = global_position.direction_to(source.global_position)
		bleedSplurt(bleedAmount, splurtDirection)
	
	var splatScale = sqrt(maxHP) / 4.0
	
	HP -= DMGDealt
	
	if source != dealer and dealer != null :
		dealer.indirectDMG(self, DMGDealt)
	if HP <= 0 : 
		if dealer != null : dealer.getKill(self)
		
		if dealer == self : givePoints(pointsOnDeath * 2, "Self Kill")
		elif dealer != null and isFoe(dealer) == false : 
			givePoints(pointsOnDeath * 2, "Team Kill")
		else : givePoints(pointsOnDeath, "Death")
		bleedSplurt(bleedAmount, splurtDirection)
		if splatResistance < 1 :
			bleedSplat(splatScale)
		die(source.name)
	elif hpLost >= splatResistance : 
		bleedSplurt(bleedAmount, splurtDirection)
		bleedSplat(splatScale * hpLost)
	
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

func bleedSplurt(amount : float, splurtDirection : Vector2) :
	var newSplurt = splurt.instantiate()
	map.add_child(newSplurt)
	newSplurt.global_position = global_position
	newSplurt.start(amount, bloodColor, splurtDirection.angle() - PI/2)

func bleedSplat(splatScale : float) :
	var newSplat = splat.instantiate()
	map.add_child(newSplat)
	newSplat.global_position = global_position
	newSplat.start(splatScale, bloodColor)

# Tile Nonsense
@onready var map : TileMapLayer = $".."
var knownTiles : Dictionary = {}
var nav : NavigationAgent2D

func trySeeTile(tileCoord : Vector2i):
	
	if tileCoord == map.local_to_map(global_position) : 
		knownTiles[tileCoord] = Time.get_ticks_msec()
		return true
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, map.map_to_local(tileCoord), 3)
	var result = space_state.intersect_ray(query)
	
	if result :
		#print("can't see ", tileCoord, " last seen ", getLastSearched(tileCoord))
		return false
	else :
		#print("found tile ", tileCoord, " last seen ", getLastSearched(tileCoord))
		knownTiles[tileCoord] = Time.get_ticks_msec()
		return true

func getLastSearched(tileCoord : Vector2i):
	
	var lastSeen = knownTiles.get(tileCoord)
	if lastSeen != null : return Time.get_ticks_msec() - lastSeen
	else :
		knownTiles[tileCoord] = -1
		return -1

func getTileNavigable(tileCoord : Vector2i):
	var data = map.get_cell_tile_data(tileCoord)
	if data == null : return false
	else : return data.get_custom_data("Navigable")

func valueCurio(tileCoord : Vector2i, toValue : Dictionary) :
	var tileDistance = tileCoord.distance_to(toValue["Tile"])
	if tileDistance < 1 : tileDistance = 1
	var value = toValue["Strength"] * (1.0 / tileDistance)
	return value

func getTileValue(tileCoord : Vector2i, searchValue : float = -1, distanceValue : float = 1, curioValue : float = 1) :
	
	var searched = getLastSearched(tileCoord)
	var distance = getDistanceTo(map.map_to_local(tileCoord))
	var curioAmount = 0.0
	for sensedCurio in curios :
		if sensedCurio["Strength"] > 0 and (sensedCurio["Source"] == self) == false :
			curioAmount += valueCurio(tileCoord, sensedCurio)
	var value = (searched * searchValue) + (distance * distanceValue)
	value -= curioValue * curioAmount * 4096
	return value

func isFoe(thing : Unit) :
	if thing != self :
		if thing.team != team : 
			#print(thing.team, " VS ", team)
			return true
		elif team == "Unalligned" : 
			#print(name)
			return true
	return false

const debugSearch = false

func getTileToSearch(searchValue : float = -1, distanceValue : float = 1, curioValue : float = 1):
	
	var myTile = map.local_to_map(global_position)
	var tilesCoords : Array[Vector2i] = map.get_used_cells()
	var tileValue : Array = []
	var theOne = Vector2i.ZERO
	
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
		var newEntry = getTileValue(tile, searchValue, distanceValue, curioValue)
		tileValue.append(newEntry)
		tileValue.sort()
		if newEntry == tileValue[0] : 
			theOne = tile
	
	if debugSearch :
		print("All Tiles : ", allTiles)
		print("Tiles Searched : ", tilesSearched)
		print("Tiles Search Percent : ", round((float(tilesSearched) / float(allTiles)) * 100), "%")
		print("Chose : ", theOne)
	
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
	reason = type + " " + reason
	UI.givePoints(amount, reason, period)

func dealKnockback(amount : float, knockDirection : Vector2) :
	velocity += knockDirection * (amount / weight)
