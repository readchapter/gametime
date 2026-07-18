class_name Figures
extends RefCounted
## The one place box-people are built. Every scene that needs a figure calls
## through here (via the ModelLib "villager_standing"/"villager_seated" slots
## where a real model may later land), so a future rigged-human drop-in
## replaces everyone at once instead of five copy-pasted builders.

const SKIN := Color(0.48, 0.38, 0.30)

## A standing figure: legs, torso, arms, head, optional hat brim (Voss) or
## slung long gun (sentries).
static func standing(cloth: Color, hat := false, armed := false) -> Node3D:
	var mb := MeshBuilder.new()
	for side: float in [-0.10, 0.10]:
		mb.box(Vector3(0.13, 0.78, 0.15), Vector3(side, 0.39, 0.0), cloth.darkened(0.25))
	mb.box(Vector3(0.40, 0.62, 0.24), Vector3(0, 1.09, 0.0), cloth)
	for side: float in [-0.245, 0.245]:
		mb.box(Vector3(0.09, 0.55, 0.12), Vector3(side, 1.10, 0.0), cloth.darkened(0.1))
	mb.sphere(0.115, 0.23, Vector3(0, 1.55, 0.0), SKIN)
	if hat:
		mb.box(Vector3(0.30, 0.05, 0.30), Vector3(0, 1.64, 0), cloth.darkened(0.2))
		mb.box(Vector3(0.22, 0.14, 0.22), Vector3(0, 1.72, 0), cloth.darkened(0.2))
	if armed:
		mb.box(Vector3(0.06, 1.15, 0.06), Vector3(0.30, 1.05, -0.05), Color(0.10, 0.08, 0.06), 0.15)
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
	mb.box(Vector3(0.38, 0.58, 0.26), at + b * Vector3(0, 0.80, 0.02), cloth, yaw)
	mb.sphere(0.115, 0.23, at + b * Vector3(0, 1.22, 0.0), SKIN)
	mb.box(Vector3(0.34, 0.16, 0.30), at + b * Vector3(0, 0.54, -0.14), cloth.darkened(0.2), yaw)
	for side: float in [-0.235, 0.235]:
		mb.box(Vector3(0.09, 0.5, 0.12), at + b * Vector3(side, 0.78, 0.0), cloth.darkened(0.1), yaw)
