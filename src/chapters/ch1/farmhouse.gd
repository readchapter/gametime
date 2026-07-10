extends Node3D
## Chapter 1 — the farmhouse, night of the crash. The family has pulled
## Travis inside; he sits to the table, then sleeps. All geometry is
## code-built vertex-color work; the scene is lit by one oil lamp and the
## fireplace against near-darkness (see docs/ART_DIRECTION.md).

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const PLASTER := Color(0.46, 0.42, 0.35)
const WOOD := Color(0.26, 0.18, 0.11)
const WOOD_DARK := Color(0.17, 0.11, 0.07)
const FLOOR_C := Color(0.30, 0.21, 0.13)
const STONE := Color(0.30, 0.28, 0.26)
const BLANKET := Color(0.23, 0.26, 0.30)
const LINEN := Color(0.60, 0.56, 0.48)
const NIGHT_GLASS := Color(0.05, 0.09, 0.17)
const CLOTH_HENRI := Color(0.21, 0.19, 0.16)
const CLOTH_MARG := Color(0.30, 0.23, 0.20)
const CLOTH_LUC := Color(0.22, 0.25, 0.27)
const SKIN := Color(0.50, 0.39, 0.31)

# Room outer size; interior is inset by wall thickness.
const W := 7.6
const D := 5.8
const H := 2.7

var _player: CharacterBody3D
var _seat_marker: Marker3D
var _fire_light: OmniLight3D
var _fire_base_energy := 1.1
var _t := 0.0

func _ready() -> void:
	_build_environment()
	_build_room()
	_build_furniture()
	_build_family()
	_build_lights()
	_build_colliders()
	_build_interactables()
	_spawn_player()
	AudioManager.play_ambient("night_interior")
	_intro()

func _process(delta: float) -> void:
	_t += delta
	if _fire_light:
		_fire_light.light_energy = _fire_base_energy \
			+ sin(_t * 11.0) * 0.05 + sin(_t * 4.7 + 1.3) * 0.06

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

func _build_room() -> void:
	var mb := MeshBuilder.new()
	# Floor and ceiling
	mb.box(Vector3(W, 0.2, D), Vector3(0, -0.1, 0), FLOOR_C)
	mb.box(Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), PLASTER.darkened(0.35))
	# Ceiling beams
	for x in [-2.2, 0.0, 2.2]:
		mb.box(Vector3(0.18, 0.2, D), Vector3(x, H - 0.1, 0), WOOD_DARK)
	# North wall (fire wall is east)
	mb.box(Vector3(W, H, 0.2), Vector3(0, H / 2, -D / 2 + 0.1), PLASTER)
	# South wall with door opening at x ~ 2.2 (0.9 wide)
	mb.box(Vector3(5.55, H, 0.2), Vector3(-1.025, H / 2, D / 2 - 0.1), PLASTER)
	mb.box(Vector3(1.15, H, 0.2), Vector3(3.225, H / 2, D / 2 - 0.1), PLASTER)
	mb.box(Vector3(0.9, 0.6, 0.2), Vector3(2.2, 2.4, D / 2 - 0.1), PLASTER)
	# Closed door filling the opening
	mb.box(Vector3(0.9, 2.1, 0.08), Vector3(2.2, 1.05, D / 2 - 0.06), WOOD_DARK)
	# West wall (window wall) and east wall (fireplace wall)
	mb.box(Vector3(0.2, H, D), Vector3(-W / 2 + 0.1, H / 2, 0), PLASTER)
	mb.box(Vector3(0.2, H, D), Vector3(W / 2 - 0.1, H / 2, 0), PLASTER.darkened(0.12))
	# Window frame on west wall
	mb.box(Vector3(0.1, 1.1, 1.3), Vector3(-W / 2 + 0.22, 1.55, -0.5), WOOD_DARK)
	# Fireplace: stone surround + hearth, opening kept dark
	mb.box(Vector3(0.5, 2.1, 1.8), Vector3(W / 2 - 0.35, 1.05, 0.4), STONE)
	mb.box(Vector3(0.7, 0.15, 2.2), Vector3(W / 2 - 0.45, 0.075, 0.4), STONE.darkened(0.2))
	mb.box(Vector3(0.3, 0.9, 1.0), Vector3(W / 2 - 0.5, 0.55, 0.4), Color(0.03, 0.02, 0.02))
	# Sideboard along the north wall
	mb.box(Vector3(1.8, 0.9, 0.5), Vector3(-2.4, 0.45, -D / 2 + 0.5), WOOD)
	add_child(mb.commit_instance("Room"))

	# Emissive night-blue window glass, slightly proud of the frame
	_emissive_box(Vector3(0.04, 0.9, 1.1), Vector3(-W / 2 + 0.26, 1.55, -0.5), NIGHT_GLASS, 1.6)
	# Embers in the firebox
	_emissive_box(Vector3(0.25, 0.12, 0.7), Vector3(W / 2 - 0.5, 0.12, 0.4), Color(0.9, 0.32, 0.08), 2.2)

