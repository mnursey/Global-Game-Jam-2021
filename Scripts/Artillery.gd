extends "res://Scripts/EnemyBase.gd"

onready var hurtbox = $EnemyHurtbox
onready var animationPlayer = $AnimationPlayer
onready var raycast = $RayCast2D
onready var shoot_audio = $ShootAudio
onready var arc_test_raycast = $ArcRaycast
onready var Shell = load('res://Scenes/Shell.tscn').instance()
onready var WarningTarget = load('res://Scenes/WarningTarget.tscn').instance()

const ROOT_2 = sqrt(2)
var ROOT_G

var num_test_shots = 20
var test_shot_resolution = 10
var estimated_impact_pos = Vector2.ZERO

var max_shell_speed = 500
var min_shell_speed = 250
var min_angle = 20.0
var max_angle = 80.0
var shot_timer = 0
var shot_counter = 0

var shell_damage
var shell_blast_radius
var shell_airburst_dist
var shell_payload
var num_frags
var frag_damage
var frag_spread
var shot_cooldown

var ammo_variant = 0
var variant_shell_damage = 		  [[25, 40, 40, 90], 	[5, 5, 5, 5], 		[5, 5, 5, 5]]
var variant_shell_blast_radius =  [[40, 60, 40, 100], 	[20, 20, 20, 20], 	[15, 15, 15, 15]]
var variant_shell_airburst_dist = [[0, 0, 0, 20], 		[0, 120, 0, 120], 	[0, 0, 120, 120]]
var variant_num_frags = 		  [[0, 0, 0, 0], 		[2, 3, 4, 6], 		[3, 6, 5, 12]]
var variant_frag_damage = 		  [[0, 0, 0, 0], 		[10, 15, 20, 30], 	[20, 25, 30, 40]]
var variant_frag_spread = 		  [[0, 0, 0, 0], 		[45, 90, 90, 180], 	[45, 90, 90, 360]]
var variant_shot_cooldown = 	  [[3.5, 3, 3.5, 3], [5, 5, 5, 5], [5, 5, 5, 5]]

var variant_health = [30, 90, 200, 500]

func _ready():
	ammo_variant = 0 #int(randf()*3)
	set_variant(2) #int(randf()*4))
	ROOT_G = sqrt(Shell.GRAVITY)
	
	
func set_variant(v):
	.set_variant(v)
	health = variant_health[v]
	shell_payload = [Shell.PayloadType.Explosive, Shell.PayloadType.Incendiary, Shell.PayloadType.Cluster][ammo_variant]
	shell_damage = variant_shell_damage[ammo_variant][v]
	shell_blast_radius = variant_shell_blast_radius[ammo_variant][v]
	shell_airburst_dist = variant_shell_airburst_dist[ammo_variant][v]
	num_frags = variant_num_frags[ammo_variant][v]
	frag_damage = variant_frag_damage[ammo_variant][v]
	frag_spread = variant_frag_spread[ammo_variant][v]
	shot_cooldown = variant_shot_cooldown[ammo_variant][v]
	healthbar.init(health)
	
func _physics_process(delta):
	shot_timer -= delta
	if shot_timer < 0:
		shot_timer = shot_cooldown
		var shot_taken = attempt_shot()
		
		if shot_taken and ammo_variant == 0 and variant == 2 and shot_counter < 2:
				shot_counter += 1
				shot_timer = 0.3
		else:
				shot_counter = 0
			
		
func attempt_shot() -> bool:
	arc_test_raycast.enabled = true
	
	var target = GM.player.global_position
	var to_target = target - global_position
	to_target.y *= -1
	
	var theta = deg2rad(min_angle + max_angle)/2 if (shell_airburst_dist == 0) else deg2rad(max_angle) 
	var delta_theta = deg2rad((max_angle - min_angle)/(num_test_shots - 1))
	for i in range(num_test_shots):
		var shell_speed = find_necessary_speed(abs(to_target.x), to_target.y, ROOT_G, theta)
		if shell_speed > min_shell_speed and shell_speed < max_shell_speed:
			var shell_vel = shell_speed*Vector2(cos(theta)*sign(to_target.x), -sin(theta))
			
			var t = 0
			var delta_t = abs(to_target.x/shell_vel.x) / (test_shot_resolution - 1)
			print(delta_t)
			var arc_valid = true
			for j in range(test_shot_resolution):
				arc_test_raycast.position = find_displacement(shell_vel, Shell.GRAVITY, t)
				arc_test_raycast.cast_to = find_velocity(shell_vel, Shell.GRAVITY, t) * delta_t
				arc_test_raycast.force_raycast_update()
				
				if arc_test_raycast.is_colliding():
					if arc_test_raycast.get_collider().is_in_group("Player"):
						arc_valid = true
						estimated_impact_pos = arc_test_raycast.get_collision_point() + 10*Vector2.DOWN
						break
					elif not arc_test_raycast.get_collider().is_in_group("Enemy"):
						arc_valid = false
						break
				t += delta_t
				
			if arc_valid:
				shoot(shell_vel)
				return true
		
		if shell_airburst_dist == 0:
			theta = theta + delta_theta*(i+1) if (i % 2 == 0) else theta - delta_theta*(i+1)
		else:
			theta -= delta_theta
			
	return false
	
func shoot(v, double = false):
	var shell = Shell.duplicate()
	get_parent().add_child(shell)
	shell.sprite.region_rect = Rect2(Vector2([0, 32, 16][ammo_variant], 0), Vector2(16, 16))
	shell.init(global_position, v, shell_blast_radius, shell_damage, shell_airburst_dist, shell_payload, num_frags, frag_damage, frag_spread)
	
	var warning_target = WarningTarget.duplicate()
	add_child(warning_target)
	warning_target.global_position = estimated_impact_pos
	shell.warning_target = warning_target
	
	#if variant == 2 and ammo_variant == 0 and not double:
	#	shoot(v.rotated(sign(randf()-0.5)*PI/16), true)
	
func find_necessary_speed(x, y, root_g, theta):
	var A = x*tan(theta) - y
	if A <= 0: return 0
	return root_g*x/cos(theta) / (ROOT_2*sqrt(A))
	
	
func find_displacement(v, g, t):
	return v*t + Vector2.DOWN*g*t*t/2
	
func find_velocity(v, g, t):
	return Vector2(v.x, v.y + g*t)
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()

