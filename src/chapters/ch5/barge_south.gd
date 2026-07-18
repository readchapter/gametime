extends Node3D
## Chapter 5B — the barge south. A static barge and a France that slides
## past it: hedged banks, poplars, the odd sleeping village, while dawn
## comes up the colour of chicory coffee. The bargeman's news is the
## survivor's ledger of the escape path — who kept her building, who is
## still pouring charm, what happened to a beet farm if you told a charming
## man where it was. One lock inspection under the tarpaulin, then landfall
## and the crow roads south.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const HULL := Color(0.12, 0.11, 0.10)
const DECK := Color(0.24, 0.19, 0.13)
const WATER := Color(0.035, 0.05, 0.06)

var _player: CharacterBody3D
var _bargeman: Node3D
var _banks: Array[Node3D] = []
var _env: Environment
var _sky_mat: ShaderMaterial
var _sun: DirectionalLight3D
var _tarp: Node3D
var _scroll := 4.0     # bank scroll speed (the barge's way through the water)
var _dawn := 0.0       # 0 pre-dawn → 1 morning
var _phase := 0        # 0 ride, 1 talk done, 2 lock, 3 landfall
var _t := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 9
	_build_environment()
	_build_barge()
	_build_water_and_banks()
	_bargeman = Figures.villager(Color(0.18, 0.19, 0.21), "Bargeman")
	_bargeman.position = Vector3(0.9, 0.55, 4.0)
	_bargeman.rotation.y = PI
	add_child(_bargeman)
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-0.5, 0.6, 1.0)
	_player.rotation.y = PI  # facing the stern and the man at the tiller
	add_child(_player)
	_player.camera.make_current()
	_player.move_enabled = false
	AudioManager.play_ambient("canal_water")
	SceneDirector.fade_in(2.2)
	Hud.subtitle("", "(Dawn the colour of chicory. The barge does not hurry; it is the one thing in France with permission not to.)", 6.0)
	CaptureHarness.snap("ch5_barge")
	_ride()

func _build_environment() -> void:
	_env = Environment.new()
	_sky_mat = SkyLib.apply(_env, {
		"top_color": Color(0.030, 0.040, 0.080),
		"horizon_color": Color(0.075, 0.080, 0.115),
		"ground_color": Color(0.02, 0.025, 0.04),
		"sun_color": Color(0.02, 0.02, 0.03),
		"horizon_sharpness": 2.6,
		"cloud_coverage": 0.35,
		"cloud_lit_color": Color(0.09, 0.10, 0.14),
		"cloud_shadow_color": Color(0.04, 0.045, 0.07),
		"star_amount": 0.5,
	})
	_env.fog_sky_affect = 0.3
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.16, 0.17, 0.22)
	_env.ambient_light_energy = 1.0
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.10, 0.11, 0.14)
	_env.fog_density = 0.010
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-9, 105, 0)
	_sun.light_color = Color(1.0, 0.75, 0.5)
	_sun.light_energy = 0.0
	add_child(_sun)

func _build_barge() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(3.4, 1.1, 12.5), Vector3(0, 0.0, 0), HULL)
	mb.box(Vector3(3.0, 0.12, 11.8), Vector3(0, 0.6, 0), DECK)
	# Cargo hatches, coiled rope, the onion crates, the wheelhouse aft
	mb.box(Vector3(2.2, 0.5, 3.4), Vector3(0, 0.85, -2.6), HULL.lightened(0.06))
	mb.box(Vector3(1.6, 1.5, 1.6), Vector3(0, 1.35, 4.9), Color(0.20, 0.15, 0.10))
	mb.box(Vector3(1.4, 0.5, 0.2), Vector3(0, 1.95, 4.2), Color(0.06, 0.07, 0.09))
	for i in 3:
		mb.box(Vector3(0.5, 0.4, 0.5), Vector3(-1.0 + i * 0.55, 0.86, 1.9 + (i % 2) * 0.4),
			Color(0.30, 0.24, 0.14), _rng.randf_range(0, TAU))
	mb.cylinder(0.35, 0.35, 0.18, Vector3(1.1, 0.7, -0.6), Color(0.28, 0.24, 0.18))
	# The tarpaulin over the bow hold — where locks are waited out
	var tmb := MeshBuilder.new()
	tmb.box(Vector3(2.4, 0.08, 3.0), Vector3(0, 1.25, 0), Color(0.16, 0.18, 0.16))
	tmb.box(Vector3(2.4, 0.5, 0.08), Vector3(0, 1.0, 1.5), Color(0.14, 0.16, 0.14))
	_tarp = tmb.commit_instance("Tarp")
	_tarp.position = Vector3(0, 0, -4.2)
	add_child(_tarp)
	add_child(mb.commit_instance("Barge"))
	# Deck collision
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 0.2, 11.8)
	cs.shape = shape
	cs.position = Vector3(0, 0.55, 0)
	body.add_child(cs)
	add_child(body)
	# The stern lamp, hooded
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.6, 4.6)
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.light_energy = 1.1
	lamp.omni_range = 7.0
	add_child(lamp)

