extends Node
## Empty slots preserve the current scene; only supplied final art replaces a mesh.
@export var tabletop_model: PackedScene
@export var door_model: PackedScene
func _ready() -> void:
	_install("Tabletop",tabletop_model)
	_install("DoorPivot/Door",door_model)
func _install(path: NodePath, model: PackedScene) -> void:
	if model == null: return
	var target := get_parent().get_node(path) as MeshInstance3D
	target.mesh = null
	var visual := model.instantiate()
	visual.name = "VisualRoot"
	target.add_child(visual)
	get_parent().get_node("RetroPresentation").apply_to_model(visual)
