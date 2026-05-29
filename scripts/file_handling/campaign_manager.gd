extends Node
#Autoload class_name CampaignManager

#TODO instead of throwing errors make an alert class to handle that

const INFO_NAME := "campaign_info.json"

var campaigns_path := "user://campaigns"

var _campaigns: Dictionary[String, String] = {} 	#id -> path
var _active_campaign: Campaign = null 			#So the campaign doesn't need to be loaded with every operation

#for dependency injection to make unit testing easier
var campaign_class := Campaign
var file_utils_class := FileUtils
var dir_access_class := DirAccess
var file_access_class := FileAccess

var campaigns: Dictionary[String, String]: 
	get:
		return _campaigns.duplicate(true)
var active_id: String:
	get:
		if _active_campaign == null:
			return ""
		return _active_campaign.id
var active_campaign: Campaign:
	get:
		return _active_campaign

func _ready() -> void:
	_initialise()

func create_campaign(campaign_name: String) -> Error:
	var res := campaign_class.create_campaign(campaign_name)
	if not res.error == OK:
		push_error("Could not create campaign: " + error_string(res.error))
		return res.error
	var campaign := res.value as Campaign
	_campaigns[campaign.id] = campaign.path
	_active_campaign = campaign
	Changelog.log("campaigns.log","Created new campaign %s with ID %s at %s" % 
	[campaign.campaign_name, campaign.id, campaign.path])
	return OK

func load_campaign(id: String) -> Result:
	if not _campaigns.has(id):
		push_error("No campaign with the id: " + id)
		return Result.new(ERR_DOES_NOT_EXIST)
	var res := campaign_class.load_campaign(_campaigns[id])
	if not res.error == OK:
		push_error("Failed to load campaign: " + id + " | " + error_string(res.error))
		return Result.new(res.error)
	var campaign = res.value as Campaign
	
	_active_campaign = campaign
	return Result.new(OK, campaign)

func delete_campaign(id: String) -> Error:
	var path := _campaigns[id]
	file_utils_class.remove_recursive(path)
	if file_access_class.file_exists(path.path_join(INFO_NAME)):
		push_error("Could not delete campaign info for campaign: " + id)
		return FAILED
	Changelog.log("campaigns.log","Deleted campaign with ID %s at %s" % [id, path])
	_campaigns.erase(id)
	if active_id == id:
		_active_campaign = null
	return OK

func _get_campaigns_from_disc() ->  Dictionary[String, String]:
	var campaign_dict: Dictionary[String, String] = {}
	var campaign_dirs := dir_access_class.get_directories_at(campaigns_path)
	for campaign in campaign_dirs:
		if file_access_class.file_exists(campaigns_path.path_join(campaign).path_join(INFO_NAME)):
			var result := campaign_class.load_campaign_info(campaigns_path.path_join(campaign))
			if result.error == OK and result.value.has("id"):
				campaign_dict[result.value["id"]] = campaigns_path.path_join(campaign)
	return campaign_dict

func _initialise() -> void:
	if not dir_access_class.dir_exists_absolute(campaigns_path):
		var err := dir_access_class.make_dir_recursive_absolute(campaigns_path)
		if not err == OK:
			push_error("Could not create campaigns folder:" + error_string(err))
	_campaigns = _get_campaigns_from_disc()
