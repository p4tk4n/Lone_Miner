extends Node

var WIDTH := 400
var HEIGHT := 400

var player_can_mine = false
var delay_inbetween_mining = 0.125

var player_inventory_open = false
var player : Node = null
var inventory = []
var did_scroll = false
var did_tab = false 
var did_mine = false

var current_player_state = "idle"

signal inventory_updated

func _ready():
	inventory.resize(18)

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
	
func increase_inventory_size(new_size):
	inventory.resize(new_size)
	inventory_updated.emit()

func set_player_refrence(player_input):
	player = player_input
	
