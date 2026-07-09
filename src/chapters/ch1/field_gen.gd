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
	add_child(_farmhouse(Vector3(-40, 0, 30)))

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
	mi.material_override = _vertex_color_material()
	return mi

func _ground_color(p: Vector3) -> Color:
	var t := (_tint.get_noise_2d(p.x, p.z) + 1.0) * 0.5
	var c := GRASS.lerp(GRASS_DRY, t)
	# Worn dirt in the dips.
	var dip := clampf(-p.y * 0.5, 0.0, 1.0)
	return c.lerp(DIRT, dip * 0.5)

func _vertex_color_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	return mat

func _hedgerow_line(from: Vector3, to: Vector3, spacing: float, seed_v: int) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var dir := to - from
	var count := int(dir.length() / spacing)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tree_mesh()
	mm.instance_count = count
	for i in count:
		var pos := from + dir * (float(i) / count)
		pos.x += rng.randf_range(-2.5, 2.5)
		pos.z += rng.randf_range(-2.5, 2.5)
		pos.y = height_at(pos.x, pos.z)
		var s := rng.randf_range(0.8, 1.5)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(s, s * rng.randf_range(0.9, 1.3), s))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Hedgerow%d" % seed_v
	mmi.multimesh = mm
	return mmi

func _tree_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.14
	trunk.bottom_radius = 0.22
	trunk.height = 1.6
	trunk.radial_segments = 5
	trunk.rings = 1
	_append_part(trunk, Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)), TRUNK, verts, norms, cols, idx)

	var canopy := SphereMesh.new()
	canopy.radius = 1.5
	canopy.height = 2.6
	canopy.radial_segments = 6
	canopy.rings = 3
	_append_part(canopy, Transform3D(Basis.IDENTITY, Vector3(0, 2.5, 0)), CANOPY, verts, norms, cols, idx)

	var canopy2 := SphereMesh.new()
	canopy2.radius = 1.0
	canopy2.height = 1.8
	canopy2.radial_segments = 6
	canopy2.rings = 3
	_append_part(canopy2, Transform3D(Basis.IDENTITY, Vector3(0.7, 3.3, 0.3)), CANOPY_LIT, verts, norms, cols, idx)

	return _commit_arrays(verts, norms, cols, idx)

func _farmhouse(at: Vector3) -> Node3D:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()

	var walls := BoxMesh.new()
	walls.size = Vector3(9, 4, 6)
	_append_part(walls, Transform3D(Basis.IDENTITY, Vector3(0, 2, 0)), PLASTER, verts, norms, cols, idx)

	var roof := PrismMesh.new()
	roof.size = Vector3(9.6, 2.6, 6.6)
	_append_part(roof, Transform3D(Basis.IDENTITY, Vector3(0, 5.3, 0)), ROOF, verts, norms, cols, idx)

	var barn := BoxMesh.new()
	barn.size = Vector3(6, 3.4, 10)
	_append_part(barn, Transform3D(Basis(Vector3.UP, 0.35), Vector3(11, 1.7, 4)), PLASTER.darkened(0.15), verts, norms, cols, idx)

	var barn_roof := PrismMesh.new()
	barn_roof.size = Vector3(6.6, 2.2, 10.6)
	_append_part(barn_roof, Transform3D(Basis(Vector3.UP, 0.35), Vector3(11, 4.5, 4)), ROOF.darkened(0.1), verts, norms, cols, idx)

	var mi := MeshInstance3D.new()
	mi.name = "Farmhouse"
	mi.mesh = _commit_arrays(verts, norms, cols, idx)
	mi.material_override = _vertex_color_material()
	mi.position = Vector3(at.x, height_at(at.x, at.z), at.z)
	return mi

func _append_part(prim: PrimitiveMesh, xform: Transform3D, color: Color,
		verts: PackedVector3Array, norms: PackedVector3Array,
		cols: PackedColorArray, idx: PackedInt32Array) -> void:
	var arr := prim.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var base := verts.size()
	for p in v:
		verts.append(xform * p)
	for nn in nrm:
		norms.append((xform.basis * nn).normalized())
	for _k in v.size():
		cols.append(color)
	for k in ix:
		idx.append(base + k)

func _commit_arrays(verts: PackedVector3Array, norms: PackedVector3Array,
		cols: PackedColorArray, idx: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _vertex_color_material())
	return mesh
