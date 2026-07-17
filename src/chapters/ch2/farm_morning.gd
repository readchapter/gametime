extends "res://src/chapters/ch1/farmhouse.gd"
## Chapter 2 — the farmhouse, morning after the crash. Same rooms, cold
## early light. The canton knows a bomber fell; a German patrol reaches the
## door and Travis hides a wall away from them. At dusk the resistance
## escort arrives. Reuses the Ch1 set via the _build_* hooks.

const HIDE_SPOT := Vector3(2.55, 0, 0.15)  # against the dividing wall, off the window lines
const FRONT_DOOR := Vector3(-1.05, 0, 2.4)

const DAY_GLASS := Color(0.72, 0.78, 0.85)
const CLOTH_MARCEL := Color(0.16, 0.17, 0.19)

# Phases: 0 wake, 1 talking, 2 knock (hide open), 3 patrol, 4 dusk/marcel,
# 5 leave available.
var _phase := 0
var _env: Environment
var _day_lights: Array[Light3D] = []
var _lamp: OmniLight3D
var _hide_spot: Interactable
var _door: Interactable
var _marcel: Node3D

func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.10, 0.115, 0.13)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.30, 0.32, 0.36)
	_env.ambient_light_energy = 0.85
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

func _build_glow() -> void:
	_glass.append(_emissive_box(Vector3(1.1, 0.9, 0.04), Vector3(-1.0, 1.55, -2.86), DAY_GLASS, 1.6))
	# Inside the frame box's inner face, so the pane reads from indoors.
	_glass.append(_emissive_box(Vector3(0.04, 0.85, 0.85), Vector3(4.76, 1.5, 1.2), DAY_GLASS, 1.5))
	_emissive_box(Vector3(0.25, 0.12, 0.7), Vector3(-3.5, 0.12, 0.4), Color(0.55, 0.16, 0.04), 1.2)

func _build_lights() -> void:
	# Cold daylight spilling from both windows; the fire is down to embers.
	for spec: Array in [[Vector3(-1.0, 1.6, -2.4), 1.7, 6.0], [Vector3(4.4, 1.5, 1.2), 1.4, 4.5]]:
		var day := OmniLight3D.new()
		day.position = spec[0]
		day.light_color = Color(0.72, 0.78, 0.88)
		day.light_energy = spec[1]
		day.omni_range = spec[2]
		day.shadow_enabled = true
		add_child(day)
		_day_lights.append(day)
	_fire_base_energy = 0.35
	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(-3.3, 0.5, 0.4)
	_fire_light.light_color = Color(1.0, 0.42, 0.16)
	_fire_light.light_energy = _fire_base_energy
	_fire_light.omni_range = 3.5
	add_child(_fire_light)
	# The table lamp, unlit until dusk.
	_lamp = OmniLight3D.new()
	_lamp.position = TABLE + Vector3(0.0, 1.4, 0.15)
	_lamp.light_color = Color(1.0, 0.72, 0.45)
	_lamp.light_energy = 0.0
	_lamp.omni_range = 6.5
	add_child(_lamp)

func _build_family() -> void:
	# Henri stands watch by the window; Marguerite by the fire; Luc at the
	# table. Nobody is eating.
	_standing_figure(Vector3(-0.35, 0, -2.15), PI, CLOTH_HENRI, "Henri")
	_standing_figure(Vector3(-2.75, 0, 1.25), PI / 2 + 0.5, CLOTH_MARG, "Marguerite")
	var luc := ModelLib.get_model("villager_seated", func() -> Node3D:
		var mb := MeshBuilder.new()
		_figure(mb, Vector3.ZERO, 0.0, CLOTH_LUC)
		return mb.commit_instance("Luc"))
	luc.position = TABLE + Vector3(0.95, 0, 0.0)
	luc.rotation.y = -PI / 2
	add_child(luc)

func _standing_figure(at: Vector3, yaw: float, cloth: Color, fig_name: String) -> Node3D:
	var node := ModelLib.get_model("villager_standing", func() -> Node3D:
		var mb := MeshBuilder.new()
		for side in [-0.10, 0.10]:
			mb.box(Vector3(0.13, 0.78, 0.15), Vector3(side, 0.39, 0.0), cloth.darkened(0.25))
		mb.box(Vector3(0.40, 0.62, 0.24), Vector3(0, 1.09, 0.0), cloth)
		for side in [-0.245, 0.245]:
			mb.box(Vector3(0.09, 0.55, 0.12), Vector3(side, 1.10, 0.0), cloth.darkened(0.1))
		mb.sphere(0.115, 0.23, Vector3(0, 1.55, 0.0), SKIN)
		return mb.commit_instance(fig_name))
	node.name = fig_name
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	return node

