extends RefCounted
class_name Result

var error : Error
var value : Variant

func _init(_error := OK, _value = null) -> void:
	error = _error
	value = _value
