extends Control
class_name MainMenuManager

enum Menus {
	MAIN_MENU,
	CREATE_LOBBY_MENU,
	JOIN_LOBBY_MENU,
	PROFILE_MENU,
	SECURITY_QUESTION,
	SESSION_EDITOR
}

@onready var main_menu: Control = $"."
@onready var security_question: Control = $"../QuitSQ"
@onready var create_lobby: Control = $"../CreateLobby"
@onready var join_lobby: Control = $"../JoinLobby"
@onready var edit_profile: Control = $"../EditProfile"
@onready var session_editor: Control = $"../SessionEditor"


func _ready() -> void:
	EventQueueUI.security_question_opened.connect(_show_security_question)
	EventQueueUI.main_menu_opened.connect(_open_main_menu)
	EventQueueUI.create_lobby_opened.connect(_open_create_lobby)
	EventQueueUI.join_lobby_opened.connect(_open_join_lobby)
	EventQueueUI.profile_opened.connect(_open_edit_profile)
	EventQueueUI.sessions_opened.connect(_open_session_editor)

func _show_security_question(pos_action: EventQueueUI.UIAction, neg_action: EventQueueUI.UIAction, text: String) -> void:
	var sq = security_question as SecurityQuestion
	sq.set_text(text)
	sq.set_pos_action(pos_action)
	sq.set_neg_action(neg_action)
	_show_Menu(Menus.SECURITY_QUESTION)

func _open_main_menu() -> void:
	_show_Menu(Menus.MAIN_MENU)

func _open_create_lobby() -> void:
	_show_Menu(Menus.CREATE_LOBBY_MENU)

func _open_join_lobby() -> void:
	_show_Menu(Menus.JOIN_LOBBY_MENU)

func _open_edit_profile() -> void:
	_show_Menu(Menus.PROFILE_MENU)

func _open_session_editor() -> void:
	_show_Menu(Menus.SESSION_EDITOR)

func _show_Menu(menu: Menus) -> void:
	main_menu.visible = menu == Menus.MAIN_MENU
	security_question.visible = menu == Menus.SECURITY_QUESTION
	create_lobby.visible = menu == Menus.CREATE_LOBBY_MENU
	join_lobby.visible = menu == Menus.JOIN_LOBBY_MENU
	edit_profile.visible = menu == Menus.PROFILE_MENU
	session_editor.visible = menu == Menus.SESSION_EDITOR
