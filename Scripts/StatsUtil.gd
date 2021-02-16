class_name StatsUtil

const HOMING_RANGE = 300
const MIN_SUCC_RANGE = 50

enum StatName {
	#Player Stats
	MAX_HEALTH,
	JUMPS,
	DASHES,
	MOVE_SPEED,
	DASH_SPEED,
	#AST Stats
	FIRE_RATE,
	DISTANCE,
	LIFETIME,
	SIZE,
	DAMAGE,
	SPEED,
	SCATTER,
	KNOCKBACK,
	SUCTION,
	HOMING,
	GRAVITY,
	SUBPULSES,
	SUBPULSE_DELAY,
	SPLIT_CHANCE
}

const PLAYER_STATS = [StatName.MAX_HEALTH, StatName.JUMPS, StatName.DASHES, StatName.MOVE_SPEED, StatName.DASH_SPEED]
const AST_STATS = [StatName.FIRE_RATE, StatName.DISTANCE, StatName.LIFETIME, StatName.SIZE, StatName.DAMAGE, StatName.SPEED, StatName.SCATTER, StatName.KNOCKBACK, StatName.SUCTION, StatName.HOMING, StatName.GRAVITY, StatName.SUBPULSES, StatName.SUBPULSE_DELAY, StatName.SPLIT_CHANCE]
const DPS_STATS = [StatName.FIRE_RATE, StatName.DAMAGE, StatName.SUBPULSES]
const INTEGER_STATS = [StatName.MAX_HEALTH, StatName.JUMPS, StatName.DASHES, StatName.MOVE_SPEED, StatName.DASH_SPEED, StatName.DISTANCE, StatName.SPEED, StatName.KNOCKBACK, StatName.SUCTION, StatName.HOMING, StatName.GRAVITY, StatName.SUBPULSES, StatName.SPLIT_CHANCE]
const SYMMETRICAL_STATS = [StatName.GRAVITY] # Stats that have the same cost whether positive or negative


const default_stats = {
	#Player 
	StatName.MAX_HEALTH:	Vector3(100, 0, 0),
	StatName.JUMPS:			Vector3(1, 0, 0),
	StatName.DASHES:		Vector3(1, 0, 0),
	StatName.MOVE_SPEED:	Vector3(160, 0, 0),
	StatName.DASH_SPEED:	Vector3(320, 0, 0),
	#AST
	StatName.FIRE_RATE: 	Vector3(2.0, 0, 0),
	StatName.DISTANCE: 		Vector3(10.0, 0, 0),
	StatName.LIFETIME: 		Vector3(0.5, 0, 0),
	StatName.SIZE: 			Vector3(0.7, 0, 0),
	StatName.DAMAGE: 		Vector3(6.0, 0, 0),
	StatName.SPEED: 		Vector3(200.0, 0, 0),
	StatName.SCATTER:		Vector3(10.0, 0, 0),
	StatName.KNOCKBACK: 	Vector3(20.0, 0, 0),
	StatName.SUCTION: 		Vector3(0, 0, 0),
	StatName.HOMING: 		Vector3(0, 0, 0),
	StatName.GRAVITY: 		Vector3(0.0, 0, 0),
	StatName.SUBPULSES:		Vector3(1, 0, 0),
	StatName.SUBPULSE_DELAY:Vector3(0.5, 0, 0),
	StatName.SPLIT_CHANCE: 	Vector3(1.0, 0, 0)
}

const doubling_costs = {
	StatName.MAX_HEALTH:	6,
	StatName.JUMPS:			6,
	StatName.DASHES:		6,
	StatName.MOVE_SPEED:	4,
	StatName.DASH_SPEED:	4,
	#AST
	StatName.FIRE_RATE: 	10,
	StatName.DISTANCE: 		4,
	StatName.LIFETIME: 		6,
	StatName.SIZE: 			4,
	StatName.DAMAGE: 		10,
	StatName.SPEED: 		6,
	StatName.SCATTER:		4,
	StatName.KNOCKBACK: 	6,
	StatName.SUCTION: 		6,
	StatName.HOMING: 		8,
	StatName.GRAVITY: 		4,
	StatName.SUBPULSES:		10,
	StatName.SUBPULSE_DELAY:4,
	StatName.SPLIT_CHANCE: 	8
}

