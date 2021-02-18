extends HBoxContainer
onready var itemEntries = [$ItemEntry1, $ItemEntry2, $ItemEntry3]
onready var itemStats = []# = [$ItemEntry1/Stats1, $ItemEntry2/Stats1, $ItemEntry3/Stats1]
onready var itemSelectionModal = $ItemSelectionModal

# Called when the node enters the scene tree for the first time.
#func _ready():
#	for entry in itemEntries:
#		itemStats.append(entry.get_children())
#		itemStats[-1].pop_front()
#	get_random_items()
#
#func clear_text():
#	for item in itemStats:
#		for stat in item:
#			stat.text = ""
#
#
#func get_random_items():
#	var items = [
#		StatsUtil.generate_item(4, 0.5),
#		StatsUtil.generate_item(4, 0.5),
#		StatsUtil.generate_item(4, 0.5)
#	]
#
#	clear_text()
#	for i in range(len(itemEntries)):
#		itemEntries[i].get_node("Item Visual").add_child(items[i])
#		items[i].position += Vector2(0, 45)
#		var effects = items[i].get_node("EffectBank").get_unpacked()
#		for j in range(len(effects)):
#			itemStats[i][j].text = effects[j].to_string()
#			if effects[j].cost > 0:
#				itemStats[i][j].add_color_override("font_color", Color(0.02, 0.9, 0.035))
#			else:
#				itemStats[i][j].add_color_override("font_color", Color(1, 0.18, 0.18))
#
#
#func on_item_clicked(event, id):
#	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
#		GM.player.apply_item(itemEntries[id].get_node("Item Visual/Item"))
#		get_owner().hide()
#		get_tree().paused = false
#
#
#func _on_ItemEntry1_gui_input(event):
#	on_item_clicked(event, 0)
#
#func _on_ItemEntry2_gui_input(event):
#	on_item_clicked(event, 1)
#
#func _on_ItemEntry3_gui_input(event):
#	on_item_clicked(event, 2)
	
	
