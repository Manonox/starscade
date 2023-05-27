extends NetworkBody3D
class_name Player


@onready var player_movement_component : PlayerMovementComponent = $PlayerMovementComponent
@onready var mouse_look_component : MouseLookComponent = $MouseLookComponent
@onready var tool_belt_component : ToolBeltComponent = $ToolBeltComponent
@onready var body : Node3D = %Body
@onready var head : Node3D = %Head
@onready var mesh_head : MeshInstance3D = %MeshHead
@onready var camera : Camera3D = %Camera
@onready var ray_forward : RayCast3D = %RayForward


func _ready() -> void:
	ray_forward.add_exception(self)
	mouse_look_component.enabled = is_local()
	mesh_head.material_override.albedo_color = Color.from_hsv(peer_id, 0.5, 0.5)
	tool_belt_component.selected_tool = 0


func _input(event: InputEvent):
	if not is_local(): return
	if (event is InputEventMouseButton) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_input(event as InputEventMouseButton)


func _mouse_input(mouse_event: InputEventMouseButton) -> void:
	var button_index := mouse_event.button_index
	if button_index > 0 and button_index <= 2:
		tool_belt_component.use(button_index, mouse_event.pressed)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_local():
		_synchronize_look()


func _synchronize_look() -> void:
	var angle := Vector2(body.rotation.y, head.rotation.x)
	rpc_id(1, &"_server_receive_look", angle)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _apply_look(angle: Vector2) -> void:
	body.rotation.y = angle.x
	head.rotation.x = angle.y


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _server_receive_look(angle: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	for id in multiplayer.get_peers():
		if peer_id == id:
			continue
		rpc_id(id, &"_apply_look", angle)


func _allocate_input_table() -> StructuredTable:
	var table := StructuredTable.new()
	table.structure = player_movement_component.INPUT_TABLE_STRUCTURE
	return table


func _populate_input_table(table: StructuredTable) -> void:
	player_movement_component.calculate_input(table)


func _movement_process(table: StructuredTable, delta: float) -> void:
	player_movement_component.move(table, delta)


func _allocate_state_table() -> StructuredTable:
	var table := StructuredTable.new()
	table.structure = player_movement_component.STATE_TABLE_STRUCTURE
	return table

func _populate_state_table(table: StructuredTable) -> void:
	table.position = position
	table.velocity = velocity
	player_movement_component.calculate_state(table)

func _apply_state_table(table: StructuredTable) -> void:
	position = table.position
	velocity = table.velocity
	player_movement_component.apply_state(table)
