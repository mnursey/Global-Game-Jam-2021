extends 'res://Scripts/EnemyBase.gd'

signal damaged(health)

var TILESIZE = 16
var movespeed = 5 * TILESIZE

var knockback = Vector2.ZERO
var knockback_distance = 50

var gravity = 1000
var max_fall_speed = 50
var jump_speed = 230

var aggro_range = 150

var hit = false
var facing_right = true
var jumping = false

var feinting = false
var feint_timer = 0
var jump_buffered = false

onready var hurtbox = $EnemyHurtbox
onready var hitbox = $EnemyHitbox
onready var pit_raycast = $PitRaycast
onready var wall_raycast = $WallRaycast
onready var floor_raycast = $FloorRaycast
onready var knockback_timer = $KnockbackTimer
onready var anim_player = $AnimationPlayer
onready var hit_audio = $HitAudio

const variant_health = [40, 120, 400]
const variant_speed = [5, 9, 12]
const variant_damage = [25, 40, 70]
const variant_jump_height = [3, 4, 5]

func _ready():
	set_variant(int(pow(randf(), 2) * 3))
	anim_player.play("Walk")
	turn_to_face(1)
	
func set_variant(v):
	variant = v
	health = variant_health[v]
	contact_damage = variant_damage[v]
	movespeed = variant_speed[v] * TILESIZE
	jump_speed = pow(2*gravity*variant_jump_height[v]*TILESIZE, 0.5) 
	Healthbar.init(health)
			

func take_damage(amount):
	.take_damage(amount)
	jumping = true
	hit_audio.play()
	if health <= 0:
		velocity = Vector2.ZERO
		movespeed = 0
		anim_player.play("Dead")
	elif variant >= 1 and randf() > 0.5:
		jump_buffered = true
		
		
		
func _physics_process(delta):
	apply_gravity(delta)
	if true or !hit:
		move(delta)
		velocity = move_and_slide(velocity)
	if false and hit:
		velocity = move_and_slide(knockback)
	
	
func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity*delta
	
func move(delta):
	if facing_right:
		velocity.x = lerp(velocity.x, movespeed, 2*delta)
	elif !facing_right:
		velocity.x = lerp(velocity.x, -movespeed, 2*delta)

	if floor_raycast.is_colliding() and velocity.y >= 0:
		jumping = false
		
	var to_player = GM.player.global_position - global_position
	var aggro = to_player.length_squared() < aggro_range*aggro_range
	
	if aggro:
		if not feinting:
			if not facing_right and to_player.x > 0:
				turn_to_face(1)
			elif facing_right and to_player.x < 0:
				turn_to_face(0)
		
		if variant >= 1:
			if not jumping and to_player.y <= -TILESIZE:
				jump()
			elif not jumping and sign(velocity.x) == sign(to_player.x) and jump_buffered:
				jump()
				jump_buffered = false
				
			if variant >= 2:
				if feint_timer > 0.3:
					feinting = false
					if not jumping and sign(GM.player.velocity.x) != sign(velocity.x) and abs(to_player.x) < 3*TILESIZE:
						feint_timer = 0
						if randf() > 0.5:
							feinting = true
							velocity.x *= -1.5
							jump(200)
							
				else:
					feint_timer += delta
					
					
						
						
					
			
	if !jumping and (!pit_raycast.is_colliding() or wall_raycast.is_colliding()):
		if aggro:
			jump()
		else:
			turn_to_face(int(!facing_right))
			
func jump(spd = jump_speed):
	jumping = true
	velocity.y = -spd
		
func turn_to_face(dir):
	if dir == 1:
		facing_right = true
		pit_raycast.rotation = -45
		wall_raycast.rotation = -90
		$Sprite.flip_h = false
	else:
		facing_right = false
		pit_raycast.rotation = 45
		wall_raycast.rotation = 90
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
