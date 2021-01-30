extends Control

onready var health_bar = $HealthBar

func on_health_updated(health, amount):
	health_bar.value = health
	
