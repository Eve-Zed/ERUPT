extends Control
class_name SecurityQuestion

@onready var label: Label = $PanelContainer/MarginContainer/VBoxContainer/Label
@onready var yes_button: ButtonController = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/AspectRatioContainer/YesButton
@onready var no_button: ButtonController = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/AspectRatioContainer2/NoButton

func set_text(text: String) -> void:
	label.text = text

func set_pos_action(action: EventQueueUI.UIAction) -> void:
	yes_button.action = action

func set_neg_action(action: EventQueueUI.UIAction) -> void:
	no_button.action = action
