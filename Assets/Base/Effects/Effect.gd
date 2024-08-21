extends Node
class_name Effect

@export var type : String = "Null"
@export var duration : float = -1
@export var level : float = 1
var affected : Unit
var dealer : Unit
@onready var timer : Timer = $Timer


func _enter_tree() -> void :
	await ready
	initEffect()
	if duration != -1 :
		timer.start(duration)

func _physics_process(delta) -> void :
	doEffect(delta)

func apply(emitter : Unit, target : Unit, appLevel : float = level, appDur : float = duration) :
	dealer = emitter
	duration = appDur
	level = appLevel
	affected = target
	for effect in target.effects :
		if effect.type == type :
			var preApplied = target.effects[target.effects.find(self)]
			preApplied.increment(self)
			cease()
			return false
	target.effects.append(self)
	target.add_child(self)

func increment(effect : Effect) :
	if level < effect.level : level = effect.level
	else : level += effect.level / level

func initEffect() :
	pass

func doEffect(_delta) :
	pass

func cease() :
	affected.effects.erase(self)
	queue_free()

func _on_timer_timeout() -> void:
	cease()
