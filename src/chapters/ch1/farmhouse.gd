extends Node3D
## Chapter 1 — the farmhouse, night of the crash. The family pulls Travis
## inside; he sits to the table in the main room, then walks through to a
## small bedroom to sleep. Rustic furniture is tone-tinted CC0 (Kit), with
## procedural fallbacks. Lit by an oil lamp and the fire against near-dark.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const PLASTER := Color(0.46, 0.42, 0.35)
const WOOD := Color(0.26, 0.18, 0.11)
const WOOD_DARK := Color(0.17, 0.11, 0.07)
const FLOOR_C := Color(0.30, 0.21, 0.13)
const STONE := Color(0.30, 0.28, 0.26)
const LINEN := Color(0.60, 0.56, 0.48)
const NIGHT_GLASS := Color(0.05, 0.09, 0.17)
const CLOTH_HENRI := Color(0.21, 0.19, 0.16)
const CLOTH_MARG := Color(0.30, 0.23, 0.20)
const CLOTH_LUC := Color(0.22, 0.25, 0.27)
const SKIN := Color(0.50, 0.39, 0.31)
# Cohesion tints for the CC0 furniture (multiply the light-wood atlas down).
const WOOD_TINT := Color(0.44, 0.31, 0.19)
const BED_TINT := Color(0.52, 0.48, 0.42)
const LAMP_TINT := Color(0.62, 0.55, 0.44)

const H := 2.7  # room height
# Table sits at the centre of the main room; everything keys off it.
const TABLE := Vector3(-1.0, 0, 0.0)
# Against the south wall — the doorway corridor (z 0.5..1.5) stays clear so
# walking straight through the gap never runs into the bed (playtest note).
const BED := Vector3(4.0, 0, 2.1)
const DOORWAY := Vector3(1.35, 0, 1.0)  # gap in the dividing wall

var _player: CharacterBody3D
var _seat_marker: Marker3D
var _fire_light: OmniLight3D
var _fire_base_energy := 1.1
var _t := 0.0
# Window glass panes, kept so subclasses can retint for time-of-day shifts.
var _glass: Array[MeshInstance3D] = []

func _ready() -> void:
	_build_environment()
	_build_shell()
	_build_fixtures()
	_build_glow()
	_build_furniture()
	_build_family()
	_build_lights()
	_build_colliders()
	_build_interactables()
	_spawn_player()
	_flow()

## Scene flow after the set is built. Ch2 reuses the set with its own flow.
func _flow() -> void:
	AudioManager.play_ambient("night_interior")
	_intro()

func _process(delta: float) -> void:
	_t += delta
	if _fire_light:
		_fire_light.light_energy = _fire_base_energy \
			+ sin(_t * 11.0) * 0.05 + sin(_t * 4.7 + 1.3) * 0.06
	_autoplay_step(delta)

## Headless verification: walk to the chair and sit, then (after the table
## scene) route through the doorway to the bed and sleep.
func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	if not GameState.get_flag("table_scene_done"):
		var chair := get_node_or_null("TravisChair")
		if chair:
			if _player.position.distance_to(chair.position) > 1.2:
				_player.position = _player.position.move_toward(chair.position, delta * 3.5)
			else:
				chair.interact(_player)
	elif not GameState.get_flag("ch1_complete"):
		# Route via the doorway so the walk reads through the rooms.
		var target := DOORWAY if _player.position.x < 1.3 else BED
		var bed := get_node_or_null("Bed")
		# 1.7m: the bed's collider stops the walker ~1.35m from its centre.
		if _player.position.distance_to(BED) > 1.7:
			_player.position = _player.position.move_toward(target, delta * 3.5)
		elif bed:
			bed.interact(_player)

func _intro() -> void:
	_player.move_enabled = false
	_player.look_enabled = false
	await CutscenePlayer.play("res://data/cutscenes/ch1/farmhouse_intro.json", self)
	_player.move_enabled = true
	_player.look_enabled = true

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.010, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.10, 0.11, 0.14)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

