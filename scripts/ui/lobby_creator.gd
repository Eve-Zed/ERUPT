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
	for campaign in CampaignManager.campaigns:
		path = CampaignManager.campaigns[campaign]
	var result = Campaign.load_campaign(path)
	if result.error != OK:
		push_error("Failed to create Lobby: Could not load campaign")
		return 
	NetworkManager.host_campaign(result.value, int(port.value))
	get_tree().change_scene_to_packed(GAME)
