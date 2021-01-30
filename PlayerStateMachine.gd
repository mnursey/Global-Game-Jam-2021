extends "res://StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("dash")
	call_deferred("set_state", states.idle)

func jump_input():
	if Input.is_action_pressed("jump") and parent.jumps > 0:
		parent.velocity.y = parent.max_jump_velocity
		parent.jumps-=1
	if state == states.jump:
		if Input.is_action_just_released("jump") and parent.velocity.y < parent.min_jump_velocity:
			parent.velocity.y = parent.min_jump_velocity

func _state_logic(delta):
	parent.move_input()
	parent.apply_gravity(delta)
	parent.apply_movement()
	jump_input()
	print(state)

func _get_transition(delta):
	match state:
		states.idle:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.fall
			elif abs(parent.velocity.x) != 0:
				return states.run
		states.run:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.fall
			elif abs(parent.velocity.x) == 0:
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
	match new_state:
		states.idle:
			parent.anim_player.play("idle")
		states.run:
			parent.anim_player.play("run")
		states.jump:
			parent.anim_player.play("jump")
		states.fall:
			parent.anim_player.play("fall")
		states.dash:
			parent.anim_player.play("dash")

func _exit_state(old_state, new_state):
	pass



