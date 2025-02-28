@tool
extends RigidBody2D

@export var quantity := 1
@export var item_type := ""
@export var item_name := ""
@export var item_texture : Texture
@export var texture_id : int

@onready var sprite = $Sprite2D
#@onready var InventoryItem = preload("res://Scenes/inventory_item.tscn")
var scene_path := "res://Scenes/item.tscn"
var player_in_range = false

func _ready():
	self.sleeping = false  
	if not Engine.is_editor_hint():
		sprite.texture = item_texture
	linear_velocity = Vector2(randf_range(-50, 50), randf_range(-50, 50))  # Small push in random direction
	apply_torque_impulse(randf_range(50.0, 100.0))  # Apply random torque for variety
	
func _process(_delta):
	if Engine.is_editor_hint():
		sprite.texture = item_texture
	if player_in_range:
		pickup_item()

func pickup_item():
	var item = {
		"quantity" : quantity,
		"item_type" : item_type,
		"item_name" : item_name,
		"item_texture" : item_texture,
		"texture_id" : texture_id
		}

	if Global.player:
		Global.add_item(item)  # Add the item to the inventory
		AudioManager.play_random_pitch(AudioManager.block_pickup,0.5,1.05)
		self.queue_free()  # Remove item from world

func _on_pickup_range_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_pickup_range_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
