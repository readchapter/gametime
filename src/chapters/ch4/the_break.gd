extends Node3D
## Chapter 4 — the break. One scene, two endings, branched on the apartment
## choice (ch4_took_fast_route):
##  CAPTURE — the fast route's courtyard, the wrong kind of car, and the
##  Voss interview: quiet, procedural, no fail state. What he knows for
##  certain is what you told Lucien.
##  ESCAPE — boots on the stairs, Béranger's drilled contingency, and a
##  player-walked rooftop traverse over the blackout canyon: the plank,
##  the chimney line, the coal chute, the canal. Her lamp goes out below.
## Both endings are canon. Both end Chapter Four.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const CLOTH_FREEMAN := Color(0.30, 0.28, 0.20)
const CLOTH_BERANGER := Color(0.26, 0.25, 0.27)
const COAT := Color(0.10, 0.10, 0.12)
const STONE := Color(0.26, 0.25, 0.23)
const ZINC := Color(0.25, 0.26, 0.30)

# Escape-side layout (above the CityGen street's east row)
const ROOF_A_Y := 15.1
const ROOF_B_Y := 14.55
const PLANK_X := 12.5
const CHUTE_AT := Vector3(17.0, 0, 16.5)
# Capture-side layout, far from the roofs
const COURT := Vector3(220, 0, 0)
const CELL := Vector3(320, 0, 0)

var _player: CharacterBody3D
var _env: Environment
var _took_fast := false
var _t := 0.0
# escape state
var _esc_stage := 0
var _lamp_leak: MeshInstance3D
var _canal_contact: Node3D
# capture props
var _voss: Node3D
var _freeman: Node3D

func _ready() -> void:
	# --autoplay-fail doubles as the bad-trust switch for direct dev loads.
	_took_fast = bool(GameState.get_flag("ch4_took_fast_route")) \
		or "--autoplay-fail" in OS.get_cmdline_user_args()
	_build_environment()
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	if _took_fast:
		_build_courtyard()
		_build_cell()
		_capture_flow()
	else:
		CityGen.build_street(self, 47)  # the same street, seen from above
		_build_roofscape()
		_escape_flow()
	_player.camera.make_current()

func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.018, 0.022, 0.036) if not _took_fast else Color(0.055, 0.065, 0.095)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.14, 0.15, 0.20)
	_env.ambient_light_energy = 1.2 if not _took_fast else 1.35
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.03, 0.035, 0.05)
	_env.fog_density = 0.005
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-42, 20, 0)
	moon.light_color = Color(0.55, 0.62, 0.80)
	# The roofs live or die by this light; the street scenes hid in the dark.
	moon.light_energy = 0.55 if not _took_fast else 0.5
	# In the walled courtyard the shadows would eat the pre-dawn grey whole.
	moon.shadow_enabled = not _took_fast
	add_child(moon)

# --- CAPTURE PATH -----------------------------------------------------------

func _build_courtyard() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(16, 0.2, 16), COURT + Vector3(0, -0.1, 0), Color(0.15, 0.15, 0.16))
	for spec: Array in [[Vector3(0, 0, -8.5), Vector3(17, 12, 1)], [Vector3(0, 0, 8.5), Vector3(17, 12, 1)],
			[Vector3(-8.5, 0, 0), Vector3(1, 12, 16)]]:
		mb.box(spec[1], COURT + spec[0] + Vector3(0, 6, 0), STONE.darkened(0.15))
	# The archway out — where the car will come from
	mb.box(Vector3(1, 12, 5.5), COURT + Vector3(8.5, 6, -5.2), STONE.darkened(0.15))
	mb.box(Vector3(1, 12, 5.5), COURT + Vector3(8.5, 6, 5.2), STONE.darkened(0.15))
	mb.box(Vector3(1, 7.5, 6), COURT + Vector3(8.5, 8.2, 0), STONE.darkened(0.2))
	# Dark windows into the yard
	for wy: float in [3.0, 5.8, 8.6]:
		for wz: float in [-6.0, -3.0, 0.0, 3.0, 6.0]:
			mb.box(Vector3(0.2, 1.4, 1.0), COURT + Vector3(-8.4, wy, wz), Color(0.03, 0.03, 0.04))
	add_child(mb.commit_instance("Courtyard"))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(16, 0.2, 16)
	cs.shape = shape
	cs.position = COURT + Vector3(0, -0.1, 0)
	body.add_child(cs)
	add_child(body)
	# One hooded lamp over the yard door
	var lamp := OmniLight3D.new()
	lamp.position = COURT + Vector3(-7.5, 3.4, 0)
	lamp.light_color = Color(0.9, 0.7, 0.4)
	lamp.light_energy = 2.4
	lamp.omni_range = 11.0
	add_child(lamp)
	# Pre-dawn grey from the open sky above the well of the yard
	var sky_fill := OmniLight3D.new()
	sky_fill.position = COURT + Vector3(0, 10.0, 0)
	sky_fill.light_color = Color(0.45, 0.50, 0.62)
	sky_fill.light_energy = 2.6
	sky_fill.omni_range = 22.0
	add_child(sky_fill)
	_freeman = Figures.villager(CLOTH_FREEMAN, "Freeman")
	_freeman.position = COURT + Vector3(-2.0, 0, 1.3)
	_freeman.rotation.y = -0.7
	add_child(_freeman)

