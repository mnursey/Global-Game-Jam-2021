extends Node2D

# EDITOR VARIABLES ---------------
export(Array, PackedScene) var level_scenes
export(Vector2) var tile_size = Vector2(16, 16)
export(int, 10, 100, 2) var level_padding_distance = 10
export(String) var name_of_interface_tilemap
export(TileSet) var interface_tileset
export(TileSet) var hallway_tileset
export(Array, TileSet) var tilesets_to_exclude
export(Array, String) var interface_tile_names = [
	"door",
	"hint",
	"wall"
]
export(int) var MAX_DOOR_SIZE = 3 # UNUSED


# WORLD DATA --------------------
var my_tilemap
var interface_tileset_id_lookup = {} # Map friendly tile names to ids
var player_exists = false

# SCENE DATA --------------------
var loaded_scenes = []

# UTIL --------------------------
var RNG = RandomNumberGenerator.new()


# FUNCTIONS ---------------------

func _ready():
	init_my_tilemap()
	init_interface_tileset_id_lookup()
	load_levels()
	#add_level_to_scene_tree(0, true)
	#for i in range(len(loaded_scenes)):
	#	spawn_level_for_each_unused_door()
	


func _input(event):
	
	# Hotkeys
	if Input.is_key_pressed(KEY_SPACE):
		spawn_level_for_each_unused_door()
		pass
	if Input.is_key_pressed(KEY_G):
		add_level_to_scene_tree(0, true)
		pass
	if Input.is_key_pressed(KEY_F):
		pass
		#clear_interface_tilemaps_from_loaded_levels()
	if Input.is_key_pressed(KEY_S):
		pass
	
	# Mouse stuff
#	if (event is InputEventMouseButton):
#		if (event.button_index == BUTTON_LEFT):		# Handle click & drag
#				if (event.is_pressed() and Input.is_key_pressed(KEY_SHIFT)):
#					var vp_transform = get_viewport_transform()
#					var vp_transform_vector = Vector2(-vp_transform[2].x, -vp_transform[2].y)
#					var click_pos = vp_transform_vector + event.position
#					click_pos.x = round(click_pos.x)
#					click_pos.y = round(click_pos.y)
#					click_pos = my_tilemap.world_to_map(click_pos)
#					var cell_clicked = my_tilemap.get_cellv(click_pos)
#					my_tilemap.set_cellv(click_pos, 3)
#				elif (!event.is_pressed()):
#					pass



func init_my_tilemap():
	my_tilemap = TileMap.new()
	my_tilemap.tile_set = interface_tileset
	my_tilemap.cell_size = tile_size
	add_child(my_tilemap)



func init_interface_tileset_id_lookup():
	for name in interface_tile_names:
		var id = interface_tileset.find_tile_by_name(name)
		interface_tileset_id_lookup[name] = id
	print(interface_tileset_id_lookup)



# Instance all the level_scenes and load their data into a list of dictionaries 
func load_levels():
	for packaged_scene in level_scenes:
		# Instance the scene and get children
		var instanced_scene = packaged_scene.instance()
		var scene_children = instanced_scene.get_children()
		
		# Find the tilemap in the scene
		var interface_tilemap
		var all_tilemaps = get_all_tilemaps_in_node(instanced_scene)
		for map in all_tilemaps:
			if (map.name == name_of_interface_tilemap):
				interface_tilemap = map
				break
		if (!interface_tilemap is TileMap):
			printerr("Error loading scene: ", packaged_scene)
			return
		var interface_tilemap_bounds = interface_tilemap.get_used_rect()
		
		# Find sets tiles that constitute each door
		var interface_door_tile_id = interface_tileset_id_lookup["door"]
		var door_tile_sets = find_door_coordinate_sets_in_tilemap(interface_tilemap, interface_door_tile_id)
		var top_door_tile_sets = []
		var right_door_tile_sets = []
		var bottom_door_tile_sets = []
		var left_door_tile_sets = []
		
		# Sort the doors by their nearest side
		for tile_set in door_tile_sets:
			var side_nearest_to_door = find_nearest_side_to_door_tile_set(interface_tilemap, tile_set)
			if (side_nearest_to_door == Vector2.UP):
				top_door_tile_sets.append(tile_set)
			elif (side_nearest_to_door == Vector2.RIGHT):
				right_door_tile_sets.append(tile_set)
			elif (side_nearest_to_door == Vector2.DOWN):
				bottom_door_tile_sets.append(tile_set)
			else:
				left_door_tile_sets.append(tile_set)
		
		# Package all the data we found into a dictionary
		var scene_data = {}
		scene_data["scene_instance"] = instanced_scene
		scene_data["topleft_tile_local_offset"] = interface_tilemap_bounds.position
		scene_data["size"] = interface_tilemap_bounds.size
		scene_data["is_spawned"] = false
		scene_data["difficulty"] = 0
		scene_data["tilemaps"] = all_tilemaps
		scene_data["interface_tilemap"] = interface_tilemap
		scene_data["top_door_local_coords"] = top_door_tile_sets
		scene_data["right_door_local_coords"] = right_door_tile_sets
		scene_data["bottom_door_local_coords"] = bottom_door_tile_sets
		scene_data["left_door_local_coords"] = left_door_tile_sets
		scene_data["top_door_used_indexes"] = []
		scene_data["right_door_used_indexes"] = []
		scene_data["bottom_door_used_indexes"] = []
		scene_data["left_door_used_indexes"] = []
		loaded_scenes.append(scene_data)
	clear_interface_tilemaps_from_loaded_levels()
	#print("loaded: ", len(loaded_scenes), ", levels")
	#dbg_print_level_data(loaded_scenes[0])
	#dbg_print_level_data(loaded_scenes[1])
	#dbg_print_level_data(loaded_scenes[2])
	#dbg_print_level_data(loaded_scenes[3])



