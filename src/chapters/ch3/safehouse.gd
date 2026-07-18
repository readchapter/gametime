extends Node3D
## Chapter 3 — the room over Sylvie's shop. A day of confinement: the rules,
## the plan, the BBC under a blanket of static — and the street sweep,
## watched from the edge of a curtain, when the knocking works its way down
## the row of doors and takes the neighbour instead of you. At dusk, the
## walk to the station.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const PLASTER := Color(0.44, 0.41, 0.36)
const WOOD := Color(0.26, 0.18, 0.11)
const WOOD_DARK := Color(0.16, 0.11, 0.07)
const FLOOR_C := Color(0.32, 0.23, 0.15)
const CLOTH_SYLVIE := Color(0.30, 0.24, 0.22)
const SKIN := Color(0.48, 0.38, 0.30)
const CURTAIN := Color(0.38, 0.30, 0.26)

const W := 5.4
const D := 4.6
const H := 2.5
const WINDOW_AT := Vector3(0.9, 1.35, D / 2 - 0.1)   # south wall, over the street
const RADIO_AT := Vector3(-1.9, 0, -1.5)
const DOOR_AT := Vector3(-2.4, 0, -2.1)

var _player: CharacterBody3D
var _sylvie: Node3D
var _radio: Interactable
var _window: Interactable
var _door: Interactable
var _lamp: OmniLight3D
var _day_light: OmniLight3D
var _env: Environment
var _glass: MeshInstance3D
var _street_figures: Array[Node3D] = []
var _phase := 0  # 0 arrive/talk, 1 radio open, 2 sweep, 3 dusk/leave
var _t := 0.0

func _ready() -> void:
	_build_environment()
	_build_room()
	_build_street()
	_build_furnishing()
	_build_people()
	_spawn_player()
	AudioManager.play_ambient("town_day")
	SceneDirector.fade_in(1.8)
	Hud.subtitle("", "(A room that smells of thread and yesterday's bread. The shop bell below, now and then.)", 5.0)
	CaptureHarness.snap("ch3_room")
	_arrival()

func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.32, 0.36, 0.42)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.30, 0.30, 0.33)
	_env.ambient_light_energy = 0.85
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

