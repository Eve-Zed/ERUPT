extends GutTest

const IndexMetadataScript = preload("res://scripts/file_handling/index_metadata.gd")
var index_metadata

#variables for constructor
var file_hash := "I am a hash value"
var priority := 1
var campaigns := PackedStringArray(["000-fun-000","000-err-000"])
var visibility := PackedStringArray(["000-eve-000","000-lyn-000"])
var description := "I am a campaign description"
var tags := PackedStringArray(["fun","DnD","goblins"])

func before_each():
    index_metadata = autofree(IndexMetadataScript.new(file_hash,priority,campaigns,visibility,description,tags))

func test_constructor_sets_values_correctly():
    assert_eq(index_metadata.file_hash,file_hash,"file hash should have the correct value")
    assert_eq(index_metadata.priority,priority,"priority should have the correct value")
    assert_eq(index_metadata.campaigns,campaigns,"campaign should have the correct value")
    assert_eq(index_metadata.visibility,visibility,"visibility should have the correct value")
    assert_eq(index_metadata.description,description,"description should have the correct value")
    assert_eq(index_metadata.tags,tags,"tags should have the correct value")

func test_to_dictionary_has_correct_values():
    var dict = index_metadata.to_dictionary()

    assert_false(dict.is_empty(),"dictionary should not be empty")
    assert_true(dict.has_all(["hash","prio","campaigns","visibility","desc","tags"]),"dictionary should have the right keys")
    assert_eq(dict["hash"],file_hash,"file hash should have the correct value")
    assert_eq(dict["prio"],priority,"priority should have the correct value")
    assert_eq(dict["campaigns"],campaigns,"campaign should have the correct value")
    assert_eq(dict["visibility"],visibility,"visibility should have the correct value")
    assert_eq(dict["desc"],description,"description should have the correct value")
    assert_eq(dict["tags"],tags,"tags should have the correct value")

func test_equals_campares_two_objects_correctly():
    var other := IndexMetadataScript.new(file_hash,priority,campaigns,visibility,description,tags)
    var res = index_metadata.equals(other)

    assert_eq(res,true,"the two objects should be the same")

    other.file_hash = "I am another file hash"
    var res_2 = index_metadata.equals(other)

    assert_eq(res_2,false,"the two objects should not be the same")


func test_create_from_doctionary_creates_correct_index_metadata():
    var index_metadata_2 = index_metadata.create_from_dictionary(index_metadata.to_dictionary())

    assert_eq(index_metadata_2.file_hash,file_hash,"file hash should have the correct value")
    assert_eq(index_metadata_2.priority,priority,"priority should have the correct value")
    assert_eq(index_metadata_2.campaigns,campaigns,"campaign should have the correct value")
    assert_eq(index_metadata_2.visibility,visibility,"visibility should have the correct value")
    assert_eq(index_metadata_2.description,description,"description should have the correct value")
    assert_eq(index_metadata_2.tags,tags,"tags should have the correct value")