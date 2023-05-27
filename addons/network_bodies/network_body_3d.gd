extends CharacterBody3D
class_name NetworkBody3D


const DEFAULT_STATE_TABLE_STRUCTURE := {
	position = Vector3(),
	velocity = Vector3(),
}

@export var peer_id: int

var _previous_global_position

var _current_tick : int = 0

var _server_input_table_history := History.new(4)
var _server_last_received_tick := -1
var _server_ticks_skipped := 0
var _server_ticks_predicted := 0
var _server_last_simulated_input_table: StructuredTable
var _server_simulation_speed_samples := History.new(Engine.physics_ticks_per_second * 2)

var _local_input_table_history := History.new(128)
var _local_state_history := History.new(128)

var _client_state_buffer := RingBuffer.new(16)
var _client_last_received_tick := -1

@onready var interpolated_node: Node3D = $Interpolated


func _physics_process(delta: float) -> void:
	if is_server():
		_server_physics_process(delta)
	elif is_local():
		_local_physics_process(delta)
	else:
		_client_physics_process(delta)

func _process(delta: float) -> void:
	var prev_pos = _previous_global_position
	if prev_pos == null:
		prev_pos = position
	interpolated_node.global_position = lerp(
			prev_pos,
			position,
			Engine.get_physics_interpolation_fraction())


func is_local() -> bool:
	return peer_id == multiplayer.get_unique_id()

func is_server() -> bool:
	return multiplayer.is_server()


func _allocate_input_table() -> StructuredTable:
	return StructuredTable.new()

func _populate_input_table(table: StructuredTable) -> void:
	pass

func _allocate_state_table() -> StructuredTable:
	var table := StructuredTable.new()
	table.structure = DEFAULT_STATE_TABLE_STRUCTURE
	return table

func _populate_state_table(table: StructuredTable) -> void:
	table.position = position
	table.velocity = velocity

func _apply_state_table(table: StructuredTable) -> void:
	position = table.position
	velocity = table.velocity

func _compare_state_tables(local_state: StructuredTable, server_state: StructuredTable) -> bool:
	return local_state.position.distance_squared_to(server_state.position) < 0.001

func _movement_process(table: StructuredTable, delta: float) -> void:
	pass


func _client_physics_process(delta: float) -> void:
	while _client_state_buffer.count() > 0:
		var state = _client_state_buffer.pop()
		print(multiplayer.get_unique_id(), " moving ", peer_id)
		_apply_state_table(state.table)
		_previous_global_position = state.table.position

func _local_physics_process(delta: float) -> void:
	_local_process_state_buffer(delta)
	var table := _allocate_input_table()
	_populate_input_table(table)
	
	_local_input_table_history.append(table)
	_local_send_input_tables()
	
	_local_push_state()
	_previous_global_position = global_position
	_movement_process(table, delta)
	
	_current_tick += 1
	

func _local_send_input_tables() -> void:
	var tables := _local_input_table_history.get_head(3)
	tables.reverse()
	var to_send := PackedByteArray()
	to_send.resize(1024)
	var tick := _current_tick - tables.size() + 1
	to_send.encode_u8(0, tables.size())
	var head := 1
	for table in tables:
		to_send.encode_u64(head, tick)
		head += 8
		
		var data: PackedByteArray = table.pack()
		to_send.encode_u64(head, data.size())
		head += 8
		for i in data.size():
			to_send[head + i] = data[i]
		head += data.size()
		
		tick += 1
	
	rpc_id(1, &"_server_receive_input_table", to_send.compress(3))


func _local_push_state() -> void:
	var table := _allocate_state_table()
	_populate_state_table(table)
	_local_state_history.append({
		table = table,
		tick = _current_tick,
	})

func _local_merge_states(to: StructuredTable, from: StructuredTable) -> void:
	for key in to.structure:
		to[key] = from[key]
	
func _local_process_state_buffer(delta: float) -> void:
	while _client_state_buffer.count() > 0:
		var dict = _client_state_buffer.pop()
		var server_state: StructuredTable = dict.table
		var server_tick: int = dict.tick
		var result = _local_state_history.find_with_index(
			func(x):
				return x.tick == server_tick
		)
		
		if result == null:
			continue
		
		var local_state: StructuredTable = result[0].table
		var history_position: int = result[1]
		if _compare_state_tables(local_state, server_state):
			return
		
		_local_merge_states(local_state, server_state)
		_local_resimulate_from(history_position, delta)


