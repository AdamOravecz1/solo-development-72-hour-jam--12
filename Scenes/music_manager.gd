extends Node

# Preload your background music track here
var bg_music = preload("res://Sounds/deuslower-medieval-citytavern-ambient-235876.wav") 

var audio_player: AudioStreamPlayer

func _ready() -> void:
	# Create the audio player programmatically
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Assign the music stream and configure it
	audio_player.stream = bg_music
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS # Keeps music playing even if the game is paused
	
	# Start playing!
	play_music()

func play_music() -> void:
	if not audio_player.playing:
		audio_player.play()

func stop_music() -> void:
	audio_player.stop()
