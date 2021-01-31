extends 'res://Scripts/EnemyBase.gd'

signal damaged(health)

var TILESIZE = 16
var movespeed = 5 * TILESIZE

var knockback = Vector2.ZERO
var knockback_distance = 50

var gravity = 9.8
var max_fall_speed = 50

var hit = false
var facing_right = true

onready var hurtbox = $EnemyHurtbox
onready var hitbox = $EnemyHitbox
onready var pit_raycast = $PitRaycast
onready var wall_raycast = $WallRaycast
onready var knockback_timer = $KnockbackTimer
onready var anim_player = $AnimationPlayer
onready var hit_audio = $HitAudio

func _ready():
	health = 30
	anim_player.play("Walk")

func take_damage(amount):
	hit_audio.play()
	health -= amount
	emit_signal("damaged", health)
	if health <= 0:
		velocity = Vector2.ZERO
		movespeed = 0
		anim_player.play("Dead")
		
		
func _physics_process(delta):
	apply_gravity(delta)
	if !hit:
		move()
		velocity = move_and_slide(velocity)
	if hit:
		velocity = move_and_slide(knockback)
	
	
func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity
	
func move():
	if !pit_raycast.is_colliding() or wall_raycast.is_colliding():
		facing_right = !facing_right
	if facing_right:
		velocity.x = movespeed
		$Sprite.flip_h = false
		pit_raycast.rotation = -45
		wall_raycast.rotation = -90
	if !facing_right:
		velocity.x = -movespeed
		pit_raycast.rotation = 45
		wall_raycast.rotation = 90
		$Sprite.flip_h = true
		

func _on_EnemyHitbox_area_entered(area):
	pass # Replace with function body.



func _on_EnemyHurtbox_area_entered(_area):
	var areas = hurtbox.get_overlapping_areas()
	for area in areas:
		if area.get_collision_mask() == 81:
			get_hit(area)


func _on_KnockbackTimer_timeout():
	hit = false


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()
