extends Node2D

const LN5 = 1.609
const animations = ["Cog", "Coil", "Piston", "Spring"]
const sizes = [0.6, 1, 2, 3, 5, 7, 10, 13, 16]
onready var anim = $AnimationPlayer

var value = 0
var velocity = Vector2.ZERO
var decel
var timer = 0
var suctioned = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func init(v, pos):
	value = v
	global_position = pos
	var s = sizes[int(log(value)/LN5)]
	scale = Vector2(s, s)
	if s > 1: get_node("Light2D").visible = true
	velocity = 100*Vector2(randf()*2-1, randf()*2-1)
	decel = velocity/(20 + randf()*20)
	anim.play(animations[randi()%4])
	
func _physics_process(delta):
	if value == 0: return
	
	global_position += velocity*delta
	timer += delta
	
	var to_player = GM.player.global_position - global_position
	if not suctioned:
		if sign(velocity.x) == sign(decel.x):
			velocity -= decel
		else:
			velocity = Vector2.ZERO
		
		if timer > 0.5 and abs(to_player.x) < 50 and abs(to_player.y) < 50:
			suctioned = true
	else:
		var dist_to_player = to_player.length()
		if dist_to_player < 10:
			GM.player.give_scrap(value)
			queue_free()
			
		velocity = 150*to_player/dist_to_player
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