func scene_data_door_direction_key_from_vector(direction:Vector2, used_indexes = false):
	if (direction == Vector2.UP):
		if (used_indexes):
			return "top_door_used_indexes"
		return "top_door_local_coords"
	if (direction == Vector2.RIGHT):
		if (used_indexes):
			return "right_door_used_indexes"
		return "right_door_local_coords"
	if (direction == Vector2.DOWN):
		if (used_indexes):
			return "bottom_door_used_indexes"
		return "bottom_door_local_coords"
	if (direction == Vector2.LEFT):
		if (used_indexes):
			return "left_door_used_indexes"
		return "left_door_local_coords"
	printerr("Error getting key from direction")
	return false



func add_level_to_scene_tree(level_index, spawn_player = false):
	var scene_instance = loaded_scenes[level_index]["scene_instance"]
	var scene_position = scene_instance.position
	loaded_scenes[level_index]["is_spawned"] = true
	
	# Load the tiles from new scene into my tilemap
	var tilemaps = loaded_scenes[level_index]["tilemaps"]
	var wall_tile_id = interface_tileset_id_lookup["wall"]
	for tilemap in tilemaps:
		if (tilemap.name != name_of_interface_tilemap and !tilesets_to_exclude.has(tilemap.tile_set)):
			var used_cells = tilemap.get_used_cells()
			for cell in used_cells:
				pass
				#my_tilemap.set_cellv(cell + scene_position, wall_tile_id)
	if (!spawn_player):
		var player_nodes = get_children_recursive_by_name(scene_instance, "Player")
		if (len(player_nodes) >= 1):
			player_nodes[0].queue_free()
	
	# Actually add scene to tree
	add_child(scene_instance)



func spawn_level_from_room(level_index):
	var used_right_door_indexes = loaded_scenes[level_index]["right_door_used_indexes"]
	var right_door_coords = loaded_scenes[level_index]["right_door_local_coords"]
	for door_index in range(len(right_door_coords)): 		# For each RIGHT door
		if (!used_right_door_indexes.has(door_index)):		# If it isn't used
			var local_door_coords = right_door_coords[door_index]
			var global_door_coords = door_coords_to_global(local_door_coords, loaded_scenes[level_index]["interface_tilemap"])
			var door_tiles_world_pos = door_coords_to_world_space(local_door_coords, loaded_scenes[level_index]["interface_tilemap"])
			var success = spawn_specific_level_from_door(level_index, door_tiles_world_pos, Vector2.RIGHT)
			if (success):
				loaded_scenes[level_index]["right_door_used_indexes"].append(door_index)



func spawn_level_for_each_unused_door():
	print("_________________________")
	print("Spawning level for each door...")
	
	# First get all the scenes that are currently spawned
	var spawned_scene_indexes = []
	for i in range(len(loaded_scenes)):
		if (loaded_scenes[i]["is_spawned"]):
			spawned_scene_indexes.append(i)
	print(len(spawned_scene_indexes), "spanwed scenes found")
	dbg_print_level_data(loaded_scenes[spawned_scene_indexes[0]])
	# Then spawn levels at each of their doors
	for i in spawned_scene_indexes:
		for door_coords in loaded_scenes[i]["top_door_local_coords"]:
			pass
		
		# SPAWN LEVELS FROM RIGHT DOORS
		var used_right_door_indexes = loaded_scenes[i]["right_door_used_indexes"]
		var right_door_coords = loaded_scenes[i]["right_door_local_coords"]
		for door_index in range(len(right_door_coords)): 		# For each RIGHT door
			if (!used_right_door_indexes.has(door_index)):		# If it isn't used
				var local_door_coords = right_door_coords[door_index]
				var global_door_coords = door_coords_to_global(local_door_coords, loaded_scenes[i]["interface_tilemap"])
				var door_tiles_world_pos = door_coords_to_world_space(local_door_coords, loaded_scenes[i]["interface_tilemap"])
				print("Attempgint to spawn level")
				var success = spawn_level_from_door(door_tiles_world_pos, Vector2.RIGHT)
				if (success):
					loaded_scenes[i]["right_door_used_indexes"].append(door_index)
			
		for door_coords in loaded_scenes[i]["bottom_door_local_coords"]:
			pass
			
		for door_coords in loaded_scenes[i]["left_door_local_coords"]:
			pass



