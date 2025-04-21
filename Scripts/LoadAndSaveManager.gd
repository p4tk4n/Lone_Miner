extends Node2D

@export var tilemap: TileMap

func save_chunk(chunk_x: int, chunk_y: int, modified_tiles):
	var chunk_key = str(chunk_x) + "_" + str(chunk_y)
	if modified_tiles.has(chunk_key):
		var save_data = {
			"chunk_pos": Vector2i(chunk_x, chunk_y),
			"modified_tiles": modified_tiles[chunk_key]
		}
		# Save to file (you'll need to implement your save system)
		var save_path = "user://chunks/chunk_%d_%d.json" % [chunk_x, chunk_y]
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_chunk(chunk_x: int, chunk_y: int):
	var load_path = "user://chunks/chunk_%d_%d.json" % [chunk_x, chunk_y]
	if FileAccess.file_exists(load_path):
		var file = FileAccess.open(load_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		
		for tile_data in data["modified_tiles"]:
			var pos = tile_data["position"]
			if tile_data["source_id"] == -1:
				tilemap.erase_cell(0, pos)
			else:
				tilemap.set_cell(0, pos, tile_data["source_id"], tile_data["atlas_coords"])
