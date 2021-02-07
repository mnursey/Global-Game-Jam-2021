extends Area2D

var damage = 25

func deal_damage():
	return get_parent().contact_damage
