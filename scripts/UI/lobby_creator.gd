extends Control
class_name LobbyCreator

const GAME = preload("uid://b6cqk16mdygwl")

@onready var server_address: Label = $PanelContainer/MarginContainer/VBoxContainer/ServerAddress
@onready var port: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/PortSpinBox

func _ready() -> void:
	EventQueueUI.lobby_created.connect(_on_start_game)

func _process(_delta: float) -> void:
	if not Input.is_anything_pressed():
		server_address.text = "127.0.0.1:"+str(int(port.value))

func _on_start_game() -> void:
	var path := ""
	for session in SessionManager.sessions:
		path = SessionManager.sessions[session]
	var result = Session.load_session(path)
	if result.error != OK:
		push_error("Failed to create Lobby: Could not load session")
		return 
	NetworkManager.host_session(result.value, int(port.value))
	get_tree().change_scene_to_packed(GAME)
