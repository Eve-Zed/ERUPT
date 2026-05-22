extends Button
class_name CampaignInfoUI

@onready var _texture_rect: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/TextureRect
@onready var _campaign_name: Label = $PanelContainer/MarginContainer/VBoxContainer/CampaignName
@onready var _description: Label = $PanelContainer/MarginContainer/VBoxContainer/CampaignDesc

func set_campaign_name(s_name: String) -> void:
	_campaign_name.text = s_name

func set_description(s_desc: String) -> void:
	_description.text = s_desc

func set_preview_image(path: String) -> void:
	pass


func _on_pressed() -> void:
	print("I was pressed! "+_campaign_name.text)
