extends Node
## Headless logic tests. Run via:
##   engine/godot --headless --path . res://tests/test_runner.tscn
## Exits 0 on success, 1 on any failure (checked by CI/session scripts).

var _failures: Array[String] = []

func _ready() -> void:
	_test_dialogue_data_valid("res://data/dialogue/ch1/farm_table.json")
	_test_dialogue_data_valid("res://data/dialogue/ch1/hardstand.json")
	_test_dialogue_data_valid("res://data/dialogue/ch1/field_wake.json")
	_test_dialogue_data_valid("res://data/dialogue/ch2/farm_morning.json")
	_test_dialogue_data_valid("res://data/dialogue/ch2/marcel_intro.json")
	_test_dialogue_data_valid("res://data/dialogue/ch2/vetting_willis.json")
	_test_dialogue_data_valid("res://data/dialogue/ch2/vetting_travis.json")
	_test_farm_morning_branches()
	_test_vetting_pass_path()
	_test_vetting_fail_path()
	_test_dialogue_data_valid("res://data/dialogue/ch3/road_handoff.json")
	_test_dialogue_data_valid("res://data/dialogue/ch3/safehouse_plan.json")
	_test_dialogue_data_valid("res://data/dialogue/ch3/checkpoint.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/door17.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/apartment_meet.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/lucien_meet.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/probe_name.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/probe_crash.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/probe_carry.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/paine_book.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/warnings.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/the_choice.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/voss_interview.json")
	_test_dialogue_data_valid("res://data/dialogue/ch4/escape_contingency.json")
	_test_dialogue_data_valid("res://data/dialogue/ch5/pat_reunion.json")
	_test_dialogue_data_valid("res://data/dialogue/ch5/barge_talk.json")
	_test_ch4_probes_and_choice()
	_test_voss_knows_what_you_told_lucien()
	_test_road_handoff_branches()
	_test_checkpoint_paths()
	_test_farm_table_walkthrough_good_landing()
	_test_farm_table_walkthrough_bad_landing()
	_test_choice_conditions()
	_test_numeric_conditions_and_increments()
	_test_line_variation_by_attempt()
	_test_beat_scene_lookup()
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
		# Narration nodes may use an empty speaker, but the key must be explicit.
		_check(n.has("speaker"), "%s: node '%s' has speaker" % [path, id])
		var lines: Array = n.get("lines", [])
		_check(lines.size() > 0, "%s: node '%s' has lines" % [path, id])
		if n.has("next"):
			_check(nodes.has(str(n["next"])), "%s: next of '%s' exists" % [path, id])
		for c: Dictionary in n.get("choices", []):
			if c.has("next"):
				_check(nodes.has(str(c["next"])),
					"%s: choice target %s of '%s' exists" % [path, c["next"], id])

func _test_road_handoff_branches() -> void:
	GameState.flags.clear()
	GameState.set_flag("lied_document", true)
	var visited := _run_dialogue("res://data/dialogue/ch3/road_handoff.json")
	_check("s_cold" in visited, "a document lie earns the cold greeting")
	GameState.flags.clear()
	GameState.set_flag("doubted_willis", true)
	visited = _run_dialogue("res://data/dialogue/ch3/road_handoff.json")
	_check("s_sharp" in visited, "doubting Willis earns the sharp greeting")
	_check("s_rules" in visited, "handoff reaches the rules")
	_check(bool(GameState.get_flag("trust_sylvie")), "first choice sets trust_sylvie")

