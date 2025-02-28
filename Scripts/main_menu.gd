extends Control

@onready var menu_light = $TextureRect/PointLight2D

func _on_play_button_pressed():
	FadingEffect.transition()
	await FadingEffect.on_transition_finished
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_exit_button_pressed():
	FadingEffect.transition()
	await FadingEffect.on_transition_finished
	get_tree().quit()

func _ready():
	var menu_cursor = preload("res://Resources/Sprites/pointer_icon.png")
	ProjectSettings.set_setting("display/mouse_cursor/custom_image",menu_cursor)

func move_light(dist):
	if menu_light.position.x <= 720:
		menu_light.position.x += dist
	elif menu_light.position.x > 480:
		print("dosiel som na koniec")
		menu_light.position.x = -196

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		FadingEffect.transition()
		await FadingEffect.on_transition_finished
		get_tree().quit()
	move_light(1)
