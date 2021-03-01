extends Area2D

onready var sprite = $Sprite
onready var particles = $Particles2D
onready var raycast = $RayCast2D

const GRAVITY = 200

var blast_radius
var damage
var airburst_dist
var payload
var num_frags
var frag_damage
var frag_spread

var velocity = Vector2.ZERO
var detonated = false
var timer = 1

var warning_target = null


enum PayloadType{
	Explosive,
	Incendiary,
	Cluster
}

func _ready():
	pass
	#init(global_position, Vector2(-100, -200), 100, 100, 0, PayloadType.Explosive, 3)

func init(pos, vel, r, d, a, p, f, fd, fs):
	global_position = pos
	velocity = vel
	blast_radius = r
	damage = d
	airburst_dist = a
	payload = p
	num_frags = f
	frag_damage = fd
	frag_spread = fs
	
func _physics_process(delta):
	if not detonated:
		rotation_degrees = rad2deg(velocity.angle())
		sprite.flip_v = abs(rotation_degrees) > 90
		
		global_position += velocity*delta
		velocity.y += GRAVITY*delta
		
		if velocity.y > 0:
			raycast.cast_to.x = 20 + airburst_dist
		
		if raycast.is_colliding():
			if not detonated and not raycast.get_collider().is_in_group("Enemy"):
				detonate()
	else:
		timer -= delta
		if timer < 0:
			queue_free()
			
func detonate():
	detonated = true
	sprite.visible = false
	particles.emitting = false
	raycast.enabled = false
	if warning_target:
		warning_target.queue_free()
	
	var frag_angle = velocity.angle() if airburst_dist > 0 else -PI/2
	var frag_speed = 120 if airburst_dist == 0 else 150
	match payload:
		PayloadType.Explosive:
			GM.spawn_explosion(blast_radius, damage, "Player", global_position, get_parent())
		PayloadType.Incendiary:
			GM.spawn_explosion(blast_radius, damage, "Player", global_position, get_parent(), num_frags, frag_angle, frag_speed, frag_spread, frag_damage, 0, 5)
		PayloadType.Cluster:
			GM.spawn_explosion(blast_radius, damage, "Player", global_position, get_parent(), num_frags, frag_angle, frag_speed, frag_spread, frag_damage, 30, 0)
	
	
