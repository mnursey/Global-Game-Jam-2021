extends Control

export var decay = 0.8  # How quickly the shaking stops [0, 1].
export var max_dist = 20  # Maximum hor/ver shake in pixels.
export var max_roll = 30  # Maximum rotation in radians (use sparingly).
export var color_fade_time = 0.5

var base_color

var base_pos
var trauma = 0.0  # Current shake strength.

func _ready():
	base_pos = rect_position
	base_color = modulate

func _process(delta):
	if trauma > 0:
		shake()
		trauma = max(trauma - trauma*decay*delta, 0)
		if trauma < 0.2: 
			trauma = 0
			rect_position = base_pos
			rect_rotation = 0
	
	if modulate != base_color:
		modulate = modulate.linear_interpolate(base_color, delta/color_fade_time)
		
func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)
	
func set_trauma(amount):
	trauma = max(trauma, amount)
	
func set_color(c):
	base_color = c
	modulate = c

func shake():
	var amount = trauma/(10+trauma)
	rect_position = base_pos + max_dist * amount * Vector2(randf()-0.5, randf()-0.5)
	rect_rotation = max_roll * amount * (randf()-0.5)

