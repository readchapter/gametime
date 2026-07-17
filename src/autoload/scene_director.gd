extends Node
## Owns chapter flow and scene transitions. Chapter 1 is a linear beat list;
## later chapters branch by consulting GameState flags before advancing.

signal transition_finished

## Chapter 1 beat map. Linear for Ch1; later chapters branch on GameState
## flags before calling goto_beat.
const CH1_BEATS := {
	"hardstand": "res://src/chapters/ch1/hardstand.tscn",
	"raid": "res://src/chapters/ch1/bomber_tail.tscn",
	"descent": "res://src/chapters/ch1/descent.tscn",
	"farmhouse": "res://src/chapters/ch1/farmhouse.tscn",
}

const CH2_BEATS := {
	"ch2_morning": "res://src/chapters/ch2/farm_morning.tscn",
	"ch2_walk": "res://src/chapters/ch2/night_walk.tscn",
	"ch2_vetting": "res://src/chapters/ch2/barn_vetting.tscn",
}

## Scene path for any beat across all chapters ("" if unknown).
static func beat_scene(beat: String) -> String:
	if CH1_BEATS.has(beat):
		return CH1_BEATS[beat]
	if CH2_BEATS.has(beat):
		return CH2_BEATS[beat]
	return ""

var _fade: ColorRect

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	add_child(layer)

func fade_to_scene(path: String, duration := 1.0) -> void:
	await fade_out(duration)
	get_tree().change_scene_to_file(path)
	await fade_in(duration)

## Advance the chapter. Records progress so the title screen can continue.
func goto_beat(beat: String, fade := 1.0) -> void:
	var scene := beat_scene(beat)
	if scene.is_empty():
		push_error("Unknown beat: " + beat)
		return
	GameState.beat = beat
	GameState.save_game()
	if _fade.modulate.a < 1.0:
		await fade_out(fade)
	get_tree().change_scene_to_file(scene)

## The first real fail state (Ch2+): fade to black, hold a stark card, then
## reload the current beat. Each retry increments attempt_<retry_key> so
## dialogue line pools vary per attempt (the replay-variation system).
func game_over(text: String, retry_key := "") -> void:
	await fade_out(1.2)
	if retry_key != "":
		var k := "attempt_" + retry_key
		GameState.set_flag(k, int(GameState.get_flag(k, 0)) + 1)
	await CutscenePlayer.caption(text, 4.0)
	get_tree().change_scene_to_file(beat_scene(GameState.beat))

func fade_out(duration := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, duration)
	await tw.finished

func fade_in(duration := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, duration)
	await tw.finished
	transition_finished.emit()
