extends Node

@onready
var campaigns_options_button: OptionButton = $OptionButton
@onready
var file_dialog: FileDialog = $FileDialog
@onready
var button: Button = $Button

func _ready() -> void:
	file_dialog.files_selected.connect(_on_file_dialog_confirmed)
	var id := 0
	for s in CampaignManager.campaigns:
		campaigns_options_button.add_item(CampaignManager.campaigns[s].get_file(),id)
		id += 1

func _on_button_pressed() -> void:
	file_dialog.visible = true

func _on_file_dialog_confirmed(paths: PackedStringArray) -> void:
	for p in paths:
		print(p)
