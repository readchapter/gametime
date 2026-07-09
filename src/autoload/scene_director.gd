extends Node
## Owns chapter flow and scene transitions. Chapter 1 is a linear beat list;
## later chapters branch by consulting GameState flags before advancing.

signal transition_finished

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

func fade_out(duration := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, duration)
	await tw.finished

func fade_in(duration := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, duration)
	await tw.finished
	transition_finished.emit()