func _build_cell() -> void:
	var mb := MeshBuilder.new()
	var wall := Color(0.30, 0.30, 0.28)
	mb.box(Vector3(4.2, 0.2, 3.4), CELL + Vector3(0, -0.1, 0), Color(0.20, 0.20, 0.19))
	mb.box(Vector3(4.2, 0.2, 3.4), CELL + Vector3(0, 3.1, 0), wall.darkened(0.3))
	mb.box(Vector3(0.2, 3.0, 3.4), CELL + Vector3(-2.1, 1.5, 0), wall)
	mb.box(Vector3(0.2, 3.0, 3.4), CELL + Vector3(2.1, 1.5, 0), wall)
	mb.box(Vector3(4.2, 3.0, 0.2), CELL + Vector3(0, 1.5, -1.7), wall)
	mb.box(Vector3(4.2, 3.0, 0.2), CELL + Vector3(0, 1.5, 1.7), wall.darkened(0.06))
	# The table between two chairs; the little book on it
	mb.box(Vector3(1.2, 0.06, 0.7), CELL + Vector3(0, 0.76, 0), Color(0.24, 0.17, 0.11))
	for leg_x: float in [-0.5, 0.5]:
		mb.box(Vector3(0.07, 0.76, 0.07), CELL + Vector3(leg_x, 0.38, 0), Color(0.15, 0.10, 0.07))
	mb.box(Vector3(0.24, 0.05, 0.17), CELL + Vector3(0.1, 0.815, 0.05), Color(0.55, 0.48, 0.35), 0.2)
	for cz: float in [-0.75, 0.75]:
		mb.box(Vector3(0.45, 0.5, 0.45), CELL + Vector3(0, 0.25, cz), Color(0.18, 0.13, 0.09))
	add_child(mb.commit_instance("Cell"))
	# The slit window's cold shaft
	var slit := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.9, 0.3, 0.06)
	slit.mesh = sb
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.55, 0.60, 0.70)
	smat.emission_enabled = true
	smat.emission = Color(0.55, 0.60, 0.70)
	smat.emission_energy_multiplier = 1.6
	slit.material_override = smat
	slit.position = CELL + Vector3(0, 2.6, -1.66)
	add_child(slit)
	var shaft := SpotLight3D.new()
	shaft.position = CELL + Vector3(0, 2.55, -1.6)
	shaft.rotation_degrees = Vector3(-52, 180, 0)  # forward is -Z: yaw around, into the room
	shaft.light_color = Color(0.55, 0.62, 0.75)
	shaft.light_energy = 2.2
	shaft.spot_range = 5.0
	shaft.spot_angle = 24.0
	add_child(shaft)
	# The bare bulb over the table — the room's one honest fixture
	var cord := MeshBuilder.new()
	cord.box(Vector3(0.02, 0.7, 0.02), CELL + Vector3(0, 2.75, 0), Color(0.05, 0.05, 0.05))
	add_child(cord.commit_instance("Cord"))
	var bulb := MeshInstance3D.new()
	var bb := SphereMesh.new()
	bb.radius = 0.06
	bb.height = 0.12
	bulb.mesh = bb
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 0.9, 0.7)
	bmat.emission_enabled = true
	bmat.emission = Color(1.0, 0.9, 0.7)
	bmat.emission_energy_multiplier = 3.0
	bulb.material_override = bmat
	bulb.position = CELL + Vector3(0, 2.36, 0)
	add_child(bulb)
	var blight := OmniLight3D.new()
	blight.position = CELL + Vector3(0, 2.2, 0)
	blight.light_color = Color(1.0, 0.85, 0.6)
	blight.light_energy = 1.8
	blight.omni_range = 5.0
	blight.shadow_enabled = true
	add_child(blight)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.2, 0.2, 3.4)
	cs.shape = shape
	cs.position = CELL + Vector3(0, -0.1, 0)
	body.add_child(cs)
	add_child(body)

