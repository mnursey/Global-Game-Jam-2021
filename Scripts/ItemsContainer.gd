extends HBoxContainer
onready var itemEntries = [$ItemEntry1, $ItemEntry2, $ItemEntry3]
onready var itemStats = [$ItemEntry1/Item1Stats, $ItemEntry2/Item2Stats, $ItemEntry3/Item3Stats]
onready var itemSelectionModal = $ItemSelectionModal

# Called when the node enters the scene tree for the first time.
func _ready():
	get_random_items()


func get_random_items():
	var items = [
		StatsUtil.generate_item(2, 0.3),
		StatsUtil.generate_item(2, 0.3),
		StatsUtil.generate_item(2, 0.3)
	]
	
	for i in range(len(itemEntries)):
		itemEntries[i].add_child(items[i])
		itemStats[i].text = items[i].get_node("EffectBank").to_string()
	
	
func _gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		get_owner().hide()
		get_tree().paused = false
