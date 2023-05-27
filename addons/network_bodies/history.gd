extends RefCounted
class_name History


var _size : int
var _count : int = 0
var _ring_buffer : RingBuffer
var _to_string_cache : String


func _init(size: int):
	_size = size
	_ring_buffer = RingBuffer.new(size)

func _to_string() -> String:
	if _to_string_cache == "":
		var arr := []
		for i in range(_size):
			arr.append(at(_size))
		_to_string_cache = ("<History:%s>" % get_instance_id()) + "\n" + str(arr)
	return _to_string_cache


func append(x):
	_ring_buffer.push(x)
	_ring_buffer.pop()
	_count = mini(_count + 1, _size)
	_to_string_cache = ""

func at(i: int):
	assert(i >= 0)
	assert(i < _size)
	var arr := data()
	i = _ring_buffer.get_write_index() - i - 1
	return arr[i]

func set_at(i: int, x) -> void:
	assert(i >= 0)
	assert(i < _size)
	var arr := data()
	i = _ring_buffer.get_write_index() - i - 1
	arr[i] = x

func get_head(max: int = -1) -> Array:
	if max == -1:
		max = _count
	var r := []
	for i in range(mini(max, _count)):
		r.append(at(i))
	return r

func find(f: Callable, max: int = -1):
	if max == -1:
		max = _count
	for i in range(mini(max, _count)):
		var x = at(i)
		if f.call(x):
			return x

func find_with_index(f: Callable, max: int = -1):
	if max == -1:
		max = _count
	for i in range(mini(max, _count)):
		var x = at(i)
		if f.call(x):
			return [x, i]

func clear():
	data().clear()
	_count = 0

func size() -> int:
	return _size

func count() -> int:
	return _count

func data() -> Array:
	return _ring_buffer.data()
