extends Node

signal player_connected(peer_id: int, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal connection_attempted(was_successful: bool)
signal campaign_info_received(was_successful: bool)

const DEFAULT_PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 32

var players := {}
var campaign : Campaign

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_campaign(_campaign: Campaign, port = DEFAULT_PORT) -> Error:
	if _campaign == null:
		return ERR_INVALID_PARAMETER
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CONNECTIONS)
	if error:
		return error
	campaign = _campaign
	multiplayer.multiplayer_peer = peer

	var host_id = multiplayer.get_unique_id()
	var player_info = ProfileManager.player_info
	players[host_id] = player_info
	player_connected.emit(host_id, player_info)
	print("created game successfully")
	return OK

func join_campaign(address = DEFAULT_SERVER_IP, port = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	print("joined game successfully")
	return OK

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()

@rpc("authority", "reliable")
func receive_campaign_info(campaign_name: String, id: String, description: String = "", tags: Array[String] = []) -> void:
	print("Received campaign info:", campaign_name, id, " | ", multiplayer.get_unique_id())
	#var result := CampaignManager.load_or_create_campaign(id, campaign_name, description, tags)
	#if result.error != OK:
		#campaign_info_received.emit(false)
		#return 
	#campaign = result.value
	campaign_info_received.emit(true)

@rpc("any_peer", "reliable")
func request_campaign_info():
	if multiplayer.is_server():
		receive_campaign_info.rpc_id(multiplayer.get_remote_sender_id(), campaign.campaign_name, campaign.id, campaign.description, campaign.tags)

func _on_player_connected(id) -> void:
	_register_player.rpc_id(id, ProfileManager.player_info)

@rpc("any_peer", "reliable")
func _register_player(new_player_info) -> void:
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id) -> void:
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok() -> void:
	var peer_id = multiplayer.get_unique_id()
	var player_info = ProfileManager.player_info
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)
	request_campaign_info.rpc_id(1)
	var info_successful = await campaign_info_received
	if not info_successful:
		remove_multiplayer_peer()
		connection_attempted.emit(false)
		return
	connection_attempted.emit(true)

func _on_connected_fail() -> void:
	remove_multiplayer_peer()
	connection_attempted.emit(false)

func _on_server_disconnected() -> void:
	remove_multiplayer_peer()
	players.clear()
	server_disconnected.emit()
