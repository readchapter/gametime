extends Node3D
## Chapter 2 — the vetting. A barn on the village edge, one lantern, the
## network chief Étienne, two armed men in the dark, and another evader —
## Willis — whose story does not hold. Wrong answers accumulate suspicion;
## at the verdict, suspicion ≥ 2 is fatal. The first fail state in the game:
## game_over reloads this beat with the question phrasings varied (the
## replay-variation pools, live).

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const WOOD := Color(0.19, 0.14, 0.09)
const WOOD_DARK := Color(0.12, 0.09, 0.06)
const DIRT := Color(0.24, 0.19, 0.14)
const STRAW := Color(0.42, 0.34, 0.16)
const CLOTH_ETIENNE := Color(0.24, 0.22, 0.19)
const CLOTH_GUARD := Color(0.15, 0.16, 0.15)
const CLOTH_WILLIS := Color(0.22, 0.24, 0.30)
const SKIN := Color(0.50, 0.39, 0.31)

const W := 9.6   # barn interior span x
const D := 7.4   # span z
const H := 4.4
const MARK := Vector3(0.0, 0, 1.15)  # where Travis is told to stand

var _player: CharacterBody3D
var _willis: Node3D
var _guards: Array[Node3D] = []
var _lantern: OmniLight3D
var _started := false
var _t := 0.0

func _ready() -> void:
	# Fresh attempt: the verdict counters must not leak across retries, and
	# the Willis section varies with the same attempt counter as the vetting.
	GameState.set_flag("suspicion", 0)
	GameState.set_flag("vetting_failed", false)
	GameState.set_flag("has_document", GameState.has_item("document_fragment"))
	GameState.set_flag("attempt_ch2_vetting_willis",
		GameState.get_flag("attempt_ch2_vetting", 0))

	_build_environment()
	_build_shell()
	_build_dressing()
	_build_people()
	_spawn_player()
	AudioManager.play_ambient("night_interior")
	SceneDirector.fade_in(1.8)
	Hud.subtitle("", "(Straw, lantern oil, and men you cannot see the hands of.)", 4.5)

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.004, 0.005, 0.009)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.09, 0.09, 0.11)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_shell() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(W, 0.2, D), Vector3(0, -0.1, 0), DIRT)
	# Plank walls with a gappy top edge, posts, tie beams
	mb.box(Vector3(0.18, H, D), Vector3(-W / 2, H / 2, 0), WOOD)
	mb.box(Vector3(0.18, H, D), Vector3(W / 2, H / 2, 0), WOOD)
	mb.box(Vector3(W, H, 0.18), Vector3(0, H / 2, -D / 2), WOOD)
	mb.box(Vector3(W, H, 0.18), Vector3(0, H / 2, D / 2), WOOD.darkened(0.1))
	# Big doors behind the player (south), one leaf ajar
	mb.box(Vector3(2.6, 3.2, 0.16), Vector3(-1.4, 1.6, D / 2 - 0.02), WOOD_DARK)
	mb.box(Vector3(2.6, 3.2, 0.16), Vector3(1.55, 1.6, D / 2 - 0.3), WOOD_DARK, 0.35)
	# Roof planes
	mb.prism(Vector3(W + 0.6, 2.0, D + 0.4), Vector3(0, H + 1.0, 0), WOOD_DARK)
	for x: float in [-W / 2 + 1.2, W / 2 - 1.2]:
		for z: float in [-D / 2 + 1.1, D / 2 - 1.1]:
			mb.box(Vector3(0.24, H, 0.24), Vector3(x, H / 2, z), WOOD_DARK)
	mb.box(Vector3(W - 1.6, 0.22, 0.22), Vector3(0, H - 0.5, 0), WOOD_DARK)
	add_child(mb.commit_instance("Shell"))

	# Collision: floor + walls
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

