extends Control

onready var stats_container = $VBoxContainer
var player
var stat_labels = []


# Called when the node enters the scene tree for the first time.
func _ready():
	rect_position -= rect_size/2
	player = get_parent().get_parent().get_parent()
	var label_theme = load('res://Art/UIThemes/StatLabelTheme.tres')
	var size = stats_container.rect_min_size
	var row_height = size.y/len(StatsUtil.StatName)
	var stat_name_width = 140
	var stat_value_width = 80
	
	stats_container.rect_min_size.x = row_height + stat_name_width + 3*stat_value_width 
	
	stat_labels = []
	for stat in range(len(StatsUtil.StatName)):
		stat = int(stat)
		var hbox = HBoxContainer.new()
		hbox.rect_min_size = Vector2(size.x, row_height)
		
		var icon = TextureRect.new()
		icon.rect_min_size = Vector2(row_height,row_height)
		#print(row_height)
		icon.rect_size = icon.rect_min_size
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.light_mask = 2
		icon.texture = load('res://Art/StatIcons/items_space-sheet' + str(int(stat)+1) + '.png')
		hbox.add_child(icon)
		
		var labels = []
		for i in range(4):
			var label = Label.new()
			label.theme = label_theme
			label.valign = Label.VALIGN_CENTER
			label.light_mask = 2
			if i == 0:
				label.rect_min_size = Vector2(stat_name_width, hbox.rect_min_size.y)
				label.text = StatsUtil.string_names[stat] + ':'
			else:
				label.rect_min_size = Vector2(stat_value_width, hbox.rect_min_size.y)
				if StatsUtil.variant_weights[stat][i-1] != 0:
					label.text = str(StatsUtil.default_stats[stat][i-1])
				else:
					label.text = '-'
			hbox.add_child(label)
			labels.append(label)
		stats_container.add_child(hbox)
		stat_labels.append(labels)
		
func refresh():
	var stat_values = player.EffectBank.apply_to_base(GM.player.base_stats)
	for i in range(len(stat_labels)):
		for j in range(3):
			if StatsUtil.variant_weights[i][j] == 0:
				continue
				
			if j == 0 and i in [StatsUtil.INTEGER_STATS]:
				stat_values[i][j] = round(stat_values[i][j])
				
			var t =  '%.2f' % stat_values[i][j]
			if player.EffectBank.effects.has(i):
				var multiplier = player.EffectBank.effects[i].multiplier[j]
				if abs(multiplier - 1) > 0.01:
					t += ' (%d%%)' % (multiplier*100)
			stat_labels[i][j+1].text = t
			
			var cost = StatsUtil.appraise(i, j, '+', stat_values[i][j] - StatsUtil.default_stats[i][j])
			if cost > 0.01:
				stat_labels[i][j+1].add_color_override("font_color", Color(0.02, 0.9, 0.035))
			elif cost < -0.01:
				stat_labels[i][j+1].add_color_override("font_color", Color(1, 0.18, 0.18))
			else:
				stat_labels[i][j+1].add_color_override("font_color", Color(1, 1, 1))
			
			
func set_visible(state):
	visible = state
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