func _test_ch4_probes_and_choice() -> void:
	# Careful path: deflect everything — zero exposure, stays with Béranger.
	GameState.flags.clear()
	GameState.set_flag("exposure", 0)
	for p in ["probe_name", "probe_crash", "probe_carry"]:
		_run_dialogue("res://data/dialogue/ch4/%s.json" % p)
	_check(int(GameState.get_flag("exposure", 0)) == 0, "deflections accrue no exposure")
	var visited := _run_dialogue("res://data/dialogue/ch4/the_choice.json")
	_check("stay_slow" in visited, "first-choice path stays with Béranger")
	_check(not bool(GameState.get_flag("ch4_took_fast_route")), "fast route flag false on stay")
	# Careless path: reveal everything — max exposure; the paper probe only
	# presses harder when the Ch2 lie travelled up the line.
	GameState.flags.clear()
	GameState.set_flag("exposure", 0)
	GameState.set_flag("lied_document", true)
	for p in ["probe_name", "probe_crash", "probe_carry"]:
		_run_dialogue("res://data/dialogue/ch4/%s.json" % p, true)
	_check(int(GameState.get_flag("exposure", 0)) == 4, "reveals accrue exposure (got %d)"
		% int(GameState.get_flag("exposure", 0)))
	_check(bool(GameState.get_flag("told_lucien_paper")), "paper reveal flagged")
	visited = _run_dialogue("res://data/dialogue/ch4/the_choice.json", true)
	_check("go_fast" in visited, "last-choice path takes the fast route")
	_check(bool(GameState.get_flag("ch4_took_fast_route")), "fast route flag set")

func _test_voss_knows_what_you_told_lucien() -> void:
	# A careful prisoner: Voss falls back on records, no farm, no paper.
	GameState.flags.clear()
	var visited := _run_dialogue("res://data/dialogue/ch4/voss_interview.json")
	_check("v_records" in visited, "careful path: the name came from records")
	_check(not ("v_farm" in visited), "careful path: the farm stays unnamed")
	_check(not ("v_paper" in visited), "careful path: the paper stays unnamed")
	_check(bool(GameState.get_flag("met_voss")), "met_voss set")
	# A careless one: every reveal comes back across the table.
	GameState.flags.clear()
	GameState.set_flag("told_lucien_name", true)
	GameState.set_flag("told_lucien_farm", true)
	GameState.set_flag("told_lucien_paper", true)
	visited = _run_dialogue("res://data/dialogue/ch4/voss_interview.json")
	_check("v_gift" in visited, "careless path: you spelled it yourself")
	_check("v_farm" in visited, "careless path: the farm is visited")
	_check("v_paper" in visited, "careless path: the paper is hunted")

func _test_checkpoint_paths() -> void:
	# Clean cover, no document lie: correct (first) choices pass.
	GameState.flags.clear()
	var visited := _run_dialogue("res://data/dialogue/ch3/checkpoint.json")
	_check(not ("stamp_q" in visited), "no document lie skips the stamp trap")
	_check("pass" in visited, "held cover passes the checkpoint")
	_check(bool(GameState.get_flag("kept_cover")), "kept_cover set on pass")
	# A document liar gets the extra question and can still pass it.
	GameState.flags.clear()
	GameState.set_flag("lied_document", true)
	visited = _run_dialogue("res://data/dialogue/ch3/checkpoint.json")
	_check("stamp_q" in visited, "document lie adds the stamp trap")
	_check("pass" in visited, "stamp trap survivable with held cover")
	# Reacting like a hearing man is fatal.
	GameState.flags.clear()
	visited = _run_dialogue("res://data/dialogue/ch3/checkpoint.json", true)
	_check(int(GameState.get_flag("suspicion", 0)) >= 2, "reactions accrue suspicion")
	_check("fail" in visited, "blown cover routes to arrest")
	_check(bool(GameState.get_flag("checkpoint_failed")), "checkpoint_failed set")

func _test_vetting_pass_path() -> void:
	GameState.flags.clear()
	GameState.set_flag("has_document", true)
	var visited := _run_dialogue("res://data/dialogue/ch2/vetting_willis.json")
	_check("e_doubt" in visited, "doubting Willis routes through e_doubt")
	_check(bool(GameState.get_flag("doubted_willis")), "doubted_willis set")
	visited = _run_dialogue("res://data/dialogue/ch2/vetting_travis.json")
	_check("doc_reveal" in visited, "document search fires with has_document")
	_check("pass" in visited, "honest answers pass the vetting")
	_check(bool(GameState.get_flag("vetting_passed")), "vetting_passed set")
	_check(not bool(GameState.get_flag("vetting_failed")), "vetting_failed unset on pass")
	_check(int(GameState.get_flag("suspicion", 0)) == 0, "clean run accrues no suspicion")
	_check(bool(GameState.get_flag("told_truth_document")), "document truth flag set")

