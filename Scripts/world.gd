extends Node2D

var world_seed = Global.current_seed
@export var noise_height_texture0 : NoiseTexture2D
@export var noise_height_texture1 : NoiseTexture2D
@export var noise_height_texture_coal : NoiseTexture2D
@export var noise_height_texture_iron : NoiseTexture2D
@export var noise_height_texture_ruby : NoiseTexture2D

@onready var tilemap = $TileMap
@onready var mining_timer = $MiningTimer
@onready var player_inventory = $hotbar/InventoryNode
@onready var tutorial_ui = $player/Tutorial
@onready var player = $player

@onready var mining_particle = preload("res://Scenes/mining_particle.tscn")
@onready var item = preload("res://Scenes/item.tscn")
@onready var merchant_scene = preload("res://Scenes/merchant.tscn")

var coal_texture = Global.item_textures["coal"]
var iron_texture = Global.item_textures["iron"]
var stone_texture = Global.item_textures["stone"]
var ruby_texture = Global.item_textures["ruby"]

var buildable_blocks = ["stone"]

var noise0 : Noise 
var noise1 : Noise 
var noise_coal : Noise 
var noise_iron : Noise 
var noise_ruby : Noise

var noises

var width : int = Global.WIDTH
var height : int = Global.HEIGHT

#chunking system
var chunk_size = Global.chunk_size
var loaded_chunks = {}
var CHUNK_LOAD_RADIUS = Global.render_distance  # Load chunks 2 units beyond visible area
var last_player_chunk = Vector2i(0, 0)
var world_top = Global.top_of_the_world #<-here am i
var cave_start = Global.cave_start
var bedrock_level = Global.rock_bottom

var stone_tiles = [
	Vector2i(6, 0),   # Stone base
	Vector2i(2, 0),   # Light gray rock
	Vector2i(3, 0),   # Darker stone
	Vector2i(1, 0),   # kinda modry stone
]

func _ready():
	noise0 = noise_height_texture0.noise
	noise1 = noise_height_texture1.noise 
	noise_coal = noise_height_texture_coal.noise 
	noise_iron = noise_height_texture_iron.noise 
	noise_ruby = noise_height_texture_ruby.noise
	
	noises = [noise0,noise1,noise_coal,noise_iron,noise_ruby]
	player_inventory.visible = Global.player_inventory_open
	for n in noises:
		print(world_seed)
		n.seed = world_seed
	
	mining_timer.timeout.connect(_on_mining_timer_timeout)
	#_generate_world()
	var start_chunk = Vector2i(
		floori(player.position.x / (chunk_size * tilemap.tile_set.tile_size.x)),
		floori(player.position.y / (chunk_size * tilemap.tile_set.tile_size.y))
	)
	
	update_active_chunks(start_chunk)
	$Effects/vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_inventory.visible = true			
	Global.god_mode = false

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		ChunkManager.save_all_active_chunks()

###############Chunking################
func update_active_chunks(center_chunk: Vector2i):
	# Only update if player moved to new chunk
	if center_chunk == last_player_chunk:
		return
	last_player_chunk = center_chunk
	
	# Calculate chunk range around player
	for x in range(center_chunk.x - CHUNK_LOAD_RADIUS, center_chunk.x + CHUNK_LOAD_RADIUS + 1):
		for y in range(center_chunk.y - CHUNK_LOAD_RADIUS, center_chunk.y + CHUNK_LOAD_RADIUS + 1):
			var chunk_pos = Vector2i(x, y)
			if !loaded_chunks.has(chunk_pos):
				generate_chunk(x, y)
				loaded_chunks[chunk_pos] = true

func _apply_saved_modifications(modifications: Dictionary, chunk_start_x: int, chunk_start_y: int):
	for local_pos in modifications:
		var world_pos = Vector2i(
			chunk_start_x + int(local_pos.x),
			chunk_start_y + int(local_pos.y)
		)
		var tile_data = modifications[local_pos]
		
		if tile_data is Dictionary:
			if tile_data["id"] == -1:
				tilemap.erase_cell(0, world_pos)
			else:
				tilemap.set_cell(0, world_pos, 
					tile_data["id"], 
					tile_data.get("atlas", Vector2i(0, 0)))
					
