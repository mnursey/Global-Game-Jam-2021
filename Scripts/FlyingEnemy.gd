extends 'res://Scripts/EnemyBase.gd'

var air_friction = 200
var wander_range = 5
var max_speed = 50
var acceleration = 300
var health = 30
var knockback_distance = 50

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

func _ready():
	health = 30
	state = pick_random_state([IDLE, WANDER])
	animationPlayer.play("Idle")

func _physics_process(delta):
	#knockback = knockback.move_toward(Vector2.ZERO, air_friction * delta)
	#knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
			seek_player()
			
			if wanderController.get_time_left() == 0:
				update_wander()
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
				
			accelerate_towards_point(wanderController.target_position, delta)
			
			if global_position.distance_to(wanderController.target_position) <= wander_range:
				update_wander()
			
		CHASE:
			var player = player_detection_zone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE
	if soft_collision.is_colliding():
		velocity += soft_collision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)
				
func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	sprite.flip_h = velocity.x < 0


func seek_player():
	if player_detection_zone.can_see_player():
		state = CHASE
		
func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func take_damage(amount):
	health -= amount
	if health < 0:
		velocity = Vector2.ZERO
		max_speed = 0
		acceleration = 0
		animationPlayer.play("Dead")
		
		
func _on_EnemyHurtbox_area_entered(area):
	var areas = hurtbox.get_overlapping_areas()
	for area in areas:
		if area.get_collision_mask() == 16:
			hit = true
			knockback_timer.start()
			knockback = area.direction
			knockback = knockback.normalized() * knockback_distance
			take_damage(area.deal_damage())


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()
