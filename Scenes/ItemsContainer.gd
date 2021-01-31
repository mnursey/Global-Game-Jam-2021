extends HBoxContainer
onready var itemEntries = [$ItemEntry1, $ItemEntry2, $ItemEntry3]
onready var itemStats = [$ItemEntry1/Item1Stats, $ItemEntry2/Item2Stats, $ItemEntry3/Item3Stats]

# Called when the node enters the scene tree for the first time.
func _ready():
	get_random_items()


# TODO: Replace this functionality with some actual random stuff
# - Maybe use EffectBank? Not sure what that is yet.
func get_random_items():
	var items = [
		StatsUtil.generate_item(2, 0.3),
		StatsUtil.generate_item(2, 0.3),
		StatsUtil.generate_item(2, 0.3)
	]
	
	for i in range(len(itemEntries)):
		itemEntries[i].add_child(items[i])
		itemStats[i].text = items[i].get_node("EffectBank").to_string()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
