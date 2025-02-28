@tool
class_name Item
extends Node2D

const ITEM_COAL = preload("res://Resources/Sprites/coal_item.png")
const ITEM_IRON = preload("res://Resources/Sprites/iron_item.png")
const ITEM_STONE = preload("res://Resources/Sprites/stone_item.png")

const ITEM_TEXTURES = [
	ITEM_COAL,ITEM_IRON,ITEM_STONE
]

func get_texture(index: int) -> Texture:
	if index < 0:
		return null
	return ITEM_TEXTURES[min(index,len(ITEM_TEXTURES)-1)]

@export var item_id = -1
var current_id = -1

func _process(delta):
	if current_id != item_id:
		current_id = item_id
		$Sprite2D.texture = get_texture(item_id)