func _build_dressing() -> void:
	var mb := MeshBuilder.new()
	# Straw heaped in the north corners
	mb.box(Vector3(2.6, 0.5, 2.0), Vector3(-W / 2 + 1.5, 0.25, -D / 2 + 1.2), STRAW)
	mb.box(Vector3(1.8, 0.9, 1.4), Vector3(-W / 2 + 1.1, 0.45, -D / 2 + 0.9), STRAW.darkened(0.15))
	mb.box(Vector3(2.2, 0.4, 1.6), Vector3(W / 2 - 1.4, 0.2, -D / 2 + 1.0), STRAW.darkened(0.05))
	# The crate Étienne works from, and the lantern crate
	mb.box(Vector3(1.1, 0.62, 0.7), Vector3(0, 0.31, -1.15), WOOD.lightened(0.08))
	# Loose straw strewn over the dirt: thin flat slivers at scattered yaws
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in 34:
		mb.box(Vector3(rng.randf_range(0.25, 0.6), 0.015, rng.randf_range(0.05, 0.12)),
			Vector3(rng.randf_range(-4.2, 4.2), 0.008, rng.randf_range(-3.1, 3.1)),
			STRAW.lightened(rng.randf_range(-0.1, 0.2)), rng.randf_range(0.0, TAU))
	add_child(mb.commit_instance("Dressing"))

	# The night through the ajar door leaf: a cold sliver behind the player.
	var slit := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.32, 2.9, 0.05)
	slit.mesh = sb
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.16, 0.20, 0.30)
	smat.emission_enabled = true
	smat.emission = Color(0.16, 0.20, 0.30)
	smat.emission_energy_multiplier = 1.1
	slit.material_override = smat
	slit.position = Vector3(0.15, 1.45, D / 2 - 0.16)
	add_child(slit)
	var spill := OmniLight3D.new()
	spill.position = Vector3(0.15, 1.6, D / 2 - 0.7)
	spill.light_color = Color(0.45, 0.55, 0.80)
	spill.light_energy = 0.5
	spill.omni_range = 3.0
	add_child(spill)

	for spec: Array in [["barrel", Vector3(-3.6, 0, 1.8), 0.0], ["barrel", Vector3(-3.9, 0, 0.7), 0.4],
			["box", Vector3(3.7, 0, 1.4), 0.2], ["box", Vector3(3.3, 0, 2.3), -0.3],
			["bucket", Vector3(2.9, 0, -2.6), 0.0], ["bedroll", Vector3(-3.2, 0.02, -1.6), 1.2]]:
		var node := Kit.model(spec[0], Color(0.45, 0.40, 0.34), 1.3)
		if node:
			node.position = spec[1]
			node.rotation.y = spec[2]
			add_child(node)

	# Lantern on the crate: the one pool of light in the room.
	var glass := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.12, 0.17, 0.12)
	glass.mesh = gb
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.76, 0.42)
	gmat.emission_enabled = true
	gmat.emission = Color(1.0, 0.76, 0.42)
	gmat.emission_energy_multiplier = 2.8
	glass.material_override = gmat
	glass.position = Vector3(0, 0.72, -1.15)
	add_child(glass)
	_lantern = OmniLight3D.new()
	_lantern.position = Vector3(0, 1.15, -1.1)
	_lantern.light_color = Color(1.0, 0.70, 0.40)
	_lantern.light_energy = 2.1
	_lantern.omni_range = 7.5
	_lantern.shadow_enabled = true
	add_child(_lantern)

func _build_people() -> void:
	# Étienne seated on a crate past the lantern, facing the mark.
	var mbe := MeshBuilder.new()
	mbe.box(Vector3(0.9, 0.55, 0.6), Vector3(0, 0.275, 0), WOOD.lightened(0.05))
	_seated(mbe, Vector3(0, 0.28, 0.05), CLOTH_ETIENNE)
	var etienne := mbe.commit_instance("Etienne")
	etienne.position = Vector3(0, 0, -2.15)
	add_child(etienne)
	# Two guards at the dark edges, long guns readable as lines.
	_guards.append(_standing(Vector3(-3.1, 0, -2.5), 0.5, CLOTH_GUARD, true))
	_guards.append(_standing(Vector3(3.2, 0, -2.2), -0.55, CLOTH_GUARD, true))
	# Willis just right of the mark, half in the lantern light, where his
	# removal happens in front of you rather than off-frame.
	_willis = _standing(Vector3(1.2, 0, -0.35), -0.3, CLOTH_WILLIS, false)

## A seated figure built into an existing MeshBuilder (torso over the crate).
func _seated(mb: MeshBuilder, at: Vector3, cloth: Color) -> void:
	mb.box(Vector3(0.38, 0.58, 0.26), at + Vector3(0, 0.62, 0.06), cloth)
	mb.sphere(0.115, 0.23, at + Vector3(0, 1.04, 0.04), SKIN)
	mb.box(Vector3(0.34, 0.16, 0.34), at + Vector3(0, 0.36, -0.08), cloth.darkened(0.2))
	for side: float in [-0.235, 0.235]:
		mb.box(Vector3(0.09, 0.5, 0.12), at + Vector3(side, 0.60, 0.04), cloth.darkened(0.1))

