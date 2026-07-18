extends Node3D
## Chapter 4 — the apartment. STUB (CH4-M3 builds this).

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE APARTMENT —", 3.0)
	SceneDirector.goto_beat("ch4_break", 1.0)
