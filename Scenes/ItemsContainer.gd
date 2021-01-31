extends HBoxContainer


onready var sprites = [
	preload("res://Scenes/Blaster.tscn"), 
	preload("res://Scenes/Heart.tscn"),
	preload("res://Scenes/Bong.tscn")
]
onready var itemEntries = [$ItemEntry1, $ItemEntry2, $ItemEntry3]

# Called when the node enters the scene tree for the first time.
func _ready():
	get_random_items()


# TODO: Replace this functionality with some actual random stuff
# - Maybe use EffectBank? Not sure what that is yet.
func get_random_items():
	for i in range(len(itemEntries)):
		itemEntries[i].add_child(sprites[i].instance())
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
