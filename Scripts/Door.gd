extends Node

onready var anim_sprite = $AnimatedSprite

func _ready():
	close()
	return

func open():
	
	anim_sprite.animation = "off"
	
	return
	
func close():
	
	anim_sprite.animation = "on"
	
	return
