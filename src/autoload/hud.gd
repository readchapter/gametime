extends Node
## Minimal diegetic-adjacent HUD: just the interaction prompt. The game has
## no health bars, minimaps, or meters by design.

var _prompt: Label

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -140
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75, 0.9))
	_prompt.hide()
	layer.add_child(_prompt)
	add_child(layer)

func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.show()

func hide_prompt() -> void:
	_prompt.hide()
