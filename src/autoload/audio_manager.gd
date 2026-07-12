extends Node
## File-based audio with graceful degradation: missing assets warn once and
## stay silent, so the game runs fully before the audio pass lands.
## Wanted files are listed in assets/audio/MANIFEST.md; licenses go in
## assets/audio/CREDITS.md.

const SFX_POOL_SIZE := 6

var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _warned := {}

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_ambient = AudioStreamPlayer.new()
	add_child(_ambient)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

func play_music(track: String) -> void:
	_start_looping(_music, "music", track)

## Looping scene bed (engine drone, wind, night interior...).
func play_ambient(bed: String) -> void:
	_start_looping(_ambient, "ambient", bed)

func play_sfx(sfx: String, volume_db := 0.0) -> void:
	var stream := _stream("sfx", sfx)
	if stream == null:
		return
	var p := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.play()

func stop_music(fade := 0.0) -> void:
	_stop(_music, fade)

func stop_ambient(fade := 0.0) -> void:
	_stop(_ambient, fade)

func _start_looping(player: AudioStreamPlayer, kind: String, name_: String) -> void:
	var stream := _stream(kind, name_)
	if stream == null:
		player.stop()
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		# loop_end is in frames; without it the loop region is empty.
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.volume_db = 0.0
	player.play()

func _stop(player: AudioStreamPlayer, fade: float) -> void:
	if not player.playing:
		return
	if fade <= 0.0:
		player.stop()
		return
	var tw := create_tween()
	tw.tween_property(player, "volume_db", -60.0, fade)
	tw.tween_callback(func() -> void:
		player.stop()
		player.volume_db = 0.0)

func _stream(kind: String, name_: String) -> AudioStream:
	for ext in ["ogg", "wav"]:
		var path := "res://assets/audio/%s/%s.%s" % [kind, name_, ext]
		if ResourceLoader.exists(path):
			return load(path)
	var key := kind + "/" + name_
	if not _warned.has(key):
		_warned[key] = true
		print("AudioManager: no asset yet for %s (see assets/audio/MANIFEST.md)" % key)
	return null
