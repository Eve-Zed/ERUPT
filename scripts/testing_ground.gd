extends Node



func _ready() -> void:
	
	print(str(SessionManager.save_file_in_session("/home/evezed/Projects/Godot/ERUPT/icon.svg",SessionManager.sessions.keys()[0])))
