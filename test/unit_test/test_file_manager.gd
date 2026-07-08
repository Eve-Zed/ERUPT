extends GutTest

const FileManagerScript = preload("res://scripts/file_handling/file_manager.gd")
const IndexMetadataScript = preload("res://scripts/file_handling/index_metadata.gd")
var manager

var campaigns := PackedStringArray(["000-fun-000","000-dnd-000"])
var visibility := PackedStringArray(["000-eve-000","000-zed-000"])
var description := "I am a very fun description"
var tags := PackedStringArray(["fun","goblin"])

class MockFileAccess:
	static func file_exists(_path: String):
		if _path == "/dir/nonexistend_file.fun":
			return false
		return true

class MockFileUtils:
	static func hash_file(_path: String):
		return "I am a file hash"

	static func atomic_save(_path: String, _data: Variant):
		if _path == "error/file_index.json":
			return ERR_FILE_CANT_WRITE
		return OK
	
	static func load_json_file(_path: String):
		if _path == "error/file_index.json":
			return Result.new(OK,"I am an invalid json")
		if _path == "test/file_index.json":
			var dict := {}
			dict["/dir/nonexistend_file.fun"] = "value"
			return Result.new(OK,dict)
		return Result.new(ERR_CANT_OPEN)

class MockGameUtils:
	static func get_file_priority(_path: String):
		return 1

class MockDirAccess:
	static func dir_exists_absolute(_path: String):
		return false
	
	static func make_dir_recursive_absolute(_path: String):
		return ERR_CANT_CREATE

func before_each():
	manager = autofree(FileManagerScript.new())

func test_add_file_adds_file_to_file_index_correctly():
	manager.file_access_class = MockFileAccess
	manager.file_utils_class = MockFileUtils
	manager.game_utils_class = MockGameUtils

	var metadata := IndexMetadataScript.new("I am a file hash",1,campaigns,visibility,description,tags)

	var err = manager.add_file("/dir/dir/cool_file.fun",campaigns,visibility,description,tags)

	assert_eq(err,OK,"add_file should run successfully")
	assert_eq(manager.file_index.size(),1,"file index should have one entry now")
	assert_true(manager.file_index.has("/dir/dir/cool_file.fun"),"file index should have the right entry")
	assert_true(manager.file_index["/dir/dir/cool_file.fun"].equals(metadata),"metadata should be set correctly")

func test_add_file_throws_error_when_file_doesnt_exist():
	manager.file_access_class = MockFileAccess

	var err = manager.add_file("/dir/nonexistend_file.fun")

	assert_push_error_count(1)
	assert_eq(err,ERR_FILE_NOT_FOUND,"should return the right error")
	assert_eq(manager.file_index.size(),0,"file index should have no entries")

func test_add_file_throws_error_when_file_is_already_in_file_index():
	manager.file_access_class = MockFileAccess
	manager._file_index["/dir/dir/duplicate_file.fun"] = null

	var err = manager.add_file("/dir/dir/duplicate_file.fun")

	assert_push_error_count(1)
	assert_eq(err,ERR_ALREADY_EXISTS,"should return the right error")
	assert_eq(manager.file_index.size(),1,"file index should have only one entry")

func test_add_file_throws_error_when_file_index_cant_be_saved():
	manager.file_access_class = MockFileAccess
	manager.file_utils_class = MockFileUtils
	manager.game_utils_class = MockGameUtils
	manager.files_path = "error"

	var err = manager.add_file("/dir/dir/cool_file.fun")

	assert_push_error_count(1)
	assert_eq(err,ERR_FILE_CANT_WRITE,"should return the right error")
	assert_eq(manager.file_index.size(),1,"file index should one entry")
	assert_true(manager.file_index.has("/dir/dir/cool_file.fun"),"file index should have the right entry")

func test_remove_file_removes_file_from_from_index():
	manager.file_utils_class = MockFileUtils
	manager._file_index["/file/to/delete.fun"] = null

	var err = manager.remove_file("/file/to/delete.fun")

	assert_eq(err,OK,"delete_file should run successfully")
	assert_eq(manager.file_index.size(),0,"file index should have no entries now")

func test_get_file_metadata_returns_right_metadata():
	var metadata := IndexMetadataScript.new("I am a file hash",1,campaigns,visibility,description,tags)
	manager._file_index["/dir/dir/cool_file.fun"] = metadata

	var other = manager.get_file_metadata("/dir/dir/cool_file.fun")

	assert_true(metadata.equals(other),"received metadata should have correct values")

func test_modify_file_metadata_sets_values_correctly():
	var metadata := IndexMetadataScript.new("I am a file hash",1,campaigns,visibility,description,tags)
	var metadata_2 := IndexMetadataScript.new("I am also a file hash",2,campaigns,visibility,description,tags)

	assert_false(metadata.equals(metadata_2),"the data should be different")

	manager._file_index["/dir/dir/cool_file.fun"] = metadata
	var err = manager.modify_file_metadata("/dir/dir/cool_file.fun",metadata_2)

	assert_eq(err,OK,"modify_file_metadata should run successfully")
	assert_true(manager.file_index["/dir/dir/cool_file.fun"].equals(metadata_2),"metadata should have the correct values")

func test_modify_file_metadata_throws_error_when_file_isnt_in_file_index():
	var err = manager.modify_file_metadata("/dir/dir/nonexistend_file.fun",null)

	assert_push_error_count(1)
	assert_eq(err,ERR_FILE_NOT_FOUND,"should return the right error")

func test_load_file_index_throws_error_when_file_camt_be_loaded():
	manager.file_utils_class = MockFileUtils

	var err = manager._load_file_index()

	assert_push_error_count(1)
	assert_eq(err,ERR_CANT_OPEN,"should return the right error")

func test_load_file_index_throws_error_when_json_is_invalid():
	manager.file_utils_class = MockFileUtils
	manager.files_path = "error"

	var err = manager._load_file_index()

	assert_push_error_count(1)
	assert_eq(err,ERR_PARSE_ERROR,"should return the right error")

func test_load_file_index_throws_warning_when_file_doesnt_exist():
	manager.file_utils_class = MockFileUtils
	manager.file_access_class = MockFileAccess
	manager.files_path = "test"

	var err = manager._load_file_index()

	assert_push_warning_count(1)
	assert_eq(err,OK,"_load_file_index should run successfully")
	assert_eq(manager.file_index.size(),0,"file index should have no entries")

func test_initialise_throws_error_when_directory_cant_be_created():
	manager.dir_access_class = MockDirAccess

	manager._initialise()

	assert_push_error_count(1)
