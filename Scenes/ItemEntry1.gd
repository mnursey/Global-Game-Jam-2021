extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		print(get_children()[1])
		get_owner().hide()
		get_tree().paused = false