func spawn_level_from_door(door_tiles_world_pos: Array, door_direction: Vector2):
	print("Spawning level from door...")
	
	# Find some loaded levels that might make good neighbors
	var candidate_levels = find_levels_with_door_constraints(door_direction * -1, 1)
	
	# Make attempts to spawn one of the candidates
	var success = false
	var MAX_ATTEMPTS = len(candidate_levels)
	var attempt_count = 0
	while (!success and attempt_count < MAX_ATTEMPTS):	
		
		# Choose a candidate at random
		var candidate_level_chosen = RNG.randi_range(0, len(candidate_levels) -1)
		
		# Get a ton of information about it
		var level_data = candidate_levels[candidate_level_chosen]
		var level_index_to_try = level_data["level_index"]
		var door_set_index = level_data["door_set_index"]
		var door_dir_key = scene_data_door_direction_key_from_vector(door_direction * -1)
		var door_dir_used_key = scene_data_door_direction_key_from_vector(door_direction * -1, true)
		var door_set = loaded_scenes[level_index_to_try][door_dir_key][door_set_index]
		var candidate_door_tiles_world_pos = door_coords_to_world_space(door_set, loaded_scenes[level_index_to_try]["interface_tilemap"])

		# Look for a position that we could place our new level
		var max_level_offset = Vector2(25, 2)
		var min_level_offset = Vector2(10, -2)
		var new_position = find_position_for_level(level_index_to_try, door_tiles_world_pos, candidate_door_tiles_world_pos, door_direction, max_level_offset, min_level_offset)
		
		# If position search didn't fail, add new level to tree
		if (new_position):
			var scene_instance = loaded_scenes[level_index_to_try]["scene_instance"]
			translate_tilemaps_in_scene(scene_instance, new_position - scene_instance.position)
			scene_instance.position += new_position
			loaded_scenes[level_index_to_try]["scene_instance"] = scene_instance
			
			# Lock the door on the new room
			loaded_scenes[level_index_to_try][door_dir_used_key].append(door_set_index)
			
			# Find the location of each door in global tileset space
			var a_coord = my_tilemap.world_to_map(util_get_top_left_vector(door_tiles_world_pos)) 
			var b_coord = my_tilemap.world_to_map(new_position) + util_get_top_left_vector(door_set)
			var path = find_path_random(a_coord, b_coord, door_direction, door_direction * -1, Vector2(3, 3))
			path = clean_path(path)
			fill_path_full(path)
			
			# add to scene tree
			add_level_to_scene_tree(level_index_to_try)
			success = true
			return true
			
		# Remove level from candidate list if unable to spawn
		else:		
			var bad_candidates_removed = false
			while (!bad_candidates_removed):
				for i in range(len(candidate_levels)):
					if (candidate_levels[i]["level_index"] == level_index_to_try):
						candidate_levels.remove(i)
						break 	# Break for loop as soon as we remove level because
								# we've invalidated the loop bounds. Keep resetting
								# loop until we finish it.
					bad_candidates_removed = true
					break
		attempt_count += 1
	
	# Print error if we maxed out our attempts to spawn and were unable to
	if (!success):
		printerr("Unable to find a suitable level to spawn")
	return false



func spawn_specific_level_from_door(level_index, door_tiles_world_pos: Array, door_direction: Vector2):
	#print("Spawning level from door...")
	
	# Make attempts to spawn one of the candidates
	var success = false
	var MAX_ATTEMPTS = 10
	var attempt_count = 0
	while (!success and attempt_count < MAX_ATTEMPTS):	
		var level_index_to_try = level_index
		var door_dir_key = scene_data_door_direction_key_from_vector(door_direction * -1)
		var door_dir_used_key = scene_data_door_direction_key_from_vector(door_direction * -1, true)
		var door_set = loaded_scenes[level_index_to_try][door_dir_key][0]
		var candidate_door_tiles_world_pos = door_coords_to_world_space(door_set, loaded_scenes[level_index_to_try]["interface_tilemap"])

		# Look for a position that we could place our new level
		var max_level_offset = Vector2(25, 2)
		var min_level_offset = Vector2(10, -2)
		var new_position = find_position_for_level(level_index_to_try, door_tiles_world_pos, candidate_door_tiles_world_pos, door_direction, max_level_offset, min_level_offset)
		
		# If position search didn't fail, add new level to tree
		if (new_position):
			var scene_instance = loaded_scenes[level_index_to_try]["scene_instance"]
			translate_tilemaps_in_scene(scene_instance, new_position - scene_instance.position)
			scene_instance.position += new_position
			loaded_scenes[level_index_to_try]["scene_instance"] = scene_instance
			
			# Find the location of each door in global tileset space
			var a_coord = my_tilemap.world_to_map(util_get_top_left_vector(door_tiles_world_pos)) 
			var b_coord = my_tilemap.world_to_map(new_position) + util_get_top_left_vector(door_set)
			var path = find_path_random(a_coord, b_coord, door_direction, door_direction * -1, Vector2(3, 3))
			path = clean_path(path)
			fill_path_full(path)
			
			# add to scene tree
			add_level_to_scene_tree(level_index_to_try)
			success = true
			return true
			
	# Print error if we maxed out our attempts to spawn and were unable to
	if (!success):
		printerr("Unable to find a suitable level to spawn")
	return false



func clear_interface_tilemaps_from_loaded_levels():
	for level in loaded_scenes:
		level["interface_tilemap"].clear()


# SOMEWHERE IS A BADLY TRANSLATED POSITION
# Returns new level position or false if none found
func find_position_for_level(level_index:int, from_door_global: Array, to_door_global: Array, from_door_direction: Vector2, max_offset: Vector2, min_level_offset: Vector2):
	var scene_instance = loaded_scenes[level_index]["scene_instance"]
	var level_size = loaded_scenes[level_index]["size"]
	var level_tile_offset = loaded_scenes[level_index]["topleft_tile_local_offset"] 	# world space
	
	var from_door_center = util_round_vector(util_find_average_point(from_door_global))
	var to_door_center = util_round_vector(util_find_average_point(to_door_global))
	
	var offset_x = RNG.randi_range(min_level_offset.x, max_offset.x)
	var offset_y = RNG.randi_range(min_level_offset.y, max_offset.y)
	var offset = Vector2(offset_x, offset_y)
	var offset_between_doors = from_door_center - to_door_center + (offset * tile_size)
	return scene_instance.position + offset_between_doors



