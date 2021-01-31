extends Area2D

var velocity = Vector2.ZERO
var damage = 0

func _physics_process(delta):
	position += velocity*delta

func _on_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		body.take_damage(damage)
	elif not body.is_in_group("Enemy"):
		queue_free()

