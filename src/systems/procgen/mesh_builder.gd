class_name MeshBuilder
extends RefCounted
## Accumulates vertex-colored geometry from primitive meshes into a single
## ArrayMesh. The whole art pipeline is textureless: color lives on vertices,
## lighting/fog does the rest (see docs/ART_DIRECTION.md).

var _verts := PackedVector3Array()
var _norms := PackedVector3Array()
var _cols := PackedColorArray()
var _idx := PackedInt32Array()

static func vertex_color_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	return mat

func add(prim: PrimitiveMesh, xform: Transform3D, color: Color) -> void:
	var arr := prim.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var base := _verts.size()
	for p in v:
		_verts.append(xform * p)
	for nn in nrm:
		_norms.append((xform.basis * nn).normalized())
	for _k in v.size():
		_cols.append(color)
	for k in ix:
		_idx.append(base + k)

func box(size: Vector3, at: Vector3, color: Color, yaw := 0.0) -> void:
	var b := BoxMesh.new()
	b.size = size
	add(b, Transform3D(Basis(Vector3.UP, yaw), at), color)

func cylinder(top_r: float, bottom_r: float, height: float, at: Vector3, color: Color, segments := 8) -> void:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = height
	c.radial_segments = segments
	c.rings = 1
	add(c, Transform3D(Basis.IDENTITY, at), color)

func sphere(radius: float, height: float, at: Vector3, color: Color, segments := 6) -> void:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = height
	s.radial_segments = segments
	s.rings = 3
	add(s, Transform3D(Basis.IDENTITY, at), color)

func prism(size: Vector3, at: Vector3, color: Color, yaw := 0.0) -> void:
	var p := PrismMesh.new()
	p.size = size
	add(p, Transform3D(Basis(Vector3.UP, yaw), at), color)

func commit() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = _norms
	arrays[Mesh.ARRAY_COLOR] = _cols
	arrays[Mesh.ARRAY_INDEX] = _idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, vertex_color_material())
	return mesh

func commit_instance(instance_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = instance_name
	mi.mesh = commit()
	return mi
