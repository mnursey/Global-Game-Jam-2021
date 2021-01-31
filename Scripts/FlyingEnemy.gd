extends 'res://Scripts/EnemyBase.gd'

signal damaged(health)

var air_friction = 200
var wander_range = 5
var max_speed = 50
var acceleration = 300
var knockback_distance = 50

var aggro_range = 150

var hit = false

enum {
	IDLE,
	WANDER,
	CHASE
}

var state = IDLE

onready var player_detection_zone = $PlayerDectectionZone
onready var hurtbox = $EnemyHurtbox
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer
onready var sprite = $Sprite
onready var knockback_timer = $KnockbackTimer
onready var soft_collision = $SoftCollision
onready var hit_audio = $HitAudio


func _ready():
	health = 30
	state = pick_random_state([IDLE, WANDER])
	animationPlayer.play("Idle")

func _physics_process(delta):
	#knockback = knockback.move_toward(Vector2.ZERO, air_friction * delta)
	#knockback = move_and_slide(knockback)
	
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
			accelerate_towards_point(GM.player.global_position, delta)
		
	#if soft_collision.is_colliding():
	#	velocity += soft_collision.get_push_vector() * delta * 400
	
	sprite.flip_h = velocity.x < 0
	velocity = move_and_slide(velocity)
				
func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	
func player_dist():
	return (GM.player.global_position - global_position).length()
		
func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func take_damage(amount):
	health -= amount
	emit_signal("damaged", health)
	hit_audio.play()
	if health <= 0:
		velocity = Vector2.ZERO
		max_speed = 0
		acceleration = 0
		animationPlayer.play("Dead")
		
		
func _on_EnemyHurtbox_area_entered(_area):
	var areas = hurtbox.get_overlapping_areas()
	for area in areas:
		if area.get_collision_mask() == 81:
			get_hit(area)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()


func _on_KnockbackTimer_timeout():
	pass # Replace with function body.
