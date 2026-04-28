extends Button
class_name SessionInfoUI

@onready var _texture_rect: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/TextureRect
@onready var _session_name: Label = $PanelContainer/MarginContainer/VBoxContainer/SessionName
@onready var _session_desc: Label = $PanelContainer/MarginContainer/VBoxContainer/SessionDesc

func set_session_name(s_name: String) -> void:
	_session_name.text = s_name

func set_session_desc(s_desc: String) -> void:
	_session_desc.text = s_desc

func set_preview_image(path: String) -> void:
	pass


func _on_pressed() -> void:
	print("I was pressed! "+_session_name.text)