# Helper to get proper visual variants
func _get_default_atlas_coords(tile_id: int) -> Vector2i:
	match tile_id:
		0: return Vector2i(6, 0)  # Stone
		1: return Vector2i(1, 0)  # Coal  
		2: return Vector2i(1, 0)  # Iron
		3: return Vector2i(1, 0)  # Placed stone
		4: return Vector2i(1, 0)  # Ruby
		_: return Vector2i(0, 0)

func generate_caves(chunk_x,chunk_y):
	var start_x = chunk_x * chunk_size
	var start_y = chunk_y * chunk_size
	var end_x = start_x + chunk_size
	var end_y = start_y + chunk_size
	# Regular cave generation for underground areas
	noise_to_tiles(noise1, [
		[-0.1, 0.0, [0, 0, [5, 0]]],
		[0.0, null, [0, 0, [6, 0]]],
		[0.1, 0.15, [0, 0, [4, 0]]],
	], start_x, end_x, start_y, end_y)
	
	noise_to_tiles(noise0, [
		[0.0, null, [0, 0, [6, 0]]],
		[0.1, 0.2, [0, 0, [2, 0]]],
		[0.2, 0.3, [0, 0, [3, 0]]],
	], start_x, end_x, start_y, end_y)
	
	# Only generate ores underground
	if start_y > cave_start:
		generate_ore(noise_coal, 0.4, 1, Vector2i(1,0), stone_tiles, chunk_x, chunk_y)
		generate_ore(noise_iron, 0.49, 2, Vector2i(1,0), stone_tiles, chunk_x, chunk_y)
		generate_ore(noise_ruby, 0.69, 4, Vector2i(1,0), stone_tiles, chunk_x, chunk_y)
		
func generate_chunk(chunk_x: int, chunk_y: int):
	var start_x = chunk_x * chunk_size
	var start_y = chunk_y * chunk_size
	var end_x = start_x + chunk_size
	var end_y = start_y + chunk_size
		
	# Only generate surface terrain if above cave start level
	if start_y <= world_top:
		wave_terrain(chunk_x, chunk_y)
		return
	
	# Generate bedrock layer at bottom
	if start_y >= bedrock_level:
		generate_bedrock_layer(chunk_x, chunk_y)
		return
	
	else:
		generate_caves(chunk_x,chunk_y)
	
	var modifications = ChunkManager.get_chunk_modifications(Vector2(chunk_x,chunk_y))
	if modifications.size() > 0:
		_apply_saved_modifications(modifications, start_x,start_y)
	
#func unload_distant_chunks():
	#var player_tile_pos = tilemap.local_to_map(player.position)
	#var player_chunk = Vector2i(
		#floori(player_tile_pos.x / float(chunk_size)),
		#floori(player_tile_pos.y / float(chunk_size))
	#)
	#
	#var chunks_to_unload = []
	#for chunk in loaded_chunks:
		#if abs(chunk.x - player_chunk.x) > CHUNK_LOAD_RADIUS + 1 or \
		   #abs(chunk.y - player_chunk.y) > CHUNK_LOAD_RADIUS + 1:
			#chunks_to_unload.append(chunk)

##########################WORLD GENERATION##########################
#values: [min,max,[layer,source_id,[atlas_x,atlas_y]]]
func noise_to_tiles(input_noise, lists, start_x, end_x, start_y, end_y):
	for x in range(start_x,end_x):
		for y in range(start_y,end_y):
			var noise_val = input_noise.get_noise_2d(x,y)
			#if x == 0 or y == 0 or x == width-1 or y == height-1:
				#noise_val += 0.5
			for values in lists:
				if values[0] == null:
					if noise_val < values[1]:
						tilemap.set_cell(
						values[2][0],
						Vector2i(x,y),
						values[2][1],
						Vector2i(values[2][2][0],values[2][2][1])
						)
						
				if values[1] == null:
					if noise_val > values[0]:
						tilemap.set_cell(
						values[2][0],
						Vector2i(x,y),
						values[2][1],
						Vector2i(values[2][2][0],values[2][2][1])
						)
				else:
					if noise_val > values[0] and noise_val < values[1]:
						
						tilemap.set_cell(
						values[2][0],
						Vector2i(x,y),
						values[2][1],
						Vector2i(values[2][2][0],values[2][2][1])
						)

func generate_bedrock_layer(chunk_x: int, chunk_y: int):
	var start_x = chunk_x * chunk_size
	var start_y = chunk_y * chunk_size
	var end_x = start_x + chunk_size
	var end_y = start_y + chunk_size
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(6, 0))  # Solid bedrock

