extends 'res://Scripts/PulseBase.gd'

onready var raycast = $RayCast2D
onready var pulse_sound = $PulseSound
onready var particles = $Particles2D
onready var sprite = $AnimatedSprite
var light

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
var enemy_recollision_timer = 0
var has_spawned_subpulse = false
var dead = false

var mute = false
var disable_particles = false
var check_wall_collision = false
var colliding_enemies = []


var space_state
var collision_query



# Called when the node enters the scene tree for the first time.
func _ready():
	timer = 0;
	if disable_particles: particles.emitting = false
	if not mute: 
		pulse_sound.pitch_scale += 0.5*(randf() - 0.2)
		pulse_sound.play()
		
	space_state = get_world_2d().direct_space_state
	collision_query = Physics2DShapeQueryParameters.new()
	collision_query.set_transform(transform)
	collision_query.set_shape(get_node("CollisionShape2D").shape)
	collision_query.collision_layer = 0b1000001
	collision_query.collide_with_areas = true

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
		mute = p.mute
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
	
	direction = p.velocity.normalized().rotated(deg2rad((randf()-0.5)*max(scatter.x, 0)))
	global_position = start_position + distance.x*direction

	cur_size = size.x
	cur_damage = damage.x
	cur_speed = speed.x
	cur_knockback = knockback.x
	cur_suction = suction.x
	cur_homing  = homing.x
	cur_gravity = gravity.x
	
	s_vel = direction*speed.x
	light = get_node('Light2D')
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
	var color = Color.from_hsv(hue, 1, 1)
	modulate = color
	light.color = color
	
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
	var succ_range = 22000
	for enemy in GM.enemies:
		if enemy:
			var to_enemy = enemy.global_position - global_position
			var sqr_dist = max(to_enemy.length_squared(), StatsUtil.MIN_SUCC_RANGE)
			if sqr_dist < succ_range:
				enemy.apply_suction(-StatsUtil.MIN_SUCC_RANGE*to_enemy/sqr_dist*cur_suction*delta)

func _physics_process(delta):
	timer += delta
	
	if not dead:
		var to_player = GM.player.global_position - global_position
		if to_player.x > 400 or to_player.y > 300:
			remaining_pulses = 0
			timer = INF
			
		if check_wall_collision:
			if len(space_state.intersect_point(global_position, 1, [], 0b0001)) > 0:
				distance /= 2
				speed /= 2
				timer = INF
		
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
		
		#raycast.force_raycast_update()
		#raycast.cast_to = displacement
		#if raycast.is_colliding():
		#	timer = INF
		#	global_position = raycast.get_collision_point() + 0.1*(raycast.get_collision_point() - global_position)
		#	velocity -= 2*velocity.dot(raycast.get_collision_normal())*raycast.get_collision_normal()
		#else:
		#	

		collision_query.set_transform(transform)
		collision_query.motion = displacement
		
		var high_speed = displacement.length_squared() > 400*cur_size*cur_size
		if high_speed:
			var total_dist = displacement.length()
			var direction = displacement/total_dist
			var dist_checked = 0
			var pulse_width = 20*cur_size
			var query_dist = total_dist
			
			
			if enemy_recollision_timer < 0:
				enemy_recollision_timer = 0.2
				colliding_enemies = []
			else:
				enemy_recollision_timer -= delta
		
			while dist_checked < total_dist:
				var dist_checked_this_loop = pulse_width
				
				collision_query.exclude = colliding_enemies
				var cols = space_state.intersect_shape(collision_query)
				if not cols.empty():
					for c in cols:
						if c.collider.is_in_group("Enemy"):
							c.collider.get_hit(self)
							colliding_enemies.append(c.rid)
						elif not c.collider.is_in_group("Player"):
							check_wall_collision = true
							collision_query.collision_layer = 0b1000000
						
				else:
					var col_dist = space_state.cast_motion(collision_query)
					var d = 0 if col_dist.empty() else col_dist[0]
					if d < 1:
						dist_checked_this_loop += d*query_dist
						
					else:
						#colliding_enemies = []
						dist_checked = total_dist
					
				dist_checked += dist_checked_this_loop
				query_dist -= dist_checked_this_loop
				collision_query.transform.origin += direction*dist_checked_this_loop
				collision_query.motion = direction*query_dist
				
		else: #Low-speed check
			collision_query.exclude = []
			
			var d = 0
			var col_dists = space_state.cast_motion(collision_query)
			if not col_dists.empty(): d = col_dists[1]
				
			if d < 1:
				collision_query.transform.origin += displacement*d
				collision_query.exclude = colliding_enemies
				var cols = space_state.intersect_shape(collision_query)
				for c in cols:
					if c.collider.is_in_group("Enemy"):
						c.collider.get_hit(self)
						colliding_enemies.append(c.rid)
					elif not c.collider.is_in_group("Player"):
						check_wall_collision = true
						collision_query.collision_layer = 0b1000000
			else:
				colliding_enemies = []
				
		position += displacement
			
		if timer > lifetime.x*subpulse_delay.x and remaining_pulses > 0 and not has_spawned_subpulse:
			has_spawned_subpulse = true
			if GM.pulse_count < GM.HARD_PULSE_CAP:
				spawn_pulse()
				if GM.pulse_count < GM.SOFT_PULSE_CAP and randf() < (1 - pow(1 - BASE_SPLIT_CHANCE, split_chance.x)):
					var p = spawn_pulse(true)
				
		if timer > lifetime.x:	
			timer = 0
			dead = true
			sprite.visible = false
			particles.emitting = false
			light.enabled = false
			GM.pulse_count -= 1
			
	elif timer > 1:
		queue_free()
		
	

#func _on_Pulse_body_entered(body):
#	if dead: return
#	
#	if body.is_in_group("Enemy"):
#		body.get_hit(self)
#	elif not body.is_in_group("Player"):
#		check_wall_collision = true
		
		
func deal_damage(target):
	target.get_hit(self)
