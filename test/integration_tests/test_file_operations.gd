extends GutTest

const FileUtilsScript = preload("res://scripts/utils/file_utils.gd")
var utils
var test_path := "user://test_file_operations"

func before_each():
    utils = autofree(FileUtilsScript.new())
    if not DirAccess.dir_exists_absolute(test_path):
        DirAccess.make_dir_recursive_absolute(test_path)


func after_each():
    if DirAccess.dir_exists_absolute(test_path):
        FileUtils.remove_recursive(test_path)

func test_atomic_save_saves_file_and_deletes_temp():
    var path := test_path.path_join("cool_file.txt")
    var data := "I am a text for a test file to contain!"

    var err = utils.atomic_save(path,data)

    assert_eq(err,OK,"atomic_save should run successfully")
    assert_true(FileAccess.file_exists(path),"File should exist now")
    assert_false(FileAccess.file_exists(path.path_join(".tmp")),"Temp file should be deleted")

    var file := FileAccess.open(path,FileAccess.READ)
    assert_false(file == null)

    assert_true(FileAccess.get_size(path) > 0,"file should have content")
    assert_eq(file.get_as_text(),"I am a text for a test file to contain!","File should have the right content")

func test_load_file_loads_file_correctly():
    var res = utils.load_file("res://test/integration_tests/test_file.txt")

    assert_eq(res.error,OK,"load_file should run successfully")
    assert_false(res.value == null,"should return a value")

    var text = res.value.get_string_from_utf8()

    assert_eq(text,"Hello I am a test text file!","should have the right content")

func test_load_json_file_loads_file_correctly():
    var res = utils.load_json_file("res://test/integration_tests/test_json.json")

    assert_eq(res.error,OK,"load_json_file should run successfully")
    assert_false(res.value == null,"should return a value")

    var json = res.value

    assert_true(json.has("test key"),"should have the right key")
    assert_eq(json["test key"],"test","key should have the right value")
    assert_true(json.has("test int"),"should have the right key")
    assert_eq(json["test int"],1.,"key should have the right value")

func test_delete_file_deletes_file_correctly():
    var path := test_path.path_join("cool_file.txt")
    var data := "I am a text for a test file to contain!"

    var err = utils.atomic_save(path,data)

    assert_eq(err,OK,"atomic_save should run successfully")
    assert_true(FileAccess.file_exists(path),"File should exist now")

    var del_err = utils.delete_file(path)

    assert_eq(del_err,OK,"delete_file should run successfully")
    assert_false(FileAccess.file_exists(path),"File should not exist now")

func test_hash_file_hashes_file_correctly():
    #file was hashed by an external tool with sha256
    var correct_hash := "8c0aef0dc54a9a61f7e6c3dd2b3a33c170788c2e733f02abfc55f0801d4e522f"

    var result_hash = utils.hash_file("res://test/integration_tests/test_file.txt")

    assert_eq(result_hash,correct_hash,"file should be hashed correctly")

func test_get_file_size_returns_correct_file_size():
    var size = utils.get_file_size("res://test/integration_tests/test_file.txt")

    assert_eq(size,28,"should return the right file size")

func test_remove_recursive_deletes_directory_and_the_files_inside():
    var path := test_path.path_join("cool_file.txt")
    var path_2 := test_path.path_join("cool_file_2.txt")
    var data := "I am a text for a test file to contain!"

    utils.atomic_save(path,data)
    utils.atomic_save(path_2,data)

    assert_true(DirAccess.dir_exists_absolute(test_path),"directory should exist now")
    assert_eq(DirAccess.get_files_at(test_path).size(),2,"there should be two files in the directory now")

    utils.remove_recursive(test_path)

    assert_false(DirAccess.dir_exists_absolute(test_path),"directory should not exist now")