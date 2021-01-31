extends Control

onready var health_over = $HealthBarOver
onready var health_under = $HealthBarUnder
onready var update_tween = $UpdateTween

func _on_Player_health_updated(health):
	health_over.value = health
	update_tween.interpolate_property(health_under, "value", health_under.value, health, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.2)
	update_tween.start()


func _on_Player_max_health_updated(max_health):
	health_over.max_value = max_health
	health_under.max_value = max_health
	