func _build_room() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(W, 0.2, D), Vector3(0, -0.1, 0), FLOOR_C)
	mb.box(Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), PLASTER.darkened(0.3))
	for x: float in [-1.6, 1.0]:
		mb.box(Vector3(0.14, 0.18, D), Vector3(x, H - 0.09, 0), WOOD_DARK)
	mb.box(Vector3(0.2, H, D), Vector3(-W / 2, H / 2, 0), PLASTER)
	mb.box(Vector3(0.2, H, D), Vector3(W / 2, H / 2, 0), PLASTER.darkened(0.06))
	mb.box(Vector3(W, H, 0.2), Vector3(0, H / 2, -D / 2), PLASTER)
	# South wall in three pieces around the window (window x 0.3..1.5, y 0.75..1.95)
	mb.box(Vector3(3.0, H, 0.2), Vector3(-1.2, H / 2, D / 2), PLASTER.darkened(0.03))
	mb.box(Vector3(1.2, H, 0.2), Vector3(2.1, H / 2, D / 2), PLASTER.darkened(0.03))
	mb.box(Vector3(1.2, 0.75, 0.2), Vector3(0.9, 0.375, D / 2), PLASTER.darkened(0.03))
	mb.box(Vector3(1.2, H - 1.95, 0.2), Vector3(0.9, (H + 1.95) / 2, D / 2), PLASTER.darkened(0.03))
	# Window frame: slats around the opening (seen THROUGH, unlike Ch1's
	# solid plank trick) + a centre mullion silhouetted in the view.
	mb.box(Vector3(1.3, 0.08, 0.1), Vector3(0.9, 1.92, D / 2 + 0.02), WOOD_DARK)  # head
	mb.box(Vector3(1.3, 0.08, 0.1), Vector3(0.9, 0.78, D / 2 + 0.02), WOOD_DARK)  # sill
	mb.box(Vector3(0.08, 1.24, 0.1), Vector3(0.32, 1.35, D / 2 + 0.02), WOOD_DARK)
	mb.box(Vector3(0.08, 1.24, 0.1), Vector3(1.48, 1.35, D / 2 + 0.02), WOOD_DARK)
	mb.box(Vector3(0.06, 1.2, 0.12), Vector3(0.9, 1.35, D / 2 - 0.02), WOOD_DARK)
	# The door out (to the stairs)
	mb.box(Vector3(0.8, 2.0, 0.12), Vector3(DOOR_AT.x, 1.0, -D / 2 + 0.04), WOOD_DARK)
	add_child(mb.commit_instance("Room"))

	# Curtains: two panels with a working gap in the middle of the pane
	var cmb := MeshBuilder.new()
	cmb.box(Vector3(0.7, 1.5, 0.04), Vector3(0.35, 1.35, D / 2 - 0.16), CURTAIN)
	cmb.box(Vector3(0.42, 1.5, 0.04), Vector3(1.45, 1.35, D / 2 - 0.16), CURTAIN.darkened(0.1))
	add_child(cmb.commit_instance("Curtains"))

	# Day glass: what light there is, through cloth
	_glass = MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(1.2, 1.2, 0.04)
	_glass.mesh = gb
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.68, 0.70, 0.72)
	gmat.emission_enabled = true
	gmat.emission = Color(0.68, 0.70, 0.72)
	gmat.emission_energy_multiplier = 1.1
	_glass.material_override = gmat
	_glass.position = Vector3(0.9, 1.35, D / 2 + 0.06)
	add_child(_glass)

	var body := StaticBody3D.new()
	for spec: Array in [
		[Vector3(W, 0.2, D), Vector3(0, -0.1, 0)],
		[Vector3(0.3, H, D), Vector3(-W / 2, H / 2, 0)],
		[Vector3(0.3, H, D), Vector3(W / 2, H / 2, 0)],
		[Vector3(W, H, 0.3), Vector3(0, H / 2, -D / 2)],
		[Vector3(W, H, 0.3), Vector3(0, H / 2, D / 2)],
	]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		cs.position = spec[1]
		body.add_child(cs)
	add_child(body)

## The street below the window: cobbles, the facade opposite, parked shapes.
## Only ever seen through the curtain gap, pitched down.
func _build_street() -> void:
	var mb := MeshBuilder.new()
	var cobble := Color(0.30, 0.29, 0.28)
	var facade := Color(0.40, 0.37, 0.33)
	mb.box(Vector3(26, 0.2, 7.0), Vector3(0, -3.6, D / 2 + 4.5), cobble)
	# Opposite row of houses
	for i in 4:
		var x := -9.0 + i * 6.0
		mb.box(Vector3(5.4, 6.0, 0.4), Vector3(x, -0.6, D / 2 + 8.2), facade.darkened(0.04 * (i % 3)))
		mb.prism(Vector3(5.8, 1.4, 1.2), Vector3(x, 3.1, D / 2 + 8.0), Color(0.22, 0.16, 0.12))
		for wy: float in [-1.8, 0.2]:
			for wx: float in [-1.6, 0.0, 1.6]:
				mb.box(Vector3(0.7, 1.0, 0.1), Vector3(x + wx, wy, D / 2 + 7.95), Color(0.10, 0.11, 0.13))
	# A canvas truck at the end of the street — where taken people go
	mb.box(Vector3(2.1, 1.6, 4.6), Vector3(8.5, -2.6, D / 2 + 4.2), Color(0.15, 0.16, 0.14))
	mb.box(Vector3(1.9, 0.9, 1.4), Vector3(8.5, -2.9, D / 2 + 1.6), Color(0.13, 0.14, 0.12))
	add_child(mb.commit_instance("Street"))

