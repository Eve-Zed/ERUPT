extends Node

const SESSIONS_PATH := "user://sessions"

const INFO_NAME := "session_info.json"

const CREATE_SESSION_ERROR := "Could not create session: "

var _sessions: Dictionary[String, String] = {} #Session_id -> Session_path
var _active_session: Session = null #So the session doesn't need to be loaded with every operation

var sessions: Dictionary[String, String]: 
	get:
		return _sessions.duplicate(true)
#var num_sessions: int:
	#get:
		#return _sessions.size()
var active_session_id: String:
	get:
		if _active_session == null:
			return ""
		return _active_session.session_id

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
	return OK

func load_session(id: String) -> Result:
	var res := Session.load_session(sessions[id])
	if res.error != OK:
		return Result.new(res.error)
	var session = res.value as Session
	return Result.new(OK, session)

func delete_session(id: String) -> Error:
	FileUtils.remove_recursive(sessions[id])
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

#func load_or_create_session(id: String, session_name: String = "", description: String = "", tags: Array[String] = []) -> Result:
	#if sessions.has(id):
		#var l_res := Session.load_session(sessions[id])
		#if l_res.error != OK:
			#return Result.new(l_res.error)
		#var session = l_res.value as Session
		#var err := session.update_session_info(session_name, description, tags)
		#if err != OK:
			#return Result.new(err)
		#return Result.new(OK,session)
	#var c_res := Session.create_session(session_name, id)
	#if c_res.error != OK:
		#return Result.new(c_res.error)
	#var session_ = c_res.value as Session
	#var err_ := session_.update_session_info(session_name, description, tags)
	#if err_ != OK:
		#return Result.new(err_)
	#return Result.new(OK,session_)

#func save_file_in_session(file_path: String, session_id: String) -> Error:
	#if active_session_id != session_id:
		#var res := load_session(session_id)
		#if res.value == null:
			#return res.error
		#_active_session = res.value
	#
	#var lf_res := FileUtils.load_file(file_path)
	#if lf_res.value == null:
		#return lf_res.error
	#var content := lf_res.value as PackedByteArray	
	#
	#var err := _active_session.cache.store_file(
		#file_path.get_file(), content, FileUtils.get_file_priority(file_path))
	#if err != OK:
		#return err
		#
	#var sr_err := _active_session.cache.save_registry()
	#if sr_err != OK:
		##cleanup if index.json can't be updated
		#_active_session.cache.delete_file(
			#file_path.get_file(), FileUtils.hash_file(file_path))
		#return sr_err
	#return  OK
