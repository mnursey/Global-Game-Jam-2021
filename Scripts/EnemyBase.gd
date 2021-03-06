extends KinematicBody2D

const SUCTION_SPEED_CAP = 50
const LN5 = 1.609

onready var room = $"../.."
onready var sprite = $Sprite
onready var healthbar = $HealthBar
onready var hit_audio = $HitAudio
onready var death_audio = $AudioStreamPlayer2D

var velocity = Vector2.ZERO
var imposed_velocity = Vector2.ZERO
var imposed_accel = Vector2.ZERO
var active_suction_vectors = 0

var health
var contact_damage = 0
var knockback_resist = 1
var knockback_resist_multiplier = 1

var scrap_held


var variant

func _ready():
	#GM.add_enemy(self)
	sprite.light_mask = 5
	for AP in [hit_audio, death_audio]:
		if AP:
			
			AP.max_distance = 500
			AP.attenuation = 1.5
	
func _physics_process(delta):
	if knockback_resist_multiplier > 1: 
		knockback_resist_multiplier *= 0.5
	else:
		knockback_resist_multiplier = 1
	
func apply_knockback(kb):
	var raw_kb_vector = kb/knockback_resist/knockback_resist_multiplier
	velocity += raw_kb_vector*(1.5/pow(raw_kb_vector.length_squared(), 0.075))
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
	
func random_variant():
	var r = randf()
	if r < 0.85:
		return 0
	elif r < 0.97:
		return 1
	elif r < 0.995:
		return 2
	else:
		return 3
	
func take_damage(amount):
	if health > 0:
		health -= amount
		healthbar.update_health(health)
		hit_audio.play()
		if health <= 0:
			death_audio.play()
			contact_damage = 0
			GM.spawn_scrap(scrap_held, global_position, room)

func get_hit(pulse):
	apply_knockback(pulse.velocity.normalized() * pow(abs(pulse.cur_knockback*600), 0.5) * sign(pulse.cur_knockback))
	take_damage(pulse.cur_damage)
	
func set_variant(v):
	variant = v
	scrap_held = int(6 * pow(3, v))
	#if set_tint:
	match v:
		0:
			sprite.modulate = Color.white
		1:
			sprite.modulate = Color(1, 0.93, 0.63)
		2:
			sprite.modulate = Color(0.52, 0.79, 1)
		3:
			sprite.modulate = Color(1, 0.37, 0.90)
