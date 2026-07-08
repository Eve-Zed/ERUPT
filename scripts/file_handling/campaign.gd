extends Resource
class_name Campaign

#region Constants
const INFO_KEYS := ["name","id","desc","preview","tags"] #keys for campaign info file
#endregion

#region Variables
var _campaign_name: String #User chosen, not unique
var _id: String #Generated UUID, unique
var _path: String #Folder for all campaign files
var _description: String #Optional, user chosen
var _preview_image_path: String #Optional, user chosen
var _tags: Array[String] = [] #Optional, user chosen

var max_desc_length := 256

#for dependency injection to make unit testing easier
var file_utils_class := FileUtils
var dir_access_class := DirAccess
var game_utils_class := GameUtils

static var s_file_utils_class := FileUtils
static var s_dir_access_class := DirAccess
static var s_campaign_class := Campaign
#endregion

#region Getter and Setter
var campaign_name: String:
	get:
		return _campaign_name
var id: String:
	get:
		return _id
var path: String:
	get:
		return _path
var info_path: String: #path for campaign info file
	get:
		return path.path_join(CampaignManager.INFO_NAME)
var description: String:
	get:
		return _description
	set(value):
		_description = value.substr(0, max_desc_length)
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
#endregion

#region Public Methods
func add_tag(tag: String) -> void:
	_tags.append(tag)

func remove_tag(tag: String) -> void:
	_tags.erase(tag)

func save_campaign_info() -> Error:
	var data := {"name": _campaign_name,
				"id": _id,
				"desc": _description,
				"preview": _preview_image_path,
				"tags": _tags} 
	return file_utils_class.atomic_save(info_path, JSON.stringify(data))

func update_campaign_info(s_name: String = "", s_desc: String = "", s_tags: Array[String] = []) -> Error:
	if not s_name.is_empty():
		_campaign_name = s_name
	if not s_desc.is_empty():
		description = s_desc
	if not s_tags.is_empty():
		tags = s_tags
	return save_campaign_info()
#endregion

#region Private Methods
func _create_new_on_disk() -> Error:
	var final_path := _path
	var temp_path := final_path + ".tmp"
	
	_cleanup_temp(temp_path)

	if not dir_access_class.dir_exists_absolute(temp_path):
		var err := dir_access_class.make_dir_recursive_absolute(temp_path)
		if err != OK:
			push_error("Failed to create temp campaign directory: " + temp_path)
			return err
	
	_path = temp_path
	var save_err := save_campaign_info()
	if save_err != OK:
		_cleanup_temp(temp_path)
		_path = final_path
		push_error("Failed to save campaign_info.json.")
		return save_err
	_path = final_path
	
	var rename_err := dir_access_class.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		push_error("Failed to finalize campaign directory rename.")
		_cleanup_temp(temp_path)
		return rename_err
	
	return OK

func _cleanup_temp(temp_path: String) -> void:
	if dir_access_class.dir_exists_absolute(temp_path):
		file_utils_class.remove_recursive(temp_path)

func _load_campaign_info() -> Error:
	var res := s_campaign_class.load_campaign_info(path)
	if res.error != OK:
		return res.error
	var parsed = res.value
	_campaign_name = parsed["name"]
	_id = parsed["id"]
	description = parsed["desc"]
	preview_image_path = parsed["preview"]
	for tag in parsed["tags"]:
		add_tag(tag)
	return OK

func _setup_new(name: String, campaign_id: String) -> void:
	_campaign_name = name
	if name.is_empty():
		_campaign_name = "Campaign"
	_id = campaign_id
	if campaign_id.is_empty():
		_id = game_utils_class.generate_uuid_v4()
	
	var safe_name := file_utils_class.sanitize_filename(_campaign_name)
	var base_path := CampaignManager.campaigns_path.path_join(safe_name)
	var campaign_path := base_path
	var num := 1
	while dir_access_class.dir_exists_absolute(campaign_path):
		campaign_path = base_path + "(" + str(num) + ")"
		num += 1
	_path = campaign_path
#endregion

#region Static Methods
static func create_campaign(name: String, campaign_id: String="") -> Result:
	var campaign := Campaign.new()
	campaign._setup_new(name, campaign_id)
	var err = campaign._create_new_on_disk()
	if err != OK:
		return Result.new(err)
	return Result.new(OK, campaign)

static func load_campaign(campaign_path: String) -> Result:
	if campaign_path.is_empty() or not s_dir_access_class.dir_exists_absolute(campaign_path):
		push_error("Failed to load campaign: invalid path")
		return Result.new(ERR_FILE_BAD_PATH)
	
	var campaign = Campaign.new()
	campaign._path = campaign_path
	var load_err := campaign._load_campaign_info()
	if load_err != OK:
		return Result.new(load_err)
	
	return Result.new(OK,campaign)

static func load_campaign_info(campaign_path: String) -> Result:
	var res := s_file_utils_class.load_json_file(campaign_path.path_join(CampaignManager.INFO_NAME))
	if res.error != OK:
		push_error("Failed to load campaign info: Could not load json file: "+error_string(res.error))
		return Result.new(res.error)
	var json = res.value
	if typeof(json) != TYPE_DICTIONARY:
		push_error("Failed to load campaign info: Could not parse json")
		return Result.new(ERR_PARSE_ERROR)
	
	if not json.has_all(INFO_KEYS):
		push_error("Failed to load campaign info: Invalid or missing data")
		return Result.new(ERR_INVALID_DATA)

	return Result.new(OK,json)
#endregion
