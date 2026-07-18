extends Node3D
## Chapter 4 — Madame Béranger's fifth floor: one evening, one day, one
## decision. Lucien's three probes are spread across the day like crumbs
## (each reveal prices the future via +exposure), Béranger warns in
## proverbs, the Paine book goes into the flour tin — and at dusk Freeman
## brings the fast route and the chapter's branch: go with the charming
## man, or stay with the slow soup.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const WALL := Color(0.36, 0.37, 0.32)     # faded green wallpaper
const WALL_DARK := Color(0.24, 0.25, 0.22)
const FLOOR_C := Color(0.30, 0.22, 0.14)
const WOOD_DARK := Color(0.15, 0.10, 0.07)
const CLOTH_BERANGER := Color(0.26, 0.25, 0.27)
const CLOTH_FREEMAN := Color(0.30, 0.28, 0.20)
const CLOTH_LUCIEN := Color(0.36, 0.30, 0.24)

const W := 7.4
const D := 5.6
const H := 2.6

var _player: CharacterBody3D
var _beranger: Node3D
var _freeman: Node3D
var _lucien: Node3D
var _env: Environment
var _shutter_glass: Array[MeshInstance3D] = []
var _lamp: OmniLight3D
var _day_light: OmniLight3D
# Phases: 0 meet, 1 lucien evening, 2 morning (probes/warnings/paine),
# 3 the choice, 4 done
var _phase := 0
var _probe_idx := 0
var _current_spot: Interactable
var _t := 0.0

func _ready() -> void:
	# The beat checkpoints at scene level: a replay re-runs every probe, so
	# the exposure ledger starts clean each entry.
	GameState.set_flag("exposure", 0)
	_build_environment()
	_build_room()
	_build_people()
	_spawn_player()
	AudioManager.play_ambient("apartment_day")
	SceneDirector.fade_in(1.8)
	Hud.subtitle("", "(Five flights up: a floor that smells of soup, wax, and eleven careful years.)", 5.0)
	CaptureHarness.snap("ch4_room")
	_evening_meet()

func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.015, 0.017, 0.026)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.13, 0.13, 0.15)
	_env.ambient_light_energy = 0.7
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

