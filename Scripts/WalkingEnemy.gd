extends 'res://Scripts/EnemyBase.gd'

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
onready var raycast = $RayCast2D
onready var knockback_timer = $KnockbackTimer

func _ready():
	health = 30

func take_damage(amount):
	health -= amount
	if health < 0:
		queue_free()
		
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
	if !raycast.is_colliding():
		facing_right = !facing_right
	if facing_right:
		velocity.x = movespeed
		$Sprite.flip_h = false
		raycast.rotation = -45
	if !facing_right:
		velocity.x = -movespeed
		raycast.rotation = 45
		$Sprite.flip_h = true
		

func _on_EnemyHitbox_area_entered(area):
	pass # Replace with function body.



func _on_EnemyHurtbox_area_entered(area):
	var areas = hurtbox.get_overlapping_areas()
	for area in areas:
		if area.get_collision_mask() == 16:
			hit = true
			knockback_timer.start()
			knockback = area.direction
			knockback = knockback.normalized() * knockback_distance
			take_damage(area.deal_damage())


func _on_KnockbackTimer_timeout():
	hit = false