func _street_figure(at_x: float, cloth: Color) -> Node3D:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0.38, 0.6, 0.24), Vector3(0, 1.08, 0), cloth)
	mb.box(Vector3(0.24, 0.78, 0.2), Vector3(0, 0.39, 0), cloth.darkened(0.2))
	mb.sphere(0.11, 0.22, Vector3(0, 1.52, 0), SKIN)
	var node := mb.commit_instance("StreetFigure")
	node.position = Vector3(at_x, -3.5, D / 2 + 4.0)
	add_child(node)
	_street_figures.append(node)
	return node

func _build_furnishing() -> void:
	var mb := MeshBuilder.new()
	# Cot along the west wall, table centre, washstand
	mb.box(Vector3(0.9, 0.3, 1.9), Vector3(-2.2, 0.15, 0.8), WOOD_DARK)
	mb.box(Vector3(0.8, 0.12, 1.8), Vector3(-2.2, 0.36, 0.8), Color(0.50, 0.47, 0.40))
	mb.box(Vector3(1.3, 0.08, 0.8), Vector3(0.3, 0.72, -0.6), WOOD)
	for leg: Vector3 in [Vector3(-0.25, 0.36, -0.95), Vector3(0.85, 0.36, -0.95),
			Vector3(-0.25, 0.36, -0.25), Vector3(0.85, 0.36, -0.25)]:
		mb.box(Vector3(0.07, 0.72, 0.07), leg, WOOD_DARK)
	mb.box(Vector3(0.5, 0.85, 0.4), Vector3(2.3, 0.425, -1.9), WOOD)
	add_child(mb.commit_instance("Furnishing"))
	var chair := Kit.model("chair", Color(0.44, 0.31, 0.19), 1.4)
	if chair:
		chair.position = Vector3(0.3, 0, -1.3)
		add_child(chair)
	var chair2 := Kit.model("chairRounded", Color(0.44, 0.31, 0.19), 1.4)
	if chair2:
		chair2.position = Vector3(0.3, 0, 0.15)
		chair2.rotation.y = PI
		add_child(chair2)

	# The radio: a wooden set on its own small stand, dial glowing faintly
	var rmb := MeshBuilder.new()
	rmb.box(Vector3(0.55, 0.5, 0.45), RADIO_AT + Vector3(0, 0.25, 0), WOOD_DARK)
	rmb.box(Vector3(0.5, 0.35, 0.35), RADIO_AT + Vector3(0, 0.75, 0), WOOD)
	add_child(rmb.commit_instance("RadioStand"))
	var dial := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(0.16, 0.06, 0.02)
	dial.mesh = db
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.95, 0.75, 0.35)
	dmat.emission_enabled = true
	dmat.emission = Color(0.95, 0.75, 0.35)
	dmat.emission_energy_multiplier = 1.6
	dial.material_override = dmat
	dial.position = RADIO_AT + Vector3(0, 0.78, 0.19)
	add_child(dial)

	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(0.3, 1.6, -0.6)
	_lamp.light_color = Color(1.0, 0.75, 0.45)
	_lamp.light_energy = 0.9
	_lamp.omni_range = 5.0
	add_child(_lamp)
	_day_light = OmniLight3D.new()
	_day_light.position = WINDOW_AT + Vector3(0, 0.2, -0.8)
	_day_light.light_color = Color(0.75, 0.78, 0.82)
	_day_light.light_energy = 1.4
	_day_light.omni_range = 5.5
	_day_light.shadow_enabled = true
	add_child(_day_light)

func _build_people() -> void:
	_sylvie = Figures.villager(CLOTH_SYLVIE, "Sylvie")
	_sylvie.position = Vector3(1.1, 0, -0.9)
	_sylvie.rotation.y = -0.6
	add_child(_sylvie)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-1.7, 0.05, -1.6)  # just in from the door
	_player.rotation.y = -PI / 2 + 0.3
	add_child(_player)

