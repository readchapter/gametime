extends Node
## Minimal HUD: interaction prompt, intercom subtitles, turret crosshair,
## damage vignette. No health bars, minimaps, or meters by design.

class Crosshair extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var col := Color(0.9, 0.88, 0.8, 0.75)
		for off in [Vector2(10, 0), Vector2(-10, 0), Vector2(0, 10), Vector2(0, -10)]:
			draw_line(c + off, c + off * 2.2, col, 1.5)

var _prompt: Label
var _subtitle: RichTextLabel
var _crosshair: Crosshair
var _vignette: ColorRect
var _subtitle_version := 0

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)

	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(0.55, 0.04, 0.02, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_vignette)

	_crosshair = Crosshair.new()
	_crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.hide()
	layer.add_child(_crosshair)

	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -140
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75, 0.9))
	_prompt.hide()
	layer.add_child(_prompt)

	_subtitle = RichTextLabel.new()
	_subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle.offset_left = 320
	_subtitle.offset_right = -320
	_subtitle.offset_top = -110
	_subtitle.offset_bottom = -56
	_subtitle.bbcode_enabled = true
	_subtitle.scroll_active = false
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.add_theme_font_size_override("normal_font_size", 22)
	_subtitle.add_theme_font_size_override("bold_font_size", 22)
	# Dark outline so intercom lines stay legible over bright sky/flak.
	_subtitle.add_theme_constant_override("outline_size", 6)
	_subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	layer.add_child(_subtitle)

func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.show()

func hide_prompt() -> void:
	_prompt.hide()

## Non-blocking intercom/ambient line. Replaces any current subtitle.
func subtitle(speaker: String, text: String, seconds := 4.0) -> void:
	_subtitle_version += 1
	var v := _subtitle_version
	var head := ""
	if not speaker.is_empty():
		head = "[color=#d9a866][b]%s[/b][/color] — " % speaker
	_subtitle.text = "[center]%s%s[/center]" % [head, text]
	_subtitle.modulate.a = 1.0
	await get_tree().create_timer(seconds, false).timeout
	if v == _subtitle_version:
		var tw := create_tween()
		tw.tween_property(_subtitle, "modulate:a", 0.0, 0.4)

func show_crosshair(on: bool) -> void:
	_crosshair.visible = on

func damage_flash(strength := 1.0) -> void:
	var tw := create_tween()
	_vignette.color.a = clampf(0.38 * strength, 0.0, 0.55)
	tw.tween_property(_vignette, "color:a", 0.0, 0.6)
