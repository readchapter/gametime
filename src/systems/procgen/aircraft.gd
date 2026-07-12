class_name Aircraft
extends RefCounted
## Hand-built low-poly aircraft (vertex-colored, no external model). The B-17
## aims for a readable silhouette: rounded tapered fuselage, glazed nose and
## cockpit, dihedral wings, four engine nacelles with propellers, the tall
## B-17 fin, and dorsal/ball/tail turrets. Nose points -Z, wings span X.

const OLIVE := Color(0.22, 0.23, 0.19)
const OLIVE_DARK := Color(0.16, 0.17, 0.14)
const UNDER := Color(0.30, 0.31, 0.30)
const GLASS := Color(0.28, 0.34, 0.40)
const METAL := Color(0.12, 0.12, 0.13)
const PROP := Color(0.08, 0.08, 0.08)

static func b17(name := "B17") -> MeshInstance3D:
	var mb := MeshBuilder.new()
	var lie := Basis(Vector3.RIGHT, PI / 2)  # cylinder Y-axis -> +Z

	# --- fuselage: rounded body + tapered nose and tail ---
	_cyl(mb, lie, 1.3, 1.3, 15.0, Vector3(0, 0, 1.0), OLIVE, 12)      # main body
	_cyl(mb, lie, 1.3, 0.55, 4.5, Vector3(0, -0.05, -7.7), OLIVE, 12) # nose taper
	mb.sphere(0.72, 1.2, Vector3(0, -0.1, -10.0), GLASS, 10)          # glazed nose
	_cyl(mb, lie, 1.25, 0.35, 7.0, Vector3(0, 0.1, 10.0), OLIVE, 12)  # tail taper
	# belly panel (lighter underside)
	_cyl(mb, lie, 1.15, 1.15, 14.5, Vector3(0, -0.2, 1.0), UNDER, 12)

	# --- cockpit greenhouse ---
	mb.box(Vector3(1.5, 0.9, 3.0), Vector3(0, 1.0, -5.2), OLIVE_DARK)
	mb.box(Vector3(1.3, 0.7, 2.4), Vector3(0, 1.25, -5.4), GLASS)
	# windscreen slope
	var wedge := PrismMesh.new()
	wedge.size = Vector3(1.3, 0.7, 1.2)
	mb.add(wedge, Transform3D(Basis(Vector3.RIGHT, -PI / 2), Vector3(0, 1.25, -6.6)), GLASS)

	# --- wings (dihedral, two-step taper per side) ---
	for s: float in [-1.0, 1.0]:
		var roll := 0.05 * s  # tips up
		_wing_box(mb, Vector3(10.0, 0.32, 4.4), Vector3(s * 5.2, -0.15, -2.4), roll, OLIVE)
		_wing_box(mb, Vector3(6.0, 0.28, 2.7), Vector3(s * 12.5, 0.25, -2.2), roll, OLIVE)
		# rounded wingtip
		mb.sphere(0.5, 0.4, Vector3(s * 15.3, 0.5, -2.2), OLIVE, 6)

	# --- engines: nacelle + cowl + prop, under each wing ---
	for ex in [-8.8, -4.6, 4.6, 8.8]:
		var y := -0.55 + absf(ex) * 0.03  # follow wing dihedral
		_cyl(mb, lie, 0.5, 0.55, 3.4, Vector3(ex, y, -4.2), METAL, 8)      # nacelle
		_cyl(mb, lie, 0.62, 0.5, 0.6, Vector3(ex, y, -5.9), OLIVE_DARK, 8) # cowl ring
		mb.sphere(0.22, 0.36, Vector3(ex, y, -6.1), METAL, 6)             # hub
		_prop(mb, Vector3(ex, y, -6.25))

	# --- tail: fin + dorsal fillet + horizontal stabilizers ---
	mb.box(Vector3(0.22, 3.2, 3.0), Vector3(0, 2.1, 11.6), OLIVE)
	var fin_cap := PrismMesh.new()
	fin_cap.size = Vector3(0.22, 1.1, 3.0)
	mb.add(fin_cap, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 3.7, 11.0)), OLIVE)
	var dorsal := PrismMesh.new()
	dorsal.size = Vector3(0.2, 1.6, 5.0)
	mb.add(dorsal, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 0.9, 8.6)), OLIVE)
	for s: float in [-1.0, 1.0]:
		_wing_box(mb, Vector3(5.0, 0.24, 2.4), Vector3(s * 2.7, 0.7, 11.4), 0.04 * s, OLIVE)
		mb.sphere(0.35, 0.3, Vector3(s * 5.1, 0.85, 11.4), OLIVE, 6)

	# --- turrets and gun positions ---
	mb.sphere(0.52, 0.7, Vector3(0, 1.35, -2.6), GLASS, 8)   # top turret
	mb.sphere(0.55, 0.8, Vector3(0, -1.2, 1.6), METAL, 8)    # ball turret
	mb.box(Vector3(1.0, 0.7, 1.0), Vector3(0, 0.15, 13.3), GLASS)  # tail gunner
	for s: float in [-1.0, 1.0]:
		mb.box(Vector3(0.1, 0.5, 0.7), Vector3(s * 1.28, 0.15, 4.0), GLASS)  # waist windows

	return mb.commit_instance(name)

