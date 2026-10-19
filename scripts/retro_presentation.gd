extends Node
## Uses the installed addon directly. Never edits or duplicates its shader source.
@export var mesh_shader: Shader = preload("res://addons/psx_shader/shaders/psx.gdshader")
@export var screen_shader: Shader = preload("res://addons/psx_shader/shaders/psx_screen.gdshader")
@export_range(1.0, 6.0) var pixel_size := 2.0
@export_range(0.0, 1.0) var vertex_snap := 0.30
@export_range(0.0, 0.3) var vertex_jitter := 0.025
@export_range(1, 8) var color_bits := 5
@export_range(0.0, 1.0) var dithering := 0.28
@export_range(0.0, 0.2) var grain := 0.012
@export_range(0.0, 1.0) var vignette := 0.30
var screen_material: ShaderMaterial
var materials: Array[ShaderMaterial] = []

func _ready() -> void:
	apply_to_model(get_parent())
	var layer := CanvasLayer.new()
	layer.layer = 1 # game HUD/menu are on 10, ending on 30, fades on 100.
	add_child(layer)
	var screen := ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_material = ShaderMaterial.new()
	screen_material.shader = screen_shader
	screen_material.set_shader_parameter("screen_pixel_size", pixel_size)
	screen_material.set_shader_parameter("screen_color_bits", color_bits)
	screen_material.set_shader_parameter("screen_dither", dithering)
	screen_material.set_shader_parameter("grain", grain)
	screen_material.set_shader_parameter("vignette", vignette)
	screen.material = screen_material
	layer.add_child(screen)
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

func apply_to_model(root: Node) -> void:
	# Works for replacement models too; preserves textures, colors and custom shaders.
	if root is MeshInstance3D and root.mesh != null:
		if root.material_override is StandardMaterial3D:
			root.material_override = _convert(root.material_override)
		elif root.material_override == null:
			for surface in range(root.mesh.get_surface_count()):
				var original = root.get_active_material(surface)
				if original is StandardMaterial3D:
					root.set_surface_override_material(surface, _convert(original))
	for child in root.get_children(): apply_to_model(child)

func _convert(original: StandardMaterial3D) -> Material:
	# Dark textured plastic needs its PBR highlights; retain the screen PSX pass.
	if original.get_meta("preserve_pbr_lighting", false): return original
	var material := ShaderMaterial.new()
	material.shader = mesh_shader
	if original.blend_mode == BaseMaterial3D.BLEND_MODE_ADD:
		material.shader = preload("res://addons/psx_shader/shaders/psx_additive.gdshader")
	elif original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		material.shader = preload("res://addons/psx_shader/shaders/psx_transparent.gdshader")
	elif original.cull_mode == BaseMaterial3D.CULL_DISABLED:
		material.shader = preload("res://addons/psx_shader/shaders/psx_double_sided.gdshader")
	material.set_shader_parameter("albedo_color", original.albedo_color)
	if original.albedo_texture != null: material.set_shader_parameter("albedo_tex", original.albedo_texture)
	if original.emission_enabled and original.emission_texture != null:
		material.set_shader_parameter("emission_tex", original.emission_texture)
		material.set_shader_parameter("emission_strength", original.emission_energy_multiplier)
	material.set_shader_parameter("pixel_size", pixel_size)
	material.set_shader_parameter("snap_strength", vertex_snap)
	material.set_shader_parameter("jitter", vertex_jitter)
	material.set_shader_parameter("jitter_rate", 12.0)
	material.set_shader_parameter("affine", 0.25)
	# Color reduction/dither occur once, in the existing screen shader.
	material.set_shader_parameter("color_bits", 8)
	material.set_shader_parameter("dither_amount", 0.0)
	material.set_shader_parameter("vertex_color_mix", 0.0)
	material.set_shader_parameter("glow", .06)
	material.set_shader_parameter("lit", 0.0 if original.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED else 1.0)
	materials.append(material)
	return material

func set_distressed(enabled: bool) -> void:
	screen_material.set_shader_parameter("grain", .13 if enabled else grain)
	screen_material.set_shader_parameter("screen_color_bits", 3 if enabled else color_bits)
	screen_material.set_shader_parameter("screen_dither", .6 if enabled else dithering)
	for material in materials:
		material.set_shader_parameter("jitter", .25 if enabled else vertex_jitter)
