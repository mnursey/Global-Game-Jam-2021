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
		
	func absorb(e:Effect, respect_caps = false):
		if stat_name == e.stat_name:
			cost += e.cost
			
			addend += e.addend
			multiplier.x *= e.multiplier.x 
			multiplier.y *= e.multiplier.y 
			multiplier.z *= e.multiplier.z 
			
			if respect_caps:
				for variant in range(3):
					var final = StatsUtil.default_stats[stat_name][variant] + addend[variant]
					if final < StatsUtil.caps[stat_name][0][variant]:
						addend[variant] = StatsUtil.caps[stat_name][0][variant] - StatsUtil.default_stats[stat_name][variant]
					elif final > StatsUtil.caps[stat_name][1][variant]:
						addend[variant] = StatsUtil.caps[stat_name][1][variant] - StatsUtil.default_stats[stat_name][variant]

		else:
			print("ERROR: Cannot merge effects due to incompatible stat types")
			
	func get_unpacked():
		var list = []
		for i in range(3):
			if addend[i] != 0: list.append(UnpackedEffect.new(stat_name, addend[i], i, '+'))
		for i in range(3):
			if multiplier[i] != 1: list.append(UnpackedEffect.new(stat_name, multiplier[i], i, '*'))

		return list
		
		
	func apply_to_base(b:Vector3):
		b += addend
		for variant in range(3):
			b[variant] = clamp(b[variant] * multiplier[variant], StatsUtil.caps[stat_name][0][variant], StatsUtil.caps[stat_name][1][variant])
		return b
		
	func _to_string():
		#breakpoint
		var s = ""
		var n = StatsUtil.string_names[stat_name]
		var suffixes = ["", "/sec", "/pulse"]
		
		for i in range(3):
			if addend[i] != 0: s += (n + suffixes[i] + (" +" if addend[i] > 0 else " -") + "%.2f\n") % abs(addend[i])
			if multiplier[i] != 1: s += (n + suffixes[i] + (" +" if multiplier[i] > 1 else " -") + "%d%%\n") % max(abs(multiplier[i]-1)*100, 1)
		return s	
		
	class UnpackedEffect:
		var stat_name
		var value
		var variant
		var op
		var cost
		
		func _init(n, val, v, o):
			stat_name = n
			value = val
			variant = v
			op = o
			cost = StatsUtil.appraise(stat_name, variant, op, value)
			
		func _to_string():
			var suffixes = ["", "/sec", "/pulse"]
			if op == '+':
				return (StatsUtil.string_names[stat_name] + suffixes[variant] + (" +" if value > 0 else " -") + "%.2f\n") % abs(value)
			else:
				return (StatsUtil.string_names[stat_name] + suffixes[variant] + (" +" if value > 1 else " -") + "%d%%\n") % (abs(value-1)*100)
			
		
		
		
				
		
var effects = {}

func absorb(eb):
	for e in eb.effects.values():
		if effects.has(e.stat_name):
			effects[e.stat_name].absorb(e)
		else:
			effects[e.stat_name] = Effect.new(e.stat_name, e.cost, e.addend, e.multiplier)
			
func add_effect(e):
	if effects.has(e.stat_name):
		effects[e.stat_name].absorb(e)
	else:
		effects[e.stat_name] = Effect.new(e.stat_name, e.cost, e.addend, e.multiplier)
		
		
func apply_to_base(stats_dict):
	var final_stats = stats_dict.duplicate()
	for stat in stats_dict.keys():
		if effects.has(stat):
			final_stats[stat] = effects[stat].apply_to_base(stats_dict[stat])
	return final_stats
	
func get_unpacked():
	var unpacked_effects = []
	for effect in effects.values():
		for e in effect.get_unpacked():
			unpacked_effects.append(e)
	unpacked_effects.sort_custom(self, "sort_by_cost_descending")
	return unpacked_effects
		
func _to_string():
	var s = ""
	for e in effects.values():
		s += e._to_string()
	return s
	
func get_primary_stat():
	var primary
	var max_cost = -INF
	for e in effects.values():
		if e.cost > max_cost:
			primary = e
			max_cost = e.cost
			
	if(StatsUtil.sprite_offsets.has(primary.stat_name)):
		return primary.stat_name	
	else:
		return 	StatsUtil.StatName.FIRE_RATE
	
	
static func print_test_bank():
	pass
	#print(generate_effect_bank(1, 1, 1, 0, ))
	
func sort_by_cost_descending(e1:Effect.UnpackedEffect, e2:Effect.UnpackedEffect):
	return e1.cost > e2.cost
			
			
static func generate_effect_bank(num_buffs, num_debuffs, abs_cost, cost_bias, pool):
	randomize()
	var new_effect
	var used_effects = []
	var bank = load('res://Scenes/EffectBank.tscn').instance().duplicate()
	
	var major_pool = []
	for s in pool:
		if s in StatsUtil.DPS_STATS: major_pool.append(s)

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
		if abs(budgets[i]) < 0.05:
			continue
			
		if i == 0 and randf() < (0.2 + num_buffs/10):
			new_effect = generate_random_effect(budgets[i], major_pool, used_effects)
		else:
			new_effect = generate_random_effect(budgets[i], pool, used_effects)
		
		used_effects.append(new_effect)
		bank.add_effect(new_effect)
		
		#Account for overdraft due to integer stat rounding
		cost_bias += budgets[i] - new_effect.cost 
			
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
		if abs(budgets[i]) < 0.05:
			continue
			
		new_effect = generate_random_effect(budgets[i], pool, used_effects)
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
	var stat_variant = StatsUtil.choose_weighted([0, 1, 2], StatsUtil.variant_weights[stat_name])
	var stat_op = StatsUtil.choose_weighted(['+', '*'], [3, 1])
	var stat_cost = stat_cost_vector[stat_variant]
	effect_vector[stat_variant] = 1
	
	if stat_cost == 0 or (stat_name in StatsUtil.SYMMETRICAL_STATS and sign(stat_cost) != sign(cost)):
		return generate_random_effect(cost, stats_pool, forbidden_effects)

	#print(StatsUtil.string_names[stat_name] + " " + stat_op)
	if stat_op == '+':
		var boost = StatsUtil.purchase(stat_name, stat_variant, '+', cost)
		effect_vector *= boost
		effect = Effect.new(stat_name, boost*stat_cost, effect_vector, Vector3.ONE)
	else:
		effect_vector *= StatsUtil.purchase(stat_name, stat_variant, '*', cost) - 1
		effect_vector += Vector3.ONE
		effect = Effect.new(stat_name, cost, Vector3.ZERO, effect_vector)
			
	for f in forbidden_effects:
		if effect.equals(f):
			# It will work eventually
			return generate_random_effect(cost, stats_pool, forbidden_effects)
			
	return effect
	
	

	
	
		
