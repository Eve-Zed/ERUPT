extends Resource
class_name Session

#region Constants
const INFO_KEYS := ["name","id","desc","preview","tags"] #keys for session info file
const MAX_DESC_LENGHT := 256
#endregion

#region Variables
var _session_name: String #User chosen, not unique
var _session_id: String #Generated UUID, unique
var _session_path: String #Folder for all session files
var _session_desc: String #Optional, user chosen
var _preview_image_path: String #Optional, user chosen
var _tags: Array[String] = [] #Optional, user chosen

var _manifest: ContentManifest #Manifest, manages which files are shared with players
var _cache: ContentCache #Index, shows which files are in the cache
#endregion

#region Getter and Setter
var session_name: String:
	get:
		return _session_name
var session_id: String:
	get:
		return _session_id
var session_path: String:
	get:
		return _session_path
var info_path: String: #path for session info file
	get:
		return _session_path.path_join(SessionManager.INFO_NAME)
var session_desc: String:
	get:
		return _session_desc
	set(value):
		_session_desc = value.substr(0, MAX_DESC_LENGHT)
var preview_image_path: String:
	get:
		return _preview_image_path
	set(value):
		if value.is_absolute_path():
			_preview_image_path = value
var tags: Array[String]:
	get:
		return _tags.duplicate(true)
	set(value):
		_tags = value.duplicate(true)

var manifest: ContentManifest:
	get:
		return _manifest
var cache: ContentCache:
	get:
		return _cache
#endregion

#region Public Methods
func add_tag(tag: String) -> void:
	_tags.append(tag)

func remove_tag(tag: String) -> void:
	_tags.erase(tag)

func save_session_info() -> Error:
	var data := {"name": _session_name,
				"id": _session_id,
				"desc": _session_desc,
				"preview": _preview_image_path,
				"tags": _tags} 
	return FileUtils.atomic_save(info_path,JSON.stringify(data))

func update_session_info(s_name: String = "", s_desc: String = "", s_tags: Array[String] = []) -> Error:
	if not s_name.is_empty():
		session_name = s_name
	if not s_desc.is_empty():
		session_desc = s_desc
	if not tags.is_empty():
		tags = s_tags
	return save_session_info()
#endregion

#region Private Methods
func _create_new_on_disk() -> Error:
	var final_path := _session_path
	var temp_path := final_path + ".tmp"
	
	if DirAccess.dir_exists_absolute(temp_path):
		var err = DirAccess.remove_absolute(temp_path)
		if err != OK:
			return err

	if not DirAccess.dir_exists_absolute(_session_path):
		var err := DirAccess.make_dir_recursive_absolute(temp_path)
		if err != OK:
			push_error("Failed to create temp session directory: " + temp_path)
			return err
	
	_session_path = temp_path
	
	var save_err := save_session_info()
	if save_err != OK:
		_cleanup_temp(temp_path)
		_session_path = final_path
		return save_err
	
	_cache = ContentCache.new(_session_path)
	save_err = _cache.save_registry()
	if save_err != OK:
		_cleanup_temp(temp_path)
		_session_path = final_path
		return save_err
	
	var res := ContentManifest.generate_from_index(_cache)
	if res.error != OK:
		_cleanup_temp(temp_path)
		_session_path = final_path
		return res.error
		
	_manifest = res.value
	save_err = _manifest.save_registry()
	if save_err != OK:
		_cleanup_temp(temp_path)
		_session_path = final_path
		return save_err
	
	_session_path = final_path
	_cache.root_path = final_path
	_manifest.root_path = final_path
	var rename_err := DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		push_error("Failed to finalize session directory rename.")
		_cleanup_temp(temp_path)
		return rename_err
	
	return OK

func _cleanup_temp(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		DirAccess.remove_absolute(path)

func _load_session_info() -> Error:
	var res := load_session_info(session_path)
	if res.error != OK:
		return res.error
	var parsed = res.value
	_session_name = parsed["name"]
	_session_id = parsed["id"]
	_session_desc = parsed["desc"]
	_preview_image_path = parsed["preview"]
	for tag in parsed["tags"]:
		add_tag(tag)
	return OK

func _setup_new(name: String, s_id: String) -> void:
	_session_name = name
	if name.is_empty():
		_session_name = "Session"
	_session_id = s_id
	if s_id.is_empty():
		_session_id = FileUtils.generate_uuid_v4()
	
	var safe_name := FileUtils.sanitize_filename(_session_name)
	var base_path := SessionManager.SESSIONS_PATH.path_join(safe_name)
	var path := base_path
	var id := 1
	while DirAccess.dir_exists_absolute(path):
		path = base_path + "(" + str(id) + ")"
		id += 1
	_session_path = path
#endregion

#region Static Methods
static func create_session(name: String, id: String="") -> Result:
	var session := Session.new()
	session._setup_new(name, id)
	var err = session._create_new_on_disk()
	if err != OK:
		return Result.new(err)
	SessionManager.register_session(session)
	return Result.new(OK, session)

static func load_session(path: String) -> Result:
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		push_error("Failed to load session: invalid path")
		return Result.new(ERR_FILE_BAD_PATH)
	
	var session = Session.new()
	session._session_path = path
	var load_err := session._load_session_info()
	if load_err != OK:
		return Result.new(load_err)
	
	session._cache = ContentCache.new(session._session_path)
	load_err = session._cache.load_registry()
	if load_err != OK:
		return Result.new(load_err)
	
	var res = ContentManifest.generate_from_index(session._cache)
	if res.error != OK:
		return res
	session._manifest = res.value
	
	return Result.new(OK,session)

static func load_session_info(path: String) -> Result:
	var json := FileUtils.load_json_file(path.path_join(SessionManager.INFO_NAME))
	if json.is_empty():
		return Result.new(FileUtils.load_error)
	
	var parsed = JSON.parse_string(json)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("Failed to load session info: Could not parse json")
		return Result.new(ERR_PARSE_ERROR)
	
	if not parsed.has_all(INFO_KEYS):
		push_error("Failed to load session info: Invalid or missing data")
		return Result.new(ERR_INVALID_DATA)
	
	return Result.new(OK,parsed)
#endregion
	
