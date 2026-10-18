extends Node
signal changed
signal caption_changed(text: String)
signal puzzle_solved(message: String)
@export var data: Resource = preload("res://resources/investigation.tres")
var tape: Node
var discovered: Array[String] = []
var listened: Dictionary = {}
var solved := false
var caption := ""

func bind(transport: Node) -> void:
	tape = transport
	tape.playback_advanced.connect(_heard)
	tape.seeked.connect(func(_time): listened.clear(); _caption(""))
	tape.state_changed.connect(func(state):
		if state != "PLAY": _caption(""))

func _heard(previous: float, current: float) -> void:
	if solved: return
	var text := ""
	for entry in data.captions:
		if current >= float(entry.start) and current < float(entry.end): text = entry.text
	for fragment in data.fragments:
		var start: float = float(fragment.time) - data.tolerance_seconds
		var end: float = float(fragment.time) + float(fragment.duration) + data.tolerance_seconds
		var overlap := maxf(0.0, minf(current, end) - maxf(previous, start))
		var id := str(fragment.id)
		if overlap > 0.0:
			listened[id] = float(listened.get(id, 0.0)) + overlap
			if float(listened[id]) >= data.required_listening_seconds and id not in discovered:
				discovered.append(id)
				tape.collect_fragment(id)
				changed.emit()
		if current >= start and current < end: text = "%s  /  %s" % [id,fragment.message]
	_caption("TEMPORARY RECORDING / TRANSCRIPT\n" + text if not text.is_empty() else "")

func _caption(text: String) -> void:
	if caption == text: return
	caption = text
	caption_changed.emit(caption)

func message_for(id: String) -> String:
	for fragment in data.fragments:
		if str(fragment.id) == id: return fragment.message
	return ""

func submit(order: Array[String]) -> bool:
	if solved or order.size() != data.correct_order.size(): return false
	for index in range(order.size()):
		if order[index] not in discovered or order[index] != data.correct_order[index]: return false
	solved = true
	puzzle_solved.emit(data.final_message)
	return true
