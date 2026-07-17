extends Node3D
## Chapter 2 — the night walk to the barn. STUB (CH2-M3 builds this):
## fades in, holds a card, moves on to the vetting.

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE WALK —", 3.0)
	SceneDirector.goto_beat("ch2_vetting", 1.0)