## Fw 190-style single-engine fighter: blunt radial cowl, bubble canopy,
## tapered wings, rounded fin. Same visual language as the B-17.
static func fw190(name := "Fw190") -> MeshInstance3D:
	var mb := MeshBuilder.new()
	var lie := Basis(Vector3.RIGHT, PI / 2)
	var paint := Color(0.16, 0.17, 0.15)
	var paint_dark := Color(0.12, 0.13, 0.12)

	# Fuselage: cowl -> body -> tail taper
	_cyl(mb, lie, 0.62, 0.62, 1.4, Vector3(0, 0, -3.2), paint_dark, 10)  # radial cowl
	mb.sphere(0.3, 0.5, Vector3(0, 0, -3.95), METAL, 8)                  # spinner
	_prop(mb, Vector3(0, 0, -4.1))
	_cyl(mb, lie, 0.62, 0.5, 3.6, Vector3(0, 0, -0.7), paint, 10)        # mid body
	_cyl(mb, lie, 0.5, 0.16, 3.6, Vector3(0, 0.08, 2.9), paint, 10)      # tail taper
	# Canopy
	mb.sphere(0.34, 0.5, Vector3(0, 0.5, -0.9), GLASS, 8)
	mb.box(Vector3(0.5, 0.3, 1.2), Vector3(0, 0.38, -0.5), paint_dark)
	# Wings: tapered, slight dihedral
	for s: float in [-1.0, 1.0]:
		_wing_box(mb, Vector3(3.4, 0.14, 1.7), Vector3(s * 2.0, -0.1, -1.0), 0.06 * s, paint)
		_wing_box(mb, Vector3(1.9, 0.12, 1.15), Vector3(s * 4.3, 0.05, -0.9), 0.06 * s, paint)
		mb.sphere(0.22, 0.16, Vector3(s * 5.25, 0.14, -0.9), paint, 6)
	# Tailplane + rounded fin
	for s: float in [-1.0, 1.0]:
		_wing_box(mb, Vector3(1.6, 0.1, 0.85), Vector3(s * 0.95, 0.12, 4.15), 0.0, paint)
	mb.box(Vector3(0.12, 1.0, 1.0), Vector3(0, 0.62, 4.2), paint)
	mb.sphere(0.3, 0.55, Vector3(0, 1.1, 4.15), paint, 6)
	# Belly intake hint
	mb.box(Vector3(0.4, 0.18, 1.6), Vector3(0, -0.55, -1.2), paint_dark)
	return mb.commit_instance(name)

## Simple 3-blade propeller in the XY plane (spinning read comes from motion).
static func _prop(mb: MeshBuilder, at: Vector3) -> void:
	for i in 3:
		var blade := BoxMesh.new()
		blade.size = Vector3(0.14, 2.0, 0.05)
		var basis := Basis(Vector3.BACK, TAU * i / 3.0)
		mb.add(blade, Transform3D(basis, at), PROP)

static func _cyl(mb: MeshBuilder, lie: Basis, top_r: float, bottom_r: float,
		length: float, at: Vector3, color: Color, seg := 8) -> void:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = length
	c.radial_segments = seg
	c.rings = 1
	mb.add(c, Transform3D(lie, at), color)

## Box rolled about Z for wing dihedral, then placed.
static func _wing_box(mb: MeshBuilder, size: Vector3, at: Vector3, roll: float, color: Color) -> void:
	var b := BoxMesh.new()
	b.size = size
	mb.add(b, Transform3D(Basis(Vector3(0, 0, 1), roll), at), color)
