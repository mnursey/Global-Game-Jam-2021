extends Node2D

onready var Pulse = load("res://Scenes/Pulse.tscn")

const DAMAGE_MAX : float = 70.0
const LOG_DAMAGE_MAX : float = log(DAMAGE_MAX)
const BASE_SPLIT_CHANCE = 0.05

export var start_position = Vector2.ZERO
export var direction = Vector2.RIGHT

var stats = {}

#Stat format: x = base, y = /sec, z = /pulse
#------------------------------------------
export var distance = 	Vector3.ZERO
export var lifetime = 	Vector3.ZERO
export var size = 		Vector3.ZERO
export var damage = 	Vector3.ZERO
export var speed = 		Vector3.ZERO
export var scatter = 	Vector3.ZERO
export var knockback = 	Vector3.ZERO
export var suction = 	Vector3.ZERO
export var homing = 	Vector3.ZERO
export var gravity = 	Vector3.ZERO

export var remaining_pulses = 0
export var subpulse_delay = Vector3.ZERO
export var split_chance = Vector3.ZERO
#------------------------------------------

var is_AST = false
var velocity = Vector2.ZERO

var stat_weights = {
	"fire rate" : 	Vector3(1, 0, 0),
	"distance" : 	Vector3(1, 0, 1),
	"lifetime" : 	Vector3(1, 0, 1),
	"size" : 		Vector3(1, 1, 1),
	"damage" : 		Vector3(1, 1, 1),
	"speed" : 		Vector3(1, 1, 1),
	"scatter" : 	Vector3(1, 0, 1),
	"knockback" : 	Vector3(1, 1, 1),
	"suction" : 	Vector3(1, 1, 1),
	"homing" : 		Vector3(1, 1, 1),
	"gravity" : 	Vector3(1, 1, 1),
	"subpulses" :	Vector3(1, 0, 0),
	"subpulse delay":	Vector3(1, 0, 1),
	"split chance" : Vector3(1, 0, 1)
}

func spawn_pulse(is_split = false):
	GM.pulse_count += 1
	var pulse = Pulse.instance()
	pulse.inherit_props(self)
	
	if is_split:
		pulse.mute = true
		pulse.disable_particles = GM.pulse_count > GM.PARTICLE_EMITTING_PULSE_CAP
		
	get_node("/root").add_child(pulse)
	return pulse


