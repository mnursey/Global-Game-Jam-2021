extends Area2D

onready var icon = $IconSprite
onready var sprite = $Sprite
onready var light = $Light2D
onready var price_display = $Label
onready var sparks = $Particles2D

onready var purchase_sound = $PurchaseSound
onready var error_sound = $ErrorSound
onready var bash_sound = $BashSound
onready var explode_sound = $ExplodeSound

var item
var base_price
var price

var broken = false
var flicker_timer = 0


func _ready():
	generate_effect()
	
func _physics_process(delta):
	if flicker_timer > 0:
		flicker_timer -= delta
	else:
		light.flicker_amount = 0.01
	
func generate_effect():
	var stat  = StatsUtil.choose_random(StatsUtil.StatName.values().duplicate())
	#if stat == StatsUtil.StatName.GRAVITY: generate_effect()
	
	var op = '+' if randf() < 0.9 else '*'
	
	sparks.emitting = op == '*'
	
	var variant = 0
	var r = randf()
	if r > 0.80 and StatsUtil.costs[stat][1] != 0:
		variant = 1
	elif r > 0.7 and StatsUtil.costs[stat][2] != 0:
		variant = 2
		
	match variant:
		0: 
			sprite.frames = load("res://Art/Dispenser/Dispenser_green_anim.tres")
			light.target_color = Color("22a266")
		1: 
			sprite.frames = load("res://Art/Dispenser/Dispenser_blue_anim.tres")
			light.target_color = Color("2266a2")
		2: 
			sprite.frames = load("res://Art/Dispenser/Dispenser_red_anim.tres")
			light.target_color = Color("a22266")
		
	var cost = 0.25
	var value
	if stat in StatsUtil.INTEGER_STATS and op == '+' and StatsUtil.costs[stat][variant] > cost:
			value = 1
			cost = StatsUtil.appraise(stat, variant, '+', value)
	else:
		value = StatsUtil.purchase(stat, variant, op, cost)
		
	base_price = int(cost / StatsUtil.SCRAP_COST)
	set_price(base_price)
	
	var addend = Vector3(0, 0, 0)
	var multiplier = Vector3(1, 1, 1)
	if op == '+':
		addend[variant] = value
	else:
		multiplier[variant] = value
		
	if not item:
		item = load('res://Scenes/Item.tscn').instance().duplicate()
		item.get_node("Sprite").visible = false
	
	var bank = item.get_node("EffectBank")
	bank.effects = {}
	
	var effect = bank.Effect.new(stat, cost, addend, multiplier)
	bank.add_effect(effect)
	
	icon.texture = load('res://Art/StatIcons/items_space-sheet' + str(int(stat)+1) + '.png')
	
	
func on_purchase(success):
	if success:
		price_display.modulate = Color.green
		set_price(int(price * (1.075 + (base_price/25.0 - 1)/20)))
		purchase_sound.play()
	else:
		price_display.set_trauma(1)
		price_display.modulate = Color.red
		error_sound.play()
	
	
func set_price(p):
	price = int(p)
	price_display.text = str(p)
	price_display.set_trauma(3)
	
	
func deactivate():
	broken = true
	icon.texture = null
	light.enabled = false
	sparks.emitting = true
	sparks.explosiveness = 0.6
	sparks.amount = 40
	sprite.frames = load("res://Art/Dispenser/Dispenser_broken_anim.tres")
	explode_sound.play()
	GM.spawn_scrap(int(5 + pow(randf(), 2)*20), global_position, self)
	

func on_bashed(player):
	player.is_dashing = false
	player.dashes = player.max_dashes
	if abs(player.global_position.x - global_position.x) > 8 or player.global_position.y - global_position.y > -10:
		player.velocity.x *= -1
	else:
		player.velocity.y *= -1
	if(randf() > 0.25):
		flicker_timer = 1
		light.flicker_amount = 0.3
		bash_sound.play()
		generate_effect()
	else:
		deactivate()


func _on_Node2D_body_entered(body):
	if body.is_in_group("Player") and not broken:
		body.selected_dispenser = self
		if body.is_dashing:
			on_bashed(body)



func _on_Node2D_body_exited(body):
	if body.is_in_group("Player"):
		if body.selected_dispenser == self:
			body.selected_dispenser = null
