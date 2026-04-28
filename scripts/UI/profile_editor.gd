extends Control
class_name ProfileEditor

@onready var file_dialog: FileDialog = $FileDialog
@onready var texture_rect: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/TextureRect

func _ready() -> void:
	EventQueueUI.file_dialog_opened.connect(_open_file_dialog)
	file_dialog.file_selected.connect(_validate_image)

func _open_file_dialog() -> void:
	file_dialog.visible = true

func _validate_image(path: String) -> void:
	print(path)
	var img := Image.new()
	var err := img.load(path)
	if err == OK:
		if img.get_size() != Vector2i(256,256):
			img.resize(256,256, Image.INTERPOLATE_LANCZOS)
			print("image resized")
		var texture = ImageTexture.create_from_image(img)
		texture_rect.texture = texture