func _capture_flow() -> void:
	_player.position = COURT + Vector3(-3.2, 0.05, -0.6)
	_player.rotation.y = -PI / 2 + 0.3  # facing the archway
	_player.move_enabled = false
	AudioManager.play_ambient("city_night")
	SceneDirector.fade_in(2.0)
	Hud.subtitle("", "(The courtyard before light. Rue Traversière keeps its promises: it is fast, it is quiet, it is exactly where Lucien said.)", 6.0)
	CaptureHarness.snap("ch4_court")
	await get_tree().create_timer(5.5, false).timeout
	Hud.subtitle("FREEMAN", "There — hear it? Right on time. Spain, Boyd. Oranges. Get the bread out of your— ", 4.5)
	await get_tree().create_timer(4.0, false).timeout
	AudioManager.play_sfx("car_trap", -8.0)
	# The car noses into the arch: headlights, then coats
	var car := Node3D.new()
	add_child(car)
	car.position = COURT + Vector3(14.0, 0, 0)
	for side: float in [-0.6, 0.6]:
		var head := SpotLight3D.new()
		head.position = Vector3(side, 0.9, 0)
		head.rotation_degrees = Vector3(-4, 90, 0)
		head.light_color = Color(0.95, 0.92, 0.8)
		head.light_energy = 4.0
		head.spot_range = 24.0
		head.spot_angle = 20.0
		car.add_child(head)
	var drive := create_tween()
	drive.tween_property(car, "position:x", COURT.x + 7.0, 3.0)
	await get_tree().create_timer(3.2, false).timeout
	Hud.subtitle("", "(The engine is wrong. Big, unhurried, official. Freeman's hand stops on the bread.)", 5.0)
	await get_tree().create_timer(4.5, false).timeout
	for spec: Array in [[Vector3(6.0, 0, -1.4), -1.9], [Vector3(6.2, 0, 1.6), 2.2]]:
		var coat := Figures.standing(COAT, true)
		coat.position = COURT + spec[0]
		coat.rotation.y = spec[1]
		add_child(coat)
	Hud.subtitle("", "(Two men leave the car the way clerks leave a desk — no hurry, no doubt, the paperwork already done.)", 5.5)
	await get_tree().create_timer(5.0, false).timeout
	Hud.subtitle("FREEMAN", "Boyd— Boyd, tell them, we're just— we're WORKERS, we're—", 4.0)
	await get_tree().create_timer(3.5, false).timeout
	await SceneDirector.fade_out(2.0)
	AudioManager.stop_ambient(0.5)
	await CutscenePlayer.caption("The hood smells of other men's mornings.", 4.5)
	# The cell
	_player.position = CELL + Vector3(0, 0.05, 1.1)
	_player.rotation = Vector3.ZERO
	_player.camera.rotation = Vector3.ZERO
	AudioManager.play_sfx("cell_door", -8.0)
	await get_tree().create_timer(1.5, false).timeout
	await SceneDirector.fade_in(1.8)
	Hud.subtitle("", "(A vault with a table. Through the wall, two rooms away: a voice you know, answering louder than it should.)", 6.0)
	await get_tree().create_timer(5.5, false).timeout
	_voss = Figures.standing(COAT, true)
	_voss.position = CELL + Vector3(0, 0, -1.1)
	_voss.rotation.y = PI
	add_child(_voss)
	AudioManager.play_sfx("cell_door", -12.0)
	CaptureHarness.snap("ch4_voss")
	await get_tree().create_timer(1.5, false).timeout
	DialogueManager.start("res://data/dialogue/ch4/voss_interview.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	GameState.set_flag("ch4_captured", true)
	GameState.set_flag("met_voss", true)
	await get_tree().create_timer(2.0, false).timeout
	await SceneDirector.fade_out(2.5)
	AudioManager.play_sfx("chapter_sting", -6.0)
	await CutscenePlayer.caption("The train east leaves before the coffee comes.", 4.5)
	await CutscenePlayer.caption("Somewhere west, a schoolmaster's road is being walked backwards."
		if GameState.get_flag("told_lucien_paper") else
		"He keeps the book. The margins are the only home left him.", 5.0)
	await CutscenePlayer.caption("END OF CHAPTER FOUR", 4.0)
	GameState.chapter = 5
	GameState.set_flag("ch4_complete", true)
	GameState.save_game()
	await CutscenePlayer.caption("CHAPTER FIVE\n\nTHE LONG WAY HOME", 4.5)
	SceneDirector.goto_beat("ch5_train", 0.1)

# --- ESCAPE PATH ------------------------------------------------------------

func _build_roofscape() -> void:
	var mb := MeshBuilder.new()
	# Roof A (the apartment building) and roof B (the Morel roof), east row,
	# a light-well gap between them; the street canyon yawns to the west.
	mb.box(Vector3(11, 0.4, 14), Vector3(13, ROOF_A_Y - 0.2, -3), ZINC)
	mb.box(Vector3(11, 0.4, 13), Vector3(13, ROOF_B_Y - 0.2, 13.5), ZINC.darkened(0.06))
	# Street-side parapets
	for spec: Array in [[Vector3(7.9, ROOF_A_Y + 0.35, -3), Vector3(0.5, 0.7, 14)],
			[Vector3(7.9, ROOF_B_Y + 0.35, 13.5), Vector3(0.5, 0.7, 13)]]:
		mb.box(spec[1], spec[0], ZINC.lightened(0.05))
	# Chimney clusters — the cover Béranger prescribed
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for spec: Array in [[13.5, -6.5, ROOF_A_Y], [11.0, -1.0, ROOF_A_Y], [15.5, 1.5, ROOF_A_Y],
			[12.0, 10.5, ROOF_B_Y], [15.0, 15.0, ROOF_B_Y], [10.5, 17.5, ROOF_B_Y]]:
		var ch := rng.randf_range(1.2, 2.2)
		mb.box(Vector3(rng.randf_range(0.7, 1.3), ch, rng.randf_range(0.7, 1.3)),
			Vector3(spec[0], spec[2] + ch / 2.0, spec[1]), Color(0.22, 0.18, 0.15))
		for p in rng.randi_range(2, 4):
			mb.cylinder(0.14, 0.14, 0.5, Vector3(spec[0] + rng.randf_range(-0.4, 0.4),
				spec[2] + ch + 0.25, spec[1] + rng.randf_range(-0.4, 0.4)), Color(0.30, 0.18, 0.12))
	# The dormer you climb out of
	mb.box(Vector3(1.8, 2.0, 1.4), Vector3(16.5, ROOF_A_Y + 1.0, -8.0), Color(0.20, 0.16, 0.12))
	mb.box(Vector3(1.4, 1.5, 0.1), Vector3(16.5, ROOF_A_Y + 0.85, -7.3), Color(0.04, 0.04, 0.055))
	# The plank across the light well
	mb.box(Vector3(0.55, 0.09, 4.6), Vector3(PLANK_X, ROOF_A_Y + 0.02, 5.6), Color(0.32, 0.24, 0.15))
	# The coal chute: a slanted board off roof B's inner edge, and the yard
	mb.box(Vector3(1.2, 0.15, 7.0), Vector3(CHUTE_AT.x + 1.8, ROOF_B_Y / 2.0, CHUTE_AT.z + 2.0),
		Color(0.25, 0.20, 0.14), 0.0)
	mb.box(Vector3(12, 0.2, 10), Vector3(24, -0.1, 22), Color(0.13, 0.13, 0.14))
	mb.box(Vector3(2.2, 1.8, 0.3), Vector3(25.3, 0.9, 26.6), Color(0.20, 0.15, 0.10), 0.55)  # the gate, ajar as promised
	# The canal: dark water, a barge, one lamp
	var water := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(60, 16)
	water.mesh = wp
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.03, 0.045, 0.06)
	wmat.metallic = 0.6
	wmat.roughness = 0.25
	water.material_override = wmat
	water.position = Vector3(30, -1.6, 38)
	add_child(water)
	mb.box(Vector3(4.5, 1.6, 11), Vector3(27, -0.4, 38), Color(0.10, 0.09, 0.08))
	mb.box(Vector3(2.0, 1.0, 3.5), Vector3(27, 0.9, 35.5), Color(0.14, 0.12, 0.10))
	add_child(mb.commit_instance("Roofscape"))

	# Colliders: roofs, plank, yard, parapet rails and light-well guards
	var body := StaticBody3D.new()
	for spec: Array in [
		[Vector3(11, 0.4, 14), Vector3(13, ROOF_A_Y - 0.2, -3)],
		[Vector3(11, 0.4, 13), Vector3(13, ROOF_B_Y - 0.2, 13.5)],
		[Vector3(0.55, 0.12, 4.6), Vector3(PLANK_X, ROOF_A_Y, 5.6)],
		[Vector3(12, 0.2, 10), Vector3(24, -0.1, 22)],
		# invisible rails: street side, far sides, and the light well except the plank
		[Vector3(0.3, 2.2, 34), Vector3(7.6, ROOF_A_Y + 1.0, 5)],
		[Vector3(0.3, 2.2, 34), Vector3(18.6, ROOF_A_Y + 1.0, 5)],
		[Vector3(11, 2.2, 0.3), Vector3(13, ROOF_A_Y + 1.0, -9.9)],
		[Vector3(3.6, 2.2, 0.3), Vector3(9.9, ROOF_A_Y + 1.0, 4.05)],
		[Vector3(3.6, 2.2, 0.3), Vector3(16.4, ROOF_A_Y + 1.0, 4.05)],
		[Vector3(3.6, 2.2, 0.3), Vector3(9.9, ROOF_B_Y + 1.0, 7.15)],
		[Vector3(3.6, 2.2, 0.3), Vector3(16.4, ROOF_B_Y + 1.0, 7.15)],
		[Vector3(0.4, 2.2, 4.8), Vector3(PLANK_X - 0.78, ROOF_A_Y + 1.0, 5.6)],
		[Vector3(0.4, 2.2, 4.8), Vector3(PLANK_X + 0.78, ROOF_A_Y + 1.0, 5.6)],
		[Vector3(11, 2.2, 0.3), Vector3(13, ROOF_B_Y + 1.0, 19.9)],
	]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		cs.position = spec[1]
		body.add_child(cs)
	add_child(body)

	# Béranger's window: a warm leak below the roof A parapet, street side.
	_lamp_leak = MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(0.12, 0.9, 0.5)
	_lamp_leak.mesh = lb
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.9, 0.65, 0.3)
	lmat.emission_enabled = true
	lmat.emission = Color(0.9, 0.65, 0.3)
	lmat.emission_energy_multiplier = 1.4
	_lamp_leak.material_override = lmat
	_lamp_leak.position = Vector3(7.05, 12.6, -5.0)
	add_child(_lamp_leak)

	# The mooring lamp: one hooded light where the line's water road begins.
	var moor := OmniLight3D.new()
	moor.position = Vector3(26.0, 3.2, 31.5)
	moor.light_color = Color(1.0, 0.75, 0.45)
	moor.light_energy = 1.6
	moor.omni_range = 9.0
	add_child(moor)
	var moor_glow := MeshInstance3D.new()
	var mgb := BoxMesh.new()
	mgb.size = Vector3(0.3, 0.14, 0.3)
	moor_glow.mesh = mgb
	var mgm := StandardMaterial3D.new()
	mgm.albedo_color = Color(1.0, 0.8, 0.5)
	mgm.emission_enabled = true
	mgm.emission = Color(1.0, 0.8, 0.5)
	mgm.emission_energy_multiplier = 2.0
	moor_glow.material_override = mgm
	moor_glow.position = Vector3(26.0, 3.35, 31.5)
	add_child(moor_glow)
	var moor_post := MeshBuilder.new()
	moor_post.box(Vector3(0.14, 3.3, 0.14), Vector3(26.0, 1.65, 31.5), Color(0.10, 0.10, 0.11))
	add_child(moor_post.commit_instance("MooringPost"))
	_canal_contact = Figures.villager(Color(0.18, 0.19, 0.21), "Bargeman")
	_canal_contact.position = Vector3(26.5, 0.02, 30.5)
	_canal_contact.rotation.y = -0.4
	add_child(_canal_contact)

