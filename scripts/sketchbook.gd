extends "res://scripts/interactable.gd"
signal page_changed(index: int)
@export var pages: Array[Resource] = [preload("res://resources/pages/notes.tres"), preload("res://resources/pages/drawings.tres"), preload("res://resources/pages/clues.tres")]
@export var investigation: Resource = preload("res://resources/investigation.tres")
@export_range(.2, .85) var turn_threshold := .42
@export var turn_smoothing := 18.0
@export var turn_finish_seconds := .28
@export var page_size := Vector2(.94, 1.14)
var opened := false
var page_index := 0
var cover_tween: Tween
var page_label: Label3D
var page_art: Sprite3D
var left_surface: Node3D
var turn_pivot: Node3D
var turn_front: Node3D
var turn_back: Node3D
var highlights: Array[Node3D] = []
var page_dragging := false
var turn_busy := false
var turn_direction := 0
var turn_progress := 0.0
var drag_start := Vector2.ZERO
var drag_axis := Vector2.ZERO
var turn_tween: Tween

func _ready() -> void:
	super._ready()
	_add_page_content($Visual/PageSurface)
	page_label = $Visual/PageSurface/Writing
	page_art = $Visual/PageSurface/Artwork
	left_surface = Node3D.new()
	left_surface.name = "LeftPageSurface"
	left_surface.position = Vector3(-page_size.x,.032,0)
	visual.add_child(left_surface)
	_add_page_content(left_surface)
	turn_pivot = Node3D.new()
	turn_pivot.name = "PageTurnPivot"
	turn_pivot.position = Vector3(-page_size.x*.5,.047,0)
	visual.add_child(turn_pivot)
	turn_front = Node3D.new()
	turn_front.position.x = page_size.x*.5
	turn_pivot.add_child(turn_front)
	_add_page_content(turn_front)
	turn_back = Node3D.new()
	turn_back.position.x = page_size.x*.5
	turn_back.rotation.z = PI
	turn_pivot.add_child(turn_back)
	_add_page_content(turn_back,false)
	turn_pivot.hide()
	for side in [1,-1]:
		var marker := MeshInstance3D.new()
		var triangle := ImmediateMesh.new()
		triangle.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in [Vector3.ZERO, Vector3(-side*.12,0,0), Vector3(0,0,-.12)]: triangle.surface_add_vertex(point)
		triangle.surface_end()
		marker.mesh = triangle
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.cull_mode = BaseMaterial3D.CULL_DISABLED
		ink.albedo_color = Color(.85,.75,.49)
		marker.material_override = ink
		marker.position = Vector3(side*(page_size.x*.5-.015),.012,page_size.y*.5-.015)
		($Visual/PageSurface if side == 1 else left_surface).add_child(marker)
		marker.hide()
		highlights.append(marker)
	_show_page()

func _add_page_content(surface: Node3D, paper: bool = true) -> void:
	if paper:
		var sheet := MeshInstance3D.new()
		sheet.name = "Paper"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(page_size.x,.002,page_size.y)
		sheet.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(.69,.64,.48)
		material.roughness = 1.0
		sheet.material_override = material
		surface.add_child(sheet)
	var writing := Label3D.new()
	writing.name = "Writing"
	writing.font = preload("res://resources/interface_font.tres")
	writing.outline_size = 0
	writing.modulate = Color(.12,.10,.09)
	writing.rotation.x = -PI/2.0
	writing.position.y = .004
	writing.double_sided = false
	surface.add_child(writing)
	var art := Sprite3D.new()
	art.name = "Artwork"
	art.rotation.x = -PI/2.0
	art.position.y = .006
	art.double_sided = false
	art.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	surface.add_child(art)

func _render_page(surface: Node3D, index: int) -> void:
	surface.visible = opened and index >= 0 and index < pages.size()
	if not surface.visible: return
	var page: Resource = pages[index]
	if page.artwork == null and not page.artwork_path.is_empty() and ResourceLoader.exists(page.artwork_path):
		page.artwork = load(page.artwork_path) as Texture2D
	var writing: Label3D = surface.get_node("Writing")
	var art: Sprite3D = surface.get_node("Artwork")
	writing.text = page.title + "\n\n" + (investigation.clue_text() if page.investigation_clues else page.text) + "\n\n- %d -" % (index+1)
	writing.position.z = 0.0
	writing.font_size = 28
	writing.pixel_size = .0021
	art.texture = page.artwork
	art.visible = page.artwork != null
	if page.artwork != null:
		art.position.z = -.16
		art.pixel_size = minf(.86/page.artwork.get_width(), .74/page.artwork.get_height())
		writing.text = page.title + "\n" + page.artwork_caption
		writing.position.z = .39
		writing.font_size = 20
		writing.pixel_size = .0018

