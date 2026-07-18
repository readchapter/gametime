extends Node3D
## Chapter 3 — the safehouse. STUB (CH3-M3 builds this).

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE SAFEHOUSE —", 3.0)
	SceneDirector.goto_beat("ch3_checkpoint", 1.0)
