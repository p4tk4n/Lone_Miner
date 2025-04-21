extends Node2D

var world_seed = randi()
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

var buildable_blocks = ["Stone"]

var noise0 : Noise 
var noise1 : Noise 
var noise_coal : Noise 
var noise_iron : Noise 
var noise_ruby : Noise

var noises

var width : int = Global.WIDTH
var height : int = Global.HEIGHT

var world_thread = Thread.new()
var world_data = []

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
	_generate_world()
	$Effects/vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_inventory.visible = true			

#values: [min,max,[layer,source_id,[atlas_x,atlas_y]]]
func noise_to_tiles(input_noise,lists):
	for x in range(0,width):
		for y in range(0,height):
			var noise_val = input_noise.get_noise_2d(x,y)
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				noise_val += 0.5
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

func wave_terrain():
	# Bounds
	var top: int = 20  # Adjusted for better terrain positioning
	var left: int = 0
	var right: int = width
	
	var a: float = 0
	var b: float = 0
	var a_increase = 0.081
	var b_increase = 0.045
	var block_type: int = 0
	
	for x in range(left, right):
		#smartass meth eq for the sin wave-like terrain
		var map_height: int = int(sin(a) * 8 + sin(b) * 6)
		
		#fill terrain from generated height downwards
		for y in range(top - map_height, top+randi_range(20,22)):
			#if the current block is the 1st one its set to block type 1 (grassblock)
			#random blocks are also placed
			
			if randf_range(0,5) > 4.8:
				block_type = 2 #bt 2 is gravel
			else:
				block_type = 0 #bt 0 is dirt
				
			if y == top-map_height:
				block_type = 1 #bt 1 is grass

			match block_type:
				0:
					tilemap.set_cell(0, Vector2i(x, y-40), 5, Vector2i(2, 0))
				1:
					tilemap.set_cell(0, Vector2i(x, y-40), 5, Vector2i(1, 0))
				2:
					tilemap.set_cell(0, Vector2i(x, y-40), 5, Vector2i(3, 0))
				_:
					tilemap.set_cell(0, Vector2i(x, y-40), 5, Vector2i(2, 0))
		a += a_increase
		b += b_increase
	
func _generate_world():
	# Main terrain generation
	
	noise_to_tiles(noise1,[
		[-0.1, 0.0, [0, 0, [5, 0]]],   # Brownish ground
		[0.0, null, [0, 0, [6, 0]]],   # Default ground
		[0.1, 0.15, [0, 0, [4, 0]]],   # Extra details
	])

	noise_to_tiles(noise0,[
		[0.0, null, [0, 0, [6, 0]]],   # Stone base
		[0.1, 0.2, [0, 0, [2, 0]]],    # Light gray rock
		[0.2, 0.3, [0, 0, [3, 0]]],    # Darker stone
	])

	# Generate coal only in valid stone/rock tiles
	generate_ore(noise_coal,0.4,1,Vector2i(1,0),stone_tiles)
	generate_ore(noise_iron,0.49,2,Vector2i(1,0),stone_tiles)
	generate_ore(noise_ruby,0.69,4,Vector2i(1,0),stone_tiles)
	wave_terrain()
	spawn_merchant()
	
func generate_ore(noise: Noise, threshold: float, source_id: int, _atlas_coords: Vector2i, valid_tiles: Array):
	for x in range(-width / 2.0, width / 2.0):
		for y in range(-height / 2.0, height / 2.0):
			var noise_val = noise.get_noise_2d(x, y)

			# Check if the noise value meets the threshold
			if noise_val > threshold:
				var tile_pos = Vector2i(x, y)

				# Get the tile below the current position
				var tile_below = tilemap.get_cell_atlas_coords(0, tile_pos + Vector2i(0, 1))

				if tile_below in valid_tiles:
					tilemap.set_cell(0, tile_pos, source_id, tile_below)  # Set ore tile

func spawn_merchant():
	var merchant_instance = merchant_scene.instantiate()
	merchant_instance.position = player.position
	add_child(merchant_instance)
	
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
	var current_block = Global.inventory[player_inventory.hovered_index]
	
	var tile_pos = get_tile_under_mouse()
	var current_tile = tilemap.get_cell_source_id(0, tile_pos)
	
	if current_tile == -1 and current_block and current_block["item_name"] in buildable_blocks:
		tilemap.set_cell(0,tile_pos,3,Vector2i(1,0))
		current_block["quantity"] -= 1
		Global.inventory_updated.emit()
		
func mine():
	var tile_pos = get_tile_under_mouse()
	var source_id = tilemap.get_cell_source_id(0, tile_pos)  # Get the tile source ID
	var atlas_coords = tilemap.get_cell_atlas_coords(0, tile_pos)  # Get the tile atlas coordinates
	var particle_instance : CPUParticles2D = mining_particle.instantiate()
	
	if source_id == -1:
		return  # No tile here, do nothing

	# Modify or erase the tile based on its type
	if atlas_coords and atlas_coords.y < 3:
		particle_instance.position = Vector2(tilemap.map_to_local(tile_pos))
		particle_instance.emitting = true
		AudioManager.play_random_pitch(AudioManager.mining_block,0.9,1)
		add_child(particle_instance)
		var new_tile_coords = Vector2i(atlas_coords.x, atlas_coords.y + 1)
		tilemap.set_cell(0, tile_pos, source_id, new_tile_coords)  # Keep source ID the same
		
	elif atlas_coords.y == 3: #block destroyed
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
			
func _on_mining_timer_timeout():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Global.player_can_mine:
		mine()
		Global.current_player_state = "mining"
		mining_timer.start(Global.delay_inbetween_mining)
	
func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		player_inventory.visible = false
		FadingEffect.transition()
		await FadingEffect.on_transition_finished
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Global.player_can_mine and mining_timer.is_stopped():
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
	
func _process(_delta):
	if Global.did_mine and Global.did_scroll and Global.did_tab:
		tutorial_ui.visible = false
		
	
		
