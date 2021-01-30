extends 'res://Scripts/PulseBase.gd'

onready var EffectBank = $EffectBank

export var base_stats = {}
export var fire_rate : float = 0
var fire_rate_timer : float = 0

func _ready():
	base_stats = StatsUtil.default_stats.duplicate()
	recalculate_stats()
	
	is_AST = true
	fire_rate_timer = 0
	
func recalculate_stats():
	set_stats_from_dict(EffectBank.apply_to_base(base_stats))
	
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
	if Input.is_action_pressed("shoot") and fire_rate_timer > 1/fire_rate:
		fire_rate_timer = 0
		spawn_pulse()
		
	if Input.is_action_just_pressed("debug_1"):
		EffectBank.print_test_bank()
		
func spawn_pulse():
	velocity = (get_global_mouse_position() - global_position).normalized()
	.spawn_pulse()

