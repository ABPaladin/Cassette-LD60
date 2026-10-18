extends StaticBody3D
## Model replacement contract: Visual/Model is art; collision and gameplay stay here.
signal inspection_changed(inspected: bool)
@export var object_id := "object"
@export var display_name := "Object"
@export var inspect_distance := 1.35
@export var lift_height := 0.55
@export var replacement_model: PackedScene
## Optional moving mesh replacements. Keep the named anchors and their collision.
@export var replacement_parts: Dictionary[NodePath, PackedScene] = {}
@onready var visual: Node3D = $Visual
var rest_transform: Transform3D
var rest_visual: Transform3D
var inspected := false
var hovered := false
var movement: Tween

func _ready() -> void:
	add_to_group("interactable")
	rest_transform = global_transform
	rest_visual = visual.transform
	if replacement_model != null:
		$Visual/Model.hide()
		visual.add_child(replacement_model.instantiate())
	for path in replacement_parts:
		var anchor := get_node_or_null(path)
		if anchor == null or not visual.is_ancestor_of(anchor):
			push_warning("Model part needs a child of Visual: " + str(path))
			continue
		if anchor is MeshInstance3D: anchor.mesh = null
		if replacement_parts[path] != null: anchor.add_child(replacement_parts[path].instantiate())

func _process(delta: float) -> void:
	var wanted := rest_visual.basis.get_scale() * (1.025 if hovered and not inspected else 1.0)
	visual.scale = visual.scale.lerp(wanted, 1.0 - exp(-12.0 * delta))

func set_hover(value: bool) -> void:
	hovered = value

func begin_inspection() -> Vector3:
	if movement: movement.kill()
	inspected = true
	hovered = false
	var point := rest_transform.origin + Vector3.UP * lift_height
	movement = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	movement.tween_property(self, "global_position", point, 0.35)
	inspection_changed.emit(true)
	return point

func end_inspection() -> void:
	if movement: movement.kill()
	inspected = false
	movement = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	movement.tween_property(self, "global_transform", rest_transform, 0.35)
	movement.tween_property(visual, "transform", rest_visual, 0.35)
	inspection_changed.emit(false)

func rotate_model(relative: Vector2) -> void:
	visual.rotate_y(relative.x * 0.008)
	visual.rotate_object_local(Vector3.RIGHT, relative.y * 0.008)

func reset_model_rotation() -> void:
	visual.transform = rest_visual