func _build_room() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(W, 0.2, D), Vector3(0, -0.1, 0), FLOOR_C)
	mb.box(Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), Color(0.42, 0.41, 0.37))
	for x: float in [-2.2, 0.6]:
		mb.box(Vector3(0.12, 0.16, D), Vector3(x, H - 0.08, 0), WOOD_DARK)
	mb.box(Vector3(0.2, H, D), Vector3(-W / 2, H / 2, 0), WALL)
	mb.box(Vector3(0.2, H, D), Vector3(W / 2, H / 2, 0), WALL.darkened(0.05))
	mb.box(Vector3(W, H, 0.2), Vector3(0, H / 2, -D / 2), WALL)
	mb.box(Vector3(W, H, 0.2), Vector3(0, H / 2, D / 2), WALL.darkened(0.03))
	# Wainscot line
	for wall_z: float in [-D / 2 + 0.11, D / 2 - 0.11]:
		mb.box(Vector3(W, 0.9, 0.04), Vector3(0, 0.45, wall_z), WALL_DARK)
	# Two tall shuttered windows on the street wall (south)
	for wx: float in [-1.8, 1.4]:
		mb.box(Vector3(1.2, 1.9, 0.1), Vector3(wx, 1.5, D / 2 - 0.06), WOOD_DARK)
		for slat in 7:
			mb.box(Vector3(1.05, 0.10, 0.05), Vector3(wx, 0.72 + slat * 0.26, D / 2 - 0.12),
				Color(0.20, 0.16, 0.11))
		var glass := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(1.05, 1.75, 0.03)
		glass.mesh = gb
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.06, 0.08, 0.13)
		gmat.emission_enabled = true
		gmat.emission = Color(0.06, 0.08, 0.13)
		gmat.emission_energy_multiplier = 1.0
		glass.material_override = gmat
		glass.position = Vector3(wx, 1.52, D / 2 - 0.02)
		add_child(glass)
		_shutter_glass.append(glass)
	# Hallway door (north wall, west end)
	mb.box(Vector3(0.9, 2.05, 0.1), Vector3(-2.6, 1.02, -D / 2 + 0.06), WOOD_DARK)
	# The stove corner (east): iron box, pipe, soup pot
	mb.box(Vector3(0.9, 1.0, 0.7), Vector3(3.0, 0.5, -1.9), Color(0.10, 0.10, 0.11))
	mb.cylinder(0.10, 0.10, 1.5, Vector3(3.0, 1.75, -1.9), Color(0.08, 0.08, 0.09))
	# Freeman's cot (west wall)
	mb.box(Vector3(0.9, 0.3, 1.9), Vector3(-3.1, 0.15, 0.6), WOOD_DARK)
	mb.box(Vector3(0.8, 0.12, 1.8), Vector3(-3.1, 0.36, 0.6), Color(0.44, 0.42, 0.36))
	# Dresser + flour tin shelf
	mb.box(Vector3(1.3, 1.0, 0.5), Vector3(2.9, 0.5, 2.3), WOOD_DARK.lightened(0.1))
	mb.box(Vector3(0.25, 0.3, 0.25), Vector3(3.2, 1.15, 2.3), Color(0.55, 0.55, 0.52))
	# Framed nothings on the walls
	for spec: Array in [[Vector3(-3.6, 1.7, -0.8), PI / 2], [Vector3(0.4, 1.8, -2.68), 0.0],
			[Vector3(-1.6, 1.6, -2.68), 0.0]]:
		mb.box(Vector3(0.5, 0.62, 0.05), spec[0], Color(0.32, 0.26, 0.18), spec[1])
		mb.box(Vector3(0.4, 0.5, 0.06), spec[0], Color(0.50, 0.48, 0.42), spec[1])
	add_child(mb.commit_instance("Room"))

	# Table + chairs (Kit, tinted) at centre
	var table := Kit.model("table", Color(0.40, 0.29, 0.18), 1.5)
	if table:
		table.position = Vector3(0.4, 0, 0.3)
		add_child(table)
	for spec: Array in [[Vector3(-0.5, 0, 0.3), PI / 2], [Vector3(1.3, 0, 0.3), -PI / 2],
			[Vector3(0.4, 0, 1.2), PI]]:
		var chair := Kit.model("chair", Color(0.40, 0.29, 0.18), 1.35)
		if chair:
			chair.position = spec[0]
			chair.rotation.y = spec[1]
			add_child(chair)

	# Collision shell
	var body := StaticBody3D.new()
	for spec: Array in [
		[Vector3(W, 0.2, D), Vector3(0, -0.1, 0)],
		[Vector3(0.3, H, D), Vector3(-W / 2, H / 2, 0)],
		[Vector3(0.3, H, D), Vector3(W / 2, H / 2, 0)],
		[Vector3(W, H, 0.3), Vector3(0, H / 2, -D / 2)],
		[Vector3(W, H, 0.3), Vector3(0, H / 2, D / 2)],
		[Vector3(1.1, 1.0, 0.7), Vector3(0.4, 0.5, 0.3)],
		[Vector3(0.9, 1.0, 0.7), Vector3(3.0, 0.5, -1.9)],
	]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		cs.position = spec[1]
		body.add_child(cs)
	add_child(body)

	# Lights: the oil lamp over the table, dim day spill at the shutters
	var lamp_glow := MeshInstance3D.new()
	var lg := BoxMesh.new()
	lg.size = Vector3(0.10, 0.14, 0.10)
	lamp_glow.mesh = lg
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(1.0, 0.76, 0.44)
	lmat.emission_enabled = true
	lmat.emission = Color(1.0, 0.76, 0.44)
	lmat.emission_energy_multiplier = 2.6
	lamp_glow.material_override = lmat
	lamp_glow.position = Vector3(0.4, 1.9, 0.3)
	add_child(lamp_glow)
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(0.4, 1.8, 0.3)
	_lamp.light_color = Color(1.0, 0.74, 0.46)
	_lamp.light_energy = 1.9
	_lamp.omni_range = 6.5
	_lamp.shadow_enabled = true
	add_child(_lamp)
	_day_light = OmniLight3D.new()
	_day_light.position = Vector3(0, 1.6, 1.9)
	_day_light.light_color = Color(0.65, 0.68, 0.72)
	_day_light.light_energy = 0.0
	_day_light.omni_range = 6.0
	add_child(_day_light)

