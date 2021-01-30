extends Label

var StartingScene = "res://Scenes/DemoLevel.tscn"

func _gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		get_tree().change_scene(StartingScene)
