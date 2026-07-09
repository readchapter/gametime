extends Node
## Data-driven dialogue runtime. Full implementation lands with milestone M2;
## this stub fixes the data contract early.
##
## Schema (data/dialogue/**.json):
##   {
##     "start": "node_id",
##     "nodes": {
##       "node_id": {
##         "speaker": "Pat",
##         "lines": ["..."],              # array: replay-variation pool; one
##                                        # entry is picked per attempt (Ch1
##                                        # always uses index 0)
##         "choices": [                   # optional; absent = linear advance
##           {"text": "...", "next": "other_id",
##            "condition": "flag_name",   # optional GameState flag gate
##            "effects": {"flag": true}}  # optional GameState flag writes;
##                                        # reserved: "trust" effects (Ch2+)
##         ],
##         "next": "other_id"             # linear nodes; absent = end
##       }
##     }
##   }

signal dialogue_started(id: String)
signal dialogue_ended(id: String)

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
