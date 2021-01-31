extends Node

onready var anim_sprite = $AnimatedSprite
onready var collision_box = $StaticBody2D/CollisionShape2D

func _ready():
	close()
	return

func open():
	
	anim_sprite.animation = "off"
	collision_box.set_disabled(true)
	
	return
	
func close():
	
	anim_sprite.animation = "on"
	collision_box.set_disabled(false)
	
	return
