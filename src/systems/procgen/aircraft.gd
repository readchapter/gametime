class_name Aircraft
extends RefCounted
## Shared low-poly aircraft silhouettes (vertex-colored, textureless).

const OLIVE := Color(0.23, 0.24, 0.20)
const METAL := Color(0.13, 0.14, 0.13)

static func b17(name := "B17") -> MeshInstance3D:
	var mb := MeshBuilder.new()
	var lie := Basis(Vector3.RIGHT, PI / 2)
	var body := CylinderMesh.new()
	body.top_radius = 1.1
	body.bottom_radius = 1.3
	body.height = 20.0
	body.radial_segments = 7
	mb.add(body, Transform3D(lie, Vector3.ZERO), OLIVE)
	var nose := CylinderMesh.new()
	nose.top_radius = 1.3
	nose.bottom_radius = 0.3
	nose.height = 3.0
	nose.radial_segments = 7
	mb.add(nose, Transform3D(lie, Vector3(0, 0, -11.5)), OLIVE.darkened(0.1))
	mb.box(Vector3(31, 0.28, 4.2), Vector3(0, 0, -2.0), OLIVE)
	mb.box(Vector3(10.5, 0.22, 2.6), Vector3(0, 0.4, 8.6), OLIVE)
	mb.box(Vector3(0.18, 3.4, 3.0), Vector3(0, 1.6, 8.9), OLIVE.darkened(0.08))
	for ex in [-8.6, -4.4, 4.4, 8.6]:
		var nac := CylinderMesh.new()
		nac.top_radius = 0.42
		nac.bottom_radius = 0.5
		nac.height = 2.6
		nac.radial_segments = 6
		mb.add(nac, Transform3D(lie, Vector3(ex, -0.35, -2.4)), METAL)
	var mi := mb.commit_instance(name)
	return mi
