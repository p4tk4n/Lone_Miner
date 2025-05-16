# chunk_manager.gd
extends Node

const CHUNK_SIZE := 16
const SAVE_DIR := "user://chunk_data/"

var modified_chunks := {}  # {Vector2: ChunkData}

func _ready():
	var dir = DirAccess.open("user://")
	
	if dir.make_dir_recursive("chunk_data") != OK:
		push_error("Failed to create chunk_data dir!")
	
# Core API --------------------------------------------------
func record_block_modification(world_pos: Vector2, tile_id: int, atlas_coords: Vector2i):
	var chunk_pos = _world_to_chunk(world_pos)
	var chunk = _get_or_create_chunk(chunk_pos)
	var local_pos = chunk.world_to_local(world_pos, CHUNK_SIZE)
	
	chunk.modified_blocks[local_pos] = {
		"id": tile_id,
		"atlas": atlas_coords
	}
	chunk.last_modified = Time.get_unix_time_from_system()
	_save_chunk(chunk)

func get_chunk_modifications(chunk_pos: Vector2) -> Dictionary:
	return _get_or_create_chunk(chunk_pos).modified_blocks

# Internal Helpers -------------------------------------------
func _world_to_chunk(world_pos: Vector2) -> Vector2:
	return Vector2(
		floori(world_pos.x / CHUNK_SIZE),
		floori(world_pos.y / CHUNK_SIZE)
	)

func _get_or_create_chunk(chunk_pos: Vector2) -> ChunkData:
	if modified_chunks.has(chunk_pos):
		return modified_chunks[chunk_pos]
	
	var chunk = _load_chunk_from_disk(chunk_pos)
	if !chunk:
		chunk = ChunkData.new()
		chunk.chunk_position = chunk_pos
	
	modified_chunks[chunk_pos] = chunk
	return chunk

func _load_chunk_from_disk(chunk_pos: Vector2) -> ChunkData:
	var path = _get_chunk_path(chunk_pos)
	return ResourceLoader.load(path) if ResourceLoader.exists(path) else null

func _save_chunk(chunk: ChunkData):
	# Explicitly mark chunk as modified
	chunk.should_persist = true  # Add this property to ChunkData
	ResourceSaver.save(chunk, _get_chunk_path(chunk.chunk_position))

func _get_chunk_path(chunk_pos: Vector2) -> String:
	return SAVE_DIR + "chunk_%d_%d.tres" % [chunk_pos.x, chunk_pos.y]

# Maintenance -----------------------------------------------
func unload_distant_chunks(current_chunk_pos: Vector2, keep_radius: int):
	for chunk_pos in modified_chunks:
		if chunk_pos.distance_to(current_chunk_pos) > keep_radius:
			modified_chunks.erase(chunk_pos)

func save_all_active_chunks():
	for chunk in modified_chunks.values():
		_save_chunk(chunk)
