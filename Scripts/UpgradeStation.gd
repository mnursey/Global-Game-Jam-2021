extends Area2D

onready var MenuContainer = $MenuZ/MenuContainer
onready var light = $Light2D

export var active = true
var menu = null
var num_items = 3

var items_magnitude = 4
var items_quality = 0.5

func _ready():
	set_active(active)
	
func _on_UpgradeStation_body_entered(body):
	if body.is_in_group("Player") and active:
		show_menu()


func _on_UpgradeStation_body_exited(body):
	if body.is_in_group("Player"):
		hide_menu()
		
func set_active(state):
	active = state
	modulate = Color.white if active else Color('696969') #nice
	light.enabled = state

func show_menu():
	if not menu:
		var items = []
		for i in range(num_items):
			items.append(StatsUtil.generate_item(items_magnitude, items_quality))
			
		var ItemSelectionMenu = load('res://Scenes/ItemSelectionMenu.tscn').instance()
		menu = ItemSelectionMenu.generate_new_menu(items)
		MenuContainer.add_child(menu)
	
	menu.rect_position = Vector2.ZERO
	menu.rect_scale = Vector2(0.1, 0.1)#Vector2(menu.rect_size.x / MenuContainer.rect_min_size.x, menu.rect_size.y / MenuContainer.rect_min_size.y) 
	menu.visible = true

func hide_menu():
	if menu:
		menu.visible = false
		
func _process(_delta):
	if menu and menu.visible: menu.rect_scale = Vector2(MenuContainer.rect_min_size.x / menu.rect_min_size.x, MenuContainer.rect_min_size.y / menu.rect_min_size.y)
	