func translate_tilemaps_in_scene(scene, translation: Vector2):
	var tilemaps = get_all_tilemaps_in_node(scene)
	for tilemap in tilemaps:
		tilemap.position += translation



# Offsets an array of vectors by the position of the given tilemap to convert coordinates in local
# tilemap space to global tilemap space.
func door_coords_to_global(door_coords: Array, tilemap: TileMap):
	var coordinate_offset = Vector2(floor(tilemap.position.x / tile_size.x), floor(tilemap.position.y / tile_size.y))
	for coordinate in door_coords:
		coordinate += coordinate_offset
	return door_coords



func door_coords_to_world_space(door_coords: Array, tilemap: TileMap):
	var world_coords = []
	for coordinate in door_coords:
		world_coords.append(coordinate * tile_size + tilemap.position)
	return world_coords



# Get a list of dictionaries like "{"level_index" : int, "door_set_global" : [Vector2]}"
func find_levels_with_door_constraints(door_side:Vector2, door_size:int, must_be_unspawned = true):
	#print("Looking for doors with direction: ", door_side, ", and size: ", door_size, "... ")
	var candidate_indexes = []
	var dir_key = scene_data_door_direction_key_from_vector(door_side)
	print("DIR_KEY: ", dir_key)
	for i in range(len(loaded_scenes)):
		if (!(must_be_unspawned and loaded_scenes[i]["is_spawned"])):
			var candidate_door_sets = loaded_scenes[i][dir_key]
			for door_set_index in range(len(candidate_door_sets)):
				if (len(candidate_door_sets[door_set_index]) == door_size): # Found a good door
					candidate_indexes.append({
						"level_index" : i, 
						"door_dir_key" : dir_key,
						"door_set_index" : door_set_index
						})
	#print ("...", len(candidate_indexes), " found")
	return candidate_indexes



# Recursive DFS for all tilemaps under this node
func get_all_tilemaps_in_node(node):
	var tilemaps = []
	var children = node.get_children()
	if (len(children) == 0):
		return tilemaps
	for child in children:
		if (child is TileMap):
			tilemaps.append(child)
		else:
			var new_maps = get_all_tilemaps_in_node(child)
			for map in new_maps:
				tilemaps.append(map)
	return tilemaps



# General DFS to get all children matching a given name
func get_children_recursive_by_name(node, name):
	var objects = []
	var children = node.get_children()
	if (len(children) == 0):
		return objects
	for child in children:
		if (child.name == name):
			objects.append(child)
		else:
			var sub_objects = get_children_recursive_by_name(child, name)
			for obj in sub_objects:
				objects.append(obj)
	return objects



# Return a vector2 indicating the side nearest to a given set of door tiles
func find_nearest_side_to_door_tile_set(tilemap:TileMap, door_tiles:Array):
	var bounds = tilemap.get_used_rect()
	var door_pos = util_find_average_point(door_tiles)
	
	# Get distances from door to each side
	var distance_to_top = door_pos.distance_to(Vector2(bounds.position.x + bounds.size.x /2, bounds.position.y))
	var distance_to_right = door_pos.distance_to(Vector2(bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y /2))
	var distance_to_bottom = door_pos.distance_to(Vector2(bounds.position.x + bounds.size.x /2, bounds.position.y + bounds.size.y))
	var distance_to_left = door_pos.distance_to(Vector2(bounds.position.x, bounds.position.y + bounds.size.y /2))
	
	# Initialize nearest side as the top
	var nearest_side = Vector2.UP
	var smallest_dist = distance_to_top

	# Check distance right
	if (distance_to_right < smallest_dist): 
		nearest_side = Vector2.RIGHT
		smallest_dist = distance_to_right
	
	# Check distance bottom
	if (distance_to_bottom < smallest_dist): 
		nearest_side = Vector2.DOWN
		smallest_dist = distance_to_bottom
	
	# Check distance left
	if (distance_to_left < smallest_dist): 
		nearest_side = Vector2.LEFT
	return nearest_side # Return nearest side



# Return average of an array of points
func util_find_average_point(points:Array):
	var sum = Vector2()
	for point in points:
		sum += point
	return sum / len(points)



func util_round_vector(v:Vector2):
	v.x = round(v.x)
	v.y = round(v.y)
	return v


# Return a list of lists of door tiles in a tilemap, grouped together if they're connected
func find_door_coordinate_sets_in_tilemap(tilemap:TileMap, door_id:int):
	var door_tiles = tilemap.get_used_cells_by_id(door_id)
	var door_tile_sets = []
	var used_door_tiles = []
	for i in range(len(door_tiles)): # Look through all door tiles
		if (!used_door_tiles.has(door_tiles[i])): # Found new SINGLE door
			var new_door_tile_set = [door_tiles[i]]
			used_door_tiles.append(door_tiles[i])
			var twin_neighbor = find_twin_neighbor_in_tilemap(tilemap, door_tiles[i], Array())
			
			if (twin_neighbor): # Is DOUBLE door
				used_door_tiles.append(twin_neighbor)
				new_door_tile_set.append(twin_neighbor)
				var triplet_neighbor = find_twin_neighbor_in_tilemap(tilemap, door_tiles[i], [twin_neighbor])
				
				if (triplet_neighbor): 	# Is TRIPLE door
					used_door_tiles.append(triplet_neighbor)
					new_door_tile_set.append(triplet_neighbor)
			door_tile_sets.append(new_door_tile_set)
			#print("APPENDING: ", new_door_tile_set)
	return door_tile_sets



