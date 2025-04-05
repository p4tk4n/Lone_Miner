extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -280.0

var default_gravity = 980
var falling_gravity = 1200
var gravity = default_gravity 

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var mining_range = $MiningRange
@onready var camera = $Camera2D

func _ready():
	Global.set_player_refrence(self)
	mining_range.mouse_entered.connect(_on_mining_range_entered)
	mining_range.mouse_exited.connect(_on_mining_range_exited)
	camera.zoom = Vector2(1,1)
	position = Vector2i(3200,-800)
	
	
func _physics_process(delta):
	if not is_on_floor_only():
		gravity = falling_gravity
		velocity.y += gravity * delta
	else:
		gravity = default_gravity
		
	if Input.is_action_pressed("player_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		Global.current_player_state = "jumping"
		
	var right = Input.is_action_pressed("player_right")
	var left = Input.is_action_pressed("player_left")
	
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Global.current_player_state = "mining"
	else:
		Global.current_player_state = "idle"

	if right:
		if not Global.current_player_state == "mining":
			Global.current_player_state = "walking"
		sprite.flip_h = false
		velocity.x = SPEED
	elif left:
		if not Global.current_player_state == "mining":
			Global.current_player_state = "walking"
		sprite.flip_h = true
		velocity.x = -SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if Global.current_player_state == "idle":
		animation.play("idle")
	elif Global.current_player_state == "mining":
		animation.play("mining")
	elif Global.current_player_state == "walking":
		animation.play("walking")
		
	move_and_slide()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("scroll up"):
		var new_zoom = camera.zoom * 1.1
		#if new_zoom.x <= 5:  # Limit max zoom
			#camera.zoom = new_zoom
			#Global.did_scroll = true
		camera.zoom = new_zoom
		
	if Input.is_action_just_pressed("scroll down"):
		var new_zoom = camera.zoom * 0.9
		#if new_zoom.x >= 1:  # Limit min zoom
			#camera.zoom = new_zoom
			#Global.did_scroll = true
		camera.zoom = new_zoom
func _on_mining_range_entered():
	Global.player_can_mine = true

func _on_mining_range_exited():
	Global.player_can_mine = false
