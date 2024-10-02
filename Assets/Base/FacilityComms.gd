extends Node
class_name FacilityComms
static var globalKnownTiles : Dictionary = {}
var unitParent : Unit


func _ready() -> void:
	unitParent = $".."

func _physics_process(_delta: float) -> void:
	for tile in unitParent.knownTiles :
		
		var lastSeen = unitParent.knownTiles[tile]
		if globalKnownTiles.get(tile) == null : 
			globalKnownTiles[tile] = lastSeen
			#print(tile, " : ",globalKnownTiles[tile])
		else :
			var globalTileLastSeen = globalKnownTiles[tile]
			if lastSeen > globalTileLastSeen :
				globalKnownTiles[tile] = lastSeen
				#print(tile, " : ",globalKnownTiles[tile])
	unitParent.knownTiles = globalKnownTiles.duplicate()
