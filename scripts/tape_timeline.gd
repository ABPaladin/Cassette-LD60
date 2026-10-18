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
	play_button = UI.button(row, "PLAY", tape.toggle)
	slider = HSlider.new()
	slider.custom_minimum_size.x = 480
	slider.max_value = tape.duration
	slider.step = .01
	slider.focus_mode = Control.FOCUS_NONE
	# Position is a readout. Tape navigation belongs to the physical pencil gesture.
	slider.editable = false
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slider.tick_count = 13
	slider.ticks_on_borders = true
	var track := StyleBoxFlat.new()
	track.bg_color = Color(.21,.17,.11)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	slider.add_theme_stylebox_override("slider", track)
	var ink := Gradient.new()
	ink.set_color(0,Color(.8,.72,.51))
	ink.set_color(1,Color(.8,.72,.51))
	var knob := GradientTexture2D.new()
	knob.gradient = ink
	knob.width = 6
	knob.height = 14
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)
	slider.add_theme_icon_override("grabber_disabled", knob)
	column.add_child(slider)

func _process(_delta: float) -> void:
	if tape == null: return
	slider.set_value_no_signal(tape.position_seconds)
	readout.text = "SIDE A   %s / %s   [%s]" % [stamp(tape.position_seconds), stamp(tape.duration), "PLAY" if tape.playing else "PAUSE"]
	play_button.text = "PAUSE" if tape.playing else "PLAY"
	play_button.disabled = manual_mode

static func stamp(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
