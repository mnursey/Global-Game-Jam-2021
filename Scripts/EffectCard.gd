extends Label

const LIFETIME = 1.5
var velocity = Vector2.ZERO
var timer = LIFETIME

func init(dir):
	rect_position = Vector2(-35, -7)
	velocity = Vector2(0*dir, -35)
	
func _physics_process(delta):
	rect_position += velocity * delta
	velocity.y += 1
	timer -= delta
	if timer < 0: queue_free()
	modulate.a = min(2*timer/LIFETIME, 1)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
