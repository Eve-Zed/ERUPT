extends GutTest

const CampaignScript = preload("res://scripts/file_handling/campaign.gd")
var campaign

class MockFileUtils:
	static func atomic_save(_path: String, _data: Variant):
		if _path == "user://test_campaigns/boring_campaign.tmp/campaign_info.json":
			return ERR_FILE_CANT_WRITE
		return OK
	
	static func load_json_file(_path: String):
		if _path == "user://test_campaigns/unparsable_campaign/campaign_info.json":
			return Result.new(OK,"Not viable json")
		if _path == "user://test_campaigns/wrong_campaign/campaign_info.json":
			return Result.new(OK,{})
		return Result.new(ERR_FILE_CANT_OPEN)

class MockDirAccess:
	static func dir_exists_absolute(_path: String):
		if _path == "user://test_campaigns/forth_campaign":
			return true
		return false
	
	static func make_dir_recursive_absolute(_path: String):
		if _path == "user://test_campaigns/error_campaign.tmp":
			return FAILED
		return OK
	
	static func rename_absolute(_path1: String, _path2: String):
		if _path2 == "user://test_campaigns/unfun_campaign":
			return ERR_FILE_NO_PERMISSION
		return OK

class MockCampaign:
	static func load_campaign_info(_path: String): 
		var json = FileUtils.load_json_file("res://test/unit_test/test_campaign_info.json").value
		return Result.new(OK,json)

class MockGameUtils:
	static func generate_uuid_v4():
		return "000-gen-000"

func before_each():
	campaign = autofree(CampaignScript.new())

func test_set_description_cuts_off_at_max_desc_length():
	campaign.max_desc_length = 10
	assert_eq(campaign.description,"","description should be empty now")
	
	campaign.description = "Hello I am a fun description" #over 10 characters so it should be cut off
	
	assert_eq(campaign.description.length(),10,"description should have the right length")
	assert_eq(campaign.description,"Hello I am","description should be cut off correctly")

func test_add_tag_adds_tag():
	assert_true(campaign.tags.is_empty(),"there should be no tags now")
	
	campaign.add_tag("fun tag")
	
	assert_eq(campaign.tags.size(),1,"there should be one tag now")
	assert_true(campaign.tags.has("fun tag"),"there should be the right tag")

func test_delete_tag_deletes_tag():
	campaign.add_tag("fun tag")
	campaign.add_tag("unfun tag")
	
	assert_eq(campaign.tags.size(),2,"there should be two tag now")
	
	campaign.remove_tag("unfun tag")
	
	assert_eq(campaign.tags.size(),1,"there should be one tag now")
	assert_false(campaign.tags.has("unfun tag"),"the deleted tag should not be there anymore")

func test_update_campaign_info_sets_values():
	campaign.file_utils_class = MockFileUtils
	
	assert_eq(campaign.campaign_name,"","campaign name should not be set")
	assert_eq(campaign.description,"","description should not be set")
	assert_eq(campaign.tags.size(),0,"there should be no tags now")
	
	var tags: Array[String] = ["fun tag"]
	var err = campaign.update_campaign_info("fun campaign","fun campaign description",tags)
	
	assert_eq(err,OK,"update_campaign_info runs successfully")
	assert_eq(campaign.campaign_name,"fun campaign","campaign name should have the right value")
	assert_eq(campaign.description,"fun campaign description","description should have the right value")
	assert_eq(campaign.tags.size(),1,"there should be one tag now")
	assert_true(campaign.tags.has("fun tag"),"tags should have the right value")

func test_create_on_disc_throws_error_when_temp_directory_cant_be_created():
	campaign.dir_access_class = MockDirAccess
	campaign._path = "user://test_campaigns/error_campaign"
	
	var err = campaign._create_new_on_disk()
	
	assert_push_error_count(1, "can't create error should be pushed")
	assert_eq(err,FAILED,"should return the right error")

func test_create_on_disc_throws_error_when_save_campaign_info_fails():
	campaign.dir_access_class = MockDirAccess
	campaign.file_utils_class = MockFileUtils
	campaign._path = "user://test_campaigns/boring_campaign"
	
	var err = campaign._create_new_on_disk()
	
	assert_push_error_count(1, "can't create error should be pushed")
	assert_eq(err,ERR_FILE_CANT_WRITE,"should return the right error")

