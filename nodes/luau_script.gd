extends Node
class_name LuauScript


signal stdout(message: String)
signal stderr(message: String)


var running := false
var object : Node
var owner_id : int
var registered_metatables := {}

@onready var luau_vm : LuauVM = $LuauVM
@onready var luau_initializer = $LuauInitializer
@onready var luau_invoker = $LuauInvoker

@onready var game : Game = Starscade.get_game_instance(self)


func _ready() -> void:
	luau_vm.connect("stdout", self._stdout)
	luau_initializer.initialize_vm()
	luau_invoker.error.connect(func(message):
		stderr.emit(message))


func _process(delta: float) -> void:
	if running:
		luau_invoker.invoke_event("update", [delta])


func _physics_process(delta: float) -> void:
	if running:
		luau_invoker.invoke_event("fixed_update", [delta])


func start() -> void:
	luau_invoker.invoke_event("start")
	running = true


func execute(s: String, chunkname: String = "execute") -> void:
	var result := luau_vm.do_string(s, chunkname)
	if result == -1:
		var error_message := luau_vm.tostring(-1)
		stderr.emit(error_message)
		luau_vm.pop(1)
	else:
		luau_vm.pop(result)


func get_script_owner() -> Node:
	return game.players.map.get(owner_id)


func _stdout(message: String) -> void:
	stdout.emit(message)
	if OS.is_debug_build():
		var tag := "[SV]" if multiplayer.is_server() else "[CL]"
		print(tag, " ", message)