func _show_page() -> void:
	_render_page($Visual/PageSurface,page_index)
	_render_page(left_surface,page_index-1)

func set_open(value: bool) -> void:
	_cancel_turn()
	opened = value
	if cover_tween: cover_tween.kill()
	cover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cover_tween.tween_property($Visual/CoverPivot,"rotation:z",2.75 if opened else 0.0,.4)
	_show_page()

func turn_page(direction: int) -> void:
	if not opened or pages.is_empty() or turn_busy: return
	page_index = clampi(page_index+direction,0,pages.size()-1)
	_show_page()
	page_changed.emit(page_index)

func corner_position(direction: int) -> Vector3:
	return visual.to_global(Vector3(page_size.x*.5-.04 if direction > 0 else -page_size.x*1.5+.04,.04,page_size.y*.5-.06))

func corner_at(pixel: Vector2, camera: Camera3D) -> int:
	if not inspected or not opened or turn_busy: return 0
	var origin := visual.to_local(camera.project_ray_origin(pixel))
	var ray := visual.global_basis.inverse()*camera.project_ray_normal(pixel)
	if origin.y < .03 or absf(ray.y) < .0001: return 0
	var distance := (.035-origin.y)/ray.y
	if distance < 0: return 0
	var point := origin+ray*distance
	if absf(point.z) < page_size.y*.28 or absf(point.z) > page_size.y*.5+.04: return 0
	if page_index < pages.size()-1 and point.x > page_size.x*.25 and point.x < page_size.x*.5+.04: return 1
	if page_index > 0 and point.x < -page_size.x*1.25 and point.x > -page_size.x*1.5-.04: return -1
	return 0

func inspection_input(event: InputEvent, camera: Camera3D) -> bool:
	if page_dragging:
		if event is InputEventMouseMotion:
			turn_progress = clampf((event.position-drag_start).dot(drag_axis)/drag_axis.length_squared(),0,1)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish_turn(turn_progress >= turn_threshold)
		return true
	if turn_busy: return event is InputEventMouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var direction := corner_at(event.position,camera)
		if direction == 0: return false
		turn_direction = direction
		drag_start = event.position
		# Project the binding-crossing motion, so gestures still work after rotating the book.
		var target := camera.unproject_position(corner_position(-direction))
		drag_axis = target-drag_start
		if drag_axis.length_squared() < 100.0: return false
		page_dragging = true
		turn_busy = true
		turn_progress = 0
		turn_pivot.rotation.z = 0 if direction > 0 else PI
		turn_pivot.show()
		var moving_index := page_index if direction > 0 else page_index-1
		_render_page(turn_front,moving_index)
		_render_page(turn_back,moving_index)
		if direction > 0: _render_page($Visual/PageSurface,page_index+1)
		else: _render_page(left_surface,page_index-2)
		return true
	return false

func _finish_turn(commit: bool) -> void:
	page_dragging = false
	var target := (PI if turn_direction > 0 else 0.0) if commit else (0.0 if turn_direction > 0 else PI)
	turn_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	turn_tween.tween_property(turn_pivot,"rotation:z",target,turn_finish_seconds)
	turn_tween.tween_callback(func():
		if commit:
			page_index += turn_direction
			page_changed.emit(page_index)
		turn_busy = false
		turn_pivot.hide()
		_show_page())

func _cancel_turn() -> void:
	if turn_tween: turn_tween.kill()
	page_dragging = false
	turn_busy = false
	if turn_pivot != null: turn_pivot.hide()
	for marker in highlights: marker.hide()

func _process(delta: float) -> void:
	super._process(delta)
	if page_dragging:
		var angle := turn_progress*PI if turn_direction > 0 else (1.0-turn_progress)*PI
		turn_pivot.rotation.z = lerpf(turn_pivot.rotation.z,angle,1.0-exp(-turn_smoothing*delta))
	var side := 0
	if inspected and opened and not turn_busy and get_viewport().gui_get_hovered_control() == null:
		side = corner_at(get_viewport().get_mouse_position(),get_viewport().get_camera_3d())
	for i in range(highlights.size()): highlights[i].visible = side == (1 if i == 0 else -1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and page_dragging: _finish_turn(false)

func end_inspection() -> void:
	set_open(false)
	super.end_inspection()

func begin_inspection() -> Vector3:
	# The open spread is centred on its binding, not the closed right-hand cover.
	return super.begin_inspection() + Vector3.LEFT * page_size.x * .5
