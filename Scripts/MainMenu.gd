extends Control

export(String, FILE, "*.tscn") var next_world

func _on_StartButton_pressed():
	get_tree().change_scene(next_world)


func _on_QuitButton_pressed():
	get_tree().quit()