func find_twin_neighbor_in_tilemap(tilemap:TileMap, origin_tile:Vector2, tiles_to_exclude:Array):
	var tile_type = tilemap.get_cellv(origin_tile)
	for x in range(-1, 2):
		for y in range(-1, 2):
			if (!(x == 0 and y == 0)): # If not on original tile
				var offset = Vector2(x, y)
				var neighbor_tile = origin_tile + offset
				var neighbor_type = tilemap.get_cellv(neighbor_tile)
				if (neighbor_type == tile_type): #  and !tiles_to_exclude.has(neighbor_tile)
					return neighbor_tile
	return false



# Return a dirty path between begin and end using a random jump & check method. 
func find_path_random(begin: Vector2, end: Vector2, begin_dir: Vector2, end_dir: Vector2, collision_size:Vector2, max_jump = 6):
	#print("_____________________")
	#print("Finding path between: ", begin, ", ", end)	
	var path = [begin]
	var last_points = [end]

	# Adjust begin and end points according to door hints if they exist.
	# This algorithm may not need this step
	var begin_hint_direction = begin_dir
	var end_hint_direction = end_dir
	if (begin_hint_direction):
		print("Found begin hint")
		begin += begin_hint_direction * collision_size
		path.append(begin)
	if (end_hint_direction):
		print("Found end hint")
		end += end_hint_direction * collision_size
		last_points.insert(0, end)
	print("After hint check, begin and end: ", begin, ", ", end)

	# Prepare data for random jump
	var direction = end - begin # this vector should always be ints
	var tiles_remaining_x = abs(direction.x)
	var tiles_remaining_y = abs(direction.y)
	var current_position = begin
	var iterations = 0
	var MAX_ITERATIONS = 15

	while (tiles_remaining_x > 0 or tiles_remaining_y > 0):
		#print("     Iteration: ", iterations, ", tiles_remaining: ", tiles_remaining_x + tiles_remaining_y)
		for attempt in range(10):	# attempt to find random jump vector
			var jump_vector
			var jump_distance
			if (RNG.randf() < tiles_remaining_y / (tiles_remaining_x + tiles_remaining_y)):
				# Jump vertically
				jump_distance = RNG.randi_range(0, min(tiles_remaining_y, max_jump)) * util_get_sign(direction.y)
				jump_vector = Vector2(0, jump_distance)
			else:
				# Jump horizontally
				jump_distance = RNG.randi_range(0, min(tiles_remaining_x, max_jump)) * util_get_sign(direction.x)
				jump_vector = Vector2(jump_distance, 0)

			# If jump is safe, update current position and move on
			if (!check_collision_in_tilemap(Rect2(current_position + jump_vector, collision_size), 0)):
				#print("     Found safe jump from: ", current_position, " to ", current_position + jump_vector)
				current_position += jump_vector
				tiles_remaining_x -= abs(jump_vector.x)
				tiles_remaining_y -= abs(jump_vector.y)
				path.append(current_position)
				break
		if (iterations >= MAX_ITERATIONS):
			printerr("Unable to find path between ", begin, " and ", end, ". Max iterations reached.")
			break
			#return false
		else:
			iterations += 1
	# End path finding loop

	# Append the last points, if there are any
	for p in last_points:
		path.append(p)
	#print("Path found with random jump algorithm: ", path)
	return path
# End func



func fill_path_full(path):
	print("_________________________")
	print("Filling path: ", path)
	
	# Fill all the corners with a full kernel
	for i in range(len(path)):
		if (i != 0 and i != len(path) -1):
			fill_rect(Rect2(path[i] + Vector2(-1, -1), Vector2(3, 3)), interface_tileset_id_lookup["wall"])
	
	# Fill all hall segments on path
	for i in range(len(path) -1):
		var corner_before = false
		var corner_after = false
		if (i > 0):
			corner_before = true
		if (i < len(path) -2):
			corner_after = true
		fill_line_single(path[i], path[i+1], corner_before, corner_after)



func fill_line_single(begin: Vector2, end: Vector2, corner_before: bool, corner_after: bool):
	# Exit early if begin and end cannot be joined with a straight line or if args equal
	if ((begin.x != end.x and begin.y != end.y) or begin == end):
		#printerr("Error generating straight hall segment - diagonal or equal args recieved")
		return
	
	# Get the normalized direction vector and distance scalar 
	var dir_vec = end - begin
	var dir_normalized = dir_vec.normalized()
	var distance = max(abs(dir_vec.x), abs(dir_vec.y))
	
	# Get the axis of the hall
	var is_horizontal = false
	if (abs(dir_normalized.x) > 0):
		is_horizontal = true
	
	for i in range(distance + 1):
		if (!(i == 0 and corner_before) and !(i == distance and corner_after)):
			if (is_horizontal):
				my_tilemap.set_cellv(begin + (dir_normalized * i) + Vector2.UP, interface_tileset_id_lookup["wall"])
				my_tilemap.set_cellv(begin + (dir_normalized * i) + Vector2.DOWN, interface_tileset_id_lookup["wall"])
			elif (!is_horizontal):
				my_tilemap.set_cellv(begin + (dir_normalized * i) + Vector2.RIGHT, interface_tileset_id_lookup["wall"])
				my_tilemap.set_cellv(begin + (dir_normalized * i) + Vector2.LEFT, interface_tileset_id_lookup["wall"])
		my_tilemap.set_cellv(begin + (dir_normalized * i), interface_tileset_id_lookup["wall"])



