extends Node

const enemyNames = ['WalkingEnemy', 'FlyingEnemy', 'Walkie Enemy', 'FlyingRangedEnemy']

onready var UpgradeStation = $UpgradeStation

var enemies = []
var doors = []
var lights = []

export (bool) var starting_room = false
var room_open = true
var room_cleared = false

signal doors_opened
	
func _ready():
	find_enemies(self)
	find_doors(self)
	find_lights()

	if starting_room:
		on_room_entered()
		close_doors()
	else:	
		dim_lights()
		open_doors()
		
	
func _physics_process(delta):
	handle_doors()
	
func on_room_entered():
	if GM.active_room != self:
		GM.set_active_room(self)
		brighten_lights()
		if not room_cleared:
			apply_difficulty(GM.rooms_cleared/2.0)
			close_doors()
	
func find_enemies(node):
	for N in get_node("Enemies").get_children():
		enemies.append(N)
	
func find_doors(node):
	for N in get_node("Doors").get_children():
		doors.append(N)
			
func find_lights():
	if get_node("Lights"):
		for light in get_node("Lights").get_children():
			lights.append(light)

func on_room_cleared():
	GM.player.set_max_health()
	GM.rooms_cleared += 1
	open_doors()
	emit_doors_opened_Signal()
	flash_lights()
	UpgradeStation.set_active(true)
	room_cleared = true
	
	
func apply_difficulty(difficulty):
	var weights = [1,0,0,0]
	for variant in range(4):
		weights[variant] = variant_weight_curve(variant, difficulty)
		
	print("Difficulty = "+ str(difficulty))
	print(weights)
	for e in enemies:
		e.set_variant(StatsUtil.choose_weighted([0, 1, 2, 3], weights))
	
func variant_weight_curve(v, d): #This somehow took two hours to make
	var x = d - v
	if x < -1:
		return 0
	elif x < 1:
		var w = (1.0 + x)/2 
		return 2*(3*w*w - 2*w*w*w)
	else:
		return 2.0*((x + 1)/x - 1.0)
	
	
func open_doors():
	room_open = true
	for N in doors:
		N.open()
	
func close_doors():
	room_open = false
	for N in doors:
		N.close()
	
func handle_doors():
	if !room_open:
		for N in enemies:
			if N and N.health > 0:
				return false	
		on_room_cleared()

func brighten_lights():
	for light in lights:
		light.fade_to_brightness(1)
		
func dim_lights():
	for light in lights:
		light.fade_to_brightness(0.3)
		
func turn_off_lights():
	for light in lights:
		light.fade_to_brightness(0)
		
func flash_lights(c = Color.green):
		for light in lights:
			light.color = c
			light.energy *= 1.5

func emit_doors_opened_Signal():
	emit_signal("doors_opened")
