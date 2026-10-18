extends Resource
## One source for fragment times, captions, listening windows, notebook and pet clues.
@export var fragments: Array[Dictionary] = []
@export var correct_order: Array[String] = []
@export var captions: Array[Dictionary] = []
@export var tolerance_seconds := 2.0
@export var required_listening_seconds := 1.0
@export var reveal_seconds := 4.0
@export var suspense_seconds := 1.5
@export_multiline var final_message := "DON'T TRUST HIM.\nCHECK THE DOOR."

func clue_text() -> String:
	var lines := "The tape slips.\nUse the pencil. Listen near:\n\n"
	for fragment in fragments:
		var time := int(fragment.time)
		lines += "%s  /  %02d:%02d\n" % [fragment.id, time / 60, time % 60]
	return lines + "\nMy little pet remembers\nthe order. Left / right\nbuttons follow its memory."