func test_create_on_disc_throws_error_when_directory_rename_fails():
	campaign.dir_access_class = MockDirAccess
	campaign.file_utils_class = MockFileUtils
	campaign._path = "user://test_campaigns/unfun_campaign"
	
	var err = campaign._create_new_on_disk()
	
	assert_push_error_count(1, "can't create error should be pushed")
	assert_eq(err,ERR_FILE_NO_PERMISSION,"should return the right error")

func test_load_campaign_info_sets_values_correctly():
	campaign.s_campaign_class = MockCampaign
	
	var err = campaign._load_campaign_info()
	
	assert_eq(err,OK,"_load_campaign_info should run successfully")
	assert_eq(campaign.campaign_name,"Fun Campaign","campaign name should have the right value")
	assert_eq(campaign.description,"this is a fun description","description should have the right value")
	assert_eq(campaign.id,"000-fun-000","ID should have the right value")
	assert_eq(campaign.preview_image_path,"res://preview.png","preview image path should have the right value")
	assert_eq(campaign.tags.size(),2,"tags should have the right number of entries")
	assert_true(campaign.tags.has("fun tag"),"tags should have the right values")
	assert_true(campaign.tags.has("other fun tag"),"tags should have the right values")

func test_setup_new_sets_values_correctly():
	campaign.dir_access_class = MockDirAccess
	#set both name and ID with parameters
	campaign._setup_new("fun campaign","000-fun-000")
	
	assert_eq(campaign.campaign_name,"fun campaign","campaign name should have the right value")
	assert_eq(campaign.id,"000-fun-000","ID should have the right value")
	assert_eq(campaign.path,"user://test_campaigns/fun_campaign","path should have the right value")
	
	var campaign_2 = autofree(CampaignScript.new())
	campaign_2.dir_access_class = MockDirAccess
	campaign_2.game_utils_class = MockGameUtils
	#only set name and generate new UID
	campaign_2._setup_new("fun campaign 2","")
	
	assert_eq(campaign_2.campaign_name,"fun campaign 2","campaign name should have the right value")
	assert_eq(campaign_2.id,"000-gen-000","ID should have the right value")
	assert_eq(campaign_2.path,"user://test_campaigns/fun_campaign_2","path should have the right value")
	
	var campaign_3 = autofree(CampaignScript.new())
	campaign_3.dir_access_class = MockDirAccess
	campaign_3.game_utils_class = MockGameUtils
	#generate name and set ID
	campaign_3._setup_new("","000-lol-000")
	
	assert_eq(campaign_3.campaign_name,"Campaign","campaign name should have the right value")
	assert_eq(campaign_3.id,"000-lol-000","ID should have the right value")
	assert_eq(campaign_3.path,"user://test_campaigns/campaign","path should have the right value")
	
	var campaign_4 = autofree(CampaignScript.new())
	campaign_4.dir_access_class = MockDirAccess
	#case that a campaign with the path .../forth_campaign already exists
	campaign_4._setup_new("forth campaign","000-444-000")
	
	assert_eq(campaign_4.campaign_name,"forth campaign","campaign name should have the right value")
	assert_eq(campaign_4.id,"000-444-000","ID should have the right value")
	assert_eq(campaign_4.path,"user://test_campaigns/forth_campaign(1)","path should have the right value")

func test_load_campaign_throws_error_when_path_doesnt_exist():
	var res = campaign.load_campaign("")

	assert_push_error_count(1)
	assert_eq(res.error,ERR_FILE_BAD_PATH,"should return the right error")
	assert_eq(res.value,null,"should not return any value")

func test_load_campaign_info_throws_error_when_json_cant_be_loaded():
	campaign.s_file_utils_class = MockFileUtils

	var res = campaign.load_campaign_info("user://test_campaigns/unloadable_campaign")

	assert_push_error_count(1)
	assert_eq(res.error,ERR_FILE_CANT_OPEN,"should return the right error")
	assert_eq(res.value,null,"should not return a value")

func test_load_campaign_info_throws_error_when_json_couldnt_be_parsed():
	campaign.s_file_utils_class = MockFileUtils

	var res = campaign.load_campaign_info("user://test_campaigns/unparsable_campaign")

	assert_push_error_count(1)
	assert_eq(res.error,ERR_PARSE_ERROR,"should return the right error")
	assert_eq(res.value,null,"should not return a value")

func test_load_campaign_info_throws_error_when_json_has_from_keys():
	campaign.s_file_utils_class = MockFileUtils

	var res = campaign.load_campaign_info("user://test_campaigns/wrong_campaign")

	assert_push_error_count(1)
	assert_eq(res.error,ERR_INVALID_DATA,"should return the right error")
	assert_eq(res.value,null,"should not return a value")