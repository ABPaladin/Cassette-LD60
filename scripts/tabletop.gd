extends Node3D
signal return_to_menu
const UI = preload("res://scripts/ui_style.gd")
@onready var inspector = $InspectController
@onready var camera = $TabletopCamera
var ui: Control
var title: Label
var instructions: Label
var actions: HBoxContainer
var pencil_selected := false
var operation := "inspect"
var timeline: PanelContainer
var rewinder: Node
var ending: Node
var puzzle: Node
var fragment_panel: PanelContainer
var word_note: PanelContainer
var note_button: Button
var ending_started := false
var subtitle: Label
var subtitle_panel: PanelContainer
var subtitles_enabled := true
var subtitle_active := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	rewinder = preload("res://scripts/pencil_rewind.gd").new()
	add_child(rewinder)
	ending = preload("res://scripts/ending_sequence.gd").new()
	ending.noise_sound = preload("res://assets/audio/placeholder/rear_noise.wav")
	ending.gunshot_sound = preload("res://assets/audio/placeholder/shot.wav")
	ending.name = "EndingSequence"
	add_child(ending)
	ending.finished.connect(func(): return_to_menu.emit())
	ending.stage_changed.connect(_ending_audio)
	inspector.selection_changed.connect(_selection_changed)
	inspector.hover_changed.connect(func(object): title.text = object.display_name if object != null else "EMILY'S BELONGINGS / 1998")
	_setup_investigation()
	_setup_subtitles()
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null: audio.start_room($Objects/Cassette/TapeAudioController)

func _ending_audio(stage: String) -> void:
	ending.cue.bus = &"SFX"
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null and stage == "door": audio.stop_room()
	if stage == "fall":
		ending.cue.stream = preload("res://assets/audio/placeholder/rear_muffled.wav")
		ending.cue.play()

func _setup_investigation() -> void:
	puzzle = preload("res://scripts/investigation.gd").new()
	add_child(puzzle)
	puzzle.bind($Objects/Cassette/TapeAudioController)
	puzzle.puzzle_solved.connect(_puzzle_solved)
	word_note = preload("res://scripts/word_note.gd").new()
	ui.add_child(word_note)
	word_note.bind(puzzle)
	word_note.closed.connect(_restore_cassette_controls)
	fragment_panel = preload("res://scripts/fragment_panel.gd").new()
	ui.add_child(fragment_panel)
	fragment_panel.bind(puzzle)
	fragment_panel.closed.connect(_restore_cassette_controls)
	$Objects/Tamagotchi.sequence = $Objects/Tamagotchi.sequence.duplicate()
	$Objects/Tamagotchi.sequence.values = PackedStringArray(puzzle.data.correct_order)
	$Objects/Tamagotchi._update_screen()

func _restore_cassette_controls() -> void:
	if ending_started: return
	inspector.enabled = true
	actions.show()
	timeline.visible = inspector.selected != null and inspector.selected.object_id == "cassette"
	_refresh_subtitle()

