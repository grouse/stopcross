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
@export_range(0, 1, 0.01) var air_control_factor : float = 0.3 
@export_range(0, 100, 0.01) var air_friction : float = 0

@export_group("Debug")
@export var draw_movement_vectors : bool = false

@onready var acceleration  = max_speed / time_to_max_speed
@onready var deceleration  = max_speed / time_to_stop;

var external_velocity : Vector3 = Vector3.ZERO

var turn_rate_rad     = 10000
var reverse_decel;

var input_direction : Vector3 = Vector3.ZERO;
var chests : Array[Node]
var levers : Array[Node]

func _ready() -> void:
	if time_to_turn_90 > 0: turn_rate_rad = 1 / time_to_turn_90
	reverse_decel = max_speed*2 / time_to_stop_reverse if time_to_stop_reverse > 0 else deceleration

func _unhandled_input(event: InputEvent) -> void:
	pass

func reject(a : Vector3, b : Vector3) -> Vector3:
	return a-b*(a.dot(b)/b.dot(b))

func _physics_process(delta: float) -> void:
	var gravity_dir = get_gravity().normalized()
	var gravity_strength = get_gravity().length() * gravity_scale

	var u_dir = -gravity_dir

	var dir   = velocity.normalized()
	var t_dir = input_direction.normalized()
	var i_dir = t_dir

	if is_on_wall():
		var wall_n = get_wall_normal()
		if draw_movement_vectors: DebugDraw3D.draw_arrow(global_position, global_position+wall_n, Color.AQUA, 0.1)

		if t_dir.length_squared() > 0.0001:
			var wall_t = t_dir - t_dir.dot(wall_n)*wall_n
			if draw_movement_vectors: DebugDraw3D.draw_arrow(global_position, global_position+wall_t, Color.TURQUOISE, 0.1)
			if wall_t.length_squared() > 0.0001:
				t_dir = wall_t.normalized()
		pass

	t_dir = (t_dir - t_dir.dot(gravity_dir)*gravity_dir).normalized()

	var movement_velocity = velocity - velocity.dot(gravity_dir)*gravity_dir

	var control_factor = 1 if is_on_floor() else air_control_factor
	var accel = acceleration
	var friction = deceleration if is_on_floor() else 0

	if not is_on_floor(): 
		external_velocity += gravity_dir*gravity_strength*delta
		var falling_component = external_velocity.dot(gravity_dir)*gravity_dir
		if falling_component.length() > terminal_velocity:
			external_velocity -= falling_component
			external_velocity += gravity_dir*terminal_velocity

	if is_on_floor():
		if movement_velocity.length_squared() > 0.0001:
			if t_dir.length_squared() > 0.0001:
				friction = 0
				var angle = dir.angle_to(t_dir)
				var max_angle_change = turn_rate_rad*delta


				if angle > PI * 0.8:
					accel = reverse_decel
				elif angle > max_angle_change:
					var axis = dir.cross(t_dir).normalized()
					if axis.length_squared() > 0.0001:
						movement_velocity = dir.rotated(axis, max_angle_change)*movement_velocity.length()
						t_dir = movement_velocity.normalized()
				else:
					movement_velocity = t_dir*movement_velocity.length()
					dir = t_dir

	var speed = movement_velocity.length()
	if t_dir.length_squared() > 0:
		movement_velocity += accel*t_dir*delta*control_factor
		speed = min(movement_velocity.length(), max_speed)
		movement_velocity = movement_velocity.normalized()*speed
	else:
		speed -= friction*delta
		speed = max(0, speed)
		movement_velocity = speed*dir

	if movement_velocity.length_squared() <= 0.001:
		movement_velocity = Vector3.ZERO

	velocity = movement_velocity + external_velocity

	if i_dir.length_squared() > 0:
		$pivot.basis = Basis(i_dir, u_dir, i_dir.cross(u_dir).normalized())

	var was_on_floor = is_on_floor()
	var old_transform = global_transform

	move_and_slide()

	if draw_movement_vectors:
		DebugDraw3D.draw_arrow(global_position, global_position+movement_velocity, Color.GREEN, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+external_velocity, Color.MAGENTA, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+i_dir, Color.CYAN, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+t_dir, Color.BLUE, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position-dir*friction, Color.RED, 0.1)
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
			var chest = chests.back()
			chest.open()

	if levers.size() > 0:
		if Input.is_action_just_pressed("interact_open"):
			var lever = levers.back()
			lever.switch_toggle()

func add_interacting_object(node : Node, nodes : Array[Node]) -> bool:
	if nodes.has(node): return false

	print("adding interacting object: ", node)
	nodes.append(node)
	return true

func remove_interacting_object(node : Node, nodes : Array[Node]) -> bool:
	var index = nodes.find(node)
	if index == -1: return false

	print("removing interacting object: ", node)
	nodes.remove_at(index)
	return true 


func _on_interact_volume_area_entered(area: Area3D) -> void:
	var node = area
	if node as Interact: node = node.root
	if node.is_in_group("chest"): add_interacting_object(node, chests)
	if node.is_in_group("lever"): add_interacting_object(node, levers)

func _on_interact_volume_area_exited(area: Area3D) -> void:
	var node = area
	if node as Interact: node = node.root
	if node.is_in_group("chest"): remove_interacting_object(node, chests)
	if node.is_in_group("lever"): remove_interacting_object(node, levers)
