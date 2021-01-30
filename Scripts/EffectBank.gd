extends Node

class Effect:
	var stat_name
	var cost : float
	var addend : Vector3
	var multiplier : Vector3

	func _init(n, c:float, a:Vector3, m:Vector3):
		stat_name = n
		cost = c
		addend = a
		multiplier = m
		
	func equals(e:Effect) -> bool:
		#True if both modify the same stat in the same way (they share an overlapping point in 3D effect-space)
		return e.stat_name == stat_name and ((addend.dot(e.addend) != 0 or (multiplier-Vector3.ONE).dot((e.multiplier-Vector3.ONE)) != 0))
		
	func absorb(e:Effect):
		if stat_name == e.stat_name:
			cost += e.cost
			addend += e.addend
			multiplier.x *= e.multiplier.x 
			multiplier.y *= e.multiplier.y 
			multiplier.z *= e.multiplier.z 
		else:
			print("ERROR: Cannot merge effects due to incompatible stat types")
		
	func apply_to_base(b:Vector3):
		b += addend
		b.x *= multiplier.x
		b.y *= multiplier.y
		b.z *= multiplier.z
		return b
		
	func _to_string():
		#breakpoint
		var s = ""
		var n = StatsUtil.string_names[stat_name]
		
		if addend.x != 0: s += (n + (" +" if addend.x > 0 else " -") + "%.2f\n") % abs(addend.x)
		if multiplier.x != 1: s += (n + (" +" if multiplier.x > 1 else " -") + "%d%%\n") % (abs(multiplier.x-1)*100)
		
		if addend.y != 0: s += (n + "/sec" + (" +" if addend.y > 0 else " -") + "%.2f\n") % abs(addend.y)
		if multiplier.y != 1: s += (n + "/sec" + (" +" if multiplier.y > 1 else " -") + "%d%%\n") % (abs(multiplier.y-1)*100)
		
		if addend.z != 0: s += (n + "/pulse" + (" +" if addend.z > 0 else " -") + "%.2f\n") % abs(addend.z)
		if multiplier.z != 1: s += (n + "/pulse" + (" +" if multiplier.z > 1 else " -") + "%d%%\n") % (abs(multiplier.z-1)*100)
		return s			
		
export var effects = {}

func absorb(eb):
	for e in eb.effects.values():
		if effects.has(e.stat_name):
			effects[e.stat_name].absorb(e)
		else:
			effects[e.stat_name] = e
			
func add_effect(e):
	if effects.has(e.stat_name):
		effects[e.stat_name].absorb(e)
	else:
		effects[e.stat_name] = e
		
		
func apply_to_base(stats_dict):
	var final_stats = stats_dict.duplicate()
	for stat in stats_dict.keys():
		if effects.has(stat):
			final_stats[stat] = effects[stat].apply_to_base(stats_dict[stat])
	return final_stats
				
func _to_string():
	var s = ""
	for e in effects.values():
		s += e._to_string()
	return s
	
static func print_test_bank():
	print(generate_effect_bank(1, 1, 1, 0))
			
			
static func generate_effect_bank(num_buffs, num_debuffs, abs_cost, cost_bias):
	randomize()
	var new_effect
	var used_effects = []
	var bank = load('res://Scenes/EffectBank.tscn').instance().duplicate()

	#breakpoint
	var remaining_cost = abs_cost + cost_bias
	var budgets = [0, 1]
	for _i in range(num_buffs-1):
		budgets.append(randf())
	budgets.sort()
	for i in range(budgets.size()-1):
		budgets[i] = (budgets[i+1] - budgets[i]) * remaining_cost
	budgets.pop_back()
	budgets.sort()
	budgets.invert()
	
	for i in range(num_buffs):
		if i == 0 and randf() < 0.6:
			new_effect = generate_random_effect(budgets[i], StatsUtil.MAJOR_STATS.duplicate(), used_effects)
		else:
			new_effect = generate_random_effect(budgets[i], StatsUtil.StatName.values().duplicate(), used_effects)
		
		used_effects.append(new_effect)
		bank.add_effect(new_effect)
		
		#Account for overdraft due to integer stat rounding
		cost_bias += budgets[i] - new_effect.cost 
			
	#breakpoint
	remaining_cost = abs_cost - cost_bias
	budgets = [0, 1]
	for _i in range(num_debuffs-1):
		budgets.append(randf())
	budgets.sort()
	for i in range(budgets.size()-1):
		budgets[i] = -(budgets[i+1] - budgets[i]) * remaining_cost
	budgets.pop_back()
	budgets.sort()
	
	for i in range(num_debuffs):
		new_effect = generate_random_effect(budgets[i], StatsUtil.StatName.values().duplicate(), used_effects)
		used_effects.append(new_effect)
		bank.add_effect(new_effect)
		
		var overdraft = budgets[i] - new_effect.cost 
		if overdraft > -0.01 or i == num_debuffs-1:
			pass
		elif overdraft > budgets[i+1]:
			budgets[i+1] -= overdraft
		else:
			i += 1 #Skip next effect
		
	return bank
		
static func generate_random_effect(cost, stats_pool, forbidden_effects = []) -> Effect:
	var effect_vector = Vector3.ZERO
	var effect;
	
	var stat_name = StatsUtil.choose_random(stats_pool)
	var stat_cost_vector = StatsUtil.costs[stat_name]
	
	var variant_weights = [2, 1, 1]
	if stat_cost_vector.y == 0:
		variant_weights[1] = 0
	if stat_cost_vector.z == 0:
		variant_weights[2] = 0
	
	var stat_variant = StatsUtil.choose_weighted(['x', 'y', 'z'], variant_weights)
	var stat_op = StatsUtil.choose_weighted(['+', '*'], [3, 1])
	
	var stat_cost
	if stat_variant == 'x':
		stat_cost = stat_cost_vector.x
		effect_vector.x = 1
	elif stat_variant == 'y':
		stat_cost = stat_cost_vector.y
		effect_vector.y = 1
	else: # stat_variant == 'z'
		stat_cost = stat_cost_vector.z
		effect_vector.z = 1
		
	#Failsafe
	if stat_cost == 0: #invalid choice
		return generate_random_effect(cost, stats_pool, forbidden_effects)
		
	print(StatsUtil.string_names[stat_name] + " " + stat_op)
	if stat_op == '+':
		var boost = cost/stat_cost
		if stat_name in StatsUtil.INTEGER_STATS:
			boost = round(boost) if abs(boost) > 0.5 else sign(boost)
		effect_vector *= boost
		effect = Effect.new(stat_name, boost*stat_cost, effect_vector, Vector3.ONE)
	else:
		effect_vector *= (pow(2, float(cost)/StatsUtil.DOUBLING_COST) - 1)
		effect_vector += Vector3.ONE
		effect = Effect.new(stat_name, cost, Vector3.ZERO, effect_vector)
			
	for f in forbidden_effects:
		if effect.equals(f):
			# It will work eventually
			return generate_random_effect(cost, stats_pool, forbidden_effects)
			
	return effect
	
	

	
	
		
