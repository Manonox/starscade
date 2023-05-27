extends RefCounted
class_name RingBuffer


var _size : int

var _array : Array
var _write_i : int = 0
var _read_i : int = 0


func _init(size : int):
	_size = size
	_array.resize(size)

func _to_string():
	# "[Ring:%s]" % get_instance_id()
	return str(_array)


func push(x):
	var next_i := _wrap_i(_write_i + 1)
	assert(next_i != _read_i)
	_array[_write_i] = x
	_write_i = next_i

func pop():
	if _write_i == _read_i:
		return null
	var x = _array[_read_i]
	_read_i = _wrap_i(_read_i + 1)
	return x

func count() -> int:
	return (_size + (_write_i - _read_i)) % _size

func top():
	return _array[_read_i]

func size() -> int:
	return _size

func get_write_index() -> int:
	return _write_i
func get_read_index() -> int:
	return _read_i

func data() -> Array:
	return _array

func _wrap_i(i : int) -> int:
	if i >= 0:
		return i % _size
	else:
		return (_size + (i % _size)) % _size # Modulo Hack