## Small glowing surfaces (window glass, embers, lamp flame): separate
## meshes because emission is a material property, not a vertex color.
func _emissive_box(size: Vector3, at: Vector3, color: Color, energy: float) -> void:
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

func _build_furniture() -> void:
	var mb := MeshBuilder.new()
	# Table
	mb.box(Vector3(1.7, 0.08, 0.9), Vector3(0.3, 0.75, -0.5), WOOD)
	for corner in [Vector3(-0.45, 0.36, -0.85), Vector3(1.05, 0.36, -0.85),
			Vector3(-0.45, 0.36, -0.15), Vector3(1.05, 0.36, -0.15)]:
		mb.box(Vector3(0.09, 0.72, 0.09), corner, WOOD_DARK)
	# Bowls and bread on the table
	mb.cylinder(0.10, 0.07, 0.06, Vector3(0.0, 0.82, -0.6), LINEN.darkened(0.3))
	mb.cylinder(0.10, 0.07, 0.06, Vector3(0.65, 0.82, -0.4), LINEN.darkened(0.3))
	mb.box(Vector3(0.35, 0.10, 0.14), Vector3(0.35, 0.84, -0.25), Color(0.52, 0.38, 0.20), 0.4)
	# Family chairs (Travis's chair is a separate Interactable)
	_chair(mb, Vector3(-0.65, 0, -0.5), PI / 2)    # Henri, west end, facing east
	_chair(mb, Vector3(0.3, 0, -1.15), 0.0)        # Marguerite, north side, facing south
	_chair(mb, Vector3(1.25, 0, -0.5), -PI / 2)    # Luc, east end, facing west
	# Bed, northwest corner
	mb.box(Vector3(0.95, 0.30, 2.0), Vector3(-2.9, 0.15, -1.6), WOOD_DARK)
	mb.box(Vector3(0.85, 0.14, 1.9), Vector3(-2.9, 0.36, -1.6), BLANKET)
	mb.box(Vector3(0.6, 0.10, 0.35), Vector3(-2.9, 0.42, -2.35), LINEN)
	add_child(mb.commit_instance("Furniture"))

func _chair(mb: MeshBuilder, at: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	mb.box(Vector3(0.42, 0.06, 0.42), at + Vector3(0, 0.46, 0), WOOD, yaw)
	mb.box(Vector3(0.42, 0.55, 0.06), at + b * Vector3(0, 0.76, 0.21), WOOD, yaw)
	for leg in [Vector3(-0.17, 0.23, -0.17), Vector3(0.17, 0.23, -0.17),
			Vector3(-0.17, 0.23, 0.17), Vector3(0.17, 0.23, 0.17)]:
		mb.box(Vector3(0.05, 0.46, 0.05), at + b * leg, WOOD_DARK)

func _build_family() -> void:
	var mb := MeshBuilder.new()
	_figure(mb, Vector3(-0.65, 0, -0.5), PI / 2, CLOTH_HENRI)
	_figure(mb, Vector3(0.3, 0, -1.15), 0.0, CLOTH_MARG)
	_figure(mb, Vector3(1.25, 0, -0.5), -PI / 2, CLOTH_LUC)
	add_child(mb.commit_instance("Family"))

## A seated figure: abstract, dark-clothed, readable in lamplight.
func _figure(mb: MeshBuilder, at: Vector3, yaw: float, cloth: Color) -> void:
	var b := Basis(Vector3.UP, yaw)
	mb.box(Vector3(0.38, 0.58, 0.26), at + b * Vector3(0, 0.80, 0.02), cloth, yaw)
	mb.sphere(0.115, 0.23, at + b * Vector3(0, 1.22, 0.0), SKIN)
	mb.box(Vector3(0.34, 0.16, 0.30), at + b * Vector3(0, 0.54, -0.14), cloth.darkened(0.2), yaw)
	for side in [-0.235, 0.235]:
		mb.box(Vector3(0.09, 0.5, 0.12), at + b * Vector3(side, 0.78, 0.0), cloth.darkened(0.1), yaw)

func _build_lights() -> void:
	var mb := MeshBuilder.new()
	# Oil lamp on the table
	mb.cylinder(0.055, 0.075, 0.10, Vector3(0.3, 0.84, -0.72), Color(0.35, 0.30, 0.22))
	add_child(mb.commit_instance("LampBase"))
	_emissive_box(Vector3(0.09, 0.13, 0.09), Vector3(0.3, 0.96, -0.72), Color(1.0, 0.75, 0.42), 3.0)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.3, 1.35, -0.72)
	lamp.light_color = Color(1.0, 0.72, 0.45)
	lamp.light_energy = 2.4
	lamp.omni_range = 7.0
	lamp.shadow_enabled = true
	add_child(lamp)

	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(W / 2 - 0.7, 0.5, 0.4)
	_fire_light.light_color = Color(1.0, 0.42, 0.16)
	_fire_light.light_energy = _fire_base_energy
	_fire_light.omni_range = 4.5
	add_child(_fire_light)

	# Faint cold spill from the window
	var moon := OmniLight3D.new()
	moon.position = Vector3(-W / 2 + 0.6, 1.6, -0.5)
	moon.light_color = Color(0.45, 0.55, 0.75)
	moon.light_energy = 0.35
	moon.omni_range = 3.5
	add_child(moon)

