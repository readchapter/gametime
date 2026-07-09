extends CanvasLayer
## Dialogue UI: bottom panel with speaker name, typewriter text, and a
## keyboard/mouse choice list. Purely reactive — all state lives in
## DialogueManager. Restrained styling per the game's tone: dark panel,
## small caps speaker, no ornament.

const TYPE_SPEED := 45.0  # characters per second

var _panel: PanelContainer
var _speaker: Label
var _text: RichTextLabel
var _choices_box: VBoxContainer
var _buttons: Array[Button] = []
var _selected := 0
var _typing := false

func _ready() -> void:
	layer = 90
	_build_ui()
	_panel.hide()
	DialogueManager.line_changed.connect(_on_line)
	DialogueManager.choices_shown.connect(_on_choices)
	DialogueManager.dialogue_ended.connect(_on_ended)

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 240
	_panel.offset_right = -240
	_panel.offset_top = -220
	_panel.offset_bottom = -48
	# Content taller than the base rect grows upward, never off-screen.
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.88)
	style.border_color = Color(0.35, 0.30, 0.24, 0.6)
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	_speaker = Label.new()
	_speaker.add_theme_color_override("font_color", Color(0.85, 0.65, 0.40))
	_speaker.add_theme_font_size_override("font_size", 20)
	_speaker.uppercase = true
	vbox.add_child(_speaker)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = true
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", 24)
	_text.add_theme_color_override("default_color", Color(0.92, 0.90, 0.86))
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_choices_box)

func _on_line(speaker: String, text: String) -> void:
	_clear_choices()
	_panel.show()
	_speaker.text = speaker
	_speaker.visible = not speaker.is_empty()
	_text.text = text
	_text.visible_ratio = 0.0
	_typing = true
	var tw := create_tween()
	tw.tween_property(_text, "visible_ratio", 1.0, text.length() / TYPE_SPEED)
	tw.tween_callback(func() -> void: _typing = false)

func _on_choices(choices: Array) -> void:
	_clear_choices()
	for c: Dictionary in choices:
		var b := Button.new()
		b.text = c["text"]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_pick.bind(int(c["index"])))
		_choices_box.add_child(b)
		_buttons.append(b)
	_selected = 0
	_update_selection()

func _on_ended(_id: String) -> void:
	_clear_choices()
	_panel.hide()

func _clear_choices() -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()

func _update_selection() -> void:
	for i in _buttons.size():
		var on := i == _selected
		_buttons[i].add_theme_color_override("font_color",
			Color(0.95, 0.80, 0.55) if on else Color(0.65, 0.63, 0.60))
		_buttons[i].text = ("»  " if on else "   ") + _buttons[i].text.trim_prefix("»  ").trim_prefix("   ")

func _pick(index: int) -> void:
	_clear_choices()
	DialogueManager.choose(index)

func _input(event: InputEvent) -> void:
	if not _panel.visible or not DialogueManager.active:
		return
	if _buttons.size() > 0:
		if event.is_action_pressed("move_back") or event.is_action_pressed("ui_down"):
			_selected = mini(_selected + 1, _buttons.size() - 1)
			_update_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_forward") or event.is_action_pressed("ui_up"):
			_selected = maxi(_selected - 1, 0)
			_update_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("advance") or event.is_action_pressed("interact"):
			var idx := -1
			var shown := DialogueManager.available_choices()
			if _selected < shown.size():
				idx = int(shown[_selected]["index"])
			if idx >= 0:
				_pick(idx)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("advance") or event.is_action_pressed("interact"):
		if _typing:
			_text.visible_ratio = 1.0
			_typing = false
		else:
			DialogueManager.advance()
		get_viewport().set_input_as_handled()
