extends 'res://Scripts/EnemyBase.gd'

signal damaged(health)

var air_friction = 75
var wander_range = 5
var max_speed = 50
var acceleration = 300
var knockback_distance = 50

var bullet_speed = 100
var bullet_damage = 10
var shot_cooldown = 1
var shoot_timer = 0

var aggro_range = 150
#var min_target_range = 75
#var max_target_range = 110

var target_point = Vector2.ZERO
var target_points = [Vector2(100, -100), Vector2(0, -120), Vector2(-100, -100)]
var current_target_point_id = 0
var offset_change_timer = INF
var target_point_offset = Vector2.ZERO
var teleport_timer = 0
var can_teleport = false
var reposition_side = 0

enum {
	IDLE,
	WANDER,
	CHASE
}

var state = IDLE

onready var Bullet = load('res://Scenes/Bullet.tscn')
onready var hurtbox = $EnemyHurtbox
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer
onready var knockback_timer = $KnockbackTimer
onready var raycast = $RayCast2D
onready var particles = $Particles2D
onready var hit_audio = $HitAudio

const variant_health = [30, 80, 200, 500]
const variant_speed = [50, 75, 100, 150]
const variant_damage = [10, 15, 20, 20]
const variant_acceleration = [300, 400, 500, 500]
const variant_kb_resist = [4, 4, 4, 4]
const variant_bullet_speed = [120, 120, 150, 200]
const variant_shot_cooldown = [1, 0.4, 1, 0.1]

func _ready():
	set_variant(random_variant())
	#set_variant(0)#int(pow(randf(), 2) * 4))
	state = pick_random_state([IDLE])
	animationPlayer.play("Idle")
	
func set_variant(v):
	#.set_variant(v)
	variant  = v
	health = variant_health[v]
	bullet_damage = variant_damage[v]
	max_speed = variant_speed[v]
	acceleration = variant_acceleration[v]
	knockback_resist = variant_kb_resist[v]
	bullet_speed = variant_bullet_speed[v]
	shot_cooldown = variant_shot_cooldown[v]
	Healthbar.init(health)
	match v:
		0:
			sprite.texture = load('res://Art/Enemies/enemy_drone_turret-sheet.png')
		1:
			sprite.texture = load('res://Art/Enemies/enemy_drone_turret2-sheet.png')
		2:
			sprite.texture = load('res://Art/Enemies/enemy_drone_turret3-sheet.png')
		3:
			sprite.texture = load('res://Art/Enemies/enemy_drone_turret4-sheet.png')


func _physics_process(delta):
	
	match state:
		IDLE:
			if player_dist() < aggro_range:
				begin_chase()
				
			velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
			if wanderController.get_time_left() == 0:
				update_wander()
		WANDER:
			if player_dist() < aggro_range:
				state = CHASE
				
			if wanderController.get_time_left() == 0:
				update_wander()
				
			accelerate_towards_point(wanderController.target_position, delta)
			
			if global_position.distance_to(wanderController.target_position) <= wander_range:
				update_wander()
			
		CHASE:
			if variant == 1 or variant == 2:
				if offset_change_timer > 1.5:
					offset_change_timer = 0
					target_point_offset = Vector2(randf(), randf()).normalized() * 50
				else:
					offset_change_timer += delta
	
			if variant == 0:
				target_point = Vector2.ZERO
			elif variant <= 2:
				if reposition_side > 0 or (reposition_side == 0 and global_position.x > GM.player.global_position.x):
					target_point = target_points[0]
				else:
					target_point = target_points[2] 
			else:
				if teleport_timer < 0:
					can_teleport = true
					
					var possible_ids = [0, 1, 2]
					possible_ids.remove(current_target_point_id)
					current_target_point_id = possible_ids[int(randf()*2)]
					target_point = target_points[current_target_point_id]
				else:
					teleport_timer -= delta
					
			var abs_target_point = GM.player.global_position + target_point + target_point_offset
			var target_dist = (abs_target_point - global_position).length()
					
			if variant == 3: raycast.cast_to = abs_target_point - global_position

			var can_shoot = false
			if variant == 0:
				if target_dist > 130:
					accelerate_towards_point(abs_target_point, delta)
				elif target_dist < 70:
					accelerate_from_point(abs_target_point, delta)
				else:
					can_shoot = true
					velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
					
			else:
				can_shoot = target_dist < 50
				if target_dist > 20:
					accelerate_towards_point(abs_target_point, delta)
					if variant == 3 and can_teleport: attempt_teleport(abs_target_point)
				else:
					reposition_side = 0
					velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
			
			shoot_timer += delta
			if can_shoot or reposition_side != 0:
				if shoot_timer > shot_cooldown:
					shoot_timer = 0
					var leading = GM.player.velocity/2 if variant != 1 else Vector2.ZERO
					var bullet_vector = bullet_speed*global_position.direction_to(GM.player.global_position + leading)
					if variant == 3:
						bullet_vector = bullet_vector.rotated((randf()-0.5)*deg2rad(15))
					shoot(bullet_vector)
					if variant == 2:
						shoot(bullet_vector.rotated(deg2rad(15)))
						shoot(bullet_vector.rotated(deg2rad(-15)))
					
							
	sprite.flip_h = velocity.x < 0
	.move()
	
func begin_chase():
	state = CHASE			
	if variant <= 1:
		pass
	elif variant <= 2:
		target_point = target_points[0] if randf() > 0.5 else target_points[2]
	else:
		current_target_point_id = int(randf()*3)
		target_points[current_target_point_id]
	
func shoot(bullet_vector):
	var bullet = Bullet.instance().duplicate()
	bullet.velocity = bullet_vector
	bullet.global_position = global_position + 10*bullet.velocity/bullet_speed
	bullet.damage = bullet_damage
	get_node("/root").add_child(bullet)
				
func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed * (1 if reposition_side == 0 else 2), acceleration * delta)
	
func accelerate_from_point(point, delta):
	var direction = -global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	
func attempt_teleport(point):
	raycast.enabled = true
	raycast.force_raycast_update()
	if not raycast.is_colliding():
		can_teleport = false
		teleport_timer = 1 + randf()
		velocity = Vector2.ZERO
		shoot_timer = -0.3
		
		global_position = point
		particles.emitting = true
	raycast.enabled = false

func player_dist():
	if GM.player: return (GM.player.global_position - global_position).length()
	return INF
	
	
		
func update_wander():
	state = pick_random_state([IDLE])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func take_damage(amount):
	.take_damage(amount)
	hit_audio.play()
	if state == IDLE: 
		begin_chase()
	if health <= 0:
		velocity = Vector2.ZERO
		max_speed = 0
		acceleration = 0
		animationPlayer.play("Dead")
	elif variant >= 1 and reposition_side == 0 and randf() > 0.5:
		offset_change_timer = INF
		reposition_side = 1 if global_position.x < GM.player.global_position.x else -1
		
		
func _on_EnemyHurtbox_area_entered(_area):
	#var areas = hurtbox.get_overlapping_areas()
	#for area in areas:
	#	if area.get_collision
	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()


func _on_KnockbackTimer_timeout():
	pass # Replace with function body.
