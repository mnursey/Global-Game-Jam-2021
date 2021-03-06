extends Camera2D

export var mouse_tracking = 0.0
export var decay = 0.8  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var player # Assign the node this camera will follow.


var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

onready var noise = OpenSimplexNoise.new()
var noise_y = 0

func _ready():
	player = get_parent()
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 3

func _process(delta):
	if player:
		global_position = player.global_position + player.mouse_vector*mouse_tracking
	if trauma:
		trauma = max(trauma - trauma*decay*delta, 0)
		shake()
		
func add_trauma(amount):
	trauma = trauma + amount
	
func set_trauma(amount):
	trauma = max(trauma, amount)

func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)

