extends Control
class_name LobbyJoiner

const IPV4_REGEX := r"^(\d{1,3}\.){3}\d{1,3}$"

const GAME = preload("uid://b6cqk16mdygwl")

@onready var server_address: Label = $PanelContainer/MarginContainer/VBoxContainer/ServerAddress
@onready var port_spin_box: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/PortSpinBox
@onready var ip_line_edit: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/IPLineEdit
@onready var name_line_edit: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/NameLineEdit

var port: int
var ip: String

func _ready() -> void:
	EventQueueUI.lobby_joined.connect(_on_start_game)
	port = int(port_spin_box.value)
	ip = ip_line_edit.placeholder_text
	ProfileManager.set_profile_name(name_line_edit.placeholder_text)

func _on_name_line_edit_text_changed(new_text: String) -> void:
	var new_name = new_text
	if new_name.is_empty():
		new_name = name_line_edit.placeholder_text
	ProfileManager.set_profile_name(new_name)

func _on_port_spin_box_value_changed(value: float) -> void:
	port = int(value)
	_update_address_label()

func _on_ip_line_edit_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		return
	var regex = RegEx.create_from_string(IPV4_REGEX)
	if regex.search(new_text) != null:
		ip = new_text
		_update_address_label()
	else:
		ip = ip_line_edit.placeholder_text
		_update_address_label()
		ip_line_edit.text = ""

func _update_address_label() -> void:
	server_address.text = ip+":"+str(port)

func _on_start_game() -> void:
	NetworkManager.join_session(ip,port)
	visible = false
	var connection_successful = await NetworkManager.connection_attempted
	if connection_successful:
		get_tree().change_scene_to_packed(GAME)
	else:
		visible = true
