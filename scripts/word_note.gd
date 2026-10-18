extends PanelContainer
signal closed
const UI = preload("res://scripts/ui_style.gd")
var puzzle: Node
var entry: LineEdit
var feedback: Label
var heading: Label

func bind(investigation: Node) -> void:
	puzzle = investigation
	position = Vector2(285,170)
	custom_minimum_size = Vector2(390,170)
	theme = UI.make_theme()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	add_child(column)
	heading = UI.label(column,"",18)
	entry = LineEdit.new()
	entry.placeholder_text = "What did I hear?"
	entry.max_length = 64
	entry.custom_minimum_size = Vector2(360,36)
	entry.text_submitted.connect(func(_text): submit_word())
	column.add_child(entry)
	feedback = UI.label(column,"",16)
	feedback.custom_minimum_size = Vector2(360,44)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := HBoxContainer.new()
	column.add_child(row)
	UI.button(row,"WRITE",submit_word)
	UI.button(row,"RETURN",dismiss)
	hide()

func open_note() -> void:
	heading.text = "MY NOTES / " + preload("res://scripts/tape_timeline.gd").stamp(puzzle.paused_position)
	entry.clear()
	feedback.text = "Write the word or phrase you heard."
	show()
	entry.grab_focus()

func submit_word() -> void:
	if puzzle.record_word(entry.text):
		feedback.text = "Written in my notes."
		entry.clear()
	else:
		feedback.text = "That doesn't match what I heard here. Listen again."
	entry.grab_focus()

func dismiss() -> void:
	entry.release_focus()
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and ((event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT)):
		dismiss()
		get_viewport().set_input_as_handled()
