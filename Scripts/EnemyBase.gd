extends KinematicBody2D


var velocity = Vector2.ZERO
var contact_damage
var health

func _ready():
	GM.add_enemy(self)

func take_damage(amount):
	health -= amount
	emit_signal("damaged", health)
	if health < 0:
		contact_damage = 0
		GM.remove_enemy(self)

func get_hit(pulse):
	velocity += pulse.velocity.normalized() * pow(pulse.cur_knockback*600, 0.5)
	take_damage(pulse.deal_damage())
