extends Node3D
## Procedurally builds the Chapter 1 landing field: rolling vertex-colored
## terrain, hedgerow tree lines, and a distant farmhouse cluster. All
## geometry is generated (no imported models, no textures) and deterministic
## (fixed seeds) so captures are reproducible.

const SIZE := 260.0
const STEP := 3.0

const GRASS := Color(0.20, 0.30, 0.15)
const GRASS_DRY := Color(0.36, 0.36, 0.19)
const DIRT := Color(0.33, 0.26, 0.19)
const TRUNK := Color(0.16, 0.12, 0.09)
const CANOPY := Color(0.13, 0.18, 0.10)
const CANOPY_LIT := Color(0.20, 0.24, 0.12)
const PLASTER := Color(0.52, 0.47, 0.40)
const ROOF := Color(0.25, 0.17, 0.13)
# Cohesion tints for the CC0 Kenney models so they sit in the dusk palette.
const TREE_TINT := Color(0.54, 0.60, 0.47)
const CROP_TINT := Color(0.70, 0.64, 0.42)
const TREE_KINDS := ["tree_default", "tree_oak", "tree_detailed", "tree_fat", "tree_pineRoundA"]

var _height := FastNoiseLite.new()
var _tint := FastNoiseLite.new()

func _ready() -> void:
	_height.seed = 7
	_height.frequency = 0.010
	_height.fractal_octaves = 3
	_tint.seed = 21
	_tint.frequency = 0.045
	add_child(_terrain())
	add_child(_hedgerow_line(Vector3(-120, 0, -45), Vector3(120, 0, -45), 7.0, 101))
	add_child(_hedgerow_line(Vector3(-95, 0, -45), Vector3(-95, 0, 110), 8.0, 102))
	add_child(_hedgerow_line(Vector3(-10, 0, -30), Vector3(-90, 0, 60), 8.0, 103))
	add_child(_crop_field(Vector3(35, 0, 55), 8, 7, 2.4, 201, "crops_wheatStageB", CROP_TINT, 2.0))
	add_child(_crop_field(Vector3(-55, 0, -70), 7, 6, 2.6, 202, "crops_cornStageC", Color(0.5, 0.56, 0.4), 2.2))
	add_child(_farmhouse(Vector3(-40, 0, 30)))
	add_child(_road())
	add_child(_village())

func height_at(x: float, z: float) -> float:
	return _height.get_noise_2d(x, z) * 2.4

func _terrain() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(SIZE / STEP)
	var half := SIZE / 2.0
	for i in n:
		for j in n:
			var x0 := -half + i * STEP
			var z0 := -half + j * STEP
			var x1 := x0 + STEP
			var z1 := z0 + STEP
			var p00 := Vector3(x0, height_at(x0, z0), z0)
			var p10 := Vector3(x1, height_at(x1, z0), z0)
			var p01 := Vector3(x0, height_at(x0, z1), z1)
			var p11 := Vector3(x1, height_at(x1, z1), z1)
			for p in [p00, p10, p11, p00, p11, p01]:
				st.set_color(_ground_color(p))
				st.add_vertex(p)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = st.commit()
	mi.material_override = MeshBuilder.vertex_color_material()
	return mi

func _ground_color(p: Vector3) -> Color:
	var t := (_tint.get_noise_2d(p.x, p.z) + 1.0) * 0.5
	var c := GRASS.lerp(GRASS_DRY, t)
	# Worn dirt in the dips.
	var dip := clampf(-p.y * 0.5, 0.0, 1.0)
	return c.lerp(DIRT, dip * 0.5)

