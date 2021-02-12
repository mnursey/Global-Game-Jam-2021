extends 'res://Scripts/EnemyBase.gd'

signal damaged(health)

var TILESIZE = 16
var movespeed = 5 * TILESIZE

var knockback = Vector2.ZERO
var knockback_distance = 50

var gravity = 1000
var max_fall_speed = 50
var jump_speed = 230

var is_dashing = false
var dash_timer = 0
var dash_cooldown_timer = 0
var dash_vel = Vector2.ZERO

var aggro = false
var aggro_range = 150

var hit = false
var facing_right = true
var jumping = false

var feinting = false
var feint_timer = 0
var dodge_buffered = false
var prev_pit_detected = false

onready var hurtbox = $EnemyHurtbox
onready var hitbox = $EnemyHitbox
onready var pit_raycast = $PitRaycast
onready var wall_raycast = $WallRaycast
onready var floor_raycast = $FloorRaycast
onready var particles = $Particles2D
onready var knockback_timer = $KnockbackTimer
onready var anim_player = $AnimationPlayer
onready var hit_audio = $HitAudio

const variant_health = [40, 120, 400, 1000]
const variant_speed = [6, 9, 12, 10]
const variant_damage = [25, 40, 70, 100]
const variant_kb_resist = [1.5, 2, 2.5, 3.5]
const variant_jump_height = [3, 4, 5, 5]
const variant_raycast_length = [20, 25, 30, 25]

func _ready():
	set_variant(0)#int(pow(randf(), 2) * 4))
	anim_player.play("Walk")
	turn_to_face(1)
	
func set_variant(v):
	variant = v
	health = variant_health[v]
	contact_damage = variant_damage[v]
	movespeed = variant_speed[v] * TILESIZE
	jump_speed = pow(2*gravity*variant_jump_height[v]*TILESIZE, 0.5) 
	wall_raycast.cast_to = Vector2(variant_raycast_length[v], 0)
	Healthbar.init(health)
			

func take_damage(amount):
	if is_dashing: return

	.take_damage(amount)
	aggro = true
	jumping = true
	hit_audio.play()
	if health <= 0:
		velocity = Vector2.ZERO
		movespeed = 0
		anim_player.play("Dead")
	elif variant >= 1 and randf() > 0.5:
		dodge_buffered = true
		
		
func _physics_process(delta):
	apply_gravity(delta)
	movement_logic(delta)
	.move()

	
	
func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity*delta
	
func movement_logic(delta):
	if not is_dashing:
		dash_cooldown_timer -= delta
		
		if facing_right:
			velocity.x = lerp(velocity.x, movespeed, 2*delta)
		elif !facing_right:
			velocity.x = lerp(velocity.x, -movespeed, 2*delta)

		if floor_raycast.is_colliding() and velocity.y >= 0:
			jumping = false
			
		var to_player = GM.player.global_position - global_position
		if not aggro and to_player.length_squared() < aggro_range*aggro_range:
			aggro = true
		
		if aggro:
			if not feinting:
				if not facing_right and to_player.x > 0:
					turn_to_face(1)
				elif facing_right and to_player.x < 0:
					turn_to_face(0)
					
			if not jumping:
				if wall_raycast.is_colliding():
					jump()
				elif not (prev_pit_detected or pit_raycast.is_colliding()) and randf() > 0.6:
					jump()
			
			if variant >= 1:
				if not jumping and to_player.y <= -TILESIZE:
					jump()
				
				if dodge_buffered:
					if variant < 3:
						if not jumping and sign(velocity.x) == sign(to_player.x):
							jump(400)
							dodge_buffered = false
					else:
						if dash_cooldown_timer <= 0:
							dash(to_player.normalized())
							dodge_buffered = false
						
				if variant >= 2:
					if feint_timer > 0.3:
						feinting = false
						if not jumping and sign(GM.player.velocity.x) != sign(velocity.x) and abs(to_player.x) < 3*TILESIZE and GM.player.is_dashing:
							feint_timer = 0
							if randf() > 0.5:
								feinting = true
								velocity.x = -300 * sign(velocity.x)
								jump(200)
								
					else:
						feint_timer += delta
						
		else:
			if wall_raycast.is_colliding() or not pit_raycast.is_colliding():
				turn_to_face(int(!facing_right))
				
		prev_pit_detected = !pit_raycast.is_colliding()
	
	else:
		if dash_timer > 0:
			dash_timer -= delta
			velocity = dash_vel
		else:
			velocity /= 2
			particles.emitting = false
			is_dashing = false
			
			
func jump(spd = jump_speed):
	jumping = true
	velocity.y = -spd
	
func dash(dir):
	is_dashing = true
	dash_timer = 0.15
	dash_cooldown_timer = 0.7
	particles.emitting = true
	dash_vel = dir*500
	
func turn_to_face(dir):
	if dir == 1:
		facing_right = true
		pit_raycast.cast_to.x = abs(pit_raycast.cast_to.x)
		wall_raycast.cast_to.x =  abs(wall_raycast.cast_to.x)
		$Sprite.flip_h = false
	else:
		facing_right = false
		pit_raycast.cast_to.x = -abs(pit_raycast.cast_to.x)
		wall_raycast.cast_to.x = -abs(wall_raycast.cast_to.x)
		$Sprite.flip_h = true
	

		

func _on_EnemyHitbox_area_entered(area):
	pass # Replace with function body.



func _on_EnemyHurtbox_area_entered(_area):
	#var areas = hurtbox.get_overlapping_areas()
	#for area in areas:
	#	if area.get_collision_mask() == 81:
	#		get_hit(area)
	pass


func _on_KnockbackTimer_timeout():
	hit = false


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()
