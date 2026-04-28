extends Node

const SESSIONS_PATH := "user://sessions"
const SHARED_FILES_PATH := "user://shared"
const GLOBAL_CACHE_PATH := "user://global"

const INDEX_NAME := "index.json"
const MANIFEST_NAME := "manifest.json"
const INFO_NAME := "session_info.json"

var _sessions: Dictionary[String, String] = {} #Session_id -> Session_path
var _num_sessions: int = 0

var sessions: Dictionary[String, String]: 
	get:
		return _sessions.duplicate(true)
var num_sessions: int = 0:
	get:
		return _num_sessions

func _ready() -> void:
	_sessions = _get_sessions_from_disc()
	_num_sessions = _sessions.size()

func register_session(session: Session) -> void:
	#TODO regsiter stuff
	_num_sessions += 1

func load_or_create_session(id: String, session_name: String = "", description: String = "", tags: Array[String] = []) -> Result:
	if sessions.has(id):
		var l_res := Session.load_session(sessions[id])
		if l_res.error != OK:
			return Result.new(l_res.error)
		var session = l_res.value as Session
		var err := session.update_session_info(session_name, description, tags)
		if err != OK:
			return Result.new(err)
		return Result.new(OK,session)
	var c_res := Session.create_session(session_name, id)
	if c_res.error != OK:
		return Result.new(c_res.error)
	var session_ = c_res.value as Session
	var err_ := session_.update_session_info(session_name, description, tags)
	if err_ != OK:
		return Result.new(err_)
	return Result.new(OK,session_)

func _get_sessions_from_disc() ->  Dictionary[String, String]:
	var session_dict: Dictionary[String, String] = {}
	var session_dirs := DirAccess.get_directories_at(SESSIONS_PATH)
	for session in session_dirs:
		if FileAccess.file_exists(SESSIONS_PATH.path_join(session).path_join(INDEX_NAME)) \
		and FileAccess.file_exists(SESSIONS_PATH.path_join(session).path_join(INFO_NAME)):
			var result := Session.load_session_info(SESSIONS_PATH.path_join(session))
			if result.error == OK and result.value.has("id"):
				session_dict[result.value["id"]] = SESSIONS_PATH.path_join(session)
	return session_dict
