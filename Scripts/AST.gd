extends 'res://Scripts/PulseBase.gd'

onready var EffectBank = $EffectBank
var Player

export var base_stats = {}
export var fire_rate : float = 0
var fire_rate_timer : float = 0

var disable = false

signal shot_ast

func _ready():
	Player = get_parent()
	
	is_AST = true
	fire_rate_timer = 0
	
func set_stats_from_dict(d):
	fire_rate = d[StatsUtil.StatName.FIRE_RATE].x
	distance = d[StatsUtil.StatName.DISTANCE]
	lifetime = d[StatsUtil.StatName.LIFETIME]
	size = d[StatsUtil.StatName.SIZE]
	damage = d[StatsUtil.StatName.DAMAGE]
	speed = d[StatsUtil.StatName.SPEED]
	scatter = d[StatsUtil.StatName.SCATTER]
	knockback = d[StatsUtil.StatName.KNOCKBACK]
	suction = d[StatsUtil.StatName.SUCTION]
	homing = d[StatsUtil.StatName.HOMING]
	gravity = d[StatsUtil.StatName.GRAVITY]
	remaining_pulses = d[StatsUtil.StatName.SUBPULSES].x
	subpulse_delay = d[StatsUtil.StatName.SUBPULSE_DELAY]
	split_chance = d[StatsUtil.StatName.SPLIT_CHANCE]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fire_rate_timer += delta
	if !disable && Input.is_action_pressed("shoot") and fire_rate_timer > 1/fire_rate:
		fire_rate_timer = 0
		emit_signal("shot_ast")
		spawn_pulse()
		
	if Input.is_action_just_pressed("debug_1"):
		var item = StatsUtil.generate_item(2, 0.3)
		item.global_position = global_position
		#get_node('/root').add_child(item)
		Player.apply_item(item)
		print(item.get_node('EffectBank'))
		
		
		#for _i in range(10):
		#	var e = EffectBank.generate_effect_bank(2, 2, 1, 0.1, StatsUtil.AST_STATS)
		#	print(e)
		#	EffectBank.absorb(e)
		#recalculate_stats()
		
func spawn_pulse():
	velocity = (get_global_mouse_position() - global_position).normalized()
	.spawn_pulse()

