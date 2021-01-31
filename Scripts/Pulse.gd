extends 'res://Scripts/PulseBase.gd'

var cur_speed
var cur_size
var cur_damage
#var cur_speed
var cur_knockback
var cur_suction
var cur_homing
var cur_gravity

var s_vel
var g_vel = Vector2.ZERO

var lifespan_timer
var retarget_timer
var has_spawned_subpulse = false

var targeted_enemy = null

# Called when the node enters the scene tree for the first time.
func _ready():
	lifespan_timer = 0;
	retarget_timer = 1.0

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
		inherited_vel = p.Player.velocity
		inherited_vel.y /= 4
	
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
	cur_homing = homing.x
	cur_gravity = gravity.x
	
	
	velocity = direction*speed.x
	apply_growth(0)
	

func apply_growth(delta):
	cur_speed += speed.y*delta
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
	
func retarget_homing():
	var min_dist = StatsUtil.HOMING_RANGE*StatsUtil.HOMING_RANGE
	for e in GM.enemies:
		
		var d = (e.global_position - global_position).length_squared()
		#print(d)
		if d < min_dist:
			targeted_enemy = e
			min_dist = d
			
func home_in(delta):
	var to_enemy = global_position.direction_to(targeted_enemy.global_position)
	var angle = acos(direction.dot(to_enemy))
	if angle < 0.01: return
	var slerp_amount = min(deg2rad(cur_homing)*delta / angle, 1)
	
	print("Angle: " + String(angle))
	print("Slerp: " + String(slerp_amount))
	
	direction = direction.slerp(to_enemy, slerp_amount)

func deal_damage():
	return cur_damage

func _process(delta):
	lifespan_timer += delta
	apply_growth(delta)
	
	if cur_homing != 0:
		retarget_timer += delta
		if retarget_timer > 0.5:
			retarget_timer = 0
			retarget_homing()
		if targeted_enemy:
			home_in(delta)
		
	
	#direction = new_drection_after_homing()
	s_vel = direction*cur_speed
	g_vel += Vector2(0, 1)*cur_gravity*delta
	velocity = s_vel + g_vel
	
	position += velocity*delta
	
	if lifespan_timer > lifetime.x*subpulse_delay.x and remaining_pulses > 0 and not has_spawned_subpulse:
		has_spawned_subpulse = true
		spawn_pulse()
		
		if randf() < (1 - pow(1 - BASE_SPLIT_CHANCE, split_chance.x)):
			spawn_pulse()
	
	if lifespan_timer > lifetime.x:	
		queue_free()
	


