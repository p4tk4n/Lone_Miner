extends Node

@onready var block_pickup = $block_pickup
@onready var mining_block = $mining_block

func play_random_pitch(audio : AudioStreamPlayer2D,min_pitch : float,max_pitch : float):
	audio.pitch_scale = randf_range(min_pitch,max_pitch)
	audio.play()