func _test_vetting_fail_path() -> void:
	GameState.flags.clear()
	GameState.set_flag("has_document", true)
	_run_dialogue("res://data/dialogue/ch2/vetting_willis.json", true)
	var visited := _run_dialogue("res://data/dialogue/ch2/vetting_travis.json", true)
	_check(int(GameState.get_flag("suspicion", 0)) >= 2, "wrong answers accrue suspicion (got %d)"
		% int(GameState.get_flag("suspicion", 0)))
	_check("fail" in visited, "suspicion routes to the fail verdict")
	_check(bool(GameState.get_flag("vetting_failed")), "vetting_failed set")
	_check(not bool(GameState.get_flag("vetting_passed")), "vetting_passed unset on fail")

## Drives a dialogue to completion, always picking the first choice (or the
## last, to walk the wrong-answer paths). Returns the visited node ids.
func _run_dialogue(path: String, pick_last := false) -> Array[String]:
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
			var pick: Dictionary = choices[choices.size() - 1] if pick_last else choices[0]
			DialogueManager.choose(int(pick["index"]))
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

func _test_farm_morning_branches() -> void:
	GameState.flags.clear()
	var visited := _run_dialogue("res://data/dialogue/ch2/farm_morning.json")
	_check("not_seen" in visited, "clean landing routes through 'not_seen'")
	_check("wait" in visited, "morning talk reaches its final node")
	_check(bool(GameState.get_flag("trust_henri")), "first choice sets trust_henri")
	GameState.flags.clear()
	GameState.set_flag("landing_bad", true)
	visited = _run_dialogue("res://data/dialogue/ch2/farm_morning.json")
	_check("seen" in visited and "seen2" in visited, "bad landing routes through 'seen'")

func _test_numeric_conditions_and_increments() -> void:
	GameState.flags.clear()
	DialogueManager._apply_effects({"+suspicion": 1})
	DialogueManager._apply_effects({"+suspicion": 1})
	_check(int(GameState.get_flag("suspicion", 0)) == 2, "+flag effects accumulate")
	_check(DialogueManager._condition_met("suspicion>=2"), "numeric >= condition true at threshold")
	_check(not DialogueManager._condition_met("suspicion>=3"), "numeric >= condition false below")
	_check(DialogueManager._condition_met("!suspicion>=3"), "negated numeric condition")
	_check(not DialogueManager._condition_met("missing>=1"), "unset numeric flag reads 0")

func _test_line_variation_by_attempt() -> void:
	GameState.flags.clear()
	DialogueManager._nodes = {"n": {"speaker": "X", "lines": ["first", "second", "third"]}}
	DialogueManager._dialogue_id = "vet_test"
	var heard := {"text": ""}
	var on_line := func(_s: String, t: String) -> void: heard["text"] = t
	DialogueManager.line_changed.connect(on_line)
	DialogueManager.active = true
	DialogueManager._enter("n")
	_check(str(heard["text"]) == "first", "attempt 0 picks line 0")
	GameState.set_flag("attempt_vet_test", 1)
	DialogueManager.active = true
	DialogueManager._enter("n")
	_check(str(heard["text"]) == "second", "attempt 1 picks line 1")
	GameState.set_flag("attempt_vet_test", 4)
	DialogueManager.active = true
	DialogueManager._enter("n")
	_check(str(heard["text"]) == "second", "attempt wraps around the pool")
	DialogueManager.line_changed.disconnect(on_line)
	DialogueManager.active = false

func _test_beat_scene_lookup() -> void:
	_check(SceneDirector.beat_scene("farmhouse").ends_with("farmhouse.tscn"),
		"ch1 beat resolves")
	_check(SceneDirector.beat_scene("ch2_vetting").ends_with("barn_vetting.tscn"),
		"ch2 beat resolves")
	_check(SceneDirector.beat_scene("ch3_checkpoint").ends_with("checkpoint.tscn"),
		"ch3 beat resolves")
	_check(SceneDirector.beat_scene("ch4_break").ends_with("the_break.tscn"),
		"ch4 beat resolves")
	_check(SceneDirector.beat_scene("ch5_barge").ends_with("barge_south.tscn"),
		"ch5 beat resolves")
	_check(SceneDirector.beat_scene("nope") == "", "unknown beat resolves empty")

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
