class_name CityGen
extends RefCounted
## Procedural blackout-Paris street canyon: cobbled roadway, two rows of
## tall Haussmann-ish facades with dark window grids and the rare warm
## blackout leak, doorway alcoves, chimney lines along the parapets.
## Deterministic per seed. The Ch4 rooftop scene reuses the same generator
## and walks the parapet line it builds.

const FACADE_X := 7.0        # canyon half-width
const STORY_H := 2.9

const COBBLE := Color(0.145, 0.145, 0.155)
const KERB := Color(0.19, 0.19, 0.20)
const ROOF_ZINC := Color(0.16, 0.17, 0.19)

## Builds a straight street along -Z from z=z_from to z=z_to. Returns a
## dict: "door17" (Vector3 of the deep alcove near the far end), "arch"
## (Vector3 of the side-arch gap the patrol crosses from), and
## "parapets" (Array[float] west-row parapet heights by segment, for M4).
static func build_street(parent: Node3D, seed_v: int, z_from := 10.0, z_to := -140.0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var mb := MeshBuilder.new()
	var length := absf(z_to - z_from)
	var mid_z := (z_from + z_to) / 2.0

	# Roadway + kerbs
	mb.box(Vector3(FACADE_X * 2.0 - 1.6, 0.2, length + 8.0), Vector3(0, -0.1, mid_z), COBBLE)
	for side: float in [-1.0, 1.0]:
		mb.box(Vector3(1.3, 0.34, length + 8.0), Vector3(side * (FACADE_X - 0.85), 0.03, mid_z), KERB)

	var out := {"door17": Vector3.ZERO, "arch": Vector3.ZERO, "parapets": []}
	var arch_done := false
	for side: float in [-1.0, 1.0]:
		var z := z_from
		while z > z_to:
			var w := rng.randf_range(9.0, 14.0)
			var stories := rng.randi_range(4, 7)
			var h := stories * STORY_H
			var bz := z - w / 2.0
			var tint := Color(0.26, 0.24, 0.22).lightened(rng.randf_range(-0.05, 0.07))
			# The patrol arch: one gap in the west row near mid-street
			if side < 0.0 and not arch_done and z < mid_z and z - w > z_to + 30.0:
				arch_done = true
				out["arch"] = Vector3(-FACADE_X, 0, bz)
				# Arch frame around the gap
				mb.box(Vector3(1.2, 5.0, 1.6), Vector3(-FACADE_X - 0.4, 2.5, z + 0.3), tint.darkened(0.1))
				mb.box(Vector3(1.2, 5.0, 1.6), Vector3(-FACADE_X - 0.4, 2.5, z - w - 0.3), tint.darkened(0.1))
				mb.box(Vector3(1.2, 1.4, w + 2.2), Vector3(-FACADE_X - 0.4, 5.6, bz), tint.darkened(0.15))
				z -= w + 0.4
				continue
			# Facade slab
			mb.box(Vector3(1.4, h, w), Vector3(side * (FACADE_X + 0.7), h / 2.0, bz), tint, 0.0)
			# Parapet + chimneys
			mb.box(Vector3(1.8, 0.5, w), Vector3(side * (FACADE_X + 0.7), h + 0.25, bz), ROOF_ZINC)
			if side < 0.0:
				out["parapets"].append(h)
			for c in rng.randi_range(1, 3):
				mb.box(Vector3(0.6, rng.randf_range(0.8, 1.6), 0.6),
					Vector3(side * (FACADE_X + 0.7 + rng.randf_range(-0.3, 0.3)),
						h + 0.9, bz + rng.randf_range(-w * 0.35, w * 0.35)),
					tint.darkened(0.25))
			# Window grid: dark panes, the rare blackout leak
			for s in range(1, stories):
				var wy := s * STORY_H - 0.9
				var cols := int(w / 2.2)
				for k in cols:
					var wz := z - 1.4 - k * 2.2
					if wz < z - w + 0.8:
						break
					if rng.randf() < 0.055:
						# a warm sliver where a curtain fails
						var leak := MeshInstance3D.new()
						var lb := BoxMesh.new()
						lb.size = Vector3(0.10, 0.9, 0.22)
						leak.mesh = lb
						var lmat := StandardMaterial3D.new()
						lmat.albedo_color = Color(0.9, 0.65, 0.3)
						lmat.emission_enabled = true
						lmat.emission = Color(0.9, 0.65, 0.3)
						lmat.emission_energy_multiplier = 1.1
						leak.material_override = lmat
						leak.position = Vector3(side * FACADE_X, wy, wz)
						parent.add_child(leak)
					else:
						mb.box(Vector3(0.16, 1.5, 1.1), Vector3(side * FACADE_X, wy, wz),
							Color(0.035, 0.038, 0.05), 0.0)
			# Street-level doorway alcove
			var dz := bz + rng.randf_range(-w * 0.2, w * 0.2)
			mb.box(Vector3(0.5, 2.4, 1.3), Vector3(side * (FACADE_X - 0.05), 1.2, dz),
				Color(0.05, 0.045, 0.04))
			z -= w + rng.randf_range(0.3, 1.0)

	# Door 17: a deeper alcove on the east row near the far end, the one
	# door in the city that matters tonight.
	var d17 := Vector3(FACADE_X - 0.2, 0, z_to + 18.0)
	mb.box(Vector3(1.0, 2.6, 1.8), d17 + Vector3(0.25, 1.3, 0), Color(0.06, 0.05, 0.045))
	mb.box(Vector3(0.14, 2.5, 1.5), d17 + Vector3(0.55, 1.25, 0), Color(0.10, 0.08, 0.06))
	out["door17"] = d17
	# The one legal light: a blue-hooded doorway lamp over 17, dim as law.
	var hood := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.18, 0.10, 0.26)
	hood.mesh = hb
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.30, 0.42, 0.80)
	hmat.emission_enabled = true
	hmat.emission = Color(0.30, 0.42, 0.80)
	hmat.emission_energy_multiplier = 1.8
	hood.material_override = hmat
	hood.position = d17 + Vector3(0.15, 2.75, 0)
	parent.add_child(hood)
	var dl := OmniLight3D.new()
	dl.position = d17 + Vector3(-0.2, 2.4, 0)
	dl.light_color = Color(0.35, 0.45, 0.85)
	dl.light_energy = 1.1
	dl.omni_range = 4.5
	parent.add_child(dl)

	# Street ends: dark cross-facades so the canyon doesn't open to void
	for zz: float in [z_from + 4.0, z_to - 4.0]:
		mb.box(Vector3(FACADE_X * 2.0 + 6.0, 17.0, 1.5), Vector3(0, 8.5, zz), Color(0.05, 0.05, 0.06))

	parent.add_child(mb.commit_instance("Street"))

	# Floor collision (see the checkpoint gotcha)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(FACADE_X * 2.0 + 4.0, 0.2, length + 10.0)
	cs.shape = shape
	cs.position = Vector3(0, -0.1, mid_z)
	body.add_child(cs)
	parent.add_child(body)
	return out
