extends Node3D
## Chapter 3 — the road west. STUB (CH3-M2 builds this).

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE ROAD WEST —", 3.0)
	SceneDirector.goto_beat("ch3_safehouse", 1.0)