## Shell: floor, ceiling, outer walls, the dividing wall with a doorway.
## Main room x∈[-3.7,1.7]; bedroom x∈[1.9,4.8], joined at the doorway.
func _build_shell() -> void:
	var mb := MeshBuilder.new()
	# Floor + ceiling span both rooms
	mb.box(Vector3(9.0, 0.2, 6.2), Vector3(0.55, -0.1, 0), FLOOR_C)
	mb.box(Vector3(9.0, 0.2, 6.2), Vector3(0.55, H + 0.1, 0), PLASTER.darkened(0.35))
	for x in [-2.4, 0.0, 3.3]:
		mb.box(Vector3(0.18, 0.2, 6.0), Vector3(x, H - 0.1, 0), WOOD_DARK)
	# Main room outer walls
	mb.box(Vector3(0.2, H, 5.8), Vector3(-3.8, H / 2, 0), PLASTER)           # west
	mb.box(Vector3(5.6, H, 0.2), Vector3(-1.0, H / 2, -2.9), PLASTER)        # north
	mb.box(Vector3(2.3, H, 0.2), Vector3(-2.65, H / 2, 2.9), PLASTER)        # south L
	mb.box(Vector3(2.4, H, 0.2), Vector3(0.6, H / 2, 2.9), PLASTER)          # south R
	mb.box(Vector3(0.9, 0.6, 0.2), Vector3(-1.05, 2.4, 2.9), PLASTER)        # front-door lintel
	mb.box(Vector3(0.9, 2.1, 0.08), Vector3(-1.05, 1.05, 2.86), WOOD_DARK)   # front door
	# Dividing wall (x=1.8) with a doorway at z∈[0.5,1.5]
	mb.box(Vector3(0.2, H, 3.4), Vector3(1.8, H / 2, -1.2), PLASTER.darkened(0.05))
	mb.box(Vector3(0.2, H, 1.4), Vector3(1.8, H / 2, 2.2), PLASTER.darkened(0.05))
	mb.box(Vector3(0.2, 0.6, 1.0), Vector3(1.8, 2.4, 1.0), PLASTER.darkened(0.05))  # doorway lintel
	# Bedroom outer walls
	mb.box(Vector3(3.1, H, 0.2), Vector3(3.35, H / 2, -0.5), PLASTER)        # bedroom north
	mb.box(Vector3(0.2, H, 3.4), Vector3(4.9, H / 2, 1.2), PLASTER.darkened(0.1))  # east
	mb.box(Vector3(3.1, H, 0.2), Vector3(3.35, H / 2, 2.9), PLASTER)         # bedroom south
	add_child(mb.commit_instance("Shell"))

## Fixtures: fireplace, windows, sideboard.
func _build_fixtures() -> void:
	var mb := MeshBuilder.new()
	# Fireplace on the main-room west wall
	mb.box(Vector3(0.5, 2.1, 1.8), Vector3(-3.55, 1.05, 0.4), STONE)
	mb.box(Vector3(0.7, 0.15, 2.2), Vector3(-3.45, 0.075, 0.4), STONE.darkened(0.2))
	mb.box(Vector3(0.3, 0.9, 1.0), Vector3(-3.5, 0.55, 0.4), Color(0.03, 0.02, 0.02))
	# Window frame on the main-room north wall + a small bedroom window
	mb.box(Vector3(1.3, 1.1, 0.1), Vector3(-1.0, 1.55, -2.82), WOOD_DARK)
	mb.box(Vector3(0.1, 1.0, 1.0), Vector3(4.82, 1.5, 1.2), WOOD_DARK)
	# Sideboard along the main-room north wall
	mb.box(Vector3(1.6, 0.9, 0.5), Vector3(0.6, 0.45, -2.55), WOOD)
	# Interior shutters flanking the main window
	for side in [-0.85, 0.85]:
		mb.box(Vector3(0.5, 1.15, 0.06), Vector3(-1.0 + side, 1.55, -2.78), WOOD_DARK)
	# Crucifix on the north wall — a French farm kitchen, 1943
	mb.box(Vector3(0.05, 0.42, 0.05), Vector3(1.9, 1.85, -2.77), WOOD_DARK)
	mb.box(Vector3(0.26, 0.05, 0.05), Vector3(1.9, 1.93, -2.77), WOOD_DARK)
	# Rag rug between the table and the fire
	mb.box(Vector3(1.4, 0.03, 0.9), Vector3(-2.5, 0.015, 0.35), Color(0.34, 0.22, 0.18))
	# Firewood stack by the hearth (logs lying along the wall)
	var log_lie := Basis(Vector3.RIGHT, PI / 2)
	for i in 5:
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.07
		log_mesh.bottom_radius = 0.07
		log_mesh.height = 0.55
		log_mesh.radial_segments = 5
		mb.add(log_mesh, Transform3D(log_lie,
			Vector3(-3.35 + (i % 3) * 0.16, 0.08 + (i / 3) * 0.14, 1.65)),
			Color(0.28, 0.20, 0.13))
	add_child(mb.commit_instance("Fixtures"))
	# Pot by the fire and a loaf on the sideboard (kit, tinted)
	# Kenney food-kit models are display-scale; shrink hard to fit the room.
	var pot := Kit.model("pot", Color(0.30, 0.28, 0.26), 0.6)
	if pot:
		pot.position = Vector3(-3.2, 0.02, 0.9)
		add_child(pot)
	var loaf := Kit.model("loaf", Color(0.52, 0.38, 0.22), 0.4)
	if loaf:
		loaf.position = Vector3(0.35, 0.9, -2.55)
		loaf.rotation.y = 0.5
		add_child(loaf)

