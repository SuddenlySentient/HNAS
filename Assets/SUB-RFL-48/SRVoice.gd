extends AudioStreamPlayer2D

var randPitch : float = 0

@export var aloneChance : int = 4096
@export var searchChance : int = 4096
@export var foundEnemiesChance : int = 4
@export var outnumberChance : int = 4096
@export var injuredChance : int = 4096
@export var uhOhChance : int = 1
@export var getKillChance : int = 4
@export var noDMGChance : int = 1024
@export var dealDMGChance : int = 1024
@onready var SR : SUBRFL48 = $".."

var previousLine = ""

func tryVoice(voiceLine : String):
	
	if randPitch == 0 : 
		randPitch = randf_range(0.875, 1.125)
		pitch_scale = randPitch
	
	if playing == false and voiceLine != previousLine :
		
		match voiceLine :
			"Hurt" : 
				#print("Hurt")
				stream = hurtAudio.pick_random()
				previousLine = voiceLine
				play()
			"Alone" :
				if randi_range(1, aloneChance) == 1 :
					#print("Alone")
					stream = aloneAudio.pick_random()
					previousLine = voiceLine
					play()
			"Search" :
				if randi_range(1, searchChance) == 1 :
					#print("Searching")
					stream = searchAudio.pick_random()
					previousLine = voiceLine
					play()
			"FoundEnemies" :
				if randi_range(1, foundEnemiesChance) == 1 and SR.inSquad :
					#print("FoundEnemies")
					stream = foundEnemiesAudio.pick_random()
					previousLine = voiceLine
					play()
			"Outnumber" :
				if randi_range(1, outnumberChance) == 1 and SR.inSquad :
					#print("Outnumber")
					stream = outnumberAudio
					previousLine = voiceLine
					play()
			"Injured" :
				if randi_range(1, injuredChance) == 1 and SR.inSquad :
					#print("Injured")
					stream = injuredAudio
					previousLine = voiceLine
					play()
			"UhOh" :
				if randi_range(1, uhOhChance) == 1 :
					#print("UhOh")
					stream = uhOhAudio
					previousLine = voiceLine
					play()
			"GetKill" :
				if randi_range(1, getKillChance) == 1 and SR.inSquad :
					#print("GetKil")
					stream = getKillAudio.pick_random()
					previousLine = voiceLine
					play()
			"NoDMG" :
				if randi_range(1, noDMGChance) == 1 and SR.inSquad :
					#print("NoDMG")
					stream = noDMGDealtAudio.pick_random()
					previousLine = voiceLine
					play()
			"DealDMG" :
				if randi_range(1, dealDMGChance) == 1 and SR.inSquad :
					#print("DealDMG")
					stream = dealDMGAudio
					previousLine = voiceLine
					play()
			_ :
				print(self.name, " : Recieved Invalid Voiceline ''", voiceLine, "''" )

var hurtAudio : Array[AudioStream] = [
load("res://Assets/SUB-RFL-48/Sound/Voice/Hurt1.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/Hurt2.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/Hurt3.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/ImHurt.wav"),
]
var aloneAudio : Array[AudioStream] = [
load("res://Assets/SUB-RFL-48/Sound/Voice/Hello.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/SentAllAlone.wav"),
]
var searchAudio : Array[AudioStream] = [
load("res://Assets/SUB-RFL-48/Sound/Voice/FindAnything.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/Scanning.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/SearchAndDestroy.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/DontSeeAnyEnemies.wav"),
]
var foundEnemiesAudio : Array[AudioStream] = [
load("res://Assets/SUB-RFL-48/Sound/Voice/HEY.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/EnemySpotted.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/WeGotHostiles.wav"),
]
var getKillAudio : Array[AudioStream] = [
load("res://Assets/SUB-RFL-48/Sound/Voice/TaggedAndBagged.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/SearchAndDestroy.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/AllTargetsEliminated.wav"),
]
var noDMGDealtAudio : Array[AudioStream] = [
load("res://Assets/SUB-RFL-48/Sound/Voice/OurWeaponsAreUseless.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/NeedBackup.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/NeedSupport.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/MaydayMayday.wav"),
]
var outnumberAudio : AudioStream = load("res://Assets/SUB-RFL-48/Sound/Voice/TargetsAreOutnumbered.wav")
var injuredAudio :AudioStream = load("res://Assets/SUB-RFL-48/Sound/Voice/ImLow.wav")
var uhOhAudio :AudioStream = load("res://Assets/SUB-RFL-48/Sound/Voice/UhOh.wav")
var dealDMGAudio :AudioStream = load("res://Assets/SUB-RFL-48/Sound/Voice/Tagged.wav")

func _on_subrfl_48_hurt(_DMG):
	tryVoice("Hurt")

func speechBubble(speechText : String) :
	pass