func _arrival() -> void:
	_player.move_enabled = false
	await get_tree().create_timer(2.5, false).timeout
	DialogueManager.start("res://data/dialogue/ch3/safehouse_plan.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	_player.move_enabled = true
	_phase = 1
	# The radio becomes the thing to do while the day crawls.
	_radio = Interactable.new()
	_radio.name = "Radio"
	_radio.prompt = "Listen"
	_radio.one_shot = true
	_radio.position = RADIO_AT + Vector3(0, 0.6, 0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.2, 0.9)
	cs.shape = shape
	cs.position = Vector3(0, 0.3, 0)
	_radio.add_child(cs)
	_radio.interacted.connect(_on_radio)
	add_child(_radio)
	Hud.subtitle("SYLVIE", "The day is long up here. The radio works, if you keep it under your breath.", 5.0)

func _on_radio(player: Node) -> void:
	player.move_enabled = false
	Hud.hide_prompt()
	AudioManager.play_sfx("radio_static", -8.0)
	await get_tree().create_timer(2.0, false).timeout
	Hud.subtitle("RADIO", "…Ici Londres. Les Français parlent aux Français…", 4.5)
	await get_tree().create_timer(4.5, false).timeout
	Hud.subtitle("RADIO", "…Jean has a long moustache. I repeat: Jean has a long moustache…", 4.5)
	await get_tree().create_timer(4.5, false).timeout
	Hud.subtitle("RADIO", "…The carrots are cooked. I repeat: the carrots are cooked…", 4.5)
	await get_tree().create_timer(4.5, false).timeout
	Hud.subtitle("SYLVIE", "That one was ours. Somewhere tonight, something happens because of nine words.", 5.0)
	GameState.set_flag("heard_radio", true)
	await get_tree().create_timer(4.0, false).timeout
	player.move_enabled = true
	_begin_sweep()

## The sweep: knocking works down the street. Watch from the curtain's edge.
func _begin_sweep() -> void:
	_phase = 2
	await get_tree().create_timer(5.0, false).timeout
	AudioManager.play_sfx("knock_door", -6.0)
	Hud.subtitle("SYLVIE", "Lamp out.", 2.5)
	_lamp.light_energy = 0.0
	await get_tree().create_timer(2.0, false).timeout
	Hud.subtitle("SYLVIE", "They are on the street. The curtain — from the edge, if you must look.", 4.5)
	_window = Interactable.new()
	_window.name = "CurtainGap"
	_window.prompt = "Watch the street"
	_window.one_shot = true
	_window.position = Vector3(WINDOW_AT.x + 0.35, 0, WINDOW_AT.z - 0.55)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 2.0, 0.7)
	cs.shape = shape
	cs.position = Vector3(0, 1.0, 0)
	_window.add_child(cs)
	_window.interacted.connect(_on_watch)
	add_child(_window)

