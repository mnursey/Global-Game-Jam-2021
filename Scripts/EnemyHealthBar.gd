extends Control

onready var health_over = $HealthBarOver
onready var health_under = $HealthBarUnder
var interp_delay 

func init(max_health):
	health_over.max_value = max_health
	health_over.value = max_health
	health_under.max_value = max_health
	health_under.value = max_health

func update_health(new_health):
	health_over.value = new_health
	#update_tween.interpolate_property(health_under, "value", health_under.value, health, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.2)
	#update_tween.start()
	
func _process(delta):
	if health_under.value > health_over.value:
		if interp_delay > 0:
			interp_delay -= delta
		else:
			health_under.value = max(health_over.value, health_under.value - health_under.max_value*delta)
	else:
		interp_delay = 0.3
