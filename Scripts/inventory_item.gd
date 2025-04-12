@tool
class_name Item
extends Node2D

func get_texture(index: int) -> Texture:
	if index < 0:
		return null
	return Global.item_textures[Global.item_textures.keys()[min(index, Global.item_textures.size() - 1)]]


@export var item_id = -1
var current_id = -1

func _process(_delta):
	if current_id != item_id:
		current_id = item_id
		$Sprite2D.texture = get_texture(item_id)