func _build_colliders() -> void:
	var body := StaticBody3D.new()
	body.name = "RoomCollision"
	_box_shape(body, Vector3(W, 0.2, D), Vector3(0, -0.1, 0))
	_box_shape(body, Vector3(W, H, 0.2), Vector3(0, H / 2, -D / 2 + 0.1))
	_box_shape(body, Vector3(W, H, 0.2), Vector3(0, H / 2, D / 2 - 0.1))
	_box_shape(body, Vector3(0.2, H, D), Vector3(-W / 2 + 0.1, H / 2, 0))
	_box_shape(body, Vector3(0.7, H, D), Vector3(W / 2 - 0.35, H / 2, 0))
	_box_shape(body, Vector3(1.9, 1.0, 1.1), Vector3(0.3, 0.5, -0.5))   # table
	_box_shape(body, Vector3(1.0, 0.6, 2.1), Vector3(-2.9, 0.3, -1.6))  # bed
	_box_shape(body, Vector3(1.8, 0.9, 0.5), Vector3(-2.4, 0.45, -D / 2 + 0.5))
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
	chair.position = Vector3(0.3, 0, 0.15)
	_box_shape_i(chair, Vector3(0.5, 1.0, 0.5), Vector3(0, 0.5, 0))
	var chair_mb := MeshBuilder.new()
	_chair(chair_mb, Vector3.ZERO, PI)
	chair.add_child(chair_mb.commit_instance("Visual"))
	chair.interacted.connect(_on_sit)
	add_child(chair)

	var bed := Interactable.new()
	bed.name = "Bed"
	bed.prompt = "Go to bed"
	bed.required_flag = "table_scene_done"
	bed.one_shot = true
	bed.position = Vector3(-2.9, 0, -1.6)
	_box_shape_i(bed, Vector3(1.0, 0.7, 2.1), Vector3(0, 0.35, 0))
	bed.interacted.connect(_on_bed)
	add_child(bed)

	_seat_marker = Marker3D.new()
	add_child(_seat_marker)
	_seat_marker.look_at_from_position(Vector3(0.3, 1.25, 0.25), Vector3(0.3, 0.95, -1.0))

func _box_shape_i(body: PhysicsBody3D, size: Vector3, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = at
	body.add_child(cs)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(2.2, 0.05, 1.7)
	_player.rotation.y = 0.67
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
	await DialogueManager.dialogue_ended
	GameState.set_flag("table_scene_done")
	var back := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(cam, "transform",
		Transform3D(Basis.IDENTITY, Vector3(0, 1.65, 0)), 1.1)
	await back.finished
	player.move_enabled = true
	player.look_enabled = true

func _on_bed(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	GameState.set_flag("ch1_complete")
	GameState.save_game()
	AudioManager.stop_ambient(3.0)
	await CutscenePlayer.play("res://data/cutscenes/ch1/farmhouse_end.json", self)