# Fill a rect with tiles in the world
func fill_rect(rect:Rect2, tile_id:int):
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			my_tilemap.set_cellv(rect.position + Vector2(x, y), tile_id)



# Remove any unnecessary points
func clean_path(path):
	var is_path_clean = false
	while (!is_path_clean):
		for i in range(1, len(path) -1):
			var point = path[i]
			var prev = path[i-1]
			var next = path[i+1]
			if ((point.x == prev.x and point.x == next.x) or (point.y == prev.y and point.y == next.y) or (point == prev) or (point == next)):
				path.remove(i)
				break
		is_path_clean = true # If we make it to end of loop we've checked all points
	print("Cleaning path. After: ", path)
	return path



# Return the vector2 direction of a hint tile relative to a door if there is one
func find_hint_direction(tilemap:TileMap, door_cell:Vector2):
	if (tilemap.get_cellv(door_cell + Vector2.UP) == interface_tileset_id_lookup["hint"]):
		return Vector2.UP
	if (tilemap.get_cellv(door_cell + Vector2.RIGHT) == interface_tileset_id_lookup["hint"]):
		return Vector2.RIGHT
	if (tilemap.get_cellv(door_cell + Vector2.DOWN) == interface_tileset_id_lookup["hint"]):
		return Vector2.DOWN
	if (tilemap.get_cellv(door_cell + Vector2.LEFT) == interface_tileset_id_lookup["hint"]):
		return Vector2.LEFT
	return false



# Return true if any tiles within the given rect contain non-empty values
func check_collision_in_tilemap(in_rect:Rect2, large_tile_buffer:int):
	# Check all tiles in rect region
	for x in range(in_rect.size.x):
		for y in range(in_rect.size.y):
			var cell = my_tilemap.get_cellv(in_rect.position + Vector2(x, y))
			if (cell != -1):
				return true
	# Does not check large_tile_buffer region for now
	return false



func get_random_point_in_rect(rect:Rect2):
	var point = Vector2()
	RNG.randomize()
	point.x = RNG.randi_range(rect.position.x, rect.size.x)
	point.y = RNG.randi_range(rect.position.y, rect.size.y)
	return point



# Returns the center point of a rectangle
func get_rect_center(rect:Rect2):
	return Vector2(rect.position.x + floor(rect.size.x/2), rect.position.y + floor(rect.size.y/2))



# Return a random integer Vector2 within some offset of a given point 
func get_random_point_int(origin:Vector2, max_offset:int):
	var point = Vector2()
	RNG.randomize()
	point.x = RNG.randi_range(origin.x - max_offset, origin.x + max_offset)
	point.y = RNG.randi_range(origin.y - max_offset, origin.y + max_offset)
	return point



# Return -1, 0 or 1
func util_get_sign(number):
	if (number < 0):
		return -1
	elif (number > 0):
		return 1
	else:
		return 0


func util_get_top_left_vector(vecs: Array):
	var top_left_anchor = Vector2(-99999, -99999)
	var current_closest = 999999999
	var my_top_left = Vector2()
	for vec in vecs:
		var distance = vec.distance_to(top_left_anchor)
		if (distance < current_closest):
			current_closest = distance
			my_top_left = vec
	return my_top_left



func dbg_draw_rect(rect:Rect2, col:Color, thickness):
	var line = Line2D.new()
	var pos = rect.position
	var size = rect.size
	line.width = thickness
	line.default_color = col
	line.add_point(Vector2(pos.x, pos.y) * tile_size)
	line.add_point(Vector2(pos.x + size.x, pos.y) * tile_size)
	line.add_point(Vector2(pos.x + size.x, pos.y + size.y) * tile_size)
	line.add_point(Vector2(pos.x, pos.y + size.y) * tile_size)
	line.add_point(Vector2(pos.x, pos.y) * tile_size)
	add_child(line)



func dbg_print_level_data(level_data):
	print("______________________")
	print("Printing level data for: ", level_data["scene_instance"])
	print("Topleft Tile Offset: ", level_data["topleft_tile_local_offset"])
	print("Size: ", level_data["size"])
	print("Is Spawned?: ", level_data["is_spawned"])
	print("Difficulty: ", level_data["difficulty"])
	print("Top Door Coords: ", level_data["top_door_local_coords"])
	print("Top Door Used Indexes: ", level_data["top_door_used_indexes"])
	print("Right Door Coords: ", level_data["right_door_local_coords"])
	print("Right Door Used Indexes: ", level_data["right_door_used_indexes"])
	print("Bottom Door Coords: ", level_data["bottom_door_local_coords"])
	print("Bottom Door Used Indexes: ", level_data["bottom_door_used_indexes"])
	print("Left Door Coords: ", level_data["left_door_local_coords"])
	print("Left Door Used Indexes: ", level_data["left_door_used_indexes"])



# DEPRECATED ----------------------

