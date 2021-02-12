extends VBoxContainer

func _gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		GM.player.apply_item(get_node("Item Visual/Item"))
		get_owner().hide()
		get_tree().paused = false


func _on_ItemEntry1_gui_input(event):
	pass # Replace with function body.
