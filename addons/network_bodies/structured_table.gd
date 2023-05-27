extends Resource
class_name StructuredTable


@export var data := {}
@export var structure := {}

func _get(property):
	if !structure.has(property):
		return null
	
	if data.has(property):
		var default = structure[property]
		var value = data[property]
		if typeof(default) != typeof(value):
			return structure[property]
		return value
	else:
		return structure[property]

func _set(property, value):
	if !structure.has(property):
		return false
	
	data[property] = value
	return true

func pack(max_size : int = 2048) -> PackedByteArray:
	var byte_array := PackedByteArray()
	byte_array.resize(max_size)
	var head := 0
	for key in structure:
		var value = data.get(key, structure[key])
		head += byte_array.encode_var(head, value)
	byte_array.resize(head)
	
	return byte_array

func unpack(from : PackedByteArray) -> void:
	var head := 0
	for key in structure:
		var value = from.decode_var(head)
		if value != null:
			data[key] = value
		head += from.decode_var_size(head)

func _to_string() -> String:
	return ("StructuredTable:%s>" % get_instance_id())
