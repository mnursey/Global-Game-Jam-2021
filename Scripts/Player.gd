extends KinematicBody2D

signal health_updated(health)
signal max_health_updated(max_health)
signal dead()

const UP = Vector2(0, -1)
const TILESIZE = 16

var velocity = Vector2()
var move_speed = 10 * TILESIZE

var max_health = 100
var health = max_health setget set_health

var gravity
var fall_gravity
var max_jump_velocity
var min_jump_velocity
var max_jump_height = 3.2 * TILESIZE
var min_jump_height= 0.8 * TILESIZE
var jump_duration = 0.3
var fall_duration = 0.325
var max_horiz_speed = 225

var max_jumps = 1
var jumps = 1
var is_jumping = false

var max_dashes = 1
var dashes = 1
var dash_speed = 20 * TILESIZE
var dash_time = 0.2
var is_dashing = false
var can_dash = true
var dash_direction = Vector2.ZERO

var facing_right = true 

onready var anim_player = $AnimationPlayer
onready var sprite = $Sprite
onready var dash_timer = $DashTimer
onready var invincibility_timer = $InvincibilityTimer
onready var coyote_timer = $CoyoteTimer

func _ready():
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	fall_gravity = 2 * max_jump_height / pow(fall_duration, 2)
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)

func _physics_process(delta):
	apply_gravity(delta)
	get_move_input()
	get_input()
	apply_movement()
	animate()

func get_input():
	if Input.is_action_just_pressed("jump") and jumps > 0:
				is_jumping = true
				velocity.y = max_jump_velocity
				jumps -= 1
	if Input.is_action_just_released("jump") and velocity.y < min_jump_velocity:
				velocity.y = min_jump_velocity
	
	if Input.is_action_just_pressed("dash") and can_dash:
		is_dashing = true
		dashes -= 1
		if dashes == 0:
			can_dash = false
		dash_timer.start(dash_time)
		
		var move_vector = Vector2.ZERO
		move_vector.x = -Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
		move_vector.y = -Input.get_action_strength("move_up") + Input.get_action_strength("move_down")
		move_vector = move_vector.clamped(1)
		dash_direction = move_vector * dash_speed

func apply_movement():
	var was_on_floor = is_on_floor()
	
	if is_dashing:
		velocity = move_and_slide(dash_direction, UP)
	else:
		velocity = move_and_slide(velocity, UP)
		if !is_on_floor() and was_on_floor and !is_jumping:
			coyote_timer.start()
	if is_on_floor():
		jumps = max_jumps
		dashes = max_dashes
		can_dash = true

func apply_gravity(delta):
	if velocity.y < 0:
		velocity.y += gravity * delta
	else:
		is_jumping = false
		velocity.y += gravity * delta
		velocity.y = lerp(velocity.y, fall_gravity * delta, 0.05)

func get_move_input():
	var move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	velocity.x = lerp(velocity.x, move_speed * move_direction, 0.2)
	if velocity.x >= 0:
		velocity.x = min(velocity.x, max_horiz_speed)
	else:
		velocity.x = max(velocity.x, -max_horiz_speed)
	
func animate():
	if velocity.x > 0.5:
		facing_right = true
		$Sprite.flip_h = false
	elif velocity.x < -0.5:
		facing_right = false
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = !facing_right
	if abs(velocity.x) <= 20 && is_on_floor():
		anim_player.play("idle")
	elif abs(velocity.x) > 20 && is_on_floor():
		anim_player.play("run")
	elif velocity.y < 0:
		anim_player.play("jump")
	else:
		anim_player.play("fall")


func _on_DashTimer_timeout():
	velocity /= 2
	is_dashing = false
	
func take_damage(amount):
	if invincibility_timer.is_stopped():
		invincibility_timer.start()
		set_health(health - amount)
		
func heal(amount):
	set_health(health + amount)

func dead():
	move_speed = 0
	max_jumps = 0
	max_dashes = 0


func set_health(value):
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health != prev_health:
		emit_signal("health_updated", health)
		if health == 0:
			dead()
			anim_player.play("Dead")
			emit_signal("dead")


func _on_Hurtbox_area_entered(area):
	take_damage(area.deal_damage()) 
	

func _on_Hurtbox_body_entered(body):
	take_damage(body.deal_damage())


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		sprite.hide()
