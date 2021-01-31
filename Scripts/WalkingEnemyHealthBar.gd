extends Control

onready var health_over = $HealthBarOver
onready var health_under = $HealthBarUnder
onready var update_tween = $UpdateTween


func _on_WalkingEnemy_damaged(health):
	print(health)
	health_over.value = health
	update_tween.interpolate_property(health_under, "value", health_under.value, health, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.2)
	update_tween.start()
