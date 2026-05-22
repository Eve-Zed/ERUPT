extends Node
#Autoload as EventQueueUI

signal create_lobby_opened
signal join_lobby_opened
signal profile_opened
signal security_question_opened(pos_action: UIAction, neg_action: UIAction, text: String) 
signal main_menu_opened
signal lobby_created
signal lobby_joined
signal file_dialog_opened
signal campaigns_opened

enum UIAction {
	CREATE_LOBBY,
	JOIN_LOBBY,
	OPEN_PROFILE,
	QUIT_GAME_SQ,
	QUIT_GAME,
	MAIN_MENU,
	CREATE_LOBBY_START,
	JOIN_LOBBY_START,
	OPEN_FILE_DIALOG,
	SAVE_PROFILE,
	OPEN_SESSIONS
}

func request_action(action: UIAction) -> void:
	match action:
		UIAction.CREATE_LOBBY:
			create_lobby_opened.emit()
		UIAction.JOIN_LOBBY:
			join_lobby_opened.emit()
		UIAction.OPEN_PROFILE:
			profile_opened.emit()
		UIAction.QUIT_GAME_SQ:
			security_question_opened.emit(UIAction.QUIT_GAME,UIAction.MAIN_MENU,"_SQ_QUIT")
		UIAction.QUIT_GAME:
			get_tree().quit()
		UIAction.MAIN_MENU:
			main_menu_opened.emit()
		UIAction.CREATE_LOBBY_START:
			lobby_created.emit()
		UIAction.JOIN_LOBBY_START:
			lobby_joined.emit()
		UIAction.OPEN_FILE_DIALOG:
			file_dialog_opened.emit()
		UIAction.OPEN_SESSIONS:
			campaigns_opened.emit()
