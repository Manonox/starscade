extends Node


const BUFFER_SIZE := 1024 * 64


@export var game : Game
@export var script_scene : PackedScene
@export var chip_scene : PackedScene

func attach(to: Node, code: String) -> LuauScript:
	var script : LuauScript = script_scene.instantiate()
	script.object = to
	add_child(script)
	return script

func _place_chip(owner_id: int, code: String, chip_id: int) -> void:
	var player : Player = game.players.map.get(owner_id)
	if player == null: return
	
	var chip : Node3D = chip_scene.instantiate()
	chip.name = str(chip_id)
	var pos := player.ray_forward.get_collision_point()
	var normal := player.ray_forward.get_collision_normal()
	if normal != Vector3.UP:
		chip.look_at_from_position(pos, pos + normal)
	else:
		chip.position = pos
		chip.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	var script := attach(chip, code)
	script.owner_id = owner_id
	script.name = str(chip_id)
	
	game.entities.add_child(chip)
	
	script.stdout.connect(self._script_stdout.bind(script))
	script.stderr.connect(self._script_stderr.bind(script))
	
	get_tree().create_timer(0.05, true, false, true).timeout.connect(func():
		script.execute(code, "main.lua")
		script.start()
		)
	
	if multiplayer.is_server():
		game.undo.push(player, [chip, script])


func send_project_to_server(dict: Dictionary):
	rpc_id(1, &"_server_receive_project", _pack_dict(dict))


@rpc("any_peer", "call_remote", "reliable")
func _server_receive_project(data: PackedByteArray) -> void:
	if not multiplayer.is_server(): return
	
	var dict := _unpack_dict(data)
	dict.owner_id = multiplayer.get_remote_sender_id()
	dict.chip_id = randi()
	rpc(&"_receive_project", _pack_dict(dict))


@rpc("authority", "call_local", "reliable")
func _receive_project(data: PackedByteArray) -> void:
	var dict := _unpack_dict(data)
	
	if not (dict.get("code") is String): return
	_place_chip(dict.owner_id, dict.code, dict.chip_id)


func _pack_dict(dict: Dictionary) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(BUFFER_SIZE)
	data.encode_var(0, dict)
	data.resize(data.decode_var_size(0))
	return data.compress()


func _unpack_dict(data: PackedByteArray) -> Dictionary:
	data = data.decompress(BUFFER_SIZE)
	var dict = data.decode_var(0)
	if not (dict is Dictionary):
		return {}
	return dict


@rpc
func _push_console_log(s: String, is_serverside: bool = false) -> void:
	Console.push_log(s, is_serverside)
	
	if not is_serverside:
		Console.push_overlay(s)


@rpc
func _push_console_error(s: String, is_serverside: bool = false) -> void:
	Console.push_log_error(s, is_serverside)
	
	if not is_serverside:
		Console.push_overlay_error(s)


func _script_stdout(s: String, script: LuauScript) -> void:
	var is_local := multiplayer.get_unique_id() == script.owner_id
	var is_server := multiplayer.is_server()
	
	if is_local:
		_push_console_log(s, false)
	
	if is_server:
		rpc_id(script.owner_id, &"_push_console_log", s, true)


func _script_stderr(s: String, script: LuauScript) -> void:
	_script_stdout("Error: " + s, script)

