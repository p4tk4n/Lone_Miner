# chunk_data.gd
extends Resource
class_name ChunkData

@export var chunk_position := Vector2.ZERO
@export var modified_blocks := {}  # {Vector2(local_x, local_y): tile_id}
@export var last_modified := 0  # Unix timestamp

# Helper to convert to/from local coordinates
func world_to_local(world_pos: Vector2, chunk_size: int) -> Vector2:
	return Vector2(
		posmod(int(world_pos.x), chunk_size),
		posmod(int(world_pos.y), chunk_size)
	)

# Optional: Add versioning for future compatibility
func get_version() -> int:
	return 1
