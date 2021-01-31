extends Node

const enemyNames = ['WalkingEnemy', 'FlyingEnemy', 'Walkie Enemy', 'FlyingRangedEnemy']
const doorNames = ['Door']

onready var enemies = []
onready var doors = []
onready var room_open = false

signal doors_opened

func _physics_process(delta):

	handle_doors()
	
	return
	
func _ready():
	find_enemies(self)
	find_doors(self)
	
	for N in enemies:
		print(N.name)
		
	for N in doors:
		print(N.name)
		
	return
	
func find_enemies(node):
	for N in node.get_children():
		
		for e in enemyNames:
			if e in N.name:
				enemies.append(N)
		
		if N.get_child_count() > 0:
			find_enemies(N)
	
func find_doors(node):
	for N in node.get_children():
		
		for d in doorNames:
			if d in N.name:
				doors.append(N)
		
		if N.get_child_count() > 0:
			find_doors(N)
	
func open_doors():
	for N in doors:
		N.open()
	emit_doors_opened_Signal()
	return
	
func handle_doors():
	if !room_open:
		var worked = true
		for N in enemies:
			if N and N.health > 0:
				worked = false
				
		if worked:
			open_doors()
			room_open = true



func emit_doors_opened_Signal():
	emit_signal("doors_opened")
