extends Node

var WIDTH := 1000
var HEIGHT := 1000

var player_can_mine = false
var delay_inbetween_mining = 0.12

var player_inventory_open = true
var player : Node = null
var inventory = []
var did_scroll = false
var did_tab = false 
var did_mine = false

var current_player_state = "idle"

signal inventory_updated
var default_inventory_size = 10

var god_mode = false

var chunk_size = 16
var render_distance = 3
var top_of_the_world = 0
var cave_start = 20
var rock_bottom = 300

var item_textures: Dictionary = {
	"coal": preload("res://Resources/Sprites/coal_item.png"),
	"iron": preload("res://Resources/Sprites/iron_item.png"),
	"stone": preload("res://Resources/Sprites/stone_item.png"),
	"ruby": preload("res://Resources/Sprites/ruby_item.png")
}

var item_textures_keys = item_textures.keys()

func _ready():
	inventory.resize(default_inventory_size)

func blockToPixel(pos):
	return pos * 16

func pixelToBlock(pos):
	return pos / 16

func count_items(array : Array):
	var items : int = 0
	for item in array:
		if item != null:
			items += 1
	return items

func add_item(item):
	for i in range(inventory.size()):
		if inventory[i] != null:
			if inventory[i]["item_type"] == item["item_type"]:
				inventory[i]["quantity"] += item["quantity"]
				inventory_updated.emit()
				return true
		elif inventory[i] == null:
			inventory[i] = item
			inventory_updated.emit()
			return true
				
	inventory_updated.emit()
		
func remove_item(item):
	var index = inventory.find(item)
	inventory.remove_at(index)
	inventory_updated.emit()

func clear_inventory(item):
	var temp: Array = [] #tu su veci na odstranenie
	#neni dobre removovat veci z arr ked cez neho iterujem takze sa to odstrani potom
	
	if item == null:
		inventory.clear()
		
	else:
		for i in range(inventory.size()):
			print("item: " + item)
			print(inventory[i])
			if inventory[i]:
				if item == inventory[i]["item_type"]:
					temp.append(inventory[i])
		for i in range(temp.size()):
			inventory.erase(temp[i])

	increase_inventory_size(default_inventory_size)
	
func increase_inventory_size(new_size):
	inventory.resize(new_size)
	inventory_updated.emit()

func set_player_refrence(player_input):
	player = player_input
	
