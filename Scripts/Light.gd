extends Light2D

enum LightEffect{
	FLICKER,
	PULSE,
	SWING,
	ROTATE,
	RAVE
}

export (int, FLAGS, "Flicker", "Pulse", "Swing", "Rotate", "Rave") var effects
var timer = 0

var base_color
export (Color) var target_color

var base_max_energy
var target_max_energy
var cur_max_energy

export var flicker_amount = 0.03
export var pulse_speed = 1.5
export var pulse_amount = 0.6
export var swing_angle = 15
export var swing_speed = 1.0
export var rotation_speed = 60



func _ready():
	#timer = randf()*10
	base_color = color
	target_color = base_color
	
	base_max_energy = energy
	target_max_energy = base_max_energy
	cur_max_energy = base_max_energy
	
func _process(delta):
	if effects != 0:
		timer += delta
		
	if cur_max_energy < target_max_energy:
		cur_max_energy = min(cur_max_energy + 0.04, target_max_energy)
	elif cur_max_energy > target_max_energy:
		cur_max_energy = max(cur_max_energy - 0.04, target_max_energy)
	energy = cur_max_energy
		
	if color != target_color:
		color = color.linear_interpolate(target_color, 0.04)

	var rotation_override = false
	
	if effects & (1 << LightEffect.FLICKER):
		var r = randf()
		if r < abs(flicker_amount):
			energy = cur_max_energy * r / abs(flicker_amount)
		else:
			energy = cur_max_energy if flicker_amount > 0 else 0
	if effects & (1 << LightEffect.PULSE):
		energy = energy * ((1 - pulse_amount/2) + (pulse_amount/2)*sin(timer*pulse_speed))
	if effects & (1 << LightEffect.SWING):
		rotation_degrees = swing_angle*sin(timer*swing_speed)
		rotation_override = true
	if effects & (1 << LightEffect.ROTATE):
		rotation_degrees += delta*rotation_speed
		rotation_override = true
	if effects & (1 << LightEffect.RAVE):
		color.v = 1
		color.s = 1
		color.h = fmod(timer + abs(global_position.x)/100, 1.0) 
	
		
	if not rotation_override:
		rotation_degrees = 0
		
func set_brightness(b):
	target_max_energy = base_max_energy * b
	energy = target_max_energy

func fade_to_brightness(b):
	target_max_energy = base_max_energy * b

func fade_to_color(c):
	target_color = c
	
func set_color(c):
	target_color = c
	color = c
	
func set_effect(e, state):
	effects ^= (-int(state) ^ effects) & (1 << int(e)) 
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
