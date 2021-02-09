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
var min_target_range = 75
var max_target_range = 110

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
onready var sprite = $Sprite
onready var knockback_timer = $KnockbackTimer
onready var soft_collision = $SoftCollision
onready var hit_audio = $HitAudio

const variant_health = [30, 80, 200]
const variant_speed = [50, 75, 100]
const variant_damage = [10, 15, 20]
const variant_acceleration = [300, 400, 500]
const variant_bullet_speed = [120, 150, 120]
const variant_shot_cooldown = [1, 0.3, 1]
const variant_ranges = [[80, 130], [0, 50], [0, 50]]


func _ready():
	set_variant(2) #int(pow(randf(), 2) * 3))
	state = pick_random_state([IDLE])
	animationPlayer.play("Idle")
	
func set_variant(v):
	variant = v
	health = variant_health[v]
	bullet_damage = variant_damage[v]
	max_speed = variant_speed[v]
	acceleration = variant_acceleration[v]
	bullet_speed = variant_bullet_speed[v]
	shot_cooldown = variant_shot_cooldown[v]
	min_target_range = variant_ranges[v][0]
	max_target_range = variant_ranges[v][1]
	Healthbar.init(health)

func _physics_process(delta):
	#knockback = knockback.move_toward(Vector2.ZERO, air_friction * delta)
	#knockback = move_and_slide(knockback)
	
	var target_point
	if variant == 0:
		target_point = GM.player.global_position
	else:
		target_point = GM.player.global_position + Vector2(100, -100)
		if reposition_side > 0 or (reposition_side == 0 and global_position.x > GM.player.global_position.x):
			target_point = GM.player.global_position + Vector2(100, -100)
		else:
			target_point = GM.player.global_position + Vector2(-100, -100)

	var player_dist = (target_point - global_position).length()
	
	match state:
		IDLE:
			if player_dist() < aggro_range:
				state = CHASE
				
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
			shoot_timer += delta
			var target_in_range = false
			if player_dist > max_target_range:
				accelerate_towards_point(target_point, delta)
			elif player_dist < min_target_range:
				accelerate_from_point(target_point, delta)
			else:
				target_in_range = true
				reposition_side = 0
				velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
			
			if target_in_range or reposition_side != 0:
				if shoot_timer > shot_cooldown:
					shoot_timer = 0
					var leading = GM.player.velocity/2 if variant != 1 else Vector2.ZERO
					var bullet_vector = bullet_speed*global_position.direction_to(GM.player.global_position + leading)
					shoot(bullet_vector)
					if variant == 2:
						shoot(bullet_vector.rotated(deg2rad(15)))
						shoot(bullet_vector.rotated(deg2rad(-15)))
						
				
				

	#if soft_collision.is_colliding():
	#	print("soft collision")
	#	velocity += soft_collision.get_push_vector() * delta * 800
		
	sprite.flip_h = velocity.x < 0
	velocity = move_and_slide(velocity)
	
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
	if health <= 0:
		velocity = Vector2.ZERO
		max_speed = 0
		acceleration = 0
		animationPlayer.play("Dead")
	elif variant >= 1 and reposition_side == 0 and randf() > 0.5:
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