func _local_resimulate_from(history_position: int, delta: float) -> void:
	var dict = _local_state_history.at(history_position)
	var old_state: StructuredTable = dict.table
	_apply_state_table(old_state)
	
	while history_position >= 0:
		var input_table = _local_input_table_history.at(history_position)
		_movement_process(input_table, delta)
		history_position -= 1
		
		if history_position > -1:
			var old_local_state = _local_state_history.at(history_position).table
			_populate_state_table(old_local_state)
			#_previous_global_position = position


@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _client_receive_state(arr: PackedByteArray) -> void:
	var tick := arr.decode_u64(0)
	if tick < 0:
		return
	
	var byte_count := arr.decode_u64(8)
	if byte_count <= 0 or byte_count > 1024:
		return
	var bytes := arr.slice(16, 16 + byte_count)
	
	if tick <= _client_last_received_tick:
		return
	_client_last_received_tick = tick
	
	var table := _allocate_state_table()
	table.unpack(bytes)

	_client_state_buffer.push({
		table = table,
		tick = tick,
	})


func _server_physics_process(delta: float) -> void:
	var input_table = _server_get_matching_input_table()
	if input_table:
		_server_ticks_skipped = 0
		_server_ticks_predicted = 0
		_server_simulation_step(input_table, delta)
		_current_tick += 1
		return
	
	var speedhacking := _server_get_simulation_speed() < 0.9 or _server_get_simulation_speed() > 1.1
	
	if _current_tick == 0:
		return
	
	if _server_ticks_skipped < 3 and not speedhacking:
		_previous_global_position = global_position
		_server_ticks_skipped += 1
		return
	
	_server_ticks_skipped = 0
	
	if _server_ticks_predicted > Engine.physics_ticks_per_second * 2:
		pass
		#multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		#push_warning("Peer(", peer_id, ") dropped")
	
	input_table = _server_last_simulated_input_table
	if input_table == null:
		input_table = _allocate_input_table()
	_server_simulation_step(input_table, delta)
	_current_tick += 1
	_server_ticks_predicted += 1


func _server_simulation_step(table : StructuredTable, delta: float) -> void:
	_server_send_state()
	_previous_global_position = position
	_movement_process(table, delta)
	_server_last_simulated_input_table = table
	_server_simulation_speed_samples.append(Time.get_ticks_usec())


func _server_get_simulation_speed() -> float:
	var count := _server_simulation_speed_samples.count()
	if count < _server_simulation_speed_samples.size():
		return 1.0
	var t = _server_simulation_speed_samples.at(0)
	var sum := 0.0
	for sample in _server_simulation_speed_samples.get_head():
		sum += t - sample
		t = sample
	sum = sum / 1000000.0
	sum *= Engine.physics_ticks_per_second
	return float(count - 1) / sum


func _server_get_matching_input_table():
	var input_table
	for entry in _server_input_table_history.get_head():
		var tick: int = entry.tick
		var table: StructuredTable = entry.table
		if tick == _current_tick:
			input_table = table
			break
	return input_table


func _server_send_state() -> void:
	var table := _allocate_state_table()
	_populate_state_table(table)
	
	var to_send := PackedByteArray()
	to_send.resize(16)
	
	var bytes := table.pack()
	to_send.encode_u64(0, _current_tick)
	to_send.encode_u64(8, bytes.size())
	to_send.append_array(bytes)
	
	rpc(&"_client_receive_state", to_send)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _server_receive_input_table(arr : PackedByteArray) -> void:
	arr = arr.decompress_dynamic(1024, 3)
	var table_count := arr.decode_u8(0)
	var head := 1
	
	for i in table_count:
		var tick := arr.decode_u64(head)
		if tick < 0:
			return
		head += 8
		var byte_count := arr.decode_u64(head)
		var bytes_end := head + byte_count
		if byte_count <= 0 or bytes_end >= arr.size():
			return
		head += 8
		var bytes := arr.slice(head, head + byte_count)
		head += byte_count
		if tick <= _server_last_received_tick:
			continue
		_server_last_received_tick = tick
		
		var table := _allocate_input_table()
		table.unpack(bytes)
		
		_server_input_table_history.append({
			table = table,
			tick = tick,
		})