## Glowing surfaces (window glass, embers) — time-of-day, so Ch2 overrides.
func _build_glow() -> void:
	_glass.append(_emissive_box(Vector3(1.1, 0.9, 0.04), Vector3(-1.0, 1.55, -2.86), NIGHT_GLASS, 1.4))
	_glass.append(_emissive_box(Vector3(0.04, 0.9, 0.9), Vector3(4.9, 1.5, 1.2), NIGHT_GLASS, 1.2))
	_emissive_box(Vector3(0.25, 0.12, 0.7), Vector3(-3.5, 0.12, 0.4), Color(0.9, 0.32, 0.08), 2.2)

## Small glowing surfaces (window glass, embers, lamp flame): separate meshes
## because emission is a material property, not a vertex color.
func _emissive_box(size: Vector3, at: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	return mi

func _place(model_name: String, tint: Color, scale: float, at: Vector3,
		yaw: float, fallback: Callable) -> Node3D:
	var node := Kit.model(model_name, tint, scale)
	if node == null:
		node = fallback.call()
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	return node

func _build_furniture() -> void:
	# Table (rustic, tinted) at the main-room centre.
	_place("tableCloth", WOOD_TINT, 1.5, TABLE, 0.0, _proc_table)
	# Table settings
	var mb := MeshBuilder.new()
	mb.cylinder(0.10, 0.07, 0.06, TABLE + Vector3(-0.35, 0.78, -0.1), LINEN.darkened(0.3))
	mb.cylinder(0.10, 0.07, 0.06, TABLE + Vector3(0.3, 0.78, 0.15), LINEN.darkened(0.3))
	add_child(mb.commit_instance("TableSettings"))
	_place("bread", Color(0.5, 0.36, 0.2), 0.4, TABLE + Vector3(0.0, 0.78, -0.05), 0.4, func(): return _null_node())
	# Family chairs (Travis's is a separate Interactable, built later)
	# Chairs face the table (backrest outward); the seated figures match.
	_place("chair", WOOD_TINT, 1.4, TABLE + Vector3(-0.95, 0, 0.0), -PI / 2, _proc_chair)  # Henri (west)
	_place("chair", WOOD_TINT, 1.4, TABLE + Vector3(0.0, 0, -0.9), PI, _proc_chair)        # Marguerite (north)
	_place("chairRounded", WOOD_TINT, 1.4, TABLE + Vector3(0.95, 0, 0.0), PI / 2, _proc_chair)  # Luc (east)
	# Bed + nightstand in the bedroom
	_place("bedSingle", BED_TINT, 1.9, BED, PI / 2, _proc_bed)
	_place("lampRoundTable", LAMP_TINT, 1.4, Vector3(4.5, 0.0, -0.1), 0.0, func(): return _null_node())
	var ns := MeshBuilder.new()
	ns.box(Vector3(0.5, 0.5, 0.5), Vector3(4.5, 0.25, -0.1), WOOD)
	add_child(ns.commit_instance("Nightstand"))

func _null_node() -> Node3D:
	return Node3D.new()

func _proc_table() -> Node3D:
	var mb := MeshBuilder.new()
	mb.box(Vector3(1.7, 0.08, 0.9), Vector3(0, 0.75, 0), WOOD)
	for corner in [Vector3(-0.75, 0.36, -0.35), Vector3(0.75, 0.36, -0.35),
			Vector3(-0.75, 0.36, 0.35), Vector3(0.75, 0.36, 0.35)]:
		mb.box(Vector3(0.09, 0.72, 0.09), corner, WOOD_DARK)
	return mb.commit_instance("ProcTable")

func _proc_chair() -> Node3D:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0.42, 0.06, 0.42), Vector3(0, 0.46, 0), WOOD)
	mb.box(Vector3(0.42, 0.55, 0.06), Vector3(0, 0.76, 0.21), WOOD)
	for leg in [Vector3(-0.17, 0.23, -0.17), Vector3(0.17, 0.23, -0.17),
			Vector3(-0.17, 0.23, 0.17), Vector3(0.17, 0.23, 0.17)]:
		mb.box(Vector3(0.05, 0.46, 0.05), leg, WOOD_DARK)
	return mb.commit_instance("ProcChair")

