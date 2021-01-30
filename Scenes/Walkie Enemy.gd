extends KinematicBody2D

var health = 100

onready var hurtbox = $EnemyHurtbox
onready var hitbox = $EnemyHitbox

func take_damage(amount):
	print(health)
	health -= amount
	if health < 0:
		queue_free()

func _on_EnemyHitbox_area_entered(area):
	pass # Replace with function body.



func _on_EnemyHurtbox_area_entered(area):
	var areas = hurtbox.get_overlapping_areas()
	for area in areas:
		if area.get_collision_mask() == 16:
			take_damage(area.deal_damage())