func _build_interactables() -> void:
	_hide_spot = Interactable.new()
	_hide_spot.name = "HideSpot"
	_hide_spot.prompt = "Press against the wall"
	_hide_spot.required_flag = "ch2_knock"
	_hide_spot.blocked_flag = "ch2_patrol_done"
	_hide_spot.one_shot = true
	_hide_spot.position = HIDE_SPOT
	_box_shape_i(_hide_spot, Vector3(0.8, 1.8, 1.0), Vector3(0, 0.9, 0.4))
	_hide_spot.interacted.connect(_on_hide)
	add_child(_hide_spot)

	_door = Interactable.new()
	_door.name = "FrontDoor"
	_door.prompt = "Leave with Marcel"
	_door.required_flag = "ch2_marcel_done"
	_door.one_shot = true
	_door.position = FRONT_DOOR
	_box_shape_i(_door, Vector3(1.0, 2.0, 0.6), Vector3(0, 1.0, 0.3))
	_door.interacted.connect(_on_leave)
	add_child(_door)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	# Beside the bed — NOT inside its collision blocker (x 3..5, z 0.75..1.85):
	# physics depenetration will pin an autoplay walker spawned intersecting it.
	_player.position = Vector3(3.6, 0.05, 2.3)
	_player.rotation.y = PI / 2  # facing the doorway through to the main room
	add_child(_player)

func _flow() -> void:
	# The beat checkpoints at the scene level: entering it (fresh or via
	# continue) always replays the whole morning, so its gate flags reset.
	for f in ["ch2_knock", "ch2_patrol_done", "ch2_marcel_done"]:
		GameState.set_flag(f, false)
	AudioManager.play_ambient("morning_farm")
	SceneDirector.fade_in(1.8)
	Hud.subtitle("", "(Morning. You slept after all.)", 4.0)
	CaptureHarness.snap("ch2_morning")

func _process(delta: float) -> void:
	_t += delta
	if _fire_light:
		_fire_light.light_energy = _fire_base_energy \
			+ sin(_t * 11.0) * 0.03 + sin(_t * 4.7 + 1.3) * 0.03
	# Reaching the main room starts the morning exchange.
	if _phase == 0 and _player and _player.position.x < 1.5:
		_phase = 1
		_morning_talk()
	_autoplay_step(delta)

func _morning_talk() -> void:
	_player.move_enabled = false
	DialogueManager.start("res://data/dialogue/ch2/farm_morning.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	_player.move_enabled = true
	# The patrol reaches the door not long after.
	await get_tree().create_timer(6.0, false).timeout
	_knock()

func _knock() -> void:
	_phase = 2
	AudioManager.play_sfx("knock_door")
	Hud.subtitle("HENRI", "The bedroom. Against the wall. Now.", 4.0)
	GameState.set_flag("ch2_knock")

func _on_hide(player: Node) -> void:
	_phase = 3
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	# Pull tight to the wall, facing the doorway gap.
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player, "position", HIDE_SPOT + Vector3(0.0, 0.05, 0.75), 0.8)
	tw.parallel().tween_property(player, "rotation:y", PI / 2, 0.8)
	await tw.finished
	CaptureHarness.snap("ch2_hide")
	await _patrol_beat(player)

func _patrol_beat(player: Node) -> void:
	AudioManager.play_sfx("knock_door")
	await get_tree().create_timer(2.2, false).timeout
	Hud.subtitle("", "(The door. Henri's voice, level. German vowels behind it.)", 4.5)
	await get_tree().create_timer(4.5, false).timeout
	if GameState.get_flag("landing_bad"):
		# They saw the chute come down near here. They step inside.
		Hud.subtitle("", "(Boots on the boards. Two of them. Inside.)", 4.0)
		await _soldier_walkthrough()
		Hud.subtitle("", "(A pause you can hear. Then boots again, going away.)", 4.5)
		await get_tree().create_timer(4.0, false).timeout
	else:
		Hud.subtitle("", "(Questions. Henri's shrug travels through the wall.)", 4.5)
		await get_tree().create_timer(5.0, false).timeout
		Hud.subtitle("", "(Footsteps recede. An engine starts, moves off.)", 4.0)
		await get_tree().create_timer(3.5, false).timeout
	GameState.set_flag("ch2_patrol_done")
	Hud.subtitle("HENRI", "They are gone. You did not breathe, I think.", 4.0)
	player.move_enabled = true
	player.look_enabled = true
	await get_tree().create_timer(3.0, false).timeout
	_to_dusk()

