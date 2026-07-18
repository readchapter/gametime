extends Node3D
## Chapter 4 — the arrival. STUB (CH4-M2 builds this).

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE CITY —", 3.0)
	SceneDirector.goto_beat("ch4_apartment", 1.0)
