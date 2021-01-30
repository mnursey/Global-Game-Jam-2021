extends KinematicBody2D

const UP = Vector2(0, -1)
const TILESIZE = 16

var velocity = Vector2()
var move_speed = 10 * TILESIZE
var deadzone = 20

var gravity
var fall_gravity
var max_jump_velocity
var min_jump_velocity
var max_jump_height = 3.2 * TILESIZE
var min_jump_height= 0.8 * TILESIZE
var jump_duration = 0.3
var fall_duration = 0.325
var max_horiz_speed = 225

var max_jumps = 2
var jumps = 2

var max_dashes = 2
var dashes = 2
var dash_speed = 10 * TILESIZE

var level_finished = false
var spawn = true
var is_attacking = false
var can_attack = true

onready var anim_player = $AnimationPlayer
onready var body = $CollisionShape2D


func _ready():
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	fall_gravity = 2 * max_jump_height / pow(fall_duration, 2)
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)

func _physics_process(delta):
		
	if is_on_floor():
		jumps = max_jumps
		
	move()
	get_input()
	
	if velocity.y < 0:
		velocity.y += gravity * delta
	else:
		velocity.y += gravity * delta
		velocity.y = lerp(velocity.y, fall_gravity * delta, 0.05)
	
	velocity = move_and_slide(velocity, UP)
	
	animate()
	
func move():
	var move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	velocity.x = lerp(velocity.x, move_speed * move_direction, 0.2)
	if velocity.x >= 0:
		velocity.x = min(velocity.x, max_horiz_speed)
	else:
		velocity.x = max(velocity.x, -max_horiz_speed)
	
func get_input():
	if Input.is_action_just_pressed("jump"):
		if jumps > 0 :
			jump()
			jumps -= 1
	
	if Input.is_action_just_released("jump") and velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity
	
	if Input.is_action_just_pressed("dash"):
		var move_vector = Vector2.ZERO
		move_vector.x = -Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
		move_vector.y = -Input.get_action_strength("move_up") + Input.get_action_strength("move_down")
		velocity = move_vector.normalized() * dash_speed

func jump():
	velocity.y = max_jump_velocity
	if !is_on_floor():
		velocity.y = 0
		velocity.y = max_jump_velocity

		
func animate():
	if velocity.x > 0:
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true

	
	if abs(velocity.x) <= 20 && is_on_floor():
		anim_player.play("idle")
	elif abs(velocity.x) > 20 && is_on_floor():
		anim_player.play("run")
	elif velocity.y < 0:
		anim_player.play("jump")
	else:
		anim_player.play("fall")

