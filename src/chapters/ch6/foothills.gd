extends Node3D
## Chapter 6 — foothills. STUB (built in a later CH6 milestone).

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE FOOTHILLS —", 3.0)
	SceneDirector.goto_beat("ch6_crossing", 1.0)
