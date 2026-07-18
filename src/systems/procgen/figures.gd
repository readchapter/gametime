class_name Figures
extends RefCounted
## The one place box-people are built. Every scene that needs a figure calls
## through here (via the ModelLib "villager_standing"/"villager_seated" slots
## where a real model may later land), so a future rigged-human drop-in
## replaces everyone at once instead of five copy-pasted builders.
##
## v2: layered clothing — trousers, boots, jacket over a hip skirt, belt,
## collar, shoulders, arms with hands, hair under the weather. Same overall
## silhouette and height as v1 so no scene framing changes.

const SKIN := Color(0.48, 0.38, 0.30)
const BOOT := Color(0.09, 0.07, 0.05)
const HAIR := Color(0.16, 0.12, 0.08)

## A standing figure: booted legs, jacketed torso, arms and hands, head with
## hair, optional hat brim (Voss/Feldgendarmerie) or slung long gun (sentries).
static func standing(cloth: Color, hat := false, armed := false) -> Node3D:
	var mb := MeshBuilder.new()
	var trouser := cloth.darkened(0.32)
	# Legs with a slight stance, boots turned a touch outward
	for side: float in [-0.10, 0.10]:
		mb.box(Vector3(0.13, 0.62, 0.15), Vector3(side, 0.42, 0.0), trouser)
		mb.box(Vector3(0.14, 0.13, 0.17), Vector3(side, 0.085, 0.005), trouser.darkened(0.15))
		mb.box(Vector3(0.13, 0.09, 0.24), Vector3(side * 1.15, 0.045, 0.045), BOOT, -side * 1.4)
	# Hip skirt of the jacket over the trousers, then the belt line
	mb.box(Vector3(0.38, 0.20, 0.25), Vector3(0, 0.80, 0.0), cloth.darkened(0.12))
	mb.box(Vector3(0.39, 0.05, 0.255), Vector3(0, 0.90, 0.0), cloth.darkened(0.45))
	# Torso: jacket body, a shade of chest panel, collar
	mb.box(Vector3(0.40, 0.50, 0.24), Vector3(0, 1.16, 0.0), cloth)
	mb.box(Vector3(0.26, 0.40, 0.03), Vector3(0, 1.14, 0.125), cloth.lightened(0.06))
	mb.box(Vector3(0.30, 0.07, 0.21), Vector3(0, 1.44, 0.0), cloth.darkened(0.22))
	# Shoulders, arms, hands
	for side: float in [-1.0, 1.0]:
		mb.box(Vector3(0.13, 0.10, 0.17), Vector3(side * 0.245, 1.37, 0.0), cloth.darkened(0.08))
		mb.box(Vector3(0.09, 0.46, 0.12), Vector3(side * 0.255, 1.09, 0.01), cloth.darkened(0.12))
		mb.box(Vector3(0.075, 0.09, 0.09), Vector3(side * 0.255, 0.82, 0.02), SKIN)
	# Head: face sphere, hair cap unless the hat covers it
	mb.sphere(0.115, 0.23, Vector3(0, 1.55, 0.0), SKIN)
	if hat:
		mb.box(Vector3(0.30, 0.05, 0.30), Vector3(0, 1.64, 0), cloth.darkened(0.2))
		mb.box(Vector3(0.22, 0.14, 0.22), Vector3(0, 1.72, 0), cloth.darkened(0.2))
	else:
		mb.box(Vector3(0.21, 0.09, 0.21), Vector3(0, 1.635, -0.01), HAIR)
		mb.box(Vector3(0.21, 0.13, 0.07), Vector3(0, 1.58, -0.085), HAIR)
	if armed:
		mb.box(Vector3(0.06, 1.15, 0.06), Vector3(0.30, 1.05, -0.05), Color(0.10, 0.08, 0.06), 0.15)
		mb.box(Vector3(0.03, 0.55, 0.09), Vector3(0.30, 1.28, -0.05), Color(0.23, 0.16, 0.09), 0.15)
	return mb.commit_instance("Figure")

## The ModelLib-wrapped standing figure most scenes want: a dropped-in
## villager_standing.glb replaces the procedural body everywhere.
static func villager(cloth: Color, fig_name := "Figure") -> Node3D:
	var node := ModelLib.get_model("villager_standing", func() -> Node3D:
		return standing(cloth))
	node.name = fig_name
	return node

## A seated figure added into an existing MeshBuilder (lap-level, for chairs
## and crates already built in that mesh).
static func seated(mb: MeshBuilder, at: Vector3, cloth: Color, yaw := 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	var trouser := cloth.darkened(0.32)
	# Torso with chest panel and collar
	mb.box(Vector3(0.38, 0.58, 0.26), at + b * Vector3(0, 0.80, 0.02), cloth, yaw)
	mb.box(Vector3(0.24, 0.36, 0.03), at + b * Vector3(0, 0.82, 0.16), cloth.lightened(0.06), yaw)
	mb.box(Vector3(0.28, 0.06, 0.22), at + b * Vector3(0, 1.12, 0.02), cloth.darkened(0.22), yaw)
	# Head and hair
	mb.sphere(0.115, 0.23, at + b * Vector3(0, 1.22, 0.0), SKIN)
	mb.box(Vector3(0.20, 0.09, 0.20), at + b * Vector3(0, 1.305, -0.01), HAIR, yaw)
	mb.box(Vector3(0.20, 0.12, 0.06), at + b * Vector3(0, 1.25, -0.09), HAIR, yaw)
	# Lap, shins tucked back, boots
	mb.box(Vector3(0.34, 0.16, 0.30), at + b * Vector3(0, 0.54, -0.14), trouser, yaw)
	for side: float in [-0.09, 0.09]:
		mb.box(Vector3(0.12, 0.34, 0.13), at + b * Vector3(side, 0.24, -0.24), trouser.darkened(0.1), yaw)
		mb.box(Vector3(0.12, 0.08, 0.20), at + b * Vector3(side, 0.04, -0.20), BOOT, yaw)
	# Arms resting toward the lap, hands on knees
	for side: float in [-1.0, 1.0]:
		mb.box(Vector3(0.09, 0.42, 0.12), at + b * Vector3(side * 0.235, 0.80, 0.0), cloth.darkened(0.1), yaw)
		mb.box(Vector3(0.07, 0.09, 0.09), at + b * Vector3(side * 0.22, 0.56, -0.06), SKIN, yaw)
