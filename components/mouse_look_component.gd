extends Node
class_name MouseLookComponent


@export var horizontal_anchor_node : Node3D
@export var vertical_anchor_node : Node3D
@export var enabled : bool = true

@export_range(0.0, 10.0, 0.05) var sensitivity : float = 1.0
@export_range(-89.0, 89.0, 1.0) var min_pitch : float = -89.0
@export_range(-89.0, 89.0, 1.0) var max_pitch : float = 89.0


func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		_on_mouse_move(event.relative)
		get_viewport().set_input_as_handled()


func _on_mouse_move(relative: Vector2) -> void:
	relative *= -sensitivity
	if horizontal_anchor_node:
		horizontal_anchor_node.rotate_y(relative.x * 0.022 / 180.0 * PI)
	
	if vertical_anchor_node:
		var rotation_x := vertical_anchor_node.rotation.x
		rotation_x += relative.y * 0.022 / 180.0 * PI
		rotation_x = clampf(rotation_x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		vertical_anchor_node.rotation.x = rotation_x
