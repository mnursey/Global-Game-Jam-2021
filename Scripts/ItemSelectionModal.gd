extends Popup


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var ModalTimer = $ModalTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_RoomController_doors_opened():
	ModalTimer.connect("timeout", self, "_on_timer_timeout") 
	ModalTimer.start()


func _on_timer_timeout():
	self.popup_centered()
	self.rect_position = GM.player.get_global_position() - (self.rect_size / 4.5)
	#get_tree().paused = true
