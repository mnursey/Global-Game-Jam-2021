extends Control

var item_entries = []
	
static func generate_new_menu(items):
	var menu = load('res://Scenes/ItemSelectionMenu.tscn').instance().duplicate()
	menu.visible = false
	var items_container = menu.get_node('VBoxContainer/ItemsContainer')
	
	for i in range(len(items)):
		var entry = VBoxContainer.new()
		entry.connect('gui_input', menu, '_on_ItemEntry' + str(i+1) + '_gui_input')
		entry.rect_min_size.x = items_container.rect_size.x/3
		entry.mouse_filter = Control.MOUSE_FILTER_STOP
		entry.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var item_visual = VBoxContainer.new()
		item_visual.rect_min_size = Vector2(0, 90)
		item_visual.rect_position = Vector2(0, 93)
		items[i].scale = Vector2(1.9, 1.9)
		item_visual.add_child(items[i])
		items[i].position = Vector2(0, 45)
		entry.add_child(item_visual)
		
		var effects = items[i].get_node("EffectBank").get_unpacked()
		for j in range(len(effects)):
			var stat_label = Label.new()
			stat_label.autowrap = true
			stat_label.align = Label.ALIGN_CENTER
			stat_label.text = effects[j].to_string()
			if effects[j].cost > 0:
				stat_label.add_color_override("font_color", Color(0.02, 0.9, 0.035))
			else:
				stat_label.add_color_override("font_color", Color(1, 0.18, 0.18))
			entry.add_child(stat_label)
				
		items_container.add_child(entry)
		menu.item_entries.append(entry)
		
	return menu
				
func on_item_clicked(event, id):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		GM.player.apply_item(item_entries[id].get_child(0).get_child(0))
		visible = false
		var station = get_parent().get_parent().get_parent()
		if station: station.set_active(false)


func _on_ItemEntry1_gui_input(event):
	on_item_clicked(event, 0)
	
func _on_ItemEntry2_gui_input(event):
	on_item_clicked(event, 1)

func _on_ItemEntry3_gui_input(event):
	on_item_clicked(event, 2)

#self.rect_position = GM.player.get_global_position() - (self.rect_size / 4.5)

	
#func clear_text():
#	for item in itemStats:
#		for stat in item:
#			stat.text = ""


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


