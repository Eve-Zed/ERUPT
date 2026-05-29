extends GutTest

const ManifestMetadataScript = preload("res://scripts/file_handling/manifest_metadata.gd")
var manifest_metadata

#variables for constructor
var file_name := "fun_file.file"
var priority := 1
var size := 16100
var campaigns := PackedStringArray(["000-fun-000","000-err-000"])

func before_each():
    manifest_metadata = autofree(ManifestMetadataScript.new(file_name,priority,size,campaigns))

func test_constructor_sets_values_correctly():
    assert_eq(manifest_metadata.file_name,file_name,"file name should have the correct value")
    assert_eq(manifest_metadata.priority,priority,"priority should have the correct value")
    assert_eq(manifest_metadata.size,size,"size should have the correct value")
    assert_eq(manifest_metadata.campaigns,campaigns,"campaign should have the correct value")

func test_to_dictionary_has_correct_values():
    var dict = manifest_metadata.to_dictionary()

    assert_false(dict.is_empty(),"dictionary should not be empty")
    assert_true(dict.has_all(["name","prio","size","campaigns"]),"dictionary should have the right keys")
    assert_eq(dict["name"],file_name,"file name should have the correct value")
    assert_eq(dict["prio"],priority,"priority should have the correct value")
    assert_eq(dict["size"],size,"size should have the correct value")
    assert_eq(dict["campaigns"],campaigns,"campaign should have the correct value")