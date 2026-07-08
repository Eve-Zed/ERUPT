extends GutTest

const CampaignManagerScript = preload("res://scripts/file_handling/campaign_manager.gd")
const TEST_PATH := "user://test_campaigns"

var manager

func before_all():
	if DirAccess.dir_exists_absolute(TEST_PATH):
		FileUtils.remove_recursive(TEST_PATH)
	#Because the Session script uses the autoload
	CampaignManager.campaigns_path = TEST_PATH
	
func before_each():
	manager = autofree(CampaignManagerScript.new())
	manager.campaigns_path = TEST_PATH
	
	DirAccess.make_dir_recursive_absolute(TEST_PATH)

func after_each():
	if DirAccess.dir_exists_absolute(TEST_PATH):
		FileUtils.remove_recursive(TEST_PATH)

func test_initialise_creates_campaigns_folder():
	if DirAccess.dir_exists_absolute(TEST_PATH):
		FileUtils.remove_recursive(TEST_PATH)
	
	manager._initialise()
	
	assert_true(DirAccess.dir_exists_absolute(TEST_PATH))

func test_create_campaign_creates_real_directory():
	var err = manager.create_campaign("Test Campaign")
	
	assert_eq(err, OK, "create_campaign should run successfully")
	assert_eq(manager.campaigns.size(), 1, "created campaign should be added to campaigns")

	var id = manager.active_id
	var path = manager.campaigns[id]

	assert_true(DirAccess.dir_exists_absolute(path),"campaign directory should exist")
	assert_true(FileAccess.file_exists(path.path_join(manager.INFO_NAME)),"campaign_info.json should exist")

func test_load_campaign_loads_from_directory():
	var err = manager.create_campaign("Test Campaign")
	assert_eq(err,OK)
	var res = manager.load_campaign(manager.active_id)
	
	assert_eq(res.error,OK,"load_campaign should run successfully")
	assert_true(res.value != null,"a campaign should be returned")
	var campaign := res.value as Campaign
	assert_eq(campaign.id,manager.active_id,"campaign should have the right id")
	assert_eq(campaign.campaign_name,"Test Campaign","campaign should have the right name")

func test_delete_campaign_deletes_directory():
	var err = manager.create_campaign("Test Campaign")
	assert_eq(err,OK)
	
	var path = manager.active_campaign.path
	assert_true(DirAccess.dir_exists_absolute(path),"folder should exist before delete campaign")
	
	var del_err = manager.delete_campaign(manager.active_id)
	
	assert_eq(del_err,OK,"delete campaign should run successfully")
	assert_eq(manager.campaigns.size(),0,"campaigns should have no entry")
	assert_true(manager.active_campaign == null,"active campaign should not be set")
	
	assert_false(DirAccess.dir_exists_absolute(path),"folder should be deleted")

func test_campaign_can_be_loaded_after_manager_restart():
	var err = manager.create_campaign("Test Campaign")
	assert_eq(err,OK)
	var id = manager.active_id
	var path = manager.campaigns[id]
	
	manager.queue_free()
	
	var new_manager = autofree(CampaignManagerScript.new())
	new_manager.campaigns_path = TEST_PATH
	
	assert_eq(new_manager.campaigns.size(),0,"campaigns should have no entry now")
	new_manager._campaigns = new_manager._get_campaigns_from_disc()
	
	assert_eq(new_manager.campaigns.size(),1,"campaigns should have one entry")
	assert_true(new_manager.campaigns.has(id),"campaigns should have the right entry")
	assert_eq(new_manager.campaigns[id],path,"campaign should have the right path")