## A soldier crosses the main room, glimpsed through the doorway gap from the
## hide spot, a cold handlamp spilling ahead of him.
func _soldier_walkthrough() -> void:
	var soldier := _standing_figure(Vector3(-1.05, 0, 2.3), 0.0, Color(0.20, 0.22, 0.18), "Soldier")
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.75, 0.85, 1.0)
	lamp.light_energy = 1.6
	lamp.omni_range = 4.0
	lamp.position = Vector3(0, 1.3, 0.4)
	soldier.add_child(lamp)
	var tw := create_tween()
	tw.tween_property(soldier, "position", Vector3(-0.8, 0, -1.8), 4.0)
	tw.tween_interval(1.6)
	tw.tween_property(soldier, "rotation:y", PI, 0.8)
	# He looks down the bedroom doorway line on his way back.
	tw.tween_property(soldier, "position", Vector3(0.9, 0, 1.0), 3.0)
	tw.tween_interval(1.8)
	tw.tween_property(soldier, "position", Vector3(-1.05, 0, 2.4), 2.4)
	await tw.finished
	soldier.queue_free()

## Time-skip to dusk while black: retint the glass, kill the daylight,
## light the lamp.
func _to_dusk() -> void:
	await SceneDirector.fade_out(1.6)
	await CutscenePlayer.caption("D U S K", 2.6)
	_env.background_color = Color(0.012, 0.014, 0.022)
	_env.ambient_light_color = Color(0.11, 0.12, 0.15)
	_env.ambient_light_energy = 0.6
	for g in _glass:
		var mat: StandardMaterial3D = g.material_override
		mat.albedo_color = NIGHT_GLASS
		mat.emission = NIGHT_GLASS
		mat.emission_energy_multiplier = 1.3
	for d in _day_lights:
		d.light_energy = 0.0
	_lamp.light_energy = 2.2
	_emissive_box(Vector3(0.09, 0.13, 0.09), TABLE + Vector3(0.0, 0.95, 0.15), Color(1.0, 0.75, 0.42), 3.0)
	_fire_base_energy = 1.0
	AudioManager.play_ambient("night_interior")
	await SceneDirector.fade_in(1.6)
	_marcel_arrives()

func _marcel_arrives() -> void:
	_phase = 4
	AudioManager.play_sfx("knock_door")
	await get_tree().create_timer(1.8, false).timeout
	_marcel = _standing_figure(Vector3(-1.6, 0, 1.9), PI * 0.85, CLOTH_MARCEL, "Marcel")
	Hud.subtitle("", "(Two knocks, then one. Henri opens the door to the dark.)", 4.0)
	await get_tree().create_timer(3.2, false).timeout
	_player.move_enabled = false
	CaptureHarness.snap("ch2_marcel")
	DialogueManager.start("res://data/dialogue/ch2/marcel_intro.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	_player.move_enabled = true
	GameState.set_flag("ch2_marcel_done")
	_phase = 5
	Hud.subtitle("", "(He is already at the door.)", 3.5)

func _on_leave(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	AudioManager.stop_ambient(2.0)
	GameState.set_flag("ch2_morning_done")
	SceneDirector.goto_beat("ch2_walk", 1.5)

## Headless drive: main room → hide spot → front door as the gates open.
func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	match _phase:
		0:
			var target := DOORWAY if _player.position.x > 1.6 else Vector3(0.0, 0, 0.6)
			_player.position = _player.position.move_toward(target, delta * 3.5)
		2:
			var route := DOORWAY if _player.position.x < 1.6 else HIDE_SPOT + Vector3(0, 0, 0.75)
			if _player.position.distance_to(HIDE_SPOT + Vector3(0, 0, 0.75)) > 1.4:
				_player.position = _player.position.move_toward(route, delta * 3.5)
			else:
				_hide_spot.interact(_player)
		5:
			var route := DOORWAY if _player.position.x > 1.6 else FRONT_DOOR
			if _player.position.distance_to(FRONT_DOOR) > 1.4:
				_player.position = _player.position.move_toward(route, delta * 3.5)
			else:
				_door.interact(_player)
