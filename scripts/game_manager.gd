extends Node
signal state_changed(state: String)
var state := ""
var content: Node
var curtain: ColorRect
var busy := false
@export var transition_seconds := 0.4

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	curtain = ColorRect.new()
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.color = Color(0,0,0,0)
	layer.add_child(curtain)
	_show_menu()
	if OS.has_feature("web_qa") and OS.has_feature("web"):
		add_child(preload("res://scripts/web_test_probe.gd").new())

func _replace(path: String, next_state: String) -> Node:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = load(path).instantiate()
	add_child(content)
	state = next_state
	state_changed.emit(state)
	return content

func _fade(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", alpha, transition_seconds)
	await tween.finished

func _show_menu() -> void:
	var menu = _replace("res://scenes/main_menu.tscn", "menu")
	menu.start_requested.connect(start_intro)

func start_intro() -> void:
	if busy: return
	busy = true
	await _fade(1.0)
	var intro = _replace("res://scenes/intro_sequence.tscn", "intro")
	intro.finished.connect(enter_tabletop)
	await _fade(0.0)
	busy = false
	if intro.done: enter_tabletop()

func enter_tabletop() -> void:
	if busy: return
	busy = true
	await _fade(1.0)
	var table = _replace("res://scenes/tabletop.tscn", "tabletop")
	if table.has_signal("return_to_menu"): table.return_to_menu.connect(return_to_menu)
	# Brief warm light transition, no extra post-processing shader.
	curtain.color = Color(.35,.23,.12,1.0)
	await _fade(0.0)
	curtain.color = Color(0,0,0,0)
	busy = false

func return_to_menu() -> void:
	if busy: return
	busy = true
	await _fade(1.0)
	_show_menu()
	await _fade(0.0)
	busy = false