## Hedgerow of tone-tinted CC0 low-poly trees, jittered along the line.
## Falls back to a procedural tree if a model is missing.
func _hedgerow_line(from: Vector3, to: Vector3, spacing: float, seed_v: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Hedgerow%d" % seed_v
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var dir := to - from
	var count := int(dir.length() / spacing)
	for i in count:
		var pos := from + dir * (float(i) / count)
		pos.x += rng.randf_range(-2.2, 2.2)
		pos.z += rng.randf_range(-2.2, 2.2)
		pos.y = height_at(pos.x, pos.z)
		var kind: String = TREE_KINDS[rng.randi() % TREE_KINDS.size()]
		var tree := Kit.model(kind, TREE_TINT, rng.randf_range(2.6, 4.0))
		if tree == null:
			tree = _proc_tree()
		tree.position = pos
		tree.rotation.y = rng.randf_range(0.0, TAU)
		root.add_child(tree)
	return root

## Field of tone-tinted crop clumps in a jittered grid.
func _crop_field(center: Vector3, cols: int, rows: int, spacing: float,
		seed_v: int, crop_name: String, tint: Color, scale: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Crop_%d" % seed_v
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for r in rows:
		for c in cols:
			var pos := center + Vector3(
				(c - cols / 2.0) * spacing + rng.randf_range(-0.6, 0.6), 0,
				(r - rows / 2.0) * spacing + rng.randf_range(-0.6, 0.6))
			pos.y = height_at(pos.x, pos.z)
			var clump := Kit.model(crop_name, tint, scale * rng.randf_range(0.85, 1.15))
			if clump == null:
				continue
			clump.position = pos
			clump.rotation.y = rng.randf_range(0.0, TAU)
			root.add_child(clump)
	return root

func _proc_tree() -> Node3D:
	var mb := MeshBuilder.new()
	mb.cylinder(0.14, 0.22, 1.6, Vector3(0, 0.8, 0), TRUNK, 5)
	mb.sphere(1.5, 2.6, Vector3(0, 2.5, 0), CANOPY)
	mb.sphere(1.0, 1.8, Vector3(0.7, 3.3, 0.3), CANOPY_LIT)
	return mb.commit_instance("ProcTree")

## The road east of the field — the danger the descent can drift toward.
## Built as short segments following the terrain.
func _road() -> MeshInstance3D:
	var mb := MeshBuilder.new()
	var z := -SIZE / 2.0
	while z < SIZE / 2.0:
		mb.box(Vector3(9, 0.18, 6.8), Vector3(80, height_at(80, z), z),
			Color(0.24, 0.22, 0.20))
		z += 6.0
	return mb.commit_instance("Road")

## Hamlet past the road; warm window lights read at dusk as a warning beacon.
func _village() -> Node3D:
	var root := Node3D.new()
	root.name = "Village"
	var mb := MeshBuilder.new()
	for spec in [[Vector3(88, 0, 40), 0.2], [Vector3(97, 0, 53), -0.3],
			[Vector3(91, 0, 66), 0.5], [Vector3(104, 0, 47), 0.0]]:
		var at: Vector3 = spec[0]
		at.y = height_at(at.x, at.z)
		var yaw: float = spec[1]
		mb.box(Vector3(5.5, 3.0, 4.2), at + Vector3(0, 1.5, 0), PLASTER.darkened(0.25), yaw)
		mb.prism(Vector3(6.0, 1.8, 4.7), at + Vector3(0, 3.9, 0), ROOF, yaw)
		var win := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(0.08, 0.55, 0.5)
		win.mesh = wb
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.75, 0.40)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.75, 0.40)
		mat.emission_energy_multiplier = 2.0
		win.material_override = mat
		win.position = at + Vector3(-2.8, 1.4, 0)
		root.add_child(win)
	root.add_child(mb.commit_instance("Houses"))
	return root

func _farmhouse(at: Vector3) -> Node3D:
	var mb := MeshBuilder.new()
	mb.box(Vector3(9, 4, 6), Vector3(0, 2, 0), PLASTER)
	mb.prism(Vector3(9.6, 2.6, 6.6), Vector3(0, 5.3, 0), ROOF)
	mb.box(Vector3(6, 3.4, 10), Vector3(11, 1.7, 4), PLASTER.darkened(0.15), 0.35)
	mb.prism(Vector3(6.6, 2.2, 10.6), Vector3(11, 4.5, 4), ROOF.darkened(0.1), 0.35)
	var mi := mb.commit_instance("Farmhouse")
	mi.position = Vector3(at.x, height_at(at.x, at.z), at.z)
	return mi