func _build_water_and_banks() -> void:
	var water := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(30, 140)
	water.mesh = wp
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = WATER
	wmat.metallic = 0.55
	wmat.roughness = 0.3
	water.material_override = wmat
	water.position = Vector3(0, -0.45, 0)
	add_child(water)
	# Two bank strips, mirrored, scrolled and looped in _process
	for side: float in [-1.0, 1.0]:
		var bank := Node3D.new()
		var mb := MeshBuilder.new()
		# The bank itself
		mb.box(Vector3(9.0, 1.2, 70.0), Vector3(side * 11.0, -0.2, 0), Color(0.14, 0.17, 0.12))
		var z := -34.0
		while z < 34.0:
			var roll := _rng.randf()
			if roll < 0.45:
				# poplar
				var h := _rng.randf_range(5.0, 8.0)
				mb.cylinder(0.14, 0.18, h, Vector3(side * 8.2, h / 2.0 - 0.2, z), Color(0.13, 0.11, 0.09))
				mb.sphere(_rng.randf_range(0.7, 1.0), _rng.randf_range(2.8, 4.0),
					Vector3(side * 8.2, h - 0.6, z), Color(0.10, 0.14, 0.09))
			elif roll < 0.8:
				# hedge run
				mb.box(Vector3(1.4, _rng.randf_range(1.0, 1.6), _rng.randf_range(2.5, 4.5)),
					Vector3(side * 7.6, 0.5, z), Color(0.10, 0.13, 0.08))
			else:
				# a sleeping house, one faint window
				mb.box(Vector3(3.0, 2.4, 3.6), Vector3(side * 10.5, 1.0, z), Color(0.17, 0.16, 0.14))
				mb.prism(Vector3(3.3, 1.1, 3.9), Vector3(side * 10.5, 2.75, z), Color(0.10, 0.08, 0.07))
			z += _rng.randf_range(4.0, 8.0)
		bank.add_child(mb.commit_instance("Bank"))
		add_child(bank)
		_banks.append(bank)

func _ride() -> void:
	await get_tree().create_timer(7.0, false).timeout
	_player.move_enabled = false
	DialogueManager.start("res://data/dialogue/ch5/barge_talk.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	_phase = 1
	Hud.subtitle("", "(The banks go on shuffling their poplars. Ahead, stone narrows the water: a lock, and a lock-keeper's lamp, and whoever the lamp belongs to.)", 6.0)
	await get_tree().create_timer(7.0, false).timeout
	_the_lock()

## The lock: the world stops moving; you stop existing. Boots on the deck.
func _the_lock() -> void:
	_phase = 2
	Hud.subtitle("BARGEMAN", "Lock. Under the tarp, parcel — locks have eyes and mine has a German one this month.", 4.5)
	var slow := create_tween()
	slow.tween_method(func(v: float) -> void: _scroll = v, _scroll, 0.0, 3.0)
	# Under the tarp: pull the player into the hold, cover the world
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_player, "position", Vector3(0, 0.62, -4.2), 1.4)
	tw.parallel().tween_property(_player.camera, "position:y", 0.5, 1.4)
	await tw.finished
	_player.look_enabled = false
	CaptureHarness.snap("ch5_lock")
	await get_tree().create_timer(2.0, false).timeout
	AudioManager.play_sfx("boots_stairs", -16.0)
	Hud.subtitle("", "(Boots on the deck, two pairs. The tarp breathes with you — in, hold, out, hold.)", 5.0)
	await get_tree().create_timer(5.0, false).timeout
	Hud.subtitle("", "(\"Zwiebeln.\" A paper rustles. \"...Und Kohle.\" The stamp comes down on the manifest like a small door closing.)", 5.5)
	AudioManager.play_sfx("stamp_thunk", -12.0)
	await get_tree().create_timer(5.5, false).timeout
	Hud.subtitle("", "(The boots leave by the gangplank. Water begins to climb the lock walls, patient as everything on this river.)", 5.0)
	await get_tree().create_timer(4.5, false).timeout
	var up := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	up.tween_property(_player.camera, "position:y", 1.65, 1.2)
	up.parallel().tween_property(_player, "position", Vector3(-0.5, 0.62, -2.0), 1.2)
	await up.finished
	_player.look_enabled = true
	var resume := create_tween()
	resume.tween_method(func(v: float) -> void: _scroll = v, 0.0, 4.0, 4.0)
	Hud.subtitle("BARGEMAN", "And through. You breathe well for a parcel. Two more hours of France, then your feet take over.", 5.0)
	await get_tree().create_timer(6.5, false).timeout
	_landfall()

