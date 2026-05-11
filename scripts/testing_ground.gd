extends Node



func _ready() -> void:
	
	#SessionManager.delete_session(SessionManager.sessions.keys()[0])
	SessionManager.create_session("Honey Heist Oneshot")
	var res := SessionManager.load_session(SessionManager.sessions.keys()[0])
	if res.error == OK:
		print(res.value.session_name)
