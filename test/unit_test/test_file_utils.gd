extends GutTest

const FileUtilsScript = preload("res://scripts/utils/file_utils.gd")
var utils

func before_each():
	utils = autofree(FileUtilsScript.new())

func test_sanize_filename_return_correct_string():
	#empty string "" -> "untitled"
	var test_1 = utils.sanitize_filename("")

	assert_eq(test_1,"untitled","empty string '' should return 'untitled'")

	#"  TEST\n" -> "test"
	var test_2 = utils.sanitize_filename("  TEST\n")

	assert_eq(test_2,"test","'  TEST\\n' should return 'test'")

	#"hello.here:are/ some?chars%" -> "hello_here_are__some_chars_"
	var test_3 = utils.sanitize_filename("hello.here:are/ some?chars%")

	assert_eq(test_3,"hello_here_are__some_chars_","'hello.here:are/ some?chars%' should return 'hello_here_are__some_chars_'")

	#test max_lenght: "helloiamatoolongstring" -> "helloiamat"
	var test_4 = utils.sanitize_filename("helloiamatoolongstring",10)

	assert_eq(test_4,"helloiamat","'helloiamatoolongstring' should return 'helloiamat'")