func wave_terrain(chunk_x: int, chunk_y: int):
	var left: int = chunk_x * chunk_size
	var right: int = left + chunk_size
	
	var a: float = 0.081 * left
	var b: float = 0.045 * left
	var a_increase = 0.081
	var b_increase = 0.045
	var block_type: int = 0
	
	for x in range(left, right):
		var map_height: int = int(sin(a) * 8 + sin(b) * 6) + world_top
		
		# Fill terrain from surface downwards
		for y in range(world_top - map_height, world_top + randi_range(20,22)):  # 5 blocks deep surface
			if y > world_top + 50:  # Don't generate above max surface height
				continue
			if randf_range(0,5) > 4.8:
				block_type = 2  # Gravel
			else:
				block_type = 0  # Dirt
			if y == world_top - map_height:
				block_type = 1  # Grass
			match block_type:
				0: tilemap.set_cell(0, Vector2i(x, y), 5, Vector2i(2, 0))
				1: tilemap.set_cell(0, Vector2i(x, y), 5, Vector2i(1, 0))
				2: tilemap.set_cell(0, Vector2i(x, y), 5, Vector2i(3, 0))
				_: tilemap.set_cell(0, Vector2i(x, y), 5, Vector2i(2, 0))
				
		a += a_increase
		b += b_increase
	
#func _generate_world():
	## Main terrain generation
	#
	#noise_to_tiles(noise1,[
		#[-0.1, 0.0, [0, 0, [5, 0]]],   # Brownish ground
		#[0.0, null, [0, 0, [6, 0]]],   # Default ground
		#[0.1, 0.15, [0, 0, [4, 0]]],   # Extra details
	#])
#
	#noise_to_tiles(noise0,[
		#[0.0, null, [0, 0, [6, 0]]],   # Stone base
		#[0.1, 0.2, [0, 0, [2, 0]]],    # Light gray rock
		#[0.2, 0.3, [0, 0, [3, 0]]],    # Darker stone
	#])
#
	## Generate coal only in valid stone/rock tiles
	#generate_ore(noise_coal,0.4,1,Vector2i(1,0),stone_tiles)
	#generate_ore(noise_iron,0.49,2,Vector2i(1,0),stone_tiles)
	#generate_ore(noise_ruby,0.69,4,Vector2i(1,0),stone_tiles)
	#wave_terrain()
	##spawn_merchant()
	
func generate_ore(noise: Noise, threshold: float, source_id: int, _atlas_coords: Vector2i, valid_tiles: Array, chunk_x: int, chunk_y: int):
	var start_x = chunk_x * chunk_size #- width / 2.0
	var end_x = start_x + chunk_size
	var start_y = chunk_y * chunk_size #- height / 2.0
	var end_y = start_y + chunk_size
	print("ores")
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var noise_val = noise.get_noise_2d(x, y)
			if noise_val > threshold:
				var tile_pos = Vector2i(x, y)
				# Get the tile below the current position
				var tile_below = tilemap.get_cell_atlas_coords(0, tile_pos + Vector2i(0, 1))

				if tile_below in valid_tiles:
					tilemap.set_cell(0, tile_pos, source_id, tile_below)	# Set ore tile
					print("Ore generated at: ", tile_pos, " with source_id: ", source_id)	
							
func spawn_merchant():
	var merchant_instance = merchant_scene.instantiate()
	merchant_instance.position = player.position
	add_child(merchant_instance)



###############actions################




func spawn_drop(pos, quantity, item_type, item_name, texture):
	var drop_instance = item.instantiate()
	drop_instance.position = pos + Vector2(0, -5)  # Slightly above ground
	drop_instance.quantity = quantity
	drop_instance.item_type = item_type
	drop_instance.item_name = item_name
	drop_instance.item_texture = texture
	
	if item_type == "coal":
		drop_instance.texture_id = 0
	elif item_type == "iron":
		drop_instance.texture_id = 1
	elif item_type == "stone":
		drop_instance.texture_id = 2
	elif item_type == "ruby":
		drop_instance.texture_id = 3
	
	add_child(drop_instance)

func get_tile_under_mouse():
	var mouse_pos = get_local_mouse_position()
	return tilemap.local_to_map(mouse_pos)  

