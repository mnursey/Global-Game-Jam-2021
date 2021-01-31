extends Node2D

var wander_range = 32

onready var start_position = global_position
onready var target_position = global_position

onready var wander_timer = $WanderTimer

func _ready():
	update_target_position()

func update_target_position():
	var target_vector = Vector2(rand_range(-wander_range, wander_range), rand_range(-wander_range, wander_range))
	target_position = start_position + target_vector

func get_time_left():
	return wander_timer.time_left
	
func start_wander_timer(duration):
	wander_timer.start(duration)

func _on_Timer_timeout():
	update_target_position()

func _on_WanderTimer_timeout():
	update_target_position()
