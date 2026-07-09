extends Node
## Music and SFX playback. Grows with the first audio pass (M5); the point of
## existing now is that scenes call AudioManager rather than owning players.

var _music: AudioStreamPlayer

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)

func play_music(stream: AudioStream) -> void:
	_music.stream = stream
	_music.play()

func stop_music(fade := 0.0) -> void:
	if fade > 0.0:
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", -60.0, fade)
		tw.tween_callback(_reset_music)
	else:
		_music.stop()

func _reset_music() -> void:
	_music.stop()
	_music.volume_db = 0.0
