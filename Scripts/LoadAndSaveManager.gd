extends Node

@export var tilemap: TileMap
var save_dir = "user://chunks/"

func _ready():
	# Double-check directory creation
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("chunks"):
			var make_dir_result = dir.make_dir("chunks")
			if make_dir_result != OK:
				push_error("FAILED to create chunks directory! Error code: ", make_dir_result)
		else:
			print("Chunks directory already exists")
	else:
		push_error("CRITICAL: Couldn't access user:// directory!")

func save_chunk(chunk_x: int, chunk_y: int, modified_tiles: Dictionary):
	var chunk_key = str(chunk_x) + "_" + str(chunk_y)
	
	# Debug: Show what we're trying to save
	print("\nAttempting to save chunk ", chunk_key)
	print("Current modified_tiles contents: ", modified_tiles)
	
	if not modified_tiles.has(chunk_key):
		print("No entry for this chunk in modified_tiles")
		return
	
	if modified_tiles[chunk_key].is_empty():
		print("No modifications to save for this chunk")
		return
	
	# Prepare save data with proper Vector2i conversion
	var tiles_to_save = []
	for tile_data in modified_tiles[chunk_key]:
		tiles_to_save.append({
			"position": {"x": tile_data["position"]["x"], "y": tile_data["position"]["y"]},
			"source_id": tile_data["source_id"],
			"atlas_coords": {"x": tile_data["atlas_coords"]["x"], "y": tile_data["atlas_coords"]["y"]}
		})
	
	var save_data = {
		"chunk_pos": {"x": chunk_x, "y": chunk_y},
		"modified_tiles": tiles_to_save
	}
	
	var save_path = save_dir + "chunk_%d_%d.json" % [chunk_x, chunk_y]
	print("Full save path: ", save_path)
	
	# Debug: Show the actual data being saved
	print("Data to save: ", save_data)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))  # Pretty-print
		file.close()
		print("SUCCESS: Saved chunk ", chunk_x, ",", chunk_y)
		print("File exists check: ", FileAccess.file_exists(save_path))  # Verify
	else:
		push_error("FAILED to save chunk. Error code: ", FileAccess.get_open_error())
		print("Full path attempted: ", ProjectSettings.globalize_path(save_path))
		

func load_chunk(chunk_x: int, chunk_y: int) -> bool:
	var load_path = save_dir + "chunk_%d_%d.json" % [chunk_x, chunk_y]
	print("\nAttempting to load from: ", load_path)
	
	# First check if file exists
	if not FileAccess.file_exists(load_path):
		print("File does not exist at path: ", ProjectSettings.globalize_path(load_path))
		return false
	
	# Try to open file
	var file = FileAccess.open(load_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file. Error code: ", FileAccess.get_open_error())
		return false
	
	# Read and parse JSON
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("JSON Parse Error: ", json.get_error_message())
		push_error("Problematic JSON: ", json_text)
		return false
	
	var data = json.get_data()
	if not data or not data is Dictionary:
		push_error("Invalid data format in file")
		return false
	
	# Validate data structure
	if not data.has("modified_tiles") or not data["modified_tiles"] is Array:
		push_error("Missing or invalid modified_tiles array")
		return false
	
	# Restore tiles
	for tile_data in data["modified_tiles"]:
		# Validate each tile's data structure
		if not tile_data.has("position") or not tile_data["position"] is Dictionary:
			push_error("Invalid position data: ", tile_data)
			continue
		
		if not tile_data.has("source_id") or not typeof(tile_data["source_id"]) == TYPE_INT:
			push_error("Invalid source_id: ", tile_data)
			continue
		
		if not tile_data.has("atlas_coords") or not tile_data["atlas_coords"] is Dictionary:
			push_error("Invalid atlas_coords: ", tile_data)
			continue
		
		# Convert to Vector2i
		var pos = Vector2i(tile_data["position"]["x"], tile_data["position"]["y"])
		var atlas = Vector2i(tile_data["atlas_coords"]["x"], tile_data["atlas_coords"]["y"])
		
		# Apply changes
		if tile_data["source_id"] == -1:
			tilemap.erase_cell(0, pos)
			print("Restored erased tile at ", pos)
		else:
			tilemap.set_cell(0, pos, tile_data["source_id"], atlas)
			print("Restored placed tile at ", pos)
	
	print("SUCCESS: Loaded chunk ", chunk_x, ",", chunk_y)
	return true
