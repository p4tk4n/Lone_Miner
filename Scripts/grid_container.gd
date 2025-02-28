extends GridContainer

@onready var highlight_slot = get_parent().get_parent().get_node("HighlightSlot")
	
func _process(_delta):
	var mouse_pos = get_local_mouse_position()
	var cell_size = Vector2(48,48)
	var column = int(mouse_pos.x / cell_size.x)
	var row = int(mouse_pos.y / cell_size.y)
	
	if Global.player_inventory_open and column >= 0 and row >= 0 and column <= 5 and row <= 2:
		highlight_slot.visible = true
		var coords = Vector2(column * cell_size.x,row * cell_size.y)
		highlight_slot.position = coords
		
	else:
		highlight_slot.visible = Global.player_inventory_open
