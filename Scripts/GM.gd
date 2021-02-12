extends Node

const PARTICLE_EMITTING_PULSE_CAP = 50
const SOFT_PULSE_CAP = 200
const HARD_PULSE_CAP = 400

var player
var enemies = []
var pulse_count = 0

func add_enemy(e):
	enemies.append(e)
	
func remove_enemy(e):
	enemies.erase(e)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func heal_player():
	player.health = player.max_health

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
