extends Button
class_name ButtonController

@export var action: EventQueueUI.UIAction

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	EventQueueUI.request_action(action)
