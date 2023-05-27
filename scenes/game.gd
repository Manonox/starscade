extends Node3D
class_name Game


@onready var map := $Map
@onready var entities = $Entities
@onready var players := $Players
@onready var crosshair = %Crosshair
@onready var ui = $UI
@onready var script_creator = $ScriptCreator
@onready var undo = $Undo


func _ready() -> void:
	load_level("res://levels/test.tscn")
	
	_align_crosshair()
	get_viewport().connect("size_changed", self._align_crosshair)
	
	multiplayer.connected_to_server.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		ui.visible = true
		)

func _align_crosshair() -> void:
	crosshair.position = get_viewport().size / 2.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("mouse_release"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()


func unload_level() -> void:
	if map.get_child_count() <= 0:
		return
	map.remove_child(map.get_child(0))


func load_level(path: String) -> void:
	unload_level()
	var resource = load(path)
	if not (resource is PackedScene):
		push_error("{0} is not a PackedScene".format([path]))
	
	var packed_scene := resource as PackedScene
	var scene := packed_scene.instantiate()
	map.add_child(scene)
