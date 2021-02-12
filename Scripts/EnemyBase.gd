extends KinematicBody2D

const SUCTION_SPEED_CAP = 50

onready var Healthbar = $HealthBar

var velocity = Vector2.ZERO
var imposed_velocity = Vector2.ZERO
var imposed_accel = Vector2.ZERO
var active_suction_vectors = 0

var health
var contact_damage = 0
var knockback_resist = 1
var knockback_resist_multiplier = 1


var variant

func _ready():
	GM.add_enemy(self)
	
func _physics_process(delta):
	if knockback_resist_multiplier > 1: 
		knockback_resist_multiplier *= 0.5
	else:
		knockback_resist_multiplier = 1
	
func apply_knockback(kb):
	velocity += kb/knockback_resist/knockback_resist_multiplier
	knockback_resist_multiplier += 1
		
func apply_suction(succ):
	active_suction_vectors += 1
	imposed_accel += succ

func move():
	if active_suction_vectors > 0:
		imposed_accel /= pow(active_suction_vectors, 0.5)
		imposed_velocity += imposed_accel
		var spd = imposed_velocity.length()
		if(spd > SUCTION_SPEED_CAP):
			imposed_velocity = imposed_velocity/spd*SUCTION_SPEED_CAP
		
	velocity = move_and_slide(velocity + imposed_velocity)
	
	imposed_velocity *= 0.5 #move_toward(Vector2.ZERO, knockback_resist*delta)
	imposed_accel = Vector2.ZERO
	active_suction_vectors = 0
	
func take_damage(amount):
	health -= amount
	#emit_signal("damaged", health)
	Healthbar.update_health(health)
	if health <= 0:
		contact_damage = 0
		GM.remove_enemy(self)

func get_hit(pulse):
	apply_knockback(pulse.velocity.normalized() * pow(abs(pulse.cur_knockback*600), 0.5) * sign(pulse.cur_knockback))
	take_damage(pulse.cur_damage)
	
func set_variant(v):
	variant = v