func place():
	var tile_pos = get_tile_under_mouse()
	var current_block = Global.inventory[player_inventory.hovered_index]
	
	if current_block and current_block["item_type"] in buildable_blocks and tilemap.get_cell_source_id(0,tile_pos) == -1:
		var chunk_pos = Vector2i(
			floori(tile_pos.x / float(chunk_size)),
			floori(tile_pos.y / float(chunk_size))
		)
		ChunkManager.record_block_modification(tile_pos,3,Vector2i(1,0))
		
		tilemap.set_cell(0, tile_pos, 3, Vector2i(1, 0))
		current_block["quantity"] -= 1
		Global.inventory_updated.emit()
		
func mine():
	var tile_pos = get_tile_under_mouse()
	var source_id = tilemap.get_cell_source_id(0, tile_pos)
	var atlas_coords = tilemap.get_cell_atlas_coords(0, tile_pos)  # Get the tile atlas coordinates
	var particle_instance : CPUParticles2D = mining_particle.instantiate()
	
	if source_id == -1: return
	
	var chunk_pos = Vector2i(
		floori(tile_pos.x / float(chunk_size)),
		floori(tile_pos.y / float(chunk_size))
	)
	
	# Modify or erase the tile based on its type
	if atlas_coords and atlas_coords.y < 3:
		particle_instance.position = Vector2(tilemap.map_to_local(tile_pos))
		particle_instance.emitting = true
		AudioManager.play_random_pitch(AudioManager.mining_block,0.9,1)
		add_child(particle_instance)
		var new_tile_coords = Vector2i(atlas_coords.x, atlas_coords.y + 1)
		tilemap.set_cell(0, tile_pos, source_id, new_tile_coords)  # Keep source ID the same
		
	elif atlas_coords.y == 3: #block destroyed
		# In mine() and place():
		ChunkManager.record_block_modification(tile_pos,-1,Vector2i(-1,-1))
		AudioManager.play_random_pitch(AudioManager.mining_block,0.7,1.1)
		if source_id == 0 or source_id == 3:
			spawn_drop(Vector2(tilemap.map_to_local(tile_pos)),1,"stone","Stone",stone_texture)
			
		elif source_id == 1:
			spawn_drop(Vector2(tilemap.map_to_local(tile_pos)),1,"coal","Coal",coal_texture)
		
		elif source_id == 2:
			spawn_drop(Vector2(tilemap.map_to_local(tile_pos)),1,"iron","Iron",iron_texture)
		
		elif source_id == 4:
			spawn_drop(Vector2(tilemap.map_to_local(tile_pos)),1,"ruby","Ruby",ruby_texture)
		tilemap.erase_cell(0, tile_pos)  # Remove the tile

##############SIGNALS######################
func _on_mining_timer_timeout():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Global.player_can_mine:
		mine()
		Global.current_player_state = "mining"
		mining_timer.start(Global.delay_inbetween_mining)

##########Input and events#######################




func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		player_inventory.visible = false
		FadingEffect.transition()
		await FadingEffect.on_transition_finished
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		
	if !Global.god_mode:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Global.player_can_mine and mining_timer.is_stopped():
			mine() 
			mining_timer.start(Global.delay_inbetween_mining)
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Global.god_mode:
			mine()
		
		mining_timer.start(Global.delay_inbetween_mining)
		if not Global.did_mine:
			Global.did_mine = true
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		place()
	
	if Input.is_action_just_pressed("open_inventory"):
		Global.player_inventory_open = !Global.player_inventory_open  
		player_inventory.visible = Global.player_inventory_open
		if not Global.did_tab:
			Global.did_tab = true
			
	if Input.is_action_just_pressed("show_help"):
		tutorial_ui.visible = not tutorial_ui.visible	
	
	if Input.is_action_just_pressed("god_mode"):
		Global.god_mode = not Global.god_mode
		print(Global.god_mode)
	
func _process(_delta):
	# Update chunks based on player position instead of camera
	var player_tile_pos = tilemap.local_to_map(player.position)
	var current_chunk = Vector2i(
		floori(player_tile_pos.x / float(chunk_size)),
		floori(player_tile_pos.y / float(chunk_size))
	)
	update_active_chunks(current_chunk)
	#unload_distant_chunks()
	if Global.did_mine and Global.did_scroll and Global.did_tab:
		tutorial_ui.visible = false
	queue_redraw()