func _build_people() -> void:
	_beranger = Figures.villager(CLOTH_BERANGER, "Beranger")
	_beranger.position = Vector3(2.4, 0, -1.6)
	_beranger.rotation.y = -2.2
	add_child(_beranger)
	_freeman = Figures.villager(CLOTH_FREEMAN, "Freeman")
	_freeman.position = Vector3(-2.6, 0, 0.9)
	_freeman.rotation.y = 1.4
	add_child(_freeman)
	_lucien = Figures.villager(CLOTH_LUCIEN, "Lucien")
	_lucien.position = Vector3(-2.5, 0, -2.0)
	_lucien.rotation.y = 0.9
	_lucien.hide()  # arrives with the bread
	add_child(_lucien)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-2.4, 0.05, -1.4)  # just in from the hallway door
	_player.rotation.y = -PI / 2 + 0.4
	add_child(_player)
	_player.camera.make_current()

## --- flow -------------------------------------------------------------

func _evening_meet() -> void:
	_player.move_enabled = false
	await get_tree().create_timer(2.2, false).timeout
	await _dialogue("res://data/dialogue/ch4/apartment_meet.json")
	# The knock that is bread and charm
	AudioManager.play_sfx("knock_door", -14.0)
	await get_tree().create_timer(2.0, false).timeout
	_lucien.show()
	Hud.subtitle("", "(Two knocks, a breath, one — the house knock, worn smooth by use.)", 4.0)
	await get_tree().create_timer(3.0, false).timeout
	CaptureHarness.snap("ch4_lucien")
	await _dialogue("res://data/dialogue/ch4/lucien_meet.json")
	_phase = 1
	await _night_skip()
	_morning()

func _night_skip() -> void:
	await SceneDirector.fade_out(1.6)
	await CutscenePlayer.caption("M O R N I N G", 2.6)
	_env.ambient_light_color = Color(0.30, 0.31, 0.33)
	_env.ambient_light_energy = 0.9
	_env.background_color = Color(0.22, 0.24, 0.28)
	for g in _shutter_glass:
		var mat: StandardMaterial3D = g.material_override
		mat.albedo_color = Color(0.62, 0.66, 0.70)
		mat.emission = Color(0.62, 0.66, 0.70)
		mat.emission_energy_multiplier = 1.3
	_day_light.light_energy = 1.5
	_lamp.light_energy = 0.7
	_lucien.position = Vector3(1.9, 0, 1.6)
	_lucien.rotation.y = -2.6
	await SceneDirector.fade_in(1.4)

## The day: three probes, the warning, the book — sequenced interactables.
func _morning() -> void:
	_phase = 2
	_player.move_enabled = true
	Hud.subtitle("", "(Morning behind shutters. Lucien is back with the ration cards — and with time on his hands.)", 5.0)
	_next_spot()

## Each beat of the day is a spot you walk to; finishing one opens the next.
## [prompt, stand_at, dialogue, snap_tag, face_toward]
const DAY_BEATS: Array = [
	["Lucien", Vector3(0.8, 0, 1.5), "res://data/dialogue/ch4/probe_name.json", "ch4_probe1", Vector3(1.9, 0, 1.6)],
	["Mme Béranger", Vector3(1.5, 0, -1.1), "res://data/dialogue/ch4/warnings.json", "", Vector3(2.4, 0, -1.6)],
	["Lucien", Vector3(0.8, 0, 1.5), "res://data/dialogue/ch4/probe_crash.json", "", Vector3(1.9, 0, 1.6)],
	["Kit bag", Vector3(-2.4, 0, 1.3), "res://data/dialogue/ch4/paine_book.json", "ch4_paine", Vector3(-3.1, 0, 0.6)],
	["Lucien", Vector3(0.8, 0, 1.5), "res://data/dialogue/ch4/probe_carry.json", "ch4_probe3", Vector3(1.9, 0, 1.6)],
]