func _escape_flow() -> void:
	_player.position = Vector3(16.5, ROOF_A_Y + 0.05, -6.6)
	_player.rotation.y = PI  # facing back at the dormer
	_player.move_enabled = false
	var beranger := Figures.villager(CLOTH_BERANGER, "Beranger")
	beranger.position = Vector3(16.5, ROOF_A_Y, -7.6)
	beranger.rotation.y = PI
	add_child(beranger)
	AudioManager.play_ambient("city_night")
	AudioManager.play_sfx("boots_stairs", -8.0)
	SceneDirector.fade_in(1.6)
	Hud.subtitle("", "(Zinc under your palms, five floors of night under the zinc. Below, on the stairs: boots, unhurried, climbing.)", 5.5)
	CaptureHarness.snap("ch4_roof")
	await get_tree().create_timer(2.5, false).timeout
	DialogueManager.start("res://data/dialogue/ch4/escape_contingency.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	var back := create_tween()
	back.tween_property(beranger, "position:z", -8.6, 2.0)
	back.tween_callback(beranger.hide)
	Hud.subtitle("", "(She steps back into the dark of her own house, straightening her collar like a woman expecting company.)", 5.0)
	_esc_stage = 1
	_player.move_enabled = true
	await get_tree().create_timer(6.0, false).timeout
	Hud.subtitle("", "(The plank. Chimneys between you and the street. Do not look down.)", 4.5)

func _escape_progress() -> void:
	# Stage advances by position: over the plank → roof B → the chute → yard
	match _esc_stage:
		1:
			if _player.position.z > 4.2:
				_esc_stage = 2
				CaptureHarness.snap("ch4_plank")
				Hud.subtitle("", "(The plank has held every man she fed. It holds one more. Eleven steps, each one a year long.)", 5.0)
		2:
			if _player.position.z > 7.6:
				_esc_stage = 3
				AudioManager.play_sfx("car_trap", -14.0)
				var dim := create_tween()
				dim.tween_property(_lamp_leak, "scale:y", 0.02, 2.5)
				Hud.subtitle("", "(Below, a car door. And in the well of the street, her window lamp goes out — a message, and you understand what it says.)", 6.0)
		3:
			if _player.position.z > 14.5 and _player.position.x > 15.0:
				_esc_stage = 4
				_chute_drop()

func _chute_drop() -> void:
	_player.move_enabled = false
	_player.look_enabled = false
	Hud.subtitle("", "(The coal chute takes you the way it takes coal: fast, black, and without opinion.)", 4.5)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_player, "position", Vector3(20.5, 0.1, 20.5), 1.6)
	await tw.finished
	Hud.damage_flash(0.4)
	_player.look_enabled = true
	_player.move_enabled = true
	_esc_stage = 5
	Hud.subtitle("", "(A yard of coal dust and quiet. The gate is oiled, as promised. Beyond it: water.)", 5.0)