const LN_2 = 0.693
const costs = {
	#Player (TEMP VALUES)
	StatName.MAX_HEALTH:	Vector3(0.05, 0, 0),
	StatName.JUMPS:			Vector3(2, 0, 0),
	StatName.DASHES:		Vector3(2, 0, 0),
	StatName.MOVE_SPEED:	Vector3(0.05, 0, 0),
	StatName.DASH_SPEED:	Vector3(0.05, 0, 0),
	#AST
	StatName.FIRE_RATE: 	Vector3(2, 0, 0),
	StatName.DISTANCE: 		Vector3(0.2, 0, 0.4),
	StatName.LIFETIME: 		Vector3(2, 0, 3),
	StatName.SIZE: 			Vector3(8, 6, 12),
	StatName.DAMAGE: 		Vector3(1, 0.5, 1),
	StatName.SPEED: 		Vector3(0.02, 0.02, 0.02),
	StatName.SCATTER:		Vector3(-0.05, 0, -0.05),
	StatName.KNOCKBACK: 	Vector3(0.05,0.02,0.03),
	StatName.SUCTION: 		Vector3(0.02,0.01,0.02),
	StatName.HOMING: 		Vector3(0.05, 0.03, 0.05),
	StatName.GRAVITY: 		Vector3(-0.01, -0.005, -0.01),
	StatName.SUBPULSES:		Vector3(3, 0, 0),
	StatName.SUBPULSE_DELAY:Vector3(-10, 0, -15),
	StatName.SPLIT_CHANCE: 	Vector3(1, 0, 1)
}

#Caps are for the sake of the framerate and quality of life ONLY
const caps = {
	#Player (TEMP VALUES)
	StatName.MAX_HEALTH:	[Vector3(1, 0, 0), Vector3(INF, 0, 0)],
	StatName.JUMPS:			[Vector3(0, 0, 0), Vector3(INF, 0, 0)],
	StatName.DASHES:		[Vector3(0, 0, 0), Vector3(INF, 0, 0)],
	StatName.MOVE_SPEED:	[Vector3(50, 0, 0), Vector3(INF, 0, 0)],
	StatName.DASH_SPEED:	[Vector3(50, 0, 0), Vector3(INF, 0, 0)],
	#AST
	StatName.FIRE_RATE: 	[Vector3(0.5, 0, 0), Vector3(INF, 0, 0)],
	StatName.DISTANCE: 		[Vector3(-50, 0, -25), Vector3(50, 0, 25)],
	StatName.LIFETIME: 		[Vector3(0.1, 0, -5), Vector3(10, 0, 5)],
	StatName.SIZE: 			[Vector3(0.2, -10, -1), Vector3(10, +10, +5)],
	StatName.DAMAGE: 		[Vector3(1, -50, -50), Vector3(INF, INF, INF)],
	StatName.SPEED: 		[Vector3(-INF, -INF, -INF), Vector3(INF, INF, INF)],
	StatName.SCATTER:		[Vector3(0, 0, -360), Vector3(360, 0, 360)],
	StatName.KNOCKBACK: 	[Vector3(-100, -INF, -INF), Vector3(INF, INF, INF)],
	StatName.SUCTION: 		[Vector3(-300, -INF, -INF), Vector3(INF, INF, INF)],
	StatName.HOMING: 		[Vector3(-50, -INF, -INF), Vector3(INF, INF, INF)],
	StatName.GRAVITY: 		[Vector3(-INF, -INF, -INF), Vector3(INF, INF, INF)],
	StatName.SUBPULSES:		[Vector3(0, 0, 0), Vector3(30, 0, 0)],
	StatName.SUBPULSE_DELAY:[Vector3(0, 0, -1), Vector3(1, 0, 1)],
	StatName.SPLIT_CHANCE: 	[Vector3(0, 0, -10), Vector3(50, 0, 10)],
}

#Min/Max stat values attainable by a pulse after all cumulative effects
const cumulative_caps = {
	StatName.DISTANCE: 		[-200, 200],
	StatName.LIFETIME: 		[10, 10],
	StatName.SIZE: 			[0.2, 20],
	StatName.DAMAGE: 		[1, INF],
	StatName.SPEED: 		[-5000, 5000],
	StatName.SCATTER:		[0, 360],
	StatName.KNOCKBACK: 	[1, 1],
	StatName.SUCTION: 		[1, 1],
	StatName.HOMING: 		[-50, INF],
	StatName.GRAVITY: 		[-INF, INF],
	StatName.SUBPULSES:		[0, 30],
	StatName.SUBPULSE_DELAY:[0, 1],
	StatName.SPLIT_CHANCE: 	[0, 20]
}

const variant_weights = {
	#Player
	StatName.MAX_HEALTH:	[1, 0, 0],
	StatName.JUMPS:			[1, 0, 0],
	StatName.DASHES:		[1, 0, 0],
	StatName.MOVE_SPEED:	[1, 0, 0],
	StatName.DASH_SPEED:	[1, 0, 0],
	#AST
	StatName.FIRE_RATE: 	[1, 0, 0],
	StatName.DISTANCE: 		[1.5, 0, 1],
	StatName.LIFETIME: 		[1.5, 0, 1],
	StatName.SIZE: 			[2, 1, 1],
	StatName.DAMAGE: 		[2, 1, 1],
	StatName.SPEED: 		[2, 1, 1],
	StatName.SCATTER:		[2, 0, 1],
	StatName.KNOCKBACK: 	[2, 0.5, 1],
	StatName.SUCTION: 		[2, 1, 1],
	StatName.HOMING: 		[2, 1, 1],
	StatName.GRAVITY: 		[1, 0.5, 1],
	StatName.SUBPULSES:		[1, 0, 0],
	StatName.SUBPULSE_DELAY:[1, 0, 1],
	StatName.SPLIT_CHANCE: 	[2, 0, 1],
}

