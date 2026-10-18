extends PanelContainer
signal closed
const UI = preload("res://scripts/ui_style.gd")
var puzzle: Node
var slots: Array[String] = ["", "", "", ""]
var selected_slot := 0
var slot_buttons: Array[Button] = []
var choices: HBoxContainer
var feedback: Label
var replay: AudioStreamPlayer

func bind(investigation: Node) -> void:
	puzzle = investigation
	position = Vector2(50,105)
	custom_minimum_size = Vector2(860,300)
	theme = UI.make_theme()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	add_child(column)
	UI.label(column,"RECOVERED WORDS / EMILY'S TAPE",22)
	UI.label(column,"Choose a position, then a recovered fragment. Listen again if needed.",16)
	choices = HBoxContainer.new()
	column.add_child(choices)
	var row := HBoxContainer.new()
	column.add_child(row)
	for index in range(slots.size()):
		var button := UI.button(row,"",func(): selected_slot = index; refresh())
		button.custom_minimum_size.x = 204
		button.add_theme_font_size_override("font_size",16)
		slot_buttons.append(button)
	feedback = UI.label(column,"",17)
	var controls := HBoxContainer.new()
	column.add_child(controls)
	UI.button(controls,"CHECK ORDER",_submit)
	UI.button(controls,"CLEAR",func(): slots.assign(["","","",""]); selected_slot = 0; refresh())
	UI.button(controls,"LISTEN AGAIN",_replay)
	UI.button(controls,"RETURN",dismiss)
	replay = AudioStreamPlayer.new()
	replay.bus = &"Cassette"
	add_child(replay)
	puzzle.changed.connect(refresh)
	refresh()
	hide()

func refresh() -> void:
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for fragment in puzzle.data.fragments:
		var id := str(fragment.id)
		var button := UI.button(choices,id + " / " + (puzzle.message_for(id) if id in puzzle.discovered else "???"),func(): place(id))
		button.disabled = id not in puzzle.discovered
		button.add_theme_font_size_override("font_size",16)
	for index in range(slots.size()):
		slot_buttons[index].text = ("> " if selected_slot == index else "") + str(index + 1) + ": " + (puzzle.message_for(slots[index]) if not slots[index].is_empty() else "____")
	feedback.text = "%d / %d fragments recovered. The pet remembers the order." % [puzzle.discovered.size(),puzzle.data.fragments.size()]

func place(id: String) -> void:
	if id not in puzzle.discovered: return
	for index in range(slots.size()):
		if slots[index] == id: slots[index] = ""
	slots[selected_slot] = id
	selected_slot = (selected_slot + 1) % slots.size()
	refresh()

func _submit() -> void:
	if not puzzle.submit(slots): feedback.text = "The words don't fit yet. Listen and try another order."

func _replay() -> void:
	var id := slots[selected_slot]
	if id.is_empty():
		feedback.text = "Choose an occupied position to listen again."
		return
	feedback.text = "TEMPORARY TRANSCRIPT / " + puzzle.message_for(id)
	for fragment in puzzle.data.fragments:
		if str(fragment.id) == id and fragment.has("clip"):
			replay.stream = load(fragment.clip) as AudioStream
			replay.play()

func dismiss() -> void:
	replay.stop()
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		dismiss()
		get_viewport().set_input_as_handled()
