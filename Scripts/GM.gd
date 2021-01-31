extends Node

var player
var enemies = []

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