const string_names = {
	#Player
	StatName.MAX_HEALTH:	"Max Health",
	StatName.JUMPS:			"Jumps",
	StatName.DASHES:		"Dashes",
	StatName.MOVE_SPEED:	"Move Speed",
	StatName.DASH_SPEED:	"Dash Speed",
	#AST
	StatName.FIRE_RATE: 	"Fire Rate",
	StatName.DISTANCE: 		"Pulse Distance",
	StatName.LIFETIME: 		"Pulse Lifetime",
	StatName.SIZE: 			"Pulse Size",
	StatName.DAMAGE: 		"Pulse Damage",
	StatName.SPEED: 		"Pulse Speed",
	StatName.SCATTER:		"Pulse Scatter",
	StatName.KNOCKBACK: 	"Pulse Knockback",
	StatName.SUCTION: 		"Pulse Suction",
	StatName.HOMING: 		"Pulse Homing",
	StatName.GRAVITY: 		"Pulse Gravity",
	StatName.SUBPULSES:		"Subpulses",
	StatName.SUBPULSE_DELAY:"Subpulse Delay",
	StatName.SPLIT_CHANCE: 	"Pulse Split Chance"
}

const sprite_offsets = {
	#Player
	StatName.MAX_HEALTH:	Vector2(2, 0),
	StatName.JUMPS:			Vector2(3, 2),
	StatName.DASHES:		Vector2(3, 2),
	StatName.MOVE_SPEED:	Vector2(3, 2),
	#AST
	StatName.FIRE_RATE: 	Vector2(0, 0),
	StatName.DISTANCE: 		Vector2(1, 0),
	StatName.LIFETIME: 		Vector2(0, 1),
	StatName.SIZE: 			Vector2(3, 2),
	StatName.DAMAGE: 		Vector2(3, 0),
	StatName.SPEED: 		Vector2(1, 0),
	StatName.SCATTER:		Vector2(2, 2),
	StatName.KNOCKBACK: 	Vector2(3, 1),
	StatName.SUCTION: 		Vector2(3, 3),
	StatName.HOMING: 		Vector2(2, 2),
	StatName.GRAVITY: 		Vector2(3, 3),
	StatName.SUBPULSES:		Vector2(1, 2),
	StatName.SUBPULSE_DELAY:Vector2(0, 0),
	StatName.SPLIT_CHANCE: 	Vector2(1, 1),
}

static func purchase(stat, variant, op, cost):
	var amount
	if op == '+':
		amount = float(cost)/costs[stat][variant]
		if stat in INTEGER_STATS: amount = round(amount) if abs(amount) > 0.5 else sign(amount)
		if stat in SYMMETRICAL_STATS: amount *= sign(randf()-0.5)
	else:
			amount = pow(2, float(cost)*sign(costs[stat][variant])/doubling_costs[stat])
		
	return amount
	
static func appraise(stat, variant, op, amount):
	var cost
	if stat in SYMMETRICAL_STATS: amount = abs(amount)
	if op == '+':
		cost = float(amount)*costs[stat][variant]
	else:
		cost = log(float(amount))*LN_2*doubling_costs[stat]*sign(costs[stat][variant])
	return cost
		

static func generate_item(magnitude, quality):
	randomize()
	var cost = magnitude*(0.75 + randf()/2)
	var num_fx = int(min(2 + cost*randf()*2, 6))
	var num_debuffs = int(num_fx/2)
	var num_buffs = num_fx - num_debuffs
	
	var item = load('res://Scenes/Item.tscn').instance().duplicate()
	var bank = load('res://Scenes/EffectBank.tscn').instance().generate_effect_bank(num_buffs, num_debuffs, cost, cost*quality, StatName.values().duplicate())
	
	item.get_node('Sprite').region_rect = Rect2(sprite_offsets[bank.get_primary_stat()]*8, Vector2(8, 8))
	item.get_node('EffectBank').absorb(bank) 
	return item
	
	


static func choose_random(values):
	var weights = []
	for _i in range(values.size()):
		weights.append(1)
		
	return choose_weighted(values, weights)
	
static func choose_weighted(values, weights):
	var cumu_weights = [weights[0]]
	for i in range(1, weights.size()):
		cumu_weights.append(weights[i] + cumu_weights[i-1])
	
	var rand = randf()*cumu_weights[cumu_weights.size()-1]
	for i in range(cumu_weights.size()):
		if rand < cumu_weights[i]:
			return values[i]
		
	

	
		
	

