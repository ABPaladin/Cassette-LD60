extends Resource
@export var title := ""
@export_multiline var text := ""
@export var artwork: Texture2D
@export var artwork_full_page := false
@export var investigation_clues := false
@export_file("*.png", "*.jpg", "*.webp") var artwork_path := ""
@export_multiline var artwork_caption := ""
