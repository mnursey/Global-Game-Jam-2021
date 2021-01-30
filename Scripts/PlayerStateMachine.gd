extends "res://Scripts/StateMachine.gd"



func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("dash")
	add_state("dead")
	call_deferred("set_state", states.idle)


		
func _state_logic(delta):
	parent.apply_gravity(delta)
	parent.move()
	parent.apply_movement()
	#get_input()
	print(jumps)
	
func _get_transition(delta):
	match state:
		states.idle:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				
				elif parent.velocity.y >= 0:
					return states.fall
			elif abs(parent.velocity.x) > 20:
				return states.run
		states.run:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				
				elif parent.velocity.y >= 0:
					return states.fall
			elif abs(parent.velocity.x) <= 20:
				return states.idle
		states.jump:
			if parent.is_on_floor():
				return states.idle
			elif parent.velocity.y >= 0:
				return states.fall
		states.fall:
			if parent.is_on_floor():
				return states.idle
			elif parent.velocity.y < 0:
				return states.jump
			
	
	return null

func _enter_state(new_state, old_state):
	if parent.velocity.x > 0:
		parent.sprite.flip_h = false
	else:
		parent.sprite.flip_h = true
	match new_state:
		states.idle:
			jumps = max_jumps
			parent.anim_player.play("idle")
			
		states.run:
			jumps = max_jumps
			parent.anim_player.play("run")
			if Input.is_action_just_pressed("jump"):
				parent.velocity.y = parent.max_jump_velocity
		states.jump:
			jumps -= 1
			parent.anim_player.play("jump")
			
		states.fall:
			parent.anim_player.play("fall")
			if Input.is_action_just_pressed("jump") and jumps > 0:
				parent.velocity.y = parent.max_jump_velocity
		states.dash:
			parent.anim_player.play("dash")

func _exit_state(old_state, new_state):
	pass



