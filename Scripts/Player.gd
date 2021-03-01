extends KinematicBody2D

signal health_updated(health)
signal max_health_updated(max_health)
signal dead()

const UP = Vector2(0, -1)
const TILESIZE = 16

var velocity = Vector2()
var move_speed = 10 * TILESIZE

var mouse_vector = Vector2.ZERO

var max_health = 100
var health = max_health setget set_health

var scrap = 0
var scrap_counter = 0
var scrap_timer = 0

var selected_dispenser = null

var effect_card_buffer = []
var effect_card_timer = 0

var base_stats

var gravity
var fall_gravity
var max_jump_velocity
var min_jump_velocity
var max_jump_height = 3.2 * TILESIZE
var min_jump_height= 0.8 * TILESIZE
var jump_duration = 0.3
var fall_duration = 0.325

var max_jumps = 1
var jumps = 1
var is_jumping = false
var jump_buffer_timer = 0

var max_dashes = 1
var dashes = 1
var dash_speed = 20 * TILESIZE
var dash_time = 0.2
var is_dashing = false
var can_dash = true
var dash_vector = Vector2.ZERO

var facing_right = true 
var dead = false

var music_hutzpah = 0
var target_music_hutzpah = 0

onready var anim_player = $AnimationPlayer
onready var sprite = $Sprite
onready var healthbar = $ShakeCamera2D/HealthBar
onready var scrap_display = $ShakeCamera2D/ScrapDisplay/Label
onready var dash_timer = $DashTimer
onready var invincibility_timer = $InvincibilityTimer
onready var coyote_timer = $CoyoteTimer
onready var death_sound = $DeadAudio
onready var jump_audio = $Jump
onready var hit_audio = $HitAudio
onready var dash_audio =$DashAudio
onready var camera = $ShakeCamera2D
onready var hurtBox = $Hurtbox/CollisionShape2D
onready var collisionBox = $CollisionShape2D
onready var stats_display = $ShakeCamera2D/StatsDisplayZ/StatsDisplay
onready var AST = $AST 
onready var music_reduced = $Music1
onready var music_combat = $Music2
var EffectBank

func _ready():
	GM.player = self
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	fall_gravity = 2 * max_jump_height / pow(fall_duration, 2)
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)
	
	EffectBank = get_node("AST/EffectBank")
	base_stats = StatsUtil.default_stats.duplicate()
	recalculate_stats()
	health = max_health
	
	music_reduced.volume_db = 0
	music_combat.volume_db = -80
	
func apply_item(item):
	var bank = item.get_node('EffectBank')
	EffectBank.absorb(bank)
	recalculate_stats()
	stats_display.refresh()
	effect_card_buffer += bank.get_unpacked()
	effect_card_timer = -1
	
func recalculate_stats():
	var stats = EffectBank.apply_to_base(base_stats)
	set_stats_from_dict(stats)
	AST.set_stats_from_dict(stats)
	
func set_stats_from_dict(d):
	var old_health = max_health
	max_health = round(d[StatsUtil.StatName.MAX_HEALTH].x)
	heal(max_health - old_health)
	
	max_dashes = round(d[StatsUtil.StatName.DASHES].x)
	max_jumps = round(d[StatsUtil.StatName.JUMPS].x)
	dash_speed = d[StatsUtil.StatName.DASH_SPEED].x
	move_speed = d[StatsUtil.StatName.MOVE_SPEED].x
	healthbar.update_max_health(max_health)
	if max_dashes + max_jumps <= 0:
		max_dashes = 1

func _physics_process(delta):
	if Input.is_action_just_pressed("restart"):
		GM.restart()
		
	if !dead:
		jump_buffer_timer -= delta
		
		apply_gravity(delta)
		get_move_input()
		get_input()
		apply_movement()
		animate()
		update_scrap_display(delta)
		update_effect_cards(delta)
		
func _process(delta):
	mouse_vector = get_global_mouse_position() - global_position
	handle_music(delta)