func _on_watch(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	var cam: Camera3D = player.camera
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# The curtain gap is centred at x≈0.97; stand in it, close, pitched down.
	tw.tween_property(player, "position", Vector3(0.97, 0.05, WINDOW_AT.z - 0.42), 1.0)
	tw.parallel().tween_property(player, "rotation:y", PI, 1.0)
	tw.parallel().tween_property(cam, "rotation:x", -0.62, 1.0)
	await tw.finished
	_glass.hide()  # the pane would block the sightline; the curtain is the frame
	# The sweep, below: two grey figures working the doors, one civilian
	# walked to the truck.
	var s1 := _street_figure(-6.0, Color(0.20, 0.22, 0.18))
	var s2 := _street_figure(-4.6, Color(0.20, 0.22, 0.18))
	var civ := _street_figure(-5.3, Color(0.32, 0.28, 0.24))
	civ.hide()
	AudioManager.play_sfx("knock_door", -10.0)
	Hud.subtitle("", "(Two of them. Working the doors on the far side, patient as rent collectors.)", 5.0)
	var t1 := create_tween()
	t1.tween_property(s1, "position:x", -1.5, 6.0)
	t1.parallel().tween_property(s2, "position:x", -0.2, 6.0)
	await get_tree().create_timer(2.5, false).timeout
	CaptureHarness.snap("ch3_sweep")
	await t1.finished
	AudioManager.play_sfx("knock_door", -8.0)
	await get_tree().create_timer(3.5, false).timeout
	civ.show()
	civ.position.x = -0.8
	Hud.subtitle("", "(A door opens. A man in shirtsleeves steps out between them, carrying nothing.)", 5.0)
	var t2 := create_tween()
	t2.tween_property(civ, "position:x", 8.0, 7.0)
	t2.parallel().tween_property(s1, "position:x", 7.2, 7.0)
	t2.parallel().tween_property(s2, "position:x", 8.8, 7.0)
	# Your eye follows them down the street to the truck. Set the full
	# rotation each step: after landing exactly on yaw=PI, Godot re-reads
	# the Euler as (-PI, 0, -PI) and a rotation:y tween goes sideways.
	t2.parallel().tween_method(func(y: float) -> void:
		player.rotation = Vector3(0, y, 0), PI, PI + 0.55, 7.0)
	await get_tree().create_timer(3.2, false).timeout
	CaptureHarness.snap("ch3_taken")
	await t2.finished
	AudioManager.play_sfx("truck_pass", -12.0)
	Hud.subtitle("", "(The truck takes him the way trucks do — like weather. Nobody on the street looks up.)", 5.5)
	await get_tree().create_timer(5.0, false).timeout
	Hud.subtitle("SYLVIE", "Monsieur Brossard. He sold them nothing; someone sold him. Come away from the window.", 5.5)
	await get_tree().create_timer(4.5, false).timeout
	var back := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(cam, "rotation:x", 0.0, 0.8)
	await back.finished
	_glass.show()
	player.look_enabled = true
	player.move_enabled = true
	_to_dusk()

func _to_dusk() -> void:
	await get_tree().create_timer(3.0, false).timeout
	await SceneDirector.fade_out(1.6)
	await CutscenePlayer.caption("D U S K", 2.6)
	_env.background_color = Color(0.06, 0.07, 0.10)
	_env.ambient_light_color = Color(0.12, 0.13, 0.17)
	_env.ambient_light_energy = 0.65
	var gmat: StandardMaterial3D = _glass.material_override
	gmat.albedo_color = Color(0.12, 0.16, 0.26)
	gmat.emission = Color(0.12, 0.16, 0.26)
	_day_light.light_energy = 0.25
	_day_light.light_color = Color(0.35, 0.42, 0.60)
	_lamp.light_energy = 1.4
	await SceneDirector.fade_in(1.4)
	_phase = 3
	Hud.subtitle("SYLVIE", "Now. The last train sits twenty minutes at the barrier — we walk slowly and arrive exactly. Ten steps.", 6.0)
	_door = Interactable.new()
	_door.name = "StairsDoor"
	_door.prompt = "Leave for the station"
	_door.one_shot = true
	_door.position = Vector3(DOOR_AT.x, 0, DOOR_AT.z)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 2.0, 0.8)
	cs.shape = shape
	cs.position = Vector3(0, 1.0, 0.2)
	_door.add_child(cs)
	_door.interacted.connect(_on_leave)
	add_child(_door)

func _on_leave(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	AudioManager.stop_ambient(1.5)
	GameState.set_flag("ch3_safehouse_done")
	SceneDirector.goto_beat("ch3_checkpoint", 1.5)

func _process(delta: float) -> void:
	_t += delta
	_autoplay_step(delta)

func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	match _phase:
		1:
			if _radio and not GameState.get_flag("heard_radio"):
				if _player.position.distance_to(_radio.position) > 1.5:
					var target := _radio.position
					target.y = _player.position.y
					_player.position = _player.position.move_toward(target, delta * 3.0)
				else:
					_radio.interact(_player)
		2:
			if _window:
				var wt := Vector3(_window.position.x, _player.position.y, _window.position.z)
				if _player.position.distance_to(wt) > 1.3:
					_player.position = _player.position.move_toward(wt, delta * 3.0)
				else:
					_window.interact(_player)
		3:
			if _door:
				var dt := Vector3(DOOR_AT.x, _player.position.y, DOOR_AT.z + 0.6)
				if _player.position.distance_to(dt) > 1.3:
					_player.position = _player.position.move_toward(dt, delta * 3.0)
				else:
					_door.interact(_player)