func _setup_subtitles() -> void:
	# Reuse the pre-drag top-centre Label and timed-cue lookup, independently of clues.
	subtitle_panel = PanelContainer.new()
	subtitle_panel.position = Vector2(160,65)
	subtitle_panel.size = Vector2(640,0)
	subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0.02,0.015,0.01,.68)
	shade.content_margin_left = 12
	shade.content_margin_right = 12
	shade.content_margin_top = 6
	shade.content_margin_bottom = 6
	subtitle_panel.add_theme_stylebox_override("panel",shade)
	ui.add_child(subtitle_panel)
	subtitle = UI.label(subtitle_panel,"",18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color",Color(.94,.9,.8))
	var tape = $Objects/Cassette/TapeAudioController
	tape.position_changed.connect(_update_subtitle)
	tape.seeked.connect(func(seconds):
		subtitle_active = true
		_update_subtitle(seconds,tape.duration))
	tape.state_changed.connect(func(state):
		_sync_cassette_audio()
		if state == "PLAY": subtitle_active = true
		elif state == "STOP" or state == "END": subtitle_active = false
		# PAUSE intentionally retains the current line.
		_update_subtitle(tape.position_seconds,tape.duration))
	ui.visibility_changed.connect(_refresh_subtitle)
	timeline.visibility_changed.connect(_refresh_subtitle)
	for panel in ui.get_children():
		if panel is PanelContainer and panel != subtitle_panel and panel != timeline:
			panel.visibility_changed.connect(_refresh_subtitle)
	_update_subtitle(tape.position_seconds,tape.duration)

func _refresh_subtitle() -> void:
	if subtitle == null: return
	_sync_cassette_audio()
	var tape = $Objects/Cassette/TapeAudioController
	_update_subtitle(tape.position_seconds,tape.duration)

func _cassette_interface_open() -> bool:
	var listening: bool = inspector.selected != null and inspector.selected.object_id == "cassette" and operation in ["inspect","rewind"]
	var blocked: bool = not inspector.enabled or not ui.is_visible_in_tree() or not timeline.visible
	for panel in ui.get_children():
		if panel is PanelContainer and panel != subtitle_panel and panel != timeline and panel.is_visible_in_tree():
			blocked = true
	return listening and not blocked and not ending_started

func _sync_cassette_audio(force_pause: bool = false) -> void:
	# Shared mode gate: pausing never seeks or resumes, and leaves ambience alone.
	var tape = $Objects/Cassette/TapeAudioController
	var listening := not force_pause and _cassette_interface_open()
	if tape.playing and (not listening or operation == "rewind"):
		tape.pause()
	if not listening and rewinder != null and rewinder.active:
		rewinder.release()
	if fragment_panel != null and (force_pause or ending_started or not fragment_panel.is_visible_in_tree()):
		fragment_panel.replay.stop()

func _update_subtitle(seconds: float, _duration: float) -> void:
	var text := ""
	if _cassette_interface_open() and subtitle_active and subtitles_enabled:
		for entry in puzzle.data.captions:
			if seconds >= float(entry.start) and seconds < float(entry.end):
				var speaker := str(entry.get("speaker",""))
				text = (speaker + "\n" if not speaker.is_empty() else "") + str(entry.text)
				break
	subtitle.text = text
	subtitle_panel.visible = not text.is_empty()
	subtitle_panel.size = Vector2(640,0)

func _set_subtitles(value: bool) -> void:
	subtitles_enabled = value
	if subtitle != null:
		var tape = $Objects/Cassette/TapeAudioController
		_update_subtitle(tape.position_seconds,tape.duration)

func _open_word_note() -> void:
	if ending_started or rewinder.active or not puzzle.can_note(): return
	inspector.enabled = false
	inspector.dragging = false
	actions.hide()
	timeline.hide()
	word_note.open_note()

func _open_fragments() -> void:
	if ending_started: return
	if rewinder.active: _stop_rewind()
	inspector.enabled = false
	actions.hide()
	timeline.hide()
	fragment_panel.refresh()
	fragment_panel.show()

func _puzzle_solved(message: String) -> void:
	if ending_started: return
	ending_started = true
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null: audio.tension = true
	fragment_panel.replay.stop()
	fragment_panel.hide()
	inspector.leave()
	inspector.enabled = false
	ui.hide()
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var reveal := UI.label(layer,message,30)
	reveal.theme = UI.make_theme()
	reveal.add_theme_color_override("font_color",Color(.94,.90,.80))
	reveal.add_theme_constant_override("line_spacing",10)
	reveal.position = Vector2(80,170)
	reveal.size = Vector2(800,160)
	reveal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	await get_tree().create_timer(puzzle.data.reveal_seconds).timeout
	reveal.hide()
	await get_tree().create_timer(puzzle.data.suspense_seconds).timeout
	layer.queue_free()
	ending.begin()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UI.make_theme()
	layer.add_child(ui)
	title = UI.label(ui, "EMILY'S BELONGINGS / 1998", 20)
	title.position = Vector2(24, 18)
	instructions = UI.label(ui, "Click an object to inspect it.", 16)
	instructions.position = Vector2(24, 506)
	actions = HBoxContainer.new()
	actions.position = Vector2(24, 454)
	actions.add_theme_constant_override("separation", 10)
	ui.add_child(actions)
	timeline = preload("res://scripts/tape_timeline.gd").new()
	timeline.position = Vector2(420, 330)
	ui.add_child(timeline)
	timeline.bind($Objects/Cassette/TapeAudioController)
	timeline.hide()
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null:
		var sound_panel: PanelContainer = audio.make_controls(ui,Vector2(24,105))
		var subtitle_toggle := CheckButton.new()
		subtitle_toggle.text = "SUBTITLES"
		subtitle_toggle.button_pressed = subtitles_enabled
		subtitle_toggle.toggled.connect(_set_subtitles)
		sound_panel.get_child(0).add_child(subtitle_toggle)
		sound_panel.get_child(0).move_child(subtitle_toggle,0)
		var sound_button := UI.button(ui,"SOUND",func(): sound_panel.visible = not sound_panel.visible)
		sound_button.position = Vector2(24,61)
		sound_button.add_theme_font_size_override("font_size",14)
	#if OS.is_debug_build() and not OS.has_feature("web"):
		#var debug_button := UI.button(ui, "DEBUG: ENDING [F9]", _debug_ending)
		#debug_button.position = Vector2(714, 16)
		#debug_button.add_theme_font_size_override("font_size", 14)

func _selection_changed(object: Node3D) -> void:
	if rewinder != null and rewinder.active:
		rewinder.finish()
		$Objects/Cassette.manual_rewind = false
	operation = "inspect"
	timeline.visible = object != null and object.object_id == "cassette"
	_refresh_subtitle()
	for child in actions.get_children(): child.queue_free()
	if object == null:
		title.text = "EMILY'S BELONGINGS / 1998"
		instructions.text = "Click an object to inspect it."
		return
	title.text = object.display_name
	instructions.text = "Drag to rotate / wheel to zoom / ESC or right-click to return"
	UI.button(actions, "RETURN", inspector.leave)
	if object.object_id == "pencil":
		UI.button(actions, "USE ON CASSETTE", _use_pencil)
	if object.object_id == "cassette":
		note_button = UI.button(actions,"NOTE WORD",_open_word_note)
		UI.button(actions,"ARRANGE FRAGMENTS",_open_fragments)
		instructions.text = "Listen, PAUSE, then NOTE WORD. Use the pencil to find the moment again."
		if pencil_selected:
			UI.button(actions, "INSERT PENCIL", _begin_rewind)
	if object.object_id == "sketchbook":
		UI.button(actions, "OPEN / CLOSE", func(): object.set_open(not object.opened))
		UI.button(actions, "< PAGE", func(): object.turn_page(-1))
		UI.button(actions, "PAGE >", func(): object.turn_page(1))
	if object.object_id == "tamagotchi":
		instructions.text = "Click its three physical buttons / drag shell to rotate / ESC returns"

func _use_pencil() -> void:
	pencil_selected = true
	inspector.select($Objects/Cassette)
	_begin_rewind()

func _begin_rewind() -> void:
	if rewinder.active: return
	operation = "rewind"
	inspector.rotation_enabled = false
	$Objects/Cassette.manual_rewind = true
	rewinder.begin($Objects/Cassette, $Objects/Pencil, camera)
	camera.inspect_at($Objects/Cassette.rest_transform.origin + Vector3.UP * .68, 1.85)
	instructions.text = "Hold LMB and circle the reel: clockwise advances / counterclockwise rewinds."
	title.text = "PENCIL REWIND"
	for child in actions.get_children(): child.queue_free()
	UI.button(actions,"REMOVE PENCIL / LISTEN",_stop_rewind)
	UI.button(actions,"RETURN",inspector.leave)

func _stop_rewind() -> void:
	_selection_changed($Objects/Cassette)
	inspector.rotation_enabled = true
	camera.inspect_at($Objects/Cassette.global_position, $Objects/Cassette.inspect_distance)

func _process(_delta: float) -> void:
	if is_instance_valid(note_button): note_button.disabled = puzzle == null or not puzzle.can_note()
	timeline.manual_mode = rewinder != null and rewinder.active
	if rewinder != null and rewinder.active:
		var center: Vector2 = rewinder.center_on_screen()
		# Keep the analog strip close to the tool without covering its circular gesture.
		timeline.position = Vector2(clampf(center.x - 255, 14, 430), clampf(center.y + 110, 260, 336))
	else:
		timeline.position = Vector2(420, 330)

#func _debug_ending() -> void:
	#if not OS.is_debug_build() or OS.has_feature("web") or ending_started: return
	#ending_started = true
	#fragment_panel.hide()
	#fragment_panel.replay.stop()
	#ending.begin()

#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		#_debug_ending()
