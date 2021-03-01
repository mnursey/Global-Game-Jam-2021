extends AnimatedSprite


func init(radius, damage, target):
	play("Explode")
	GM.player.camera.set_trauma(0.25*pow(radius, 1.5)/max((GM.player.global_position - global_position).length(), radius))
	
	speed_scale = 120.0/(radius + 120.0)
	if radius >= 100:
		modulate = Color("49ff48")
	
	var targets = []
	if(target == "Player"):
		targets.append(GM.player)
	elif(target == "Enemy"):
		for enemy in GM.active_room.enemies:
			if enemy: targets.append[enemy]
				
	for t in targets:
		var to_target = t.global_position - global_position
		var target_dist = to_target.length()
		if target_dist < radius:
			t.take_damage(damage)
			t.velocity += 200*(to_target/target_dist + Vector2(0, -0.4))
			
func _physics_process(_delta):
	if frame == 7:
		queue_free()
	
