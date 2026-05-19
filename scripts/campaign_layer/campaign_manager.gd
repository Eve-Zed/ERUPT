extends Node

const CAMPAIGNS_PATH := "user://campaigns"
const INFO_NAME := "campaign_info.json"

var _campaigns: Dictionary[String, String] = {} 	#id -> path
var _active_campaign: Campaign = null 			#So the campaign doesn't need to be loaded with every operation

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
	if !DirAccess.dir_exists_absolute(CAMPAIGNS_PATH):
		DirAccess.make_dir_recursive_absolute(CAMPAIGNS_PATH)
	_campaigns = _get_campaigns_from_disc()

func create_campaign(campaign_name: String) -> Error:
	var res := Campaign.create_campaign(campaign_name)
	if res.error != OK:
		push_error("Could not create campaign: " + error_string(res.error))
		return res.error
	var campaign := res.value as Campaign
	_campaigns[campaign.id] = campaign.path
	_active_campaign = campaign
	Changelog.log("campaigns.log","Created new campaign %s with ID %s at %s" % 
	[campaign.campaign_name, campaign.id, campaign.path])
	return OK

func load_campaign(id: String) -> Result:
	var res := Campaign.load_campaign(campaigns[id])
	if res.error != OK:
		return Result.new(res.error)
	var campaign = res.value as Campaign
	return Result.new(OK, campaign)

func delete_campaign(id: String) -> Error:
	FileUtils.remove_recursive(campaigns[id])
	Changelog.log("campaigns.log","Deleted campaign with ID %s at %s" % [id, campaigns[id]])
	_campaigns.erase(id)
	if active_id == id:
		_active_campaign = null
	return OK

func _get_campaigns_from_disc() ->  Dictionary[String, String]:
	var campaign_dict: Dictionary[String, String] = {}
	var campaign_dirs := DirAccess.get_directories_at(CAMPAIGNS_PATH)
	for campaign in campaign_dirs:
		if FileAccess.file_exists(CAMPAIGNS_PATH.path_join(campaign).path_join(INFO_NAME)):
			var result := Campaign.load_campaign_info(CAMPAIGNS_PATH.path_join(campaign))
			if result.error == OK and result.value.has("id"):
				campaign_dict[result.value["id"]] = CAMPAIGNS_PATH.path_join(campaign)
	return campaign_dict
