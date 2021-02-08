extends KinematicBody2D

onready var Healthbar = $HealthBar

var velocity = Vector2.ZERO
var contact_damage = 0
var health

var variant

func _ready():
	GM.add_enemy(self)

func take_damage(amount):
	health -= amount
	emit_signal("damaged", health)
	Healthbar.update_health(health)
	if health < 0:
		contact_damage = 0
		GM.remove_enemy(self)

func get_hit(pulse):
	velocity += pulse.velocity.normalized() * pow(abs(pulse.cur_knockback*600), 0.5) * sign(pulse.cur_knockback)
	take_damage(pulse.cur_damage)
	
func set_variant(v):
	variant = v
