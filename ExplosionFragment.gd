extends Area2D

onready var sprite = $AnimatedSprite
onready var particles = $Particles2D
onready var light = $Light2D

var blast_radius
var damage
var lifetime

var velocity = Vector2.ZERO
var grounded = false
var dead = false
var timer = 1

func init(pos, vel, r, d, lifetime = 0):
	global_position = pos
	velocity = vel
	blast_radius = r
	damage = d
	timer = lifetime
	if blast_radius > 0:
		modulate = Color("43fbff")
		light.enabled = false
		particles.amount = 30
	else:
		modulate = Color("ffffff")
		light.enabled = true
		particles.amount = 40

func _physics_process(delta):
	if not grounded:
		rotation_degrees = rad2deg(velocity.angle())
		global_position += velocity*delta
		velocity.y += 100*delta
	else:
		timer -= delta
		if timer < 0:
			if not dead:
				timer = 1
				dead = true
				sprite.visible = false
				particles.emitting = false
				light.enabled = false
			else:
				queue_free()
			

func _on_ExplosionFragment_body_entered(body):
	if not body.is_in_group("Enemy"):
		if blast_radius > 0 and not grounded:
			GM.spawn_explosion(blast_radius, damage, "Player", global_position, get_parent())
			grounded = true
			timer = 0
		elif body.is_in_group("Player") and blast_radius <= 0 and not dead:
			body.take_damage(damage)
		elif not grounded:
			grounded = true
			rotation_degrees = 90
			scale *= 2
			particles.amount = 80
			