func _landfall() -> void:
	_phase = 3
	var slow := create_tween()
	slow.tween_method(func(v: float) -> void: _scroll = v, _scroll, 0.0, 4.0)
	CaptureHarness.snap("ch5_landfall")
	Hud.subtitle("BARGEMAN", "Here. No quay, no witnesses — just a bank with low opinions. South now, parcel. Crows, sheep, mountains. Tell the shepherd the widow keeps her building.", 6.5)
	await get_tree().create_timer(7.0, false).timeout
	GameState.set_flag("alone_south", true)
	await SceneDirector.fade_out(2.5)
	AudioManager.stop_ambient(0.5)
	AudioManager.play_sfx("chapter_sting", -6.0)
	await CutscenePlayer.caption("The bank takes his weight and the barge forgets him,\nthe way rivers are paid to forget.", 5.5)
	await CutscenePlayer.caption("South: crow roads, sheep roads,\nand then the white teeth of the border sky.", 5.0)
	await CutscenePlayer.caption("END OF CHAPTER FIVE", 4.0)
	GameState.set_flag("ch5_complete", true)
	GameState.chapter = 6
	GameState.save_game()
	await CutscenePlayer.caption("CHAPTER SIX\n\nTHE WHITE TEETH OF THE SKY", 4.5)
	SceneDirector.goto_beat("ch6_foothills", 0.1)

func _process(delta: float) -> void:
	_t += delta
	# The barge breathes; the banks do the travelling; dawn does the rising.
	rotation.z = sin(_t * 0.8) * 0.004
	for bank in _banks:
		bank.position.z = fmod(bank.position.z + _scroll * delta + 35.0, 70.0) - 35.0
	if _dawn < 1.0:
		_dawn = minf(_dawn + delta / 95.0, 1.0)
		var d := _dawn
		_env.ambient_light_color = Color(0.16, 0.17, 0.22).lerp(Color(0.42, 0.40, 0.38), d)
		_env.fog_light_color = Color(0.10, 0.11, 0.14).lerp(Color(0.45, 0.42, 0.38), d)
		_sun.light_energy = d * 1.1
		# The sky itself does the rising: stars drain, the east catches
		_sky_mat.set_shader_parameter("top_color",
			Color(0.030, 0.040, 0.080).lerp(Color(0.36, 0.44, 0.58), d))
		_sky_mat.set_shader_parameter("horizon_color",
			Color(0.075, 0.080, 0.115).lerp(Color(0.92, 0.68, 0.46), d))
		_sky_mat.set_shader_parameter("sun_color",
			Color(0.02, 0.02, 0.03).lerp(Color(1.0, 0.78, 0.50), d))
		_sky_mat.set_shader_parameter("star_amount", 0.5 * (1.0 - d))
		_sky_mat.set_shader_parameter("cloud_lit_color",
			Color(0.09, 0.10, 0.14).lerp(Color(0.95, 0.76, 0.58), d))
		_sky_mat.set_shader_parameter("cloud_shadow_color",
			Color(0.04, 0.045, 0.07).lerp(Color(0.42, 0.42, 0.50), d))
