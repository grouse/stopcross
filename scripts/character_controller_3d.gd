extends CharacterBody3D

@export_group("Movement")
@export_range(0, 1000, 0.1, "suffix:m/s") var max_speed            : float = 10.0
@export_range(0, 100, 0.01, "suffix:s") var time_to_max_speed    : float = 0.3
@export_range(0, 100, 0.01, "suffix:s") var time_to_stop         : float = 0.15
@export_range(0, 100, 0.01, "suffix:s") var time_to_turn_90      : float = 0.05
@export_range(0, 100, 0.01, "suffix:s") var time_to_stop_reverse : float = 0.15

@onready var acceleration  = max_speed / time_to_max_speed
@onready var deceleration  = max_speed / time_to_stop;

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

	var dir   = velocity.normalized()
	var f_dir = -dir
	var t_dir = input_direction.normalized()

	var accel = acceleration
	var friction = 0

	if velocity.length_squared() > 0.0001:
		if t_dir.length_squared() <= 0.0001:
			friction = deceleration
		else:
			var angle = dir.angle_to(t_dir)
			var max_angle_change = turn_rate_rad*delta

			if angle > PI * 0.8:
				accel = reverse_decel*2
			elif angle > max_angle_change:
				var axis = dir.cross(t_dir).normalized()
				if axis.length_squared() > 0.0001:
					velocity = dir.rotated(axis, max_angle_change)*velocity.length()
					dir = velocity.normalized()
			else:
				velocity = t_dir*velocity.length()
				dir = t_dir

	DebugDraw3D.draw_arrow(global_position, global_position+velocity, Color.GREEN, 0.05)
	DebugDraw3D.draw_arrow(global_position, global_position+t_dir*acceleration, Color.RED, 0.05)
	DebugDraw3D.draw_arrow(global_position, global_position+f_dir*friction, Color.MAGENTA, 0.05)
	velocity += t_dir*accel*delta + f_dir*friction*delta;

	if velocity.length_squared() > max_speed*max_speed: 
		velocity = velocity.normalized()*max_speed;

	if t_dir.length_squared() > 0:
		$pivot.basis = Basis(t_dir, Vector3.UP, t_dir.cross(Vector3.UP).normalized())

	move_and_slide()

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