## Fill a straight line in the tilemap using blocks of cells (large tiles)
## Note: This may fail to place single hall tiles at times
#func generate_hallway(begin: Vector2, end: Vector2, corner_before: bool, corner_after: bool):
#
#	# Exit early if begin and end cannot be joined with a straight line or if args equal
#	if ((begin.x != end.x and begin.y != end.y) or begin == end):
#		printerr("Error generating straight hall segment - diagonal or equal args recieved")
#		return
#
#	#print("Generating hallway between: ", begin, ", ", end)
#
#	# Trim the segment to leave room for corners
#	if (begin.x < end.x and corner_before):	# Right -> Left
#		begin.x += corridor_tile_size
#
#	if (begin.x > end.x and corner_after): # Left -> Right
#		end.x += corridor_tile_size
#
#	if (begin.y < end.y and corner_before): # Top -> Bottom
#		begin.y += corridor_tile_size
#
#	if (begin.y > end.y and corner_after):	# Bottom -> Top
#		end.y += corridor_tile_size
#
#
#	# Make sure we're always generating in the same direction by swapping points if necessary
#	if (begin.x > end.x or begin.y > end.y):
#		print("Swapping!")
#		var temp_begin = begin
#		begin = end
#		end = temp_begin
##		var translate_vector
##		if (begin.x > end.x):
##			translate_vector = Vector2(1, 0)
##		else:
##			translate_vector = Vector2(0, 1)
##		begin += translate_vector
##		end += translate_vector
#
#	# Get the normalized direction vector and distance scalar 
#	var dir_vec = end - begin
#	var dir_normalized = dir_vec.normalized()
#	var distance = max(abs(dir_vec.x), abs(dir_vec.y))
#
#	# Get the axis of the hall
#	var is_horizontal = false
#	if (abs(dir_normalized.x) > 0):
#		is_horizontal = true
#
#	# Find the tile(s) we should use depending on direction
#	var full_tile_id = 0
#	var single_tile_id = 0
#	var full_tile_offset = Vector2(0, 0)
#	var single_tile_offset = Vector2(0, 0)
#	if (is_horizontal):
#		full_tile_id = interface_tileset_id_lookup["hall_h3"]
#		single_tile_id = interface_tileset_id_lookup["hall_h1"]
#	elif (!is_horizontal):
#		full_tile_id = interface_tileset_id_lookup["hall_v3"]
#		single_tile_id = interface_tileset_id_lookup["hall_v1"]
#
#	# Find the offsets for our selected tiles
##	var full_tile_region = world_tileset.tile_get_region(full_tile_id)
##	var single_tile_region = world_tileset.tile_get_region(single_tile_id)
##	if (is_horizontal):
##		if (dir_normalized.x > 0):
##			full_tile_offset = Vector2(-1, -1)
##			single_tile_offset = Vector2(-1, -1)
##		else:
##			full_tile_offset = Vector2(-1, -1)
##			single_tile_offset = Vector2(-1, -1)
##	elif (!is_horizontal):
##		if (dir_normalized.y > 0):
##			full_tile_offset = Vector2(-1, -1)
##			single_tile_offset = Vector2(-1, -1)
##		else:
##			full_tile_offset = Vector2(-1, -1)
##			single_tile_offset = Vector2(-1, -1)
#
#	# Prepare some data for the hall-building loop
#	var main_tiles_needed = floor(distance / corridor_tile_size)
#	var singles_needed = int(distance) % corridor_tile_size
#	var total_tiles_needed = main_tiles_needed + singles_needed
#	var single_tiles_placed = 0
#	var distance_so_far = 0
#
#	# This "chance to place" business should be generalized to build the hall with
#	# any number of pieces of any size. In fact, I should ONLY be using singles, perhaps,
#	# until I have a general system for placing tiles of any size. For now it's hard coded
#	# for only two sizes
#	#var chance_to_place_single = 0
#	#if (singles_needed > 0):
#	#	chance_to_place_single = 1 / total_tiles_needed * singles_needed
#
#	# Place the tiles in the hall
#	for i in range(total_tiles_needed):
#		if (single_tiles_placed < singles_needed):
#			var target_x = round(begin.x + dir_normalized.x * distance_so_far)
#			var target_y = round(begin.y + dir_normalized.y * distance_so_far)
#			world.set_cell(target_x, target_y, single_tile_id)
#			single_tiles_placed += 1 # Keep track so we don't place too many. 
#			distance_so_far += 1
#		else:
#			var target_x = round(begin.x + dir_normalized.x * distance_so_far)
#			var target_y = round(begin.y + dir_normalized.y * distance_so_far)
#			world.set_cell(target_x, target_y, full_tile_id)
#			distance_so_far += corridor_tile_size
#
#
#
#func generate_corner(a: Vector2, b: Vector2, c: Vector2):
#	# Find orientation of corner
#	var is_top = true
#	var is_left = true
#	if (a.y < b.y):
#		is_top = false
#	if (b.y > c.y):
#		is_top = false
#	if (a.x < b.x):
#		is_left = false
#	if (b.x > c.x):
#		is_left = false	
#
#	# Find tile ID
#	var corner_tile_id
#	if (is_top and is_left):
#		corner_tile_id = interface_tileset_id_lookup["corner_tl"]
#	elif (is_top and !is_left):
#		corner_tile_id = interface_tileset_id_lookup["corner_tr"]
#	elif (!is_top and is_left):
#		corner_tile_id = interface_tileset_id_lookup["corner_bl"]
#	elif (!is_top and !is_left):
#		corner_tile_id = interface_tileset_id_lookup["corner_br"]
#
#	# Clear existing tiles to avoid overlapping any other cells
##	var corner_tile_size = world_tileset.tile_get_region(corner_tile_id).size / tile_size
##	for x in range(corner_tile_size.x):
##		for y in range(corner_tile_size.y):
##			world.set_cell(b.x + x, b.y + y, -1)
#
#	# Write corner tile to world map
#	world.set_cellv(b, corner_tile_id)
# Fill a straight line in the tilemap between 2 points using single cells
#
#
#
#func generate_segment_single(begin: Vector2, end: Vector2):
#	var direction = end - begin
#	var dir_norm = direction.normalized()
#	for i in range(floor(direction.length())):
#		var target_cell_x = round(begin.x + dir_norm.x * i)
#		var target_cell_y = round(begin.y + dir_norm.y * i)
#		world.set_cell(target_cell_x, target_cell_y, 3)
#
#
# Return an array of vectors containing tilemap cells to traverse
#func find_path_regular(begin: Vector2, end: Vector2, collision_size:Vector2):
#	var path = [begin]
#	var last_points = [end]
#
#	# Adjust begin and end points according to door hints if they exist
#	var begin_hint_direction = find_hint_direction(begin)
#	var end_hint_direction = find_hint_direction(end)
#	if (begin_hint_direction):
#		begin += begin_hint_direction * collision_size
#		path.append(begin)
#	if (end_hint_direction):
#		end += end_hint_direction * collision_size
#		last_points.insert(0, end)
#
#	var difference = end - begin
#	if (difference.x == 0 or difference.y == 0): # Use straight line
#		path.append(end)
#		return path
#	elif (difference.x >= difference.y):	# Differentiate btw options for path
#		path.append(Vector2(begin.x + floor(difference.x /2), begin.y))
#		path.append(Vector2(begin.x + floor(difference.x /2), begin.y + difference.y))
#	elif (difference.x < difference.y):
#		path.append(Vector2(begin.x, begin.y + floor(difference.y /2)))
#		path.append(Vector2(begin.x + difference.x, begin.y + floor(difference.y /2)))
#	for p in last_points:
#		path.append(p)
#	return path
#
#
# Spawns all tiles from a tilemap into the main world starting at a given pos
#func spawn_tilemap(level_index, tilemap:TileMap, position:Vector2):
#	var tilemap_bounds = tilemap.get_used_rect()
#	var spawn_offset = tilemap_bounds.position - position
#	spawned_level_bounds.append(Rect2(spawn_offset, tilemap_bounds.size)) # Log the level bounds
#	var cells = tilemap.get_used_cells()
#	var new_doors = []
#	for cell in cells:
#		world.set_cellv(cell - spawn_offset, tilemap.get_cell(cell.x, cell.y))
#		if (tilemap.get_cellv(cell) == interface_tileset_id_lookup["door"]):
#			new_doors.append(cell - spawn_offset)
#			dbg_draw_rect(Rect2(cell - spawn_offset, Vector2(1, 1)), Color.green, 1)
#	door_tiles.append(new_doors)
#
#
# Spawns a scene within a given offset of a point in the tilemap. Checks for collisions.
#func spawn_level_from_point(level_index, point:Vector2, max_offset:int):
#	print("Attempting to spawn level within ", max_offset, " of ", point, "...")
#
#	# Load tilemap from scene
#	var scene = levels_to_spawn[level_index].instance()
#	var tilemap = -1
#	for child in scene.get_children():
#		if child is TileMap:
#			tilemap = child
#			break
#	if (!tilemap is TileMap):
#		print("Error spawning level - no tilemap found in scene")
#		return
#
#	# Check collision and spawn
#	var new_map_bounds = tilemap.get_used_rect()
#	for i in range(25):
#		var spawn_point = get_random_point_int(point, max_offset)
#		var test_spawn_bounds = Rect2(spawn_point, new_map_bounds.size).grow(10)
#		if (!check_collision_in_tilemap(test_spawn_bounds, 0)):
#			spawn_tilemap(level_index, tilemap, spawn_point)
#			spawned_level_indexes.append(level_index)
#			dbg_draw_rect(test_spawn_bounds, Color.yellow, 3)
#			dbg_draw_rect(Rect2(spawn_point, new_map_bounds.size), Color.green, 3)
#			print("...Success")
#			return true
#	print("...Unable to find safe spot")
#	return false


# Looks for the first two doors and generates a path between them
#func connect_doors():
#	if (len(door_tiles) >= 2):
#		var door_pair = find_door_pair()
#		path_points = find_path_random(door_pair[0], door_pair[1], Vector2(3, 3))
#		if	(path_points):
#			path_points = clean_path(path_points)
#			fill_path_full(path_points)
#		else:
#			print("Unable to connect doors")



# Returns the locations of the two doors closest to each other
#func find_door_pair():
#	var shortest_distance = 99999
#	var best_pair = []
#	for room_index_1 in range(len(door_tiles)):
#		for room_index_2 in range(len(door_tiles)):
#			if (room_index_1 == room_index_2):
#				break
#			var r1_doors = door_tiles[room_index_1]
#			var r2_doors = door_tiles[room_index_2]
#			for d1 in r1_doors:
#				for d2 in r2_doors:
#					if (d1 == d2):
#						break
#					var distance = d1.distance_to(d2)
#					if (distance < shortest_distance):
#						shortest_distance = distance
#						best_pair = [d1, d2]
#	print("Best door pair: ", best_pair)
#	return best_pair
