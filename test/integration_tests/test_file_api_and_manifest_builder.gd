extends GutTest

const FileManagerScript = preload("res://scripts/file_handling/file_manager.gd")
const ManifestBuilderScript = preload("res://scripts/file_handling/manifest_builder.gd")
var manager
var builder
var files_path := "user://test_files"

var campaigns := PackedStringArray(["000-fun-000"])
var visibility := PackedStringArray(["000-eve-000"])
var description := "I am a fun description!"
var tags := PackedStringArray(["fun","goblin"])

func before_each():
	manager = autofree(FileManagerScript.new())
	builder = autofree(ManifestBuilderScript.new())

	manager.files_path = files_path

	if not DirAccess.dir_exists_absolute(files_path):
		DirAccess.make_dir_recursive_absolute(files_path)

func after_each():
	if DirAccess.dir_exists_absolute(files_path):
		FileUtils.remove_recursive(files_path)

func test_add_file_creates_file_index_json_with_correct_entry():
	var err = manager.add_file("res://test/integration_tests/test_file.txt",campaigns,visibility,description,tags)

	assert_eq(err,OK,"add_file should run successfully")
	assert_true(FileAccess.file_exists(manager.index_path),"file_index.json should exist now")

	var res = FileUtils.load_json_file(manager.index_path)

	assert_eq(res.error,OK,"json file should be loadable")

	var json = res.value as Dictionary
	var parsed_campaigns = PackedStringArray(json["res://test/integration_tests/test_file.txt"]["campaigns"])
	var parsed_visibility = PackedStringArray(json["res://test/integration_tests/test_file.txt"]["visibility"])
	var parsed_tags = PackedStringArray(json["res://test/integration_tests/test_file.txt"]["tags"])

	assert_true(json.has("res://test/integration_tests/test_file.txt"),"file index should have an entry for the right file")
	assert_eq(parsed_campaigns,campaigns,"metadata should have the right values")
	assert_eq(parsed_visibility,visibility,"metadata should have the right values")
	assert_eq(json["res://test/integration_tests/test_file.txt"]["desc"],description,"metadata should have the right values")
	assert_eq(parsed_tags,tags,"metadata should have the right values")

func test_remove_file_updates_file_index_json_correctly():
	var err = manager.add_file("res://test/integration_tests/test_file.txt")
	assert_eq(err,OK,"add_file should run successfully")

	var del_err = manager.remove_file("res://test/integration_tests/test_file.txt")

	assert_eq(del_err,OK,"remove_file should run successfully")
	assert_true(FileAccess.file_exists(manager.index_path),"file_index.json should exist")
  
	var res = FileUtils.load_json_file(manager.index_path)

	assert_eq(res.error,OK,"json file should be loadable")

	var json = res.value as Dictionary

	assert_false(json.has("res://test/integration_tests/test_file.txt"),"file index should have no entry for the removed file")

func test_modify_file_metadata_updates_file_index_json_correctly():
	var metadata = IndexMetadata.new("random hash",2,campaigns,visibility,description,tags)

	var err = manager.add_file("res://test/integration_tests/test_file.txt")
	assert_eq(err,OK,"add_file should run successfully")

	var mod_err = manager.modify_file_metadata("res://test/integration_tests/test_file.txt",metadata)

	assert_eq(mod_err,OK,"modify_file_metadata should run successfully")
	assert_true(FileAccess.file_exists(manager.index_path),"file_index.json should exist")

	var res = FileUtils.load_json_file(manager.index_path)

	assert_eq(res.error,OK,"json file should be loadable")

	var json = res.value as Dictionary
	var parsed_campaigns = PackedStringArray(json["res://test/integration_tests/test_file.txt"]["campaigns"])
	var parsed_visibility = PackedStringArray(json["res://test/integration_tests/test_file.txt"]["visibility"])
	var parsed_tags = PackedStringArray(json["res://test/integration_tests/test_file.txt"]["tags"])

	assert_true(json.has("res://test/integration_tests/test_file.txt"),"file index should have an entry for the right file")
	assert_eq(json["res://test/integration_tests/test_file.txt"]["hash"],"random hash","metadata should have the right values")
	assert_eq(json["res://test/integration_tests/test_file.txt"]["prio"],2.,"metadata should have the right values")
	assert_eq(parsed_campaigns,campaigns,"metadata should have the right values")
	assert_eq(parsed_visibility,visibility,"metadata should have the right values")
	assert_eq(json["res://test/integration_tests/test_file.txt"]["desc"],description,"metadata should have the right values")
	assert_eq(parsed_tags,tags,"metadata should have the right values")

func test_load_file_index_loads_file_index_correctly():
	manager.add_file("res://test/integration_tests/test_file.txt")
	manager.add_file("res://test/integration_tests/test_json.json")
	manager.add_file("res://test/unit_test/test_campaign_info.json")

	assert_true(FileAccess.file_exists(manager.index_path),"file_index.json should exist")

	var manager_2 = autofree(FileManagerScript.new())
	manager_2.files_path = files_path

	var err = manager_2._load_file_index()

	assert_eq(err,OK,"_load_file_index should run successfully")
	assert_eq(manager_2.file_index.size(),3,"file index should have 3 entries now")
	assert_true(manager_2.file_index.has("res://test/integration_tests/test_file.txt"),"file index should have the right entries")
	assert_true(manager_2.file_index.has("res://test/integration_tests/test_json.json"),"file index should have the right entries")
	assert_true(manager_2.file_index.has("res://test/unit_test/test_campaign_info.json"),"file index should have the right entries")

func test_save_manifest_creats_and_saves_manifests_correctly():
	builder.file_manager_class = manager
	
	manager.add_file("res://test/integration_tests/test_file.txt",campaigns,visibility)
	manager.add_file("res://test/integration_tests/test_json.json",PackedStringArray(["000-fun-000","000-dnd-000"]),visibility)
	manager.add_file("res://test/unit_test/test_campaign_info.json",PackedStringArray(["000-dnd-000"]),visibility)

	var err = builder.save_manifest("000-fun-000","000-eve-000")

	assert_eq(err,OK,"save_manifest should run succesfully")
	var manifest_path := files_path.path_join("000-fun-000_000-eve-000.json")
	assert_true(FileAccess.file_exists(manifest_path),"manifest file should exist now")

	var res = FileUtils.load_json_file(manifest_path)

	assert_eq(res.error,OK,"json file should be loadable")
	var json = res.value
	assert_true(json.has("8c0aef0dc54a9a61f7e6c3dd2b3a33c170788c2e733f02abfc55f0801d4e522f"),"manifest should have the right entries")
	assert_true(json.has("3807cd7ad7b10137310c3ecd529dde9671c3957b587efbf2ecf4b2b099e3c940"),"manifest should have the right entries")
