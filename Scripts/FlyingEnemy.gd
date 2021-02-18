extends 'res://Scripts/EnemyBase.gd'

signal damaged(health)

var air_friction = 200
var wander_range = 5
var max_speed = 100
var acceleration = 300
var knockback_distance = 50

var aggro_range = 150
var buffered_dodge = false
var stalking_offset = Vector2(0, -100)
var chase_timer = 5

var can_teleport = false
var teleport_timer = -1
var stall_timer = -1

enum {
	IDLE,
	WANDER,
	CHASE,
	STALK
}

var state = IDLE

#onready var player_detection_zone = $PlayerDectectionZone
onready var hurtbox = $EnemyHurtbox
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer
onready var knockback_timer = $KnockbackTimer
onready var raycast = $RayCast2D
onready var particles = $Particles2D
onready var hit_audio = $HitAudio

const variant_health = [30, 90, 300, 800]
const variant_speed = [100, 150, 300, 300]
const variant_damage = [20, 35, 50, 60]
const variant_acceleration = [300, 300, 600, 600]
const variant_kb_resist = [1, 1.5, 2, 3]


func _ready():
	set_variant(random_variant())
	#set_variant(0)#int(pow(randf(), 2) * 4))
	state = pick_random_state([IDLE])
	animationPlayer.play("Idle")
	
func set_variant(v):
	.set_variant(v)
	health = variant_health[v]
	contact_damage = variant_damage[v]
	max_speed = variant_speed[v]
	acceleration = variant_acceleration[v]
	knockback_resist = variant_kb_resist[v]
	Healthbar.init(health)

func _physics_process(delta):
	#knockback = knockback.move_toward(Vector2.ZERO, air_friction * delta)
	#knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			if player_dist() < aggro_range:
				begin_chase()
				
			velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
			#if wanderController.get_time_left() == 0:
			#	update_wander()
		WANDER:
			if player_dist() < aggro_range:
				state = CHASE
				
			if wanderController.get_time_left() == 0:
				update_wander()
				
			accelerate_towards_point(wanderController.target_position, delta)
			
			if global_position.distance_to(wanderController.target_position) <= wander_range:
				update_wander()
			
		CHASE:
			if stall_timer > 0:
				stall_timer -= delta
				return
				
			accelerate_towards_point(GM.player.global_position, delta)
				
			if variant >= 2:
				if chase_timer < 0:
					chase_timer = randf()*2 + 3
					state = STALK
				else:
					chase_timer -= delta
			
			if buffered_dodge:
				var player_dir = (GM.player.global_position - global_position).normalized()
				if velocity.normalized().dot(player_dir) > 0.92:
					buffered_dodge = false
					
					var dodge_vel
					if abs(velocity.x) > 2*abs(velocity.y):
						dodge_vel = 200*Vector2.UP
					else:
						dodge_vel = 200 * player_dir.tangent() * sign(randf() - 0.5)
						
					dodge_vel *= sign(randf() - 0.5)
					velocity += dodge_vel
			
			if variant == 3:
				if teleport_timer < 0:
					var to_player = (GM.player.global_position - global_position)
					if abs(GM.player.velocity.x) > 100 and sign(to_player.x) == sign(GM.player.velocity.x) and to_player.length_squared() < 10000 and not GM.player.is_dashing:
						attempt_teleport(GM.player.global_position + Vector2(GM.player.velocity.x*0.7, GM.player.velocity.y*0.2))
				else:
					teleport_timer -= delta		
				
		
		STALK:
			var target_point = GM.player.global_position + stalking_offset
			if (target_point - global_position).length_squared() < 1500:
				if chase_timer > 0:
					chase_timer -= 1
					randomize_stalking_offset()
				else:
					velocity = velocity*0.7 + max_speed/2*(GM.player.global_position - global_position).normalized() 
					chase_timer = randf()*3 + 3
					teleport_timer = 1 + randf()
					state = CHASE
			
			else:		
				accelerate_towards_point(target_point, delta)
				
		
	#if soft_collision.is_colliding():
	#	velocity += soft_collision.get_push_vector() * delta * 400
	
	sprite.flip_h = velocity.x < 0
	.move()
	
func begin_chase():
	state = CHASE if variant < 2 else STALK
				
func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	
func randomize_stalking_offset():
	var theta = (randf()*2.4 + 0.6)*PI/6 
	if stalking_offset.x > 0: theta += PI/3
	stalking_offset = Vector2(cos(theta), -sin(theta))*120
	
func attempt_teleport(point):
	raycast.enabled = true
	raycast.cast_to = point - global_position
	raycast.force_raycast_update()
	if not raycast.is_colliding():
		can_teleport = false
		teleport_timer = 1.5 + randf()
		stall_timer = 0.3
		velocity = Vector2.ZERO
		
		global_position = point
		particles.emitting = true
		
	raycast.enabled = false
	
func player_dist():
	return (GM.player.global_position - global_position).length()
		
func update_wander():
	state = pick_random_state([IDLE, WANDER])
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
	elif variant >= 1 and randf() > 0.5:
		buffered_dodge = true

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()
