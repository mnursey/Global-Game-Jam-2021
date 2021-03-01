extends Node2D

onready var anim_sprite = $AnimatedSprite
onready var collision_box = $StaticBody2D
onready var detector = $Area2D
onready var room_controller = $"../.."
export (int, "Right", "Left", "Up", "Down") var inward_direction = 0

const directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]

func open():
	anim_sprite.animation = "off"
	anim_sprite.light_mask = 1
	collision_box.collision_layer = 0
	collision_box.collision_mask = 0
	
func close():
	anim_sprite.animation = "on"
	anim_sprite.light_mask = 2
	collision_box.collision_layer = 1
	collision_box.collision_mask = 1

func _on_Area2D_body_exited(body):
	if body.is_in_group("Player"):
		var disp = body.global_position - global_position
		if disp.dot(directions[inward_direction]) > 0:
			room_controller.on_room_entered()

		

		
