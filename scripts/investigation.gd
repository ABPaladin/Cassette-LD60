extends Node
signal changed
signal puzzle_solved(message: String)
@export var data: Resource = preload("res://resources/investigation.tres")
var tape: Node
var discovered: Array[String] = []
var listened: Dictionary = {}
var solved := false
var paused_position := -1.0
var was_playing := false
var normalizer := RegEx.new()

func bind(transport: Node) -> void:
	tape = transport
	normalizer.compile("[^\\p{L}\\p{N}]")
	tape.playback_advanced.connect(_heard)
	tape.seeked.connect(func(_time): listened.clear(); paused_position = -1.0)
	tape.state_changed.connect(_state_changed)

func _state_changed(state: String) -> void:
	if state == "PLAY":
		was_playing = true
		paused_position = -1.0
	elif state == "PAUSE":
		if was_playing: paused_position = tape.position_seconds
		was_playing = false
	elif state == "END":
		paused_position = tape.position_seconds
		was_playing = false
	elif state == "STOP":
		paused_position = -1.0
		was_playing = false

func _heard(previous: float, current: float) -> void:
	# Listening only records eligibility. It NEVER reveals or collects a word.
	if solved: return
	for fragment in data.fragments:
		var start := float(fragment.time)
		var end := start+float(fragment.duration)
		var overlap := maxf(0.0,minf(current,end)-maxf(previous,start))
		if overlap > 0:
			var id := str(fragment.id)
			listened[id] = float(listened.get(id,0.0))+overlap

func can_note() -> bool:
	return not solved and not tape.playing and paused_position >= 0.0

func normalize(text: String) -> String:
	return normalizer.sub(text.to_lower(),"",true)

func record_word(text: String) -> bool:
	if not can_note(): return false
	var answer := normalize(text)
	if answer.is_empty(): return false
	for fragment in data.fragments:
		var id := str(fragment.id)
		var start: float = float(fragment.time)-data.tolerance_seconds
		var end: float = float(fragment.time)+float(fragment.duration)+data.tolerance_seconds
		if paused_position < start or paused_position > end: continue
		if float(listened.get(id,0.0)) < data.required_listening_seconds: continue
		var accepted: Array = fragment.get("accepted_answers",[]).duplicate()
		accepted.append(str(fragment.message))
		for candidate in accepted:
			if normalize(str(candidate)) == answer:
				if id not in discovered:
					discovered.append(id)
					tape.collect_fragment(id)
					changed.emit()
				return true
	return false

func message_for(id: String) -> String:
	if id not in discovered: return ""
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
