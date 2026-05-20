extends Resource
class_name Campaign

#region Constants
const INFO_KEYS := ["name","id","desc","preview","tags"] #keys for campaign info file
const MAX_DESC_LENGHT := 256
#endregion

#region Variables
var _campaign_name: String #User chosen, not unique
var _id: String #Generated UUID, unique
var _path: String #Folder for all campaign files
var _description: String #Optional, user chosen
var _preview_image_path: String #Optional, user chosen
var _tags: Array[String] = [] #Optional, user chosen
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
		return _path.path_join(CampaignManager.INFO_NAME)
var description: String:
	get:
		return _description
	set(value):
		_description = value.substr(0, MAX_DESC_LENGHT)
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
	return FileUtils.atomic_save(info_path,JSON.stringify(data))

func update_campaign_info(s_name: String = "", s_desc: String = "", s_tags: Array[String] = []) -> Error:
	if not s_name.is_empty():
		campaign_name = s_name
	if not s_desc.is_empty():
		description = s_desc
	if not tags.is_empty():
		tags = s_tags
	return save_campaign_info()
#endregion

#region Private Methods
func _create_new_on_disk() -> Error:
	var final_path := _path
	var temp_path := final_path + ".tmp"
	
	if DirAccess.dir_exists_absolute(temp_path):
		var err = DirAccess.remove_absolute(temp_path)
		if err != OK:
			return err

	if not DirAccess.dir_exists_absolute(_path):
		var err := DirAccess.make_dir_recursive_absolute(temp_path)
		if err != OK:
			push_error("Failed to create temp campaign directory: " + temp_path)
			return err
	
	_path = temp_path
	var save_err := save_campaign_info()
	if save_err != OK:
		_cleanup_temp(temp_path)
		_path = final_path
		return save_err
	_path = final_path
	
	var rename_err := DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		push_error("Failed to finalize campaign directory rename.")
		_cleanup_temp(temp_path)
		return rename_err
	
	return OK

func _cleanup_temp(temp_path: String) -> void:
	if DirAccess.dir_exists_absolute(temp_path):
		DirAccess.remove_absolute(temp_path)

func _load_campaign_info() -> Error:
	var res := load_campaign_info(path)
	if res.error != OK:
		return res.error
	var parsed = res.value
	_campaign_name = parsed["name"]
	_id = parsed["id"]
	_description = parsed["desc"]
	_preview_image_path = parsed["preview"]
	for tag in parsed["tags"]:
		add_tag(tag)
	return OK

func _setup_new(name: String, campaign_id: String) -> void:
	_campaign_name = name
	if name.is_empty():
		_campaign_name = "Campaign"
	_id = campaign_id
	if campaign_id.is_empty():
		_id = GameUtils.generate_uuid_v4()
	
	var safe_name := FileUtils.sanitize_filename(_campaign_name)
	var base_path := CampaignManager.CAMPAIGNS_PATH.path_join(safe_name)
	var campaign_path := base_path
	var num := 1
	while DirAccess.dir_exists_absolute(campaign_path):
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
	if campaign_path.is_empty() or not DirAccess.dir_exists_absolute(campaign_path):
		push_error("Failed to load campaign: invalid path")
		return Result.new(ERR_FILE_BAD_PATH)
	
	var campaign = Campaign.new()
	campaign._path = campaign_path
	var load_err := campaign._load_campaign_info()
	if load_err != OK:
		return Result.new(load_err)
	
	return Result.new(OK,campaign)

static func load_campaign_info(campaign_path: String) -> Result:
	var res := FileUtils.load_json_file(campaign_path.path_join(CampaignManager.INFO_NAME))
	if res.error != OK:
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
	
