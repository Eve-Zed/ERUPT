extends GutTest

const CampaignManagerScript = preload("res://scripts/file_handling/campaign_manager.gd")
var manager

class MockCampaign:
	static var fake_campaign = Campaign.new()
	
	static func setup_fake_campaign() -> void:
		fake_campaign._id = "000-000"
		fake_campaign._path = "user://campaigns/test"
		fake_campaign._campaign_name = "Test Campaign"
	
	static func create_campaign(_name: String):
		setup_fake_campaign()
		return Result.new(OK, fake_campaign)
		
	static func load_campaign(_path: String):
		setup_fake_campaign()
		return Result.new(OK, fake_campaign)

class MockCampaignError:
	static func create_campaign(_name: String):
		return Result.new(ERR_CANT_CREATE)
	
	static func load_campaign(_path: String):
		return Result.new(ERR_FILE_CANT_OPEN)

class MockFileUtils:
	static func remove_recursive(_directory: String):
		pass

class MockFileAccess:
	static func file_exists(_path: String):
		return false

class MockFileAccessError:
	static func file_exists(_path: String):
		return true

func before_each():
	manager = CampaignManagerScript.new() as CampaignManager

func after_each():
	manager.queue_free()

#done to avoid orphans
func after_all():
	ProfileManager._player_info.queue_free()

func test_active_id_is_empty_when_no_campaign_loaded():
	assert_eq(manager.active_id, "", "active id should be empty when no campaign is set")

func test_create_campaign_adds_campaign_and_sets_active():
	manager.campaign_class = MockCampaign
	
	var err = manager.create_campaign("Test Campaign")
	
	assert_eq(err, OK, "create_campaign should run successfully")
	assert_eq(manager.campaigns.size(),1,"campaigns should have one entry now")
	assert_eq(manager.campaigns.has("000-000"), true, "added campaign should have the right id")
	assert_eq(manager.campaigns["000-000"],"user://campaigns/test","added campaign should have the right path")
	assert_true(manager.active_campaign != null,"active campaign should be set to a value")
	assert_eq(manager.active_id,"000-000","the active campaing should have the right id")

func test_create_campaign_returns_error_when_creation_fails():
	manager.campaign_class = MockCampaignError
	
	var err = manager.create_campaign("Test Campaign")
	
	assert_push_error_count(1, "can't create error should be pushed")
	assert_eq(err,ERR_CANT_CREATE,"should return the right error")
	assert_eq(manager.campaigns.size(),0,"campaigns should have no entry")
	assert_true(manager.active_campaign == null,"active campaign should not be set")

func test_load_campaign_returns_campaign_and_sets_active():
	manager.campaign_class = MockCampaign
	
	manager.create_campaign("Test Campaign")
	var res = manager.load_campaign("000-000")
	
	assert_eq(res.error,OK,"load_campaign should run successfully")
	assert_eq(res.value.id,"000-000","the right campaign should be loaded")
	assert_true(manager.active_campaign != null,"active campaign should be set to a value")
	assert_eq(manager.active_id,"000-000","the active campaing should have the right id")

func test_load_campaign_returns_error_when_campaign_not_found():
	manager.campaign_class = MockCampaign
	
	var res = manager.load_campaign("000-000")
	
	assert_push_error_count(1, "not found error should be pushed")
	assert_eq(res.error,ERR_DOES_NOT_EXIST,"should return the right error")
	assert_eq(res.value,null,"should not return a campaign")
	assert_true(manager.active_campaign == null,"active campaign should not be set")

func test_load_campaign_returns_error_when_loading_campaign_fails():
	manager.campaign_class = MockCampaign
	manager.create_campaign("Test Campaign")
	manager._active_campaign = null
	
	manager.campaign_class = MockCampaignError
	var res = manager.load_campaign("000-000")
	
	assert_push_error_count(1, "could not load error should be pushed")
	assert_eq(res.error,ERR_FILE_CANT_OPEN,"should return the right error")
	assert_eq(res.value,null,"should not return a campaign")
	assert_true(manager.active_campaign == null,"active campaign should not be set")

func test_delete_campaign_removes_campaign_and_clears_active():
	manager.file_utils_class = MockFileUtils
	manager.campaign_class = MockCampaign
	manager.file_access_class = MockFileAccess
	manager.create_campaign("Test Campaign")
	
	var err = manager.delete_campaign("000-000")
	
	assert_eq(err,OK,"delete_campaign should run successfully")
	assert_eq(manager.campaigns.size(),0,"campaigns should have no entry")
	assert_true(manager.active_campaign == null,"active campaign should not be set")

func test_delete_campaign_returns_error_when_campaign_info_not_deleted():
	manager.file_utils_class = MockFileUtils
	manager.campaign_class = MockCampaign
	manager.file_access_class = MockFileAccessError
	manager.create_campaign("Test Campaign")
	
	var err = manager.delete_campaign("000-000")
	
	assert_push_error_count(1, "could not delete error should be pushed")
	assert_eq(err,FAILED,"should return the right error")
	assert_eq(manager.campaigns.size(),1,"campaigns should still have one entry")
	assert_true(manager.active_campaign != null,"active campaign should still be set")
