extends AudioStreamPlayer2D

var hurtAudio : Array[AudioStream] = [
load("res://Assets/SUB-RFL-48/Sound/Voice/Hurt1.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/Hurt2.wav"),
load("res://Assets/SUB-RFL-48/Sound/Voice/Hurt3.wav")
]

var randPitch : float

func tryVoice():
	if randPitch == null : 
		randPitch = randf_range(0.75, 1.5)
		pitch_scale = randPitch
	

func _on_subrfl_48000_hurt(_DMG):
	if randPitch == null : 
		randPitch = randf_range(0.5, 1.5)
		pitch_scale = randPitch
	stream = hurtAudio.pick_random()
	play()
