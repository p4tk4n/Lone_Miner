extends Node

@onready var console = $textInput
@export var player: CharacterBody2D

var text_from_console: String
var command_history: Array
var max_command_history_size: int = 100
var nth_command: int = 0

var valid_commands: Array = [
	"give", "clear", "tp", "spawn"
]

func _ready():
	pass

func give_item_to_player(item_type: String, item_quantity: String):
	var texture_id = Global.item_textures_keys.find(item_type)
	var item = {
		"quantity" : int(item_quantity),
		"item_type" : item_type,
		"item_name" : item_type.capitalize(),
		"item_texture" : Global.item_textures[item_type],
		"texture_id" : texture_id
		}
	Global.add_item(item)

func clear_item_from_player(item_to_remove):
	Global.clear_inventory(item_to_remove)

func teleport_player(x,y):
	var final_pos = Vector2(int(x),int(y))
	player.position = Vector2(Global.blockToPixel(final_pos.x),Global.blockToPixel(final_pos.y))
	
func readCommands(input: String):
	var tokens = (input.trim_prefix("/")).split(" ")
	var main_command: String = tokens[0]
	if main_command in valid_commands:
		if main_command == valid_commands[0]:
			give_item_to_player(tokens[1],tokens[2])
		if main_command == valid_commands[1]:
			if typeof(tokens) == TYPE_PACKED_STRING_ARRAY:
				clear_item_from_player(null)
			else:
				clear_item_from_player(tokens[1])
		if main_command == valid_commands[2]:
			var x_pos = tokens[1]
			var y_pos = tokens[2]
			var rel_x
			var rel_y
			var real_x
			var real_y
			
			if x_pos.find("~") != -1:
				rel_x = x_pos.strip_edges(true,false)
				real_x = int(rel_x) + Global.pixelToBlock(player.position.x)
			if y_pos.find("~") != -1:
				rel_y = y_pos.strip_edges(true,false)
				real_y = int(rel_y) + Global.pixelToBlock(player.position.y)
			
			if real_y and real_x:
				teleport_player(real_x,real_y)
			else:
				teleport_player(tokens[1],tokens[2])
				
func _process(_delta):
	if Input.is_action_just_pressed("show_console"):
		console.visible = not console.visible
		if console.visible:
			console.grab_focus()
		else:
			console.release_focus()
			console.clear()
	
	if Input.is_action_just_pressed("confirm_command"):
		text_from_console = console.text
		command_history.append(text_from_console)
		readCommands(text_from_console)
		console.clear()
		nth_command = 0
		console.visible = false
	
	if Input.is_action_just_pressed("show_last_command") and console.visible and command_history.size() > 0:
		# znizi nth_command aby ukazal posledny cmd
		if nth_command > -command_history.size():
			nth_command -= 1
		console.text = command_history[nth_command]
		
	if Input.is_action_just_pressed("show_prev_command") and console.visible and command_history.size() > 0:
		# zvysi nth_command aby ukazal predosly cmd
		if nth_command < -1:
			nth_command += 1
		console.text = command_history[nth_command]
	
	if command_history.size() > max_command_history_size:
		command_history.pop_front()
	
func _on_text_input_text_changed(new_text: String):
	if not new_text.begins_with("/"):
		console.text = "/" + new_text.strip_edges(true,false)
		console.caret_column = console.text.length()
