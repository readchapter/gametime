extends Node
## Data-driven dialogue runtime. Dialogue lives in external JSON
## (data/dialogue/**), never in scripts — this is what lets replay variation,
## localization, and future voice work extend without rewrites.
##
## Schema:
##   {
##     "id": "farm_table",                # optional; defaults to filename
##     "start": "node_id",
##     "nodes": {
##       "node_id": {
##         "speaker": "Henri",
##         "lines": ["..."],              # variation pool: the line is picked
##                                        # by attempt_<dialogue_id> % size
##                                        # (0 when never retried — Ch1 shape)
##         "effects": {"flag": true,      # optional; applied on node enter
##                     "+suspicion": 1},  # "+key" increments a numeric flag
##         "choices": [                   # optional; absent = linear
##           {"text": "...", "next": "id",
##            "condition": "flag",        # optional; "!flag" negates,
##                                        # "flag>=n" compares numerically
##            "autoplay": true,           # optional; headless runs prefer it
##            "effects": {"flag": true}}  # optional; applied on select
##         ],
##         "next": "id",                  # linear advance; absent = end
##         "branch": {"flag": "f",        # pure branch node (no lines):
##            "if_true": "a",             # jumps immediately by condition
##            "if_false": "b"}            # ("f" may use ! or >= forms)
##       }
##     }
##   }
## Trust is ordinary flags by convention ("trust_<person>", "doubted_<x>"),
## consulted through conditions — never a visible meter.

signal dialogue_started(id: String)
signal line_changed(speaker: String, text: String)
signal choices_shown(choices: Array)
signal dialogue_ended(id: String)

var active := false
var current_node_id := ""

var _nodes: Dictionary = {}
var _current: Dictionary = {}
var _dialogue_id := ""

func load_dialogue(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Dialogue file not found: " + path)
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Malformed dialogue JSON: " + path)
		return {}
	return data

func start(path: String) -> void:
	var data := load_dialogue(path)
	if data.is_empty():
		return
	_nodes = data.get("nodes", {})
	_dialogue_id = str(data.get("id", path.get_file().get_basename()))
	active = true
	dialogue_started.emit(_dialogue_id)
	_enter(str(data.get("start", "")))

## Called by the UI when the current line has been read. Shows choices if the
## node has any, otherwise moves to the next node or ends.
func advance() -> void:
	if not active:
		return
	var choices := available_choices()
	if choices.size() > 0:
		choices_shown.emit(choices)
	elif _current.has("next"):
		_enter(str(_current["next"]))
	else:
		_end()

func choose(index: int) -> void:
	if not active:
		return
	var cs: Array = _current.get("choices", [])
	if index < 0 or index >= cs.size():
		return
	var c: Dictionary = cs[index]
	_apply_effects(c.get("effects", {}))
	if c.has("next"):
		_enter(str(c["next"]))
	else:
		_end()

func available_choices() -> Array:
	var out: Array = []
	var cs: Array = _current.get("choices", [])
	for i in cs.size():
		var c: Dictionary = cs[i]
		if _condition_met(str(c.get("condition", ""))):
			out.append({"text": str(c.get("text", "")), "index": i,
				"autoplay": bool(c.get("autoplay", false))})
	return out

func _enter(node_id: String) -> void:
	if node_id.is_empty() or not _nodes.has(node_id):
		_end()
		return
	current_node_id = node_id
	_current = _nodes[node_id]
	_apply_effects(_current.get("effects", {}))
	if _current.has("branch"):
		var b: Dictionary = _current["branch"]
		var v := _condition_met(str(b.get("flag", "")))
		_enter(str(b["if_true"] if v else b["if_false"]))
		return
	var lines: Array = _current.get("lines", [])
	var text := ""
	if lines.size() > 0:
		# Replay variation: retries of this dialogue rotate through the pool.
		var attempt := int(GameState.get_flag("attempt_" + _dialogue_id, 0))
		text = str(lines[attempt % lines.size()])
	line_changed.emit(str(_current.get("speaker", "")), text)

func _condition_met(cond: String) -> bool:
	if cond.is_empty():
		return true
	if cond.begins_with("!"):
		return not _condition_met(cond.substr(1))
	if ">=" in cond:
		var parts := cond.split(">=")
		return int(GameState.get_flag(parts[0].strip_edges(), 0)) \
			>= int(parts[1].strip_edges())
	return bool(GameState.get_flag(cond))

func _apply_effects(effects: Dictionary) -> void:
	for k in effects:
		var key := str(k)
		if key.begins_with("+"):
			var flag := key.substr(1)
			GameState.set_flag(flag, int(GameState.get_flag(flag, 0)) + int(effects[k]))
		else:
			GameState.set_flag(key, effects[k])

## Dev-only: drives the active dialogue to completion so headless verification
## runs can pass interactive gates. Prefers choices marked "autoplay": true
## (e.g. the correct vetting answers), else takes the first.
func autoplay(interval := 0.6) -> void:
	while active:
		await get_tree().create_timer(interval, false).timeout
		if not active:
			return
		var cs := available_choices()
		if cs.size() > 0:
			var pick: Dictionary = cs[0]
			for c: Dictionary in cs:
				if c["autoplay"]:
					pick = c
					break
			choose(int(pick["index"]))
		else:
			advance()

func _end() -> void:
	active = false
	current_node_id = ""
	_current = {}
	dialogue_ended.emit(_dialogue_id)
