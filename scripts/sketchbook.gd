extends "res://scripts/interactable.gd"
signal page_changed(index: int)
@export var pages: Array[Resource] = [preload("res://resources/pages/notes.tres"), preload("res://resources/pages/drawings.tres"), preload("res://resources/pages/clues.tres")]
var opened := false
var page_index := 0
var cover_tween: Tween
var page_label: Label3D
var page_art: Sprite3D
@export var investigation: Resource = preload("res://resources/investigation.tres")

func _ready() -> void:
	super._ready()
	page_label = Label3D.new()
	page_label.font = preload("res://resources/interface_font.tres")
	page_label.font_size = 28
	page_label.pixel_size = .0021
	page_label.outline_size = 0
	page_label.modulate = Color(.12,.10,.09)
	page_label.rotation.x = -PI / 2.0
	$Visual/PageSurface.add_child(page_label)
	page_art = Sprite3D.new()
	page_art.rotation.x = -PI / 2.0
	page_art.position.y = .003
	page_art.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	$Visual/PageSurface.add_child(page_art)
	_show_page()

func set_open(value: bool) -> void:
	opened = value
	if cover_tween: cover_tween.kill()
	cover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cover_tween.tween_property($Visual/CoverPivot, "rotation:z", 2.75 if opened else 0.0, .4)
	_show_page()

func turn_page(direction: int) -> void:
	if not opened or pages.is_empty(): return
	page_index = clampi(page_index + direction, 0, pages.size() - 1)
	_show_page()
	page_changed.emit(page_index)
	var flutter := create_tween()
	flutter.tween_property($Visual/PageSurface, "position:y", .075, .10)
	flutter.tween_property($Visual/PageSurface, "position:y", .03, .12)

func _show_page() -> void:
	$Visual/PageSurface.visible = opened
	if pages.is_empty(): return
	var page: Resource = pages[page_index]
	if page.artwork == null and not page.artwork_path.is_empty() and ResourceLoader.exists(page.artwork_path):
		page.artwork = load(page.artwork_path) as Texture2D
	page_label.text = page.title + "\n\n" + (investigation.clue_text() if page.investigation_clues else page.text) + "\n\n— %d —" % (page_index + 1)
	page_art.texture = page.artwork
	page_art.visible = page.artwork != null
	page_label.visible = true
	page_label.position.z = 0.0
	page_label.pixel_size = .0021
	page_label.font_size = 28
	if page.artwork != null:
		page_art.position.z = -.16
		page_art.pixel_size = minf(.86 / page.artwork.get_width(), .74 / page.artwork.get_height())
		page_label.text = page.title + "\n" + page.artwork_caption
		page_label.position.z = .39
		page_label.font_size = 20
		page_label.pixel_size = .0018

func end_inspection() -> void:
	set_open(false)
	super.end_inspection()