func _proc_bed() -> Node3D:
	var mb := MeshBuilder.new()
	mb.box(Vector3(2.0, 0.30, 0.95), Vector3(0, 0.15, 0), WOOD_DARK)
	mb.box(Vector3(1.9, 0.14, 0.85), Vector3(0, 0.36, 0), Color(0.23, 0.26, 0.30))
	mb.box(Vector3(0.35, 0.10, 0.6), Vector3(-0.75, 0.42, 0), LINEN)
	return mb.commit_instance("ProcBed")

func _build_family() -> void:
	# Facing the table: local -Z (face and knees) points at the tabletop.
	var seats := [
		[TABLE + Vector3(-0.95, 0, 0.0), -PI / 2, CLOTH_HENRI],  # Henri (west)
		[TABLE + Vector3(0.0, 0, -0.9), PI, CLOTH_MARG],         # Marguerite (north)
		[TABLE + Vector3(0.95, 0, 0.0), PI / 2, CLOTH_LUC],      # Luc (east)
	]
	for s in seats:
		var cloth: Color = s[2]
		var node := ModelLib.get_model("villager_seated", func() -> Node3D:
			var mb := MeshBuilder.new()
			Figures.seated(mb, Vector3.ZERO, cloth, 0.0)
			return mb.commit_instance("Villager"))
		node.position = s[0]
		node.rotation.y = s[1]
		add_child(node)

func _build_lights() -> void:
	# Oil lamp over the table
	_emissive_box(Vector3(0.09, 0.13, 0.09), TABLE + Vector3(0.0, 0.95, 0.15), Color(1.0, 0.75, 0.42), 3.0)
	var lamp := OmniLight3D.new()
	lamp.position = TABLE + Vector3(0.0, 1.4, 0.15)
	lamp.light_color = Color(1.0, 0.72, 0.45)
	lamp.light_energy = 2.4
	lamp.omni_range = 6.5
	lamp.shadow_enabled = true
	add_child(lamp)

	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(-3.3, 0.5, 0.4)
	_fire_light.light_color = Color(1.0, 0.42, 0.16)
	_fire_light.light_energy = _fire_base_energy
	_fire_light.omni_range = 4.5
	add_child(_fire_light)

	# Faint cold spill from the main window
	var moon := OmniLight3D.new()
	moon.position = Vector3(-1.0, 1.6, -2.6)
	moon.light_color = Color(0.45, 0.55, 0.75)
	moon.light_energy = 0.35
	moon.omni_range = 3.5
	add_child(moon)

	# Small warm lamp in the bedroom (nightstand)
	_emissive_box(Vector3(0.09, 0.12, 0.09), Vector3(4.5, 0.62, -0.1), Color(1.0, 0.74, 0.44), 2.4)
	var blamp := OmniLight3D.new()
	blamp.position = Vector3(4.4, 1.0, 0.2)
	blamp.light_color = Color(1.0, 0.72, 0.46)
	blamp.light_energy = 1.5
	blamp.omni_range = 4.0
	add_child(blamp)