func _next_spot() -> void:
	if _probe_idx >= DAY_BEATS.size():
		_evening_choice()
		return
	var beat: Array = DAY_BEATS[_probe_idx]
	_current_spot = Interactable.new()
	_current_spot.name = "DayBeat%d" % _probe_idx
	_current_spot.prompt = "Talk" if beat[0] != "Kit bag" else "Sort your kit"
	_current_spot.one_shot = true
	_current_spot.position = beat[1]
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1, 1.9, 1.1)
	cs.shape = shape
	cs.position = Vector3(0, 0.95, 0)
	_current_spot.add_child(cs)
	_current_spot.interacted.connect(_on_spot)
	add_child(_current_spot)

func _on_spot(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	var beat: Array = DAY_BEATS[_probe_idx]
	# Face whoever this beat belongs to before the first line lands.
	var to_face: Vector3 = beat[4] - player.position
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(y: float) -> void:
		player.rotation = Vector3(0, y, 0),
		player.rotation.y, atan2(-to_face.x, -to_face.z), 0.7)
	await tw.finished
	player.look_enabled = true
	if str(beat[3]) != "":
		CaptureHarness.snap(str(beat[3]))
	await _dialogue(str(beat[2]))
	player.move_enabled = true
	if is_instance_valid(_current_spot):
		_current_spot.queue_free()
	_probe_idx += 1
	_next_spot()

## Dusk. Freeman has news, and you have a decision.
func _evening_choice() -> void:
	_phase = 3
	await SceneDirector.fade_out(1.4)
	await CutscenePlayer.caption("D U S K", 2.4)
	_env.ambient_light_color = Color(0.13, 0.13, 0.15)
	_env.ambient_light_energy = 0.7
	_env.background_color = Color(0.015, 0.017, 0.026)
	for g in _shutter_glass:
		var mat: StandardMaterial3D = g.material_override
		mat.albedo_color = Color(0.06, 0.08, 0.13)
		mat.emission = Color(0.06, 0.08, 0.13)
	_day_light.light_energy = 0.0
	_lamp.light_energy = 1.9
	_lucien.hide()  # the tempter is never present for the temptation
	_freeman.position = Vector3(-1.2, 0, 0.9)
	_freeman.rotation.y = 1.2
	await SceneDirector.fade_in(1.4)
	_player.move_enabled = false
	_player.look_enabled = false
	var to_freeman := _freeman.position - _player.position
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(y: float) -> void:
		_player.rotation = Vector3(0, y, 0),
		_player.rotation.y, atan2(-to_freeman.x, -to_freeman.z), 0.8)
	await tw.finished
	_player.look_enabled = true
	CaptureHarness.snap("ch4_choice")
	await _dialogue("res://data/dialogue/ch4/the_choice.json")
	_phase = 4
	GameState.set_flag("freeman_lost", true)  # either way, he is on that route
	GameState.save_game()
	await get_tree().create_timer(2.5, false).timeout
	AudioManager.stop_ambient(2.0)
	SceneDirector.goto_beat("ch4_break", 1.6)

func _dialogue(path: String) -> void:
	DialogueManager.start(path)
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended

func _process(delta: float) -> void:
	_t += delta
	if _lamp:
		_lamp.light_energy += sin(_t * 8.0) * 0.004
	_autoplay_step(delta)

func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	if _phase == 2 and _current_spot and is_instance_valid(_current_spot):
		var target := Vector3(_current_spot.position.x, _player.position.y, _current_spot.position.z)
		if _player.position.distance_to(target) > 1.35:
			_player.position = _player.position.move_toward(target, delta * 3.2)
		else:
			_current_spot.interact(_player)
