extends Node


func set_multiplayer(server_multiplayer: MultiplayerAPI) -> void:
	get_tree().set_multiplayer(server_multiplayer, get_path())

func load_scene(packed_scene: PackedScene) -> void:
	var scene = packed_scene.instantiate()
	add_child(scene)


func unload_scene() -> void:
	if get_child_count() <= 0:
		return
	remove_child(get_child(0))
