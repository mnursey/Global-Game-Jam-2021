extends 'res://Scripts/PulseBase.gd'

onready var pulse_sound = $PulseSound

var cur_size
var cur_damage
var cur_speed
var cur_knockback
var cur_suction
var cur_homing
var cur_gravity

var timer
var has_spawned_subpulse = false

# Called when the node enters the scene tree for the first time.
func _ready():
	timer = 0;
	pulse_sound.play()

func inherit_props(p):
	start_position = p.global_position

	distance = p.distance;
	lifetime = p.lifetime
	size = p.size;
	damage = p.damage;
	speed = p.speed;
	scatter = p.scatter
	knockback = p.knockback
	suction = p.suction
	homing = p.homing
	gravity = p.gravity
	remaining_pulses = p.remaining_pulses - 1
	subpulse_delay = p.subpulse_delay
	split_chance = p.split_chance
	
	var inherited_vel = Vector2.ZERO

	if not p.is_AST:
		distance.x += distance.z 
		lifetime.x += lifetime.z 
		size.x += size.z 
		damage.x += damage.z 
		speed.x += speed.z 
		scatter.x += scatter.z
		knockback.x += knockback.z
		suction.x += suction.z 
		homing.x += homing.z 
		gravity.x += gravity.z 
		subpulse_delay.x += subpulse_delay.z
		split_chance.x += split_chance.z
	else:
		pass
		#inherited_vel = p.Player.velocity
		#inherited_vel.y /= 4

	
	inherited_vel = Vector2.ZERO
	
	is_AST = false
	
	direction = p.velocity.normalized().rotated(deg2rad((randf()-0.5)*scatter.x))

	global_position = start_position + distance.x*direction
	
	var init_vel = direction*speed.x
	init_vel += inherited_vel
	cur_speed = init_vel.length();
	direction = init_vel/cur_speed;
	

	cur_size = size.x
	cur_damage = damage.x
	#cur_speed = speed.x
	cur_knockback = knockback.x
	cur_suction = suction.x
	cur_homing  = homing.x
	cur_gravity = gravity.x
	
	
	velocity = direction*speed.x
	apply_growth(0)
	

func apply_growth(delta):
	cur_size = max(cur_size + size.y*delta, 0.1)
	cur_damage = max(cur_damage + damage.y*delta, 1)
	#cur_speed += speed.y*delta
	cur_knockback += knockback.y*delta
	cur_suction += suction.y*delta
	cur_homing  += homing.y*delta
	cur_gravity += gravity.y*delta
	
	scale = Vector2(cur_size, cur_size)
	var hue = 0.6 - min(pow(cur_damage/DAMAGE_MAX, 0.7), 1)*0.6
	modulate = Color.from_hsv(hue, 1, 1)

func deal_damage():
	return cur_damage

func _process(delta):

	timer += delta
	apply_growth(delta)
	
	#direction = new_drection_after_homing()
	velocity += direction*speed.y*delta
	velocity += Vector2(0, 1)*cur_gravity*delta
	position += velocity*delta
	
	if timer > lifetime.x*subpulse_delay.x and remaining_pulses > 0 and not has_spawned_subpulse:
		has_spawned_subpulse = true
		spawn_pulse()
		
		
		if randf() < (1 - pow(1 - BASE_SPLIT_CHANCE, split_chance.x)):
			spawn_pulse()
	
	if timer > lifetime.x:	
		queue_free()
	



func _on_Pulse_body_entered(body):
	if !body.is_in_group("Player") and !body.is_in_group("Enemy"):
		cur_speed = Vector2(0.001, .001)
		velocity = Vector2(0.001,0.001)