func get_input():
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.1
		
	if jump_buffer_timer > 0:
		if jumps > 0:
			jump_buffer_timer = 0
			jump_audio.play()
			is_jumping = true
			jumps -= 1
			velocity.y = max_jump_velocity
			if is_dashing:
				is_dashing = false
				if is_on_floor():
					dashes = max_dashes
				if dash_vector.y > 1:
					velocity.y *= 0.7
				else:
					velocity.x *= 0.7
			
		
	if Input.is_action_just_released("jump") and velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity
	
	if (Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("dash2")) and dashes > 0:
		is_dashing = true
		dashes -= 1
		dash_timer.start(dash_time)
		invincibility_timer.start(dash_time)
		dash_audio.play()
		camera.set_trauma(0.4)
		
		if Input.is_action_just_pressed("dash"):
			dash_vector = mouse_vector.normalized() * dash_speed
		else:
			dash_vector = Vector2(-int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right")), -int(Input.is_action_pressed("move_up")) + int(Input.is_action_pressed("move_down"))).normalized() * dash_speed + Vector2(0, 0.5)
		
	if Input.is_action_just_pressed("use"):
		if selected_dispenser:
			print(selected_dispenser.price)
			print(selected_dispenser.item.get_node("EffectBank").get_unpacked()[0])
			if scrap >= selected_dispenser.price:
				give_scrap(-selected_dispenser.price)
				apply_item(selected_dispenser.item)
				camera.set_trauma(0.2)
				selected_dispenser.on_purchase(true)
			else:
				selected_dispenser.on_purchase(false)
		
	if Input.is_action_just_pressed("toggle_stats_ui"):
		stats_display.set_visible(true)
	elif Input.is_action_just_released("toggle_stats_ui"):
		stats_display.set_visible(false)
		
	if Input.is_action_just_pressed("debug_1"):
		camera.set_trauma(3)
		GM.spawn_scrap(1000, global_position, GM.active_room)
		set_max_health()
		for enemy in GM.active_room.enemies:
			if enemy:
				enemy.take_damage(enemy.health - 1)
		for light in GM.active_room.lights:
			light.set_effect(light.LightEffect.RAVE, true)
			light.set_effect(light.LightEffect.SWING, true)
	

func apply_movement():
	var was_on_floor = is_on_floor()
	
	if is_dashing:
		if dash_vector.y > 1 and is_on_floor():
			dash_vector = Vector2(dash_speed*sign(dash_vector.x), 2)	
			
		velocity = move_and_slide(dash_vector, Vector2.UP)
		#velocity = lerp(velocity, velocity/100, 0.2)
		sprite.scale = Vector2(0.9, 0.9)
	else:
		velocity = move_and_slide(velocity, UP)
		sprite.scale = Vector2(1, 1)
		if !is_on_floor() and was_on_floor and !is_jumping:
			coyote_timer.start()
			
	if is_on_floor():
		jumps = max_jumps
		
	if is_on_floor() and dash_timer.is_stopped():
		dashes = max_dashes
		
func apply_gravity(delta):
	if velocity.y < 0:
		velocity.y += gravity * delta
	else:
		is_jumping = false
		velocity.y += gravity * delta
		velocity.y = lerp(velocity.y, fall_gravity * delta, 0.05)

func get_move_input():
	var move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	if move_direction == 0 or sign(move_direction) != sign(velocity.x) or is_on_floor() or abs(move_speed) > abs(velocity.x):
		velocity.x = lerp(velocity.x, move_speed * move_direction, 0.2)
	else:
		velocity.x = lerp(velocity.x, move_speed * move_direction, 0.02)

	
func animate():
	if velocity.x > 0.5:
		facing_right = true
		$Sprite.flip_h = false
	elif velocity.x < -0.5:
		facing_right = false
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = !facing_right
	if abs(velocity.x) <= 20 && is_on_floor():
		anim_player.play("idle")
	elif abs(velocity.x) > 20 && is_on_floor():
		anim_player.play("run")
	elif velocity.y < 0:
		anim_player.play("jump")
	else:
		anim_player.play("fall")
		
func update_scrap_display(delta):
	if scrap_counter != scrap:
		if scrap_timer < 0:
			var dif = scrap - scrap_counter
			scrap_display.set_trauma(sqrt(abs(dif)-1))
			if abs(dif) < 10:
				scrap_timer = 0.4/abs(dif)
				scrap_counter += sign(dif)
			else:
				scrap_timer = 0.05
				scrap_counter += int(dif/10)
			scrap_display.text = str(scrap_counter)
			scrap_display.rect_pivot_offset.x = 7*len(str(scrap_counter))
		else:
			scrap_timer -= delta
			
func update_effect_cards(delta):
	if effect_card_buffer.empty(): return
	if effect_card_timer < 0:
		effect_card_timer = 0.3
		var e = effect_card_buffer.pop_back()
		var card = load("res://Scenes/EffectCard.tscn").instance().duplicate()
		add_child(card)	
		card.text = e.to_string()
		card.init(-1 if facing_right else 1)
		
		if e.cost > 0:
			card.add_color_override("font_color", Color(0.02, 0.9, 0.035))
		else:
			card.add_color_override("font_color", Color(1, 0.18, 0.18))
		
		
	else:
		effect_card_timer -= delta

		


func _on_DashTimer_timeout():
	if is_dashing:
		velocity /= 2
		is_dashing = false
	
func take_damage(amount):
	if !dead and invincibility_timer.is_stopped() and amount > 0:
		invincibility_timer.start(0.3)
		set_health(health - amount)
		hit_audio.play()
		camera.set_trauma(0.5)
		
func heal(amount):
	set_health(health + amount)

func dead():
	dead = true
	anim_player.play("dead")
	emit_signal("dead")
	camera.set_trauma(0.8)
	hurtBox.set_disabled(true)
	collisionBox.set_disabled(true)
	AST.disable = true
	
func set_health(value):
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health != prev_health:
		emit_signal("health_updated", health)
		if health <= 0:
			dead()
			
func give_scrap(v):
	scrap += v
	scrap_timer = -1
	
	
func handle_music(delta):
	target_music_hutzpah = int(!GM.active_room.room_cleared)
	
	var volume_changed = true
	if target_music_hutzpah > music_hutzpah:
		music_hutzpah = min(music_hutzpah + delta, 1)
	elif target_music_hutzpah < music_hutzpah:
		music_hutzpah = max(music_hutzpah - delta, 0)
	else:
		volume_changed = false
		
	if volume_changed:
		music_combat.volume_db = 20*log(max(pow(music_hutzpah, 0.5), 0.0001)) - 3
		music_reduced.volume_db = 20*log(max(pow(1 - music_hutzpah, 0.5), 0.0001)) - 3
			

func set_max_health():
	set_health(max_health)

func _on_Hurtbox_area_entered(area):
	#if area.is_in_group('Enemy'):
		take_damage(area.deal_damage()) 
	

func _on_Hurtbox_body_entered(body):
	take_damage(body.deal_damage())


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "dead":
		sprite.hide()


func _on_AST_shot_ast():
	camera.set_trauma(0.4)
	