func _canal_beat() -> void:
	_esc_stage = 6
	_player.move_enabled = false
	Hud.subtitle("BARGEMAN", "You are the widow's parcel? Under the tarpaulin, between the onions. If you snore, snore like cargo.", 6.0)
	CaptureHarness.snap("ch4_canal")
	await get_tree().create_timer(6.0, false).timeout
	GameState.set_flag("ch4_escaped", true)
	GameState.set_flag("beranger_taken", true)
	await SceneDirector.fade_out(2.5)
	AudioManager.stop_ambient(0.5)
	AudioManager.play_sfx("chapter_sting", -6.0)
	await CutscenePlayer.caption("The barge smells of onions and rust.\nIt moves at the speed of slow soup.", 5.0)
	await CutscenePlayer.caption("Five floors up, a door is opened for some visitors\nby a woman with eleven years of practice being no one.", 5.5)
	await CutscenePlayer.caption("END OF CHAPTER FOUR", 4.0)
	GameState.chapter = 5
	GameState.set_flag("ch4_complete", true)
	GameState.save_game()
	await CutscenePlayer.caption("CHAPTER FIVE\n\nTHE LONG WAY HOME", 4.5)
	SceneDirector.goto_beat("ch5_barge", 0.1)

func _process(delta: float) -> void:
	_t += delta
	if _took_fast or _player == null:
		return
	if _esc_stage >= 1 and _esc_stage <= 3:
		_escape_progress()
	elif _esc_stage == 5 and _player.position.z > 26.0:
		_canal_beat()
	_autoplay_step(delta)

## Headless drive for the escape traverse: dormer → plank → roof B → chute
## trigger → yard gate → the bargeman.
func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	var target: Vector3
	match _esc_stage:
		1, 2:
			target = Vector3(PLANK_X, _player.position.y, 9.0)
		3:
			target = Vector3(CHUTE_AT.x, _player.position.y, CHUTE_AT.z)
		5:
			target = Vector3(24.0, _player.position.y, 28.0)
		_:
			return
	_player.position = _player.position.move_toward(target, delta * 3.2)
