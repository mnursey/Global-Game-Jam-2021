extends 'res://Scripts/PulseBase.gd'

onready var raycast = $RayCast2D
onready var pulse_sound = $PulseSound

var cur_size
var cur_damage
var cur_speed
var cur_knockback
var cur_suction
var cur_homing
var cur_gravity

var s_vel
var g_vel = Vector2.ZERO

var targeted_enemy = null
var retarget_timer = 1

var timer
var has_spawned_subpulse = false
var halted

# Called when the node enters the scene tree for the first time.
func _ready():
	timer = 0;
	halted = false
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
	
	is_AST = false
	
	direction = p.velocity.normalized().rotated(deg2rad((randf()-0.5)*scatter.x))
	global_position = start_position + distance.x*direction

	cur_size = size.x
	cur_damage = damage.x
	cur_speed = speed.x
	cur_knockback = knockback.x
	cur_suction = suction.x
	cur_homing  = homing.x
	cur_gravity = gravity.x
	
	s_vel = direction*speed.x
	apply_growth(0)
	

func apply_growth(delta):
	cur_size = max(cur_size + size.y*delta, 0.1)
	cur_damage = max(cur_damage + damage.y*delta, 1)
	cur_speed += speed.y*delta
	cur_knockback += knockback.y*delta
	cur_suction += suction.y*delta
	cur_homing  += homing.y*delta
	cur_gravity += gravity.y*delta
	
	scale = Vector2(cur_size, cur_size)
	var hue = 0.6 - min(pow(cur_damage/DAMAGE_MAX, 0.7), 1)*0.6
	modulate = Color.from_hsv(hue, 1, 1)
	
func retarget_homing():
	var min_dist = StatsUtil.HOMING_RANGE*StatsUtil.HOMING_RANGE
	for enemy in GM.enemies:
		if enemy:
			var sqr_dist = (enemy.global_position - global_position).length_squared()
			if sqr_dist < min_dist:
				min_dist = sqr_dist
				targeted_enemy = enemy
			
func home_in(delta):
	var to_enemy = (targeted_enemy.global_position - global_position).normalized()
	var angle = abs(direction.angle_to(to_enemy))
	if(angle > 0.01):
		var slerp_amount = deg2rad(cur_homing)*delta/angle
		direction = direction.slerp(to_enemy, slerp_amount)
		
func succ(delta):
	var succ_range = pow(cur_suction, 2)
	for enemy in GM.enemies:
		if enemy:
			var to_enemy = enemy.global_position - global_position
			var sqr_dist = max(to_enemy.length_squared(), StatsUtil.MIN_SUCC_RANGE)
			if sqr_dist < succ_range:
				enemy.velocity -= StatsUtil.MIN_SUCC_RANGE*to_enemy/sqr_dist*cur_suction*delta

func _physics_process(delta):
	timer += delta
	apply_growth(delta)
	
	if cur_suction != 0:
		succ(delta);
	
	if cur_homing != 0:
		retarget_timer += delta
		if retarget_timer > 0.2:
			retarget_timer = 0
			retarget_homing()
		if targeted_enemy:
			home_in(delta)
			
	s_vel = cur_speed*direction
	g_vel += Vector2(0, 1)*cur_gravity*delta
	velocity = s_vel + g_vel
	var displacement = velocity*delta
	
	raycast.force_raycast_update()
	raycast.cast_to = displacement
	if raycast.is_colliding():
		timer = INF
		global_position = raycast.get_collision_point() + 0.1*(raycast.get_collision_point() - global_position)
		velocity -= 2*velocity.dot(raycast.get_collision_normal())*raycast.get_collision_normal()
		print(raycast.get_collider())
	else:
		position += displacement
		
	if timer > lifetime.x*subpulse_delay.x and remaining_pulses > 0 and not has_spawned_subpulse:
		has_spawned_subpulse = true
		spawn_pulse()
		
		if randf() < (1 - pow(1 - BASE_SPLIT_CHANCE, split_chance.x)):
			spawn_pulse()
	
	if timer > lifetime.x:	
		queue_free()
	

func _on_Pulse_body_entered(body):
	if body.is_in_group("Enemy"):
		body.get_hit(self)
	elif !body.is_in_group("Player"):
		pass
		#cur_speed = 0
		#velocity = direction*0.01
		
func deal_damage(target):
	target.get_hit(self)