func _standing(at: Vector3, yaw: float, cloth: Color, armed: bool) -> Node3D:
	var node := Figures.standing(cloth, false, armed)
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	return node

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-0.3, 0.05, 2.9)
	_player.rotation.y = 0.0  # facing the lantern
	add_child(_player)

func _process(delta: float) -> void:
	_t += delta
	if _lantern:
		_lantern.light_energy = 2.1 + sin(_t * 9.0) * 0.06 + sin(_t * 3.7 + 0.8) * 0.07
	if not _started and _player and _player.position.z < 2.0:
		_started = true
		_vetting()
	_autoplay_step(delta)

func _vetting() -> void:
	_player.move_enabled = false
	Hud.subtitle("", "(\"Far enough.\" A hand you did not see puts you on the mark.)", 4.0)
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_player, "position", MARK + Vector3(0, 0.05, 0), 1.2)
	await tw.finished
	CaptureHarness.snap("ch2_vetting")

	DialogueManager.start("res://data/dialogue/ch2/vetting_willis.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	await _willis_taken()

	DialogueManager.start("res://data/dialogue/ch2/vetting_travis.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended

	if GameState.get_flag("vetting_failed"):
		await _fail()
	else:
		await _pass()

## Willis is walked out through the ajar door. Then the flat sound.
func _willis_taken() -> void:
	var g: Node3D = _guards[1]
	var tw := create_tween()
	tw.tween_property(g, "position", _willis.position + Vector3(0.7, 0, 0.2), 2.0)
	await tw.finished
	var out := create_tween()
	out.tween_property(_willis, "position", Vector3(1.9, 0, 4.6), 3.2)
	out.parallel().tween_property(g, "position", Vector3(2.6, 0, 4.6), 3.2)
	Hud.subtitle("WILLIS", "Wait — ask me the squadrons again. Ask me anything. Tell them, gunner— tell them!", 5.0)
	await out.finished
	_willis.hide()
	g.hide()
	await get_tree().create_timer(5.0, false).timeout
	AudioManager.play_sfx("rifle_crack")
	CaptureHarness.snap("ch2_willis")
	Hud.subtitle("", "(One shot. Flat, unremarkable, final. The lantern does not flicker.)", 5.0)
	await get_tree().create_timer(4.5, false).timeout
	Hud.subtitle("ÉTIENNE", "You understand now what the questions weigh. Good.", 4.5)
	await get_tree().create_timer(3.5, false).timeout

func _fail() -> void:
	Hud.subtitle("", "(The two shapes leave the dark at the walls and become men.)", 4.0)
	for g in _guards:
		if g.visible:
			var tw := create_tween()
			tw.tween_property(g, "position", _player.position + (g.position - _player.position).normalized() * 0.9, 2.2)
	await get_tree().create_timer(4.0, false).timeout
	AudioManager.stop_ambient(1.0)
	await SceneDirector.fade_out(2.0)
	AudioManager.play_sfx("rifle_crack")
	await get_tree().create_timer(2.0, false).timeout
	GameState.set_flag("ch2_failed_once", true)
	await SceneDirector.game_over("The network could not afford the doubt.", "ch2_vetting")

func _pass() -> void:
	CaptureHarness.snap("ch2_verdict")
	await get_tree().create_timer(2.0, false).timeout
	AudioManager.stop_ambient(3.0)
	await SceneDirector.fade_out(2.5)
	AudioManager.play_sfx("chapter_sting", -6.0)
	await CutscenePlayer.caption("At dawn, Jean Caillet moves west.", 4.0)
	await CutscenePlayer.caption("The paper goes to London by a route that is not him.\nSomewhere, someone opens a file about it.", 5.0)
	await CutscenePlayer.caption("END OF CHAPTER TWO", 4.0)
	GameState.chapter = 3
	GameState.set_flag("ch2_complete")
	GameState.save_game()
	await CutscenePlayer.caption("CHAPTER THREE\n\nTHE LINE", 4.5)
	SceneDirector.goto_beat("ch3_road", 0.1)

## Headless drive: walk to the mark; dialogue autoplay answers correctly.
func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _started or _player == null or not _player.move_enabled:
		return
	_player.position = _player.position.move_toward(MARK, delta * 3.0)
