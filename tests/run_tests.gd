extends Node
## Headless logic tests. Run via:
##   engine/godot --headless --path . res://tests/test_runner.tscn
## Exits 0 on success, 1 on any failure (checked by CI/session scripts).

var _failures: Array[String] = []

func _ready() -> void:
	_test_dialogue_data_valid("res://data/dialogue/ch1/farm_table.json")
	_test_farm_table_walkthrough_good_landing()
	_test_farm_table_walkthrough_bad_landing()
	_test_choice_conditions()
	_test_game_state_persistence()
	_test_landing_grades()

	if _failures.is_empty():
		print("ALL TESTS PASSED")
		get_tree().quit(0)
	else:
		for f in _failures:
			printerr("FAIL: " + f)
		printerr("%d test(s) failed" % _failures.size())
		get_tree().quit(1)

func _check(cond: bool, what: String) -> void:
	if not cond:
		_failures.append(what)

## Every next/branch/choice target in a dialogue file must exist, and every
## non-branch node must have a speaker and at least one line.
func _test_dialogue_data_valid(path: String) -> void:
	var data := DialogueManager.load_dialogue(path)
	_check(not data.is_empty(), "%s parses" % path)
	if data.is_empty():
		return
	var nodes: Dictionary = data.get("nodes", {})
	_check(nodes.has(str(data.get("start", ""))), "%s start node exists" % path)
	for id: String in nodes:
		var n: Dictionary = nodes[id]
		if n.has("branch"):
			var b: Dictionary = n["branch"]
			for key in ["if_true", "if_false"]:
				_check(nodes.has(str(b.get(key, ""))),
					"%s: branch target %s of '%s' exists" % [path, b.get(key), id])
			continue
		_check(str(n.get("speaker", "")) != "", "%s: node '%s' has speaker" % [path, id])
		var lines: Array = n.get("lines", [])
		_check(lines.size() > 0, "%s: node '%s' has lines" % [path, id])
		if n.has("next"):
			_check(nodes.has(str(n["next"])), "%s: next of '%s' exists" % [path, id])
		for c: Dictionary in n.get("choices", []):
			if c.has("next"):
				_check(nodes.has(str(c["next"])),
					"%s: choice target %s of '%s' exists" % [path, c["next"], id])

## Drives a dialogue to completion, always picking the first choice.
## Returns the visited node ids.
func _run_dialogue(path: String) -> Array[String]:
	var visited: Array[String] = []
	# Lambdas capture locals by value in GDScript, so use a mutable dict.
	var state := {"ended": 0}
	var on_line := func(_s: String, _t: String) -> void:
		visited.append(DialogueManager.current_node_id)
	var on_end := func(_id: String) -> void:
		state["ended"] += 1
	DialogueManager.line_changed.connect(on_line)
	DialogueManager.dialogue_ended.connect(on_end)
	DialogueManager.start(path)
	var steps := 0
	while DialogueManager.active and steps < 100:
		var choices := DialogueManager.available_choices()
		if choices.size() > 0:
			DialogueManager.choose(int(choices[0]["index"]))
		else:
			DialogueManager.advance()
		steps += 1
	DialogueManager.line_changed.disconnect(on_line)
	DialogueManager.dialogue_ended.disconnect(on_end)
	_check(int(state["ended"]) == 1, "%s emits dialogue_ended exactly once" % path)
	return visited

func _test_farm_table_walkthrough_good_landing() -> void:
	GameState.flags.clear()
	var visited := _run_dialogue("res://data/dialogue/ch1/farm_table.json")
	_check("not_seen" in visited, "good landing routes through 'not_seen'")
	_check(not ("seen" in visited), "good landing skips 'seen'")
	_check("luck" in visited, "walkthrough reaches final node")
	_check(bool(GameState.get_flag("told_crew_count")), "first choice set told_crew_count")

func _test_farm_table_walkthrough_bad_landing() -> void:
	GameState.flags.clear()
	GameState.set_flag("landing_bad", true)
	var visited := _run_dialogue("res://data/dialogue/ch1/farm_table.json")
	_check("seen" in visited, "bad landing routes through 'seen'")
	_check(not ("not_seen" in visited), "bad landing skips 'not_seen'")

func _test_choice_conditions() -> void:
	GameState.flags.clear()
	DialogueManager._nodes = {
		"q": {"speaker": "X", "lines": ["?"], "choices": [
			{"text": "gated", "condition": "some_flag", "next": "q"},
			{"text": "negated", "condition": "!some_flag", "next": "q"},
			{"text": "open", "next": "q"},
		]}}
	DialogueManager._current = DialogueManager._nodes["q"]
	DialogueManager.active = true
	var open := DialogueManager.available_choices()
	_check(open.size() == 2, "condition gating hides flagged choice (got %d)" % open.size())
	GameState.set_flag("some_flag", true)
	var after := DialogueManager.available_choices()
	_check(after.size() == 2, "negated condition hides after flag set (got %d)" % after.size())
	_check(str(after[0]["text"]) == "gated", "gated choice appears once flag set")
	DialogueManager.active = false

func _test_landing_grades() -> void:
	const Descent := preload("res://src/chapters/ch1/descent.gd")
	_check(Descent.grade_landing(Vector3(-50, 0, 15)) == "good",
		"landing on the hedgerow line grades good")
	_check(Descent.grade_landing(Vector3(0, 0, 0)) == "neutral",
		"landing mid-field grades neutral")
	_check(Descent.grade_landing(Vector3(60, 0, 0)) == "bad",
		"landing near the road grades bad")
	_check(Descent.grade_landing(Vector3(100, 0, 50)) == "bad",
		"landing in the village grades bad")

func _test_game_state_persistence() -> void:
	GameState.flags.clear()
	GameState.inventory.clear()
	GameState.set_flag("landing_bad", true)
	GameState.add_item("document_fragment")
	GameState.mark_cutscene_seen("farmhouse_intro")
	GameState.chapter = 1
	GameState.beat = "farmhouse"
	GameState.save_game()

	GameState.flags.clear()
	GameState.inventory.clear()
	GameState.seen_cutscenes.clear()
	GameState.beat = ""
	_check(GameState.load_game(), "save file loads")
	_check(bool(GameState.get_flag("landing_bad")), "flag survives save/load")
	_check(GameState.has_item("document_fragment"), "inventory survives save/load")
	_check(GameState.has_seen_cutscene("farmhouse_intro"), "seen cutscenes survive save/load")
	_check(GameState.beat == "farmhouse", "beat survives save/load")