func _build_colliders() -> void:
	var body := StaticBody3D.new()
	body.name = "RoomCollision"
	_box_shape(body, Vector3(9.0, 0.2, 6.2), Vector3(0.55, -0.1, 0))          # floor
	_box_shape(body, Vector3(0.2, H, 5.8), Vector3(-3.8, H / 2, 0))           # west
	_box_shape(body, Vector3(5.6, H, 0.2), Vector3(-1.0, H / 2, -2.9))        # main north
	_box_shape(body, Vector3(9.0, H, 0.2), Vector3(0.55, H / 2, 2.9))         # south (whole)
	_box_shape(body, Vector3(3.1, H, 0.2), Vector3(3.35, H / 2, -0.5))        # bedroom north
	_box_shape(body, Vector3(0.2, H, 3.4), Vector3(4.9, H / 2, 1.2))          # east
	# Dividing wall halves (doorway gap at z∈[0.5,1.5])
	_box_shape(body, Vector3(0.2, H, 3.4), Vector3(1.8, H / 2, -1.2))
	_box_shape(body, Vector3(0.2, H, 1.4), Vector3(1.8, H / 2, 2.2))
	# Furniture blockers
	_box_shape(body, Vector3(1.6, 1.0, 1.0), TABLE + Vector3(0, 0.5, 0))      # table
	_box_shape(body, Vector3(2.0, 0.7, 1.1), BED + Vector3(0, 0.35, 0))       # bed
	_box_shape(body, Vector3(1.6, 0.9, 0.5), Vector3(0.6, 0.45, -2.55))       # sideboard
	add_child(body)

func _box_shape(body: StaticBody3D, size: Vector3, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = at
	body.add_child(cs)

func _build_interactables() -> void:
	# Travis's chair, south side of the table
	var chair := Interactable.new()
	chair.name = "TravisChair"
	chair.prompt = "Sit down"
	chair.blocked_flag = "table_scene_done"
	chair.position = TABLE + Vector3(0.0, 0, 0.9)
	_box_shape_i(chair, Vector3(0.5, 1.0, 0.5), Vector3(0, 0.5, 0))
	var vis := Kit.model("chair", WOOD_TINT, 1.4)
	if vis == null:
		vis = _proc_chair()
	vis.rotation.y = 0.0  # backrest south, seat open toward the table
	chair.add_child(vis)
	chair.interacted.connect(_on_sit)
	add_child(chair)

	var bed := Interactable.new()
	bed.name = "Bed"
	bed.prompt = "Go to bed"
	bed.required_flag = "table_scene_done"
	bed.one_shot = true
	bed.position = BED
	# Tall target matching the blocker footprint: the prompt appears when
	# looking at the bed from anywhere in the room, and the interact body
	# adds no invisible lip beyond the bed itself (playtest note).
	_box_shape_i(bed, Vector3(2.1, 1.5, 1.15), Vector3(0, 0.75, 0))
	bed.interacted.connect(_on_bed)
	add_child(bed)

	# Seated camera: over the table looking at the family (north).
	_seat_marker = Marker3D.new()
	add_child(_seat_marker)
	_seat_marker.look_at_from_position(
		TABLE + Vector3(0.0, 1.25, 0.55), TABLE + Vector3(0.0, 0.95, -0.6), Vector3.UP)

func _box_shape_i(body: PhysicsBody3D, size: Vector3, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = at
	body.add_child(cs)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-1.0, 0.05, 2.2)  # just inside the front door
	_player.rotation.y = 0.0  # facing into the room (-Z), toward the table
	add_child(_player)

func _on_sit(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	var cam: Camera3D = player.camera
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "global_transform", _seat_marker.global_transform, 1.1)
	await tw.finished
	DialogueManager.start("res://data/dialogue/ch1/farm_table.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	GameState.set_flag("table_scene_done")
	var back := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(cam, "transform",
		Transform3D(Basis.IDENTITY, Vector3(0, 1.65, 0)), 1.1)
	await back.finished
	Hud.subtitle("", "(Through there. Sleep, if you can.)", 5.0)
	player.move_enabled = true
	player.look_enabled = true

func _on_bed(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	GameState.set_flag("ch1_complete")
	GameState.chapter = 2
	GameState.save_game()
	AudioManager.stop_ambient(3.0)
	AudioManager.play_sfx("chapter_sting", -6.0)
	await CutscenePlayer.play("res://data/cutscenes/ch1/farmhouse_end.json", self)
	# Straight into Chapter 2: the morning after, same rooms.
	SceneDirector.goto_beat("ch2_morning", 0.1)
