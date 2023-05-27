extends Node
class_name PlayerMovementComponent


const INPUT_TABLE_STRUCTURE := {
	wish_dir = Vector3(),
	wish_jump = false,
}

const STATE_TABLE_STRUCTURE := {
	position = Vector3(),
	velocity = Vector3(),
	on_ground = false,
	touching_ground = false,
}


@export var player : Player
@export var horizontal_anchor : Node3D

@export var properties : MovementProperties


var input : StructuredTable
var dt := 0.0
var on_ground := false
var touching_ground := false


func calculate_state(table: StructuredTable) -> void:
	table.on_ground = on_ground
	table.touching_ground = touching_ground


func apply_state(table: StructuredTable) -> void:
	on_ground = table.on_ground
	touching_ground = table.touching_ground


func calculate_input(table: StructuredTable) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var keydir_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var keydir_3d := Vector3(keydir_2d.x, 0, keydir_2d.y)
	var direction = (horizontal_anchor.transform.basis * keydir_3d).normalized()
	table.wish_dir = direction
	
	table.wish_jump = Input.is_action_pressed("move_jump")


func move(table: StructuredTable, deltatime: float) -> void:
	input = table
	dt = deltatime
	
	_apply_gravity(0.5)
	_friction()
	_accelerate()
	on_ground = false
	touching_ground = false
	_float()
	_check_up_velocity()
	_try_jump()
	_apply_gravity(0.5)
	
	player.move_and_slide()
	for i in range(player.get_slide_collision_count()):
		_handle_collision(player.get_slide_collision(i))
	_check_up_velocity()


func _accelerate() -> void:
	var wish_dir : Vector3 = input.wish_dir
	wish_dir = _sanitize_wish_dir(wish_dir)
	
	var wish_speed := properties.max_speed if on_ground else properties.air_limit
	var current_speed := player.velocity.dot(wish_dir)
	var add_speed := wish_speed - current_speed
	if add_speed < 0.0:
		return
	
	var acceleration := properties.ground_acceleration if on_ground else properties.air_acceleration
	var acceleration_speed := minf(acceleration * wish_speed * dt, add_speed)
	player.velocity += wish_dir * acceleration_speed


func _friction() -> void:
	if not on_ground:
		return
	
	var speed_squared := player.velocity.length_squared()
	if speed_squared < 0.001:
		player.velocity = Vector3()
		return
	
	var speed := pow(speed_squared, 0.5)
	var control := maxf(properties.stopspeed, speed)
	var drop := control * properties.friction * dt
	
	var newspeed := maxf(speed - drop, 0.0)
	player.velocity *= newspeed / speed


func _apply_gravity(multiplier: float) -> void:
	player.velocity.y -= properties.gravity * multiplier * dt


func _check_up_velocity() -> void:
	if player.velocity.y > 3.0:
		on_ground = false


func _try_jump() -> void:
	if not input.wish_jump:
		return
	if not touching_ground:
		return
	_jump()


func _jump() -> void:
	on_ground = false
	player.velocity.y = properties.jump_power


func _float() -> void:
	var float_height := properties.float_height
	var collision := player.move_and_collide(Vector3(0.0, -float_height, 0.0), true)
	if collision == null:
		return
	_handle_collision(collision)
	var updraft := collision.get_remainder().length()
	updraft = pow(updraft, 2.0)
	updraft = minf(updraft, 4.0 * float_height * dt)
	player.move_and_collide(Vector3(0.0, updraft, 0.0))


func _handle_collision(collision: KinematicCollision3D) -> void:
	if collision == null:
		return
	for i in range(collision.get_collision_count()):
		var normal := collision.get_normal(i)
		var is_ground := normal.y > 0.5
		if is_ground:
			touching_ground = true
		if normal.dot(player.velocity) < 0.0:
			player.velocity = player.velocity.slide(normal)
			if is_ground:
				on_ground = true

func _sanitize_wish_dir(wish_dir: Vector3) -> Vector3:
	var up := horizontal_anchor.transform.basis.y
	var up_component := wish_dir.dot(up) * up
	wish_dir = wish_dir - up_component
	return wish_dir.normalized()
