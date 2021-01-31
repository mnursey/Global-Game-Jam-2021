extends KinematicBody2D

var velocity = Vector2.ZERO
var health

func _ready():
	GM.add_enemy(self)

func take_damage(amount):
	health -= amount
	if health < 0:
		GM.remove_enemy(self)
		queue_free()

func get_hit(pulse):
	velocity += pulse.velocity.normalized * pulse.cur_knockback
	take_damage(pulse.deal_damage())
