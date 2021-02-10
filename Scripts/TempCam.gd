extends Camera2D

const MAX_ZOOM = 0.1

var is_dragging = false
var current_zoom = Vector2( 1, 1 )

func _input(event):
	if (event is InputEventMouseMotion and is_dragging):
		var mouse_motion = event.relative
		translate(Vector2(-mouse_motion.x * current_zoom.x, -mouse_motion.y * current_zoom.y))
	
	if (event is InputEventMouseButton):
		if (event.button_index == BUTTON_LEFT):		# Handle click & drag
			current = true
			if (event.is_pressed()):
				is_dragging = true
			elif (!event.is_pressed()):
				is_dragging = false
		elif (event.button_index == BUTTON_WHEEL_UP and event.is_pressed()):	# Handle zoom
			if (current_zoom.x >= MAX_ZOOM):
				current_zoom -= Vector2( 0.1, 0.1 )
				zoom = current_zoom
		elif (event.button_index == BUTTON_WHEEL_DOWN and event.is_pressed()):
			current_zoom += Vector2( 0.1, 0.1 )
			zoom = current_zoom
	
	if (Input.is_key_pressed(KEY_ESCAPE)):	# Quit on ESCAPE
		get_tree().quit()
