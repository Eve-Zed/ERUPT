extends Node2D
class_name GameManager

@onready var label: Label = $UI/Label

func start_game() -> void:
	print("startet game")
	
func _ready() -> void:
	NetworkManager.player_connected.connect(_add_to_label)
	NetworkManager.player_disconnected.connect(_update_label)
	_update_label()
	
func _update_label(_id=0) -> void:
	#NetworkManager.campaign.campaign_name + 
	label.text = NetworkManager.campaign.campaign_name + "\n Joined Players:"
	for id in NetworkManager.players:
		var player = NetworkManager.players[id]
		label.text += "\n" + player["name"] + " | id:" + str(id)

func _add_to_label(_player_id: int, player_info) -> void:
	label.text += "\n" + player_info["name"] + " | id:" + str(_player_id)
