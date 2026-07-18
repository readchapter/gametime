extends Node3D
## Chapter 4 — arrival in the city, after curfew. A blackout canyon of
## shuttered facades, Sylvie ten steps ahead and never looking back, one
## patrol crossing from an arch — and at the end of it, door 17, where the
## countryside line ends and Madame Béranger's city begins.

const PLAYER_SCENE := preload("res://src/player/player.tscn")
const CLOTH_SYLVIE := Color(0.30, 0.24, 0.22)

var _player: CharacterBody3D
var _sylvie: Node3D
var _door17: Vector3
var _arch: Vector3
var _wp := 0
var _waypoints: Array[Vector3] = []
var _patrol_done := false
var _lock := false
var _t := 0.0

func _ready() -> void:
	_build_environment()
	var street := CityGen.build_street(self, 47)
	_door17 = street["door17"]
	_arch = street["arch"]
	# Route: down the canyon, drifting kerb to kerb, ending at door 17.
	# The patrol beat fires as she clears the arch.
	_waypoints = [
		Vector3(-1.0, 0, -18.0),
		Vector3(1.5, 0, -42.0),
		Vector3(-0.5, 0, _arch.z - 4.0),
		Vector3(2.5, 0, -96.0),
		Vector3(_door17.x - 1.6, 0, _door17.z + 1.2),
	]

	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(0.5, 0.05, 4.0)
	_player.rotation.y = 0.0  # facing down the canyon, -Z
	add_child(_player)
	_player.camera.make_current()

	_sylvie = Figures.villager(CLOTH_SYLVIE, "Sylvie")
	_sylvie.position = Vector3(-0.5, 0, -4.0)
	add_child(_sylvie)

	AudioManager.play_ambient("city_night")
	SceneDirector.fade_in(2.0)
	Hud.subtitle("", "(The city after curfew: a canyon of shut eyes. Somewhere a cat, somewhere a car, nowhere a light you are meant to see.)", 6.0)
	CaptureHarness.snap("ch4_street")

func _build_environment() -> void:
	var env := Environment.new()
	SkyLib.apply(env, {
		"top_color": Color(0.012, 0.016, 0.030),
		"horizon_color": Color(0.045, 0.050, 0.075),
		"ground_color": Color(0.015, 0.018, 0.03),
		"sun_color": Color(0.02, 0.02, 0.03),
		"horizon_sharpness": 3.5,
		"cloud_coverage": 0.22,
		"cloud_lit_color": Color(0.07, 0.08, 0.11),
		"cloud_shadow_color": Color(0.03, 0.035, 0.055),
		"star_amount": 0.7,
		"moon_amount": 0.35,
		"moon_dir": Vector3(0.3, 0.55, 0.6),
	})
	env.fog_sky_affect = 0.2
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.15, 0.20)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.03, 0.035, 0.05)
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# A sliver of moon finds the canyon: one cold directional, low energy
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-38, 25, 0)
	moon.light_color = Color(0.55, 0.62, 0.80)
	moon.light_energy = 0.22
	moon.shadow_enabled = true
	add_child(moon)

func _process(delta: float) -> void:
	_t += delta
	if _sylvie == null or _player == null:
		return
	_sylvie_walk(delta)
	_autoplay_step(delta)

func _sylvie_walk(delta: float) -> void:
	if _lock or _wp >= _waypoints.size():
		return
	var target := _waypoints[_wp]
	if _sylvie.position.distance_to(_player.position) > 10.0:
		return
	var flat := _sylvie.position.move_toward(Vector3(target.x, 0, target.z), 3.0 * delta)
	flat.y = absf(sin(_t * 9.0)) * 0.04
	if Vector2(flat.x, flat.z).distance_to(Vector2(target.x, target.z)) < 0.6:
		_wp += 1
		if _wp == 3 and not _patrol_done:
			_patrol_beat()
		elif _wp >= _waypoints.size():
			_door_beat()
	else:
		var look := target - _sylvie.position
		if look.length() > 0.5:
			_sylvie.rotation.y = atan2(-look.x, -look.z) + PI
	_sylvie.position = flat

## Headlights swing out of the arch and walk the far wall. Doorway. Still.
func _patrol_beat() -> void:
	_patrol_done = true
	_lock = true
	Hud.subtitle("SYLVIE", "Doorway. Now.", 2.5)
	_player.move_enabled = false
	_player.look_enabled = false
	var alcove := Vector3(5.9, 0.05, _arch.z + 8.0)
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_player, "position", alcove, 1.0)
	# Back to the door, eyes across the street where the beams will walk
	# (+PI/2 faces -X/west; bias south toward the sweep).
	tw.parallel().tween_method(func(y: float) -> void:
		_player.rotation = Vector3(0, y, 0), _player.rotation.y, PI / 2.0 - 0.45, 1.0)
	tw.parallel().tween_property(_sylvie, "position",
		Vector3(5.9, 0, _arch.z + 10.5), 1.0)
	await tw.finished
	AudioManager.play_sfx("truck_pass", -14.0)
	# The sweep: a hooded pair of beams crossing the canyon from the arch
	var car := Node3D.new()
	add_child(car)
	car.position = Vector3(_arch.x - 2.0, 0, _arch.z - 5.0)
	for side: float in [-0.5, 0.5]:
		var head := SpotLight3D.new()
		head.position = Vector3(side, 0.9, 0)
		head.light_color = Color(0.9, 0.88, 0.75)
		head.light_energy = 3.4
		head.spot_range = 30.0
		head.spot_angle = 16.0
		car.add_child(head)
	car.rotation.y = -PI / 2  # SpotLight forward -Z → beams east, across the street
	var sweep := create_tween()
	sweep.tween_property(car, "position:z", _arch.z - 14.0, 6.5)
	await get_tree().create_timer(3.2, false).timeout
	CaptureHarness.snap("ch4_patrol")
	Hud.subtitle("", "(The beams walk the far wall, unhurried. Boots, two pairs, discussing something ordinary.)", 5.0)
	await get_tree().create_timer(5.5, false).timeout
	car.queue_free()
	Hud.subtitle("SYLVIE", "They sweep to a clock. Remember the clock. Come.", 4.0)
	_player.move_enabled = true
	_player.look_enabled = true
	_lock = false

## Door 17. The knock, the goodbye, the city changing hands.
func _door_beat() -> void:
	_lock = true
	_player.move_enabled = false
	_player.look_enabled = false
	var to_door := _door17 - _player.position
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(y: float) -> void:
		_player.rotation = Vector3(0, y, 0),
		_player.rotation.y, atan2(-to_door.x, -to_door.z), 0.9)
	await tw.finished
	_player.look_enabled = true
	CaptureHarness.snap("ch4_door17")
	AudioManager.play_sfx("knock_door", -12.0)
	await get_tree().create_timer(2.0, false).timeout
	DialogueManager.start("res://data/dialogue/ch4/door17.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	# She is gone before the door finishes opening.
	var gone := create_tween()
	gone.tween_property(_sylvie, "position:z", _sylvie.position.z + 26.0, 8.0)
	Hud.subtitle("", "(You do not see her go. That is how you know she is good at this.)", 4.5)
	await get_tree().create_timer(4.0, false).timeout
	AudioManager.stop_ambient(2.0)
	GameState.set_flag("ch4_arrived")
	SceneDirector.goto_beat("ch4_apartment", 1.5)

func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	var target := _sylvie.position
	if _wp < _waypoints.size() and _player.position.distance_to(target) < 3.0:
		return
	target.y = _player.position.y
	_player.position = _player.position.move_toward(target, delta * 3.4)
	_player.position.y = 0.05
