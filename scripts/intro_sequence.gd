extends Control
signal finished
@export var characters_per_second := 34.0
@export var lines: PackedStringArray = ["My best friend Emily died not long ago.", "They said she took her own life.", "I brought some of her belongings home.", "But something doesn't feel right.", "I need to know what really happened."]
const UI = preload("res://scripts/ui_style.gd")
var line_index := 0
var progress := 0.0
var body: Label
var done := false

func _ready() -> void:
	theme = UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := ColorRect.new()
	background.color = Color(.006,.007,.01,1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	body = UI.label(self, "", 26)
	body.position = Vector2(100,215)
	body.size = Vector2(760,120)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hint := UI.label(self, "CLICK / SPACE to continue     ESC to skip", 16)
	hint.position = Vector2(220,470)
	var skip_button := UI.button(self, "SKIP", skip)
	skip_button.position = Vector2(820,474)
	_show_line()

func _process(delta: float) -> void:
	if done: return
	progress += delta * characters_per_second
	body.visible_characters = mini(int(progress), body.text.length())

func _show_line() -> void:
	if lines.is_empty(): skip(); return
	body.text = lines[line_index]
	progress = 0.0
	body.visible_characters = 0

func advance() -> void:
	if done: return
	if body.visible_characters < body.text.length():
		progress = body.text.length()
		body.visible_characters = body.text.length()
	elif line_index + 1 < lines.size():
		line_index += 1
		_show_line()
	else: skip()

func skip() -> void:
	if done: return
	done = true
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: skip()
		elif event.keycode in [KEY_SPACE, KEY_ENTER]: advance()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: advance()
