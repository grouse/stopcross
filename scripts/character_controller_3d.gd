extends CharacterBody3D

@export_group("Movement")
@export_range(0, 1000, 0.1, "suffix:m/s") var max_speed            : float = 10.0
@export_range(0, 100, 0.01, "suffix:s") var time_to_max_speed    : float = 0.3
@export_range(0, 100, 0.01, "suffix:s") var time_to_stop         : float = 0.15
@export_range(0, 100, 0.01, "suffix:s") var time_to_turn_90      : float = 0.05
@export_range(0, 100, 0.01, "suffix:s") var time_to_stop_reverse : float = 0.15

@export_group("Falling")
@export_range(0, 100, 0.01) var gravity_scale : float = 1
@export_range(0, 1000, 0.01, "suffix:m/s") var terminal_velocity : float = 50

@export_group("Debug")
@export var draw_movement_vectors : bool = false

@onready var acceleration  = max_speed / time_to_max_speed
@onready var deceleration  = max_speed / time_to_stop;

var external_velocity : Vector3 = Vector3.ZERO

var turn_rate_rad     = 10000
var reverse_decel;

var input_direction : Vector3 = Vector3.ZERO;
var chests : Array[Node]

func _ready() -> void:
	if time_to_turn_90 > 0: turn_rate_rad = 0.5 / time_to_turn_90
	reverse_decel = max_speed / time_to_stop_reverse if time_to_stop_reverse > 0 else deceleration

func _unhandled_input(event: InputEvent) -> void:
	pass

func reject(a : Vector3, b : Vector3) -> Vector3:
	return a-b*(a.dot(b)/b.dot(b))

func _physics_process(delta: float) -> void:
	var gravity_dir = get_gravity().normalized()
	var gravity_strength = get_gravity().length() * gravity_scale

	var dir   = velocity.normalized()
	var t_dir = input_direction.normalized()
	t_dir = t_dir - t_dir.dot(gravity_dir)*gravity_dir

	var movement_velocity = velocity - velocity.dot(gravity_dir)*gravity_dir

	var accel = acceleration if is_on_floor() else 0
	var friction = 0

	if not is_on_floor(): 
		external_velocity += gravity_dir*gravity_strength*delta
		var falling_component = external_velocity.dot(gravity_dir)*gravity_dir
		if falling_component.length() > terminal_velocity:
			external_velocity -= falling_component
			external_velocity += gravity_dir*terminal_velocity
	else:
		external_velocity -= external_velocity.dot(gravity_dir)*gravity_dir

	if movement_velocity.length_squared() > 0.0001:
		if t_dir.length_squared() <= 0.0001:
			if is_on_floor(): friction = deceleration
		else:
			var angle = dir.angle_to(t_dir)
			var max_angle_change = turn_rate_rad*delta

			if angle > PI * 0.8:
				accel = reverse_decel*2
				dir = t_dir
			elif angle > max_angle_change:
				var axis = dir.cross(t_dir).normalized()
				if axis.length_squared() > 0.0001:
					movement_velocity = dir.rotated(axis, max_angle_change)*movement_velocity.length()
					dir = movement_velocity.normalized()
			else:
				movement_velocity = t_dir*movement_velocity.length()
				dir = t_dir
	else:
		dir = t_dir

	var speed = movement_velocity.length()
	if t_dir.length_squared() > 0:
		speed = min(speed+accel*delta, max_speed)
	else:
		speed = max(speed-friction*delta, 0)

	if speed > 0 and dir.length_squared() > 0.0001:
		movement_velocity = dir*speed
	else:
		movement_velocity = Vector3.ZERO

	velocity = movement_velocity + external_velocity

	if t_dir.length_squared() > 0:
		$pivot.basis = Basis(t_dir, Vector3.UP, t_dir.cross(Vector3.UP).normalized())

	var was_on_floor = is_on_floor()
	var old_transform = global_transform

	move_and_slide()

	if draw_movement_vectors:
		DebugDraw3D.draw_arrow(global_position, global_position+t_dir*acceleration, Color.RED, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position-dir*friction, Color.MAGENTA, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+velocity, Color.GREEN, 0.1)
		DebugDraw3D.draw_text(global_position+Vector3.FORWARD+Vector3.UP, "%.2f" % velocity.length(), 64)

		if is_on_floor() and !was_on_floor:
			DebugDraw3D.draw_sphere(old_transform.origin, 0.5, Color.GREEN, 1)
		elif !is_on_floor() and was_on_floor:
			DebugDraw3D.draw_sphere(old_transform.origin, 0.5, Color.RED, 1)

		DebugDraw3D.draw_sphere(old_transform.origin, 0.1, Color.WHITE, 1)

func _process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_direction.x = direction.x;
	input_direction.z = direction.y;

	if chests.size() > 0:
		if Input.is_action_just_pressed("interact_open"):
			var chest = chests.pop_back()
			chest.open()

func _on_interact_volume_area_entered(area: Area3D) -> void:
	var node = area
	if node as Interact: node = node.root
	if node.is_in_group("chest") && !chests.has(node): chests.append(node)

func _on_interact_volume_area_exited(area: Area3D) -> void:
	var node = area
	if node as Interact: node = node.root
	if node.is_in_group("chest"):
		var index = chests.find(node)
		if index != -1: chests.remove_at(index)
