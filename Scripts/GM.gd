extends Node

const PARTICLE_EMITTING_PULSE_CAP = 50
const SOFT_PULSE_CAP = 200
const HARD_PULSE_CAP = 400
const LN5 = 1.609

var player
var active_room
var rooms_cleared = 0
var enemies = []
var pulse_count = 0

func restart():
	rooms_cleared = 0
	get_tree().reload_current_scene()

func set_active_room(room_controller):
	active_room = room_controller
	enemies = active_room.enemies

static func spawn_scrap(amount, pos, parent):
	var Scrap = load("res://Scenes/Scrap.tscn").instance()
	var v = 1
	while amount > 0:
		if amount < 5:
			v = 1
		else:
			v = int(pow(5, randi() % int(1 + log(amount)/LN5)))
			
		amount -= v
		var new_scrap = Scrap.duplicate()
		parent.add_child(new_scrap)
		new_scrap.init(v, pos)
		
static func spawn_explosion(radius, damage, target, pos, parent, num_frags = 0, frag_angle = 0, frag_speed = 0, frag_spread = 0, frag_damage = 0, frag_radius = 0, frag_lifetime = 0):
	var explosion = load("res://Scenes/Explosion.tscn").instance().duplicate()
	parent.add_child(explosion)
	explosion.global_position = pos
	explosion.scale = Vector2(radius/13.0, radius/15.0)
	explosion.init(radius, damage, target)
	
	if num_frags > 0:
		var Frag = load("res://Scenes/ExplosionFragment.tscn").instance()
		
		var delta_angle = 0
		var angle = frag_angle
		if num_frags > 1:
			delta_angle = deg2rad(frag_spread/(num_frags-1))
			angle = frag_angle - deg2rad(frag_spread/2)
			
		for i in range(num_frags):
			var frag = Frag.duplicate()
			parent.add_child(frag)
			frag.global_position = pos
			
			var fudged_angle = angle + deg2rad(20*randf() - 10)
			var dir = Vector2(cos(fudged_angle), sin(fudged_angle)) 
			frag.init(pos, dir*frag_speed, frag_radius, frag_damage, frag_lifetime)
			
			angle += delta_angle

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
