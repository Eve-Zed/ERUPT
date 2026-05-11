extends Node

const SESSIONS_PATH := "user://sessions"
const INFO_NAME := "session_info.json"

const CREATE_SESSION_ERROR := "Could not create session: "

var _sessions: Dictionary[String, String] = {} 	#Session_id -> Session_path
var _active_session: Session = null 			#So the session doesn't need to be loaded with every operation

var sessions: Dictionary[String, String]: 
	get:
		return _sessions.duplicate(true)
var active_session_id: String:
	get:
		if _active_session == null:
			return ""
		return _active_session.session_id
var active_session: Session:
	get:
		return _active_session

func _ready() -> void:
	_sessions = _get_sessions_from_disc()

func create_session(session_name: String) -> Error:
	var res := Session.create_session(session_name)
	if res.error != OK:
		push_error(CREATE_SESSION_ERROR + error_string(res.error))
		return res.error
	var session := res.value as Session
	_sessions[session.session_id] = session.session_path
	_active_session = session
	Changelog.log("sessions.log","Created new session %s with ID %s at %s" % 
	[session.session_name, session.session_id, session.session_path])
	return OK

func load_session(id: String) -> Result:
	var res := Session.load_session(sessions[id])
	if res.error != OK:
		return Result.new(res.error)
	var session = res.value as Session
	return Result.new(OK, session)

func delete_session(id: String) -> Error:
	FileUtils.remove_recursive(sessions[id])
	Changelog.log("sessions.log","Deleted session with ID %s at %s" % [id, sessions[id]])
	_sessions.erase(id)
	if active_session_id == id:
		_active_session = null
	return OK

func _get_sessions_from_disc() ->  Dictionary[String, String]:
	var session_dict: Dictionary[String, String] = {}
	var session_dirs := DirAccess.get_directories_at(SESSIONS_PATH)
	for session in session_dirs:
		if FileAccess.file_exists(SESSIONS_PATH.path_join(session).path_join(INFO_NAME)):
			var result := Session.load_session_info(SESSIONS_PATH.path_join(session))
			if result.error == OK and result.value.has("id"):
				session_dict[result.value["id"]] = SESSIONS_PATH.path_join(session)
	return session_dict
