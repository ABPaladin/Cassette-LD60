extends PanelContainer
const UI = preload("res://scripts/ui_style.gd")
var tape: Node
var readout: Label
var slider: HSlider
var play_button: Button
var manual_mode := false

func bind(controller: Node) -> void:
	tape = controller
	custom_minimum_size = Vector2(510, 100)
	theme = UI.make_theme()
	var column := VBoxContainer.new()
	add_child(column)
	readout = UI.label(column, "", 16)
	var row := HBoxContainer.new()
	column.add_child(row)
	UI.button(row, "<< 5s", func(): tape.seek(tape.position_seconds - 5.0))
	play_button = UI.button(row, "PLAY", tape.toggle)
	UI.button(row, ">> 5s", func(): tape.seek(tape.position_seconds + 5.0))
	slider = HSlider.new()
	slider.custom_minimum_size.x = 480
	slider.max_value = tape.duration
	slider.step = .01
	slider.focus_mode = Control.FOCUS_NONE
	column.add_child(slider)
	slider.value_changed.connect(func(value): tape.seek(value))

func _process(_delta: float) -> void:
	if tape == null: return
	slider.set_value_no_signal(tape.position_seconds)
	readout.text = "SIDE A   %s / %s   [%s]" % [stamp(tape.position_seconds), stamp(tape.duration), "PLAY" if tape.playing else "PAUSE"]
	play_button.text = "PAUSE" if tape.playing else "PLAY"
	play_button.disabled = manual_mode

static func stamp(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
