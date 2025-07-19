extends IKCC 

@export_group("Movement")
@export_range(0, 1000, 0.1, "suffix:m/s") var max_speed            : float = 10.0
@export_range(0, 100, 0.01, "suffix:s") var time_to_max_speed    : float = 0.3
@export_range(0, 100, 0.01, "suffix:s") var time_to_stop         : float = 0.15
@export_range(0, 100, 0.01, "suffix:s") var time_to_stop_reverse : float = 0.15

@export_group("Falling")
@export_range(0, 100, 0.01) var gravity_scale : float = 1
@export_range(0, 1000, 0.01, "suffix:m/s") var terminal_velocity : float = 50
@export_range(0, 1, 0.01) var air_control_factor : float = 0.3 
@export_range(0, 100, 0.01) var air_friction : float = 0

@export_group("Debug")
@export var draw_movement_vectors : bool = false
@export var draw_wall_detection : bool = false

@onready var acceleration  = max_speed / time_to_max_speed if time_to_max_speed > 0 else max_speed
@onready var deceleration  = max_speed / time_to_stop if time_to_stop > 0 else max_speed
@onready var reverse_decel = max_speed * 2 / time_to_stop_reverse if time_to_stop_reverse > 0 else deceleration

func _ready() -> void:
	print("Acceleration: %.2f m/s², Deceleration: %.2f m/s², Reverse Deceleration: %.2f m/s²" % [acceleration, deceleration, reverse_decel])


var external_velocity : Vector3 = Vector3.ZERO
var input_direction : Vector3 = Vector3.ZERO;

func _physics_process(delta: float) -> void:
	var gravity_dir = get_gravity().normalized()
	var gravity_strength = get_gravity().length() * gravity_scale

	var floor_n = last_floor_normal
	var floor_t = floor_n.cross(Vector3.RIGHT).normalized()
	var floor_b = floor_t.cross(Vector3.UP).normalized()

	var u_dir = -gravity_dir
	var i_dir = input_direction.normalized()
	var dir   = velocity.normalized()

	if is_on_floor:
		var friction_factor = 1
		var ground_accel = acceleration
		var ground_friction = deceleration

		if i_dir != Vector3.ZERO:
			friction_factor = 0
			var turn_angle = velocity.angle_to(i_dir)
			if turn_angle > PI*0.8:
				ground_accel = reverse_decel
			else:
				# snap-turn to input_dir 
				velocity = i_dir*velocity.length()
				dir = velocity.normalized()

		var ground_dir = i_dir.slide(current_floor_normal).normalized()
		velocity += gravity_dir.dot(ground_dir) * ground_dir * delta * gravity_strength

		velocity = apply_friction(velocity, ground_friction*friction_factor, delta)
		velocity = accelerate(velocity, ground_accel, i_dir, max_speed, delta)
	else:
		velocity += gravity_dir*gravity_strength * delta

		var v_velocity = velocity.project(up_direction)
		var h_velocity = velocity - v_velocity

		var air_accel = acceleration * air_control_factor
		h_velocity = apply_friction(h_velocity, air_friction, delta)
		h_velocity = accelerate(h_velocity, air_accel, i_dir, max_speed, delta)
		velocity = h_velocity + v_velocity

	if i_dir.length_squared() > 0:
		$pivot.basis = Basis(i_dir, u_dir, i_dir.cross(u_dir).normalized())

	var was_on_floor = is_on_floor
	var old_transform = global_transform

	move_and_slide()

	if draw_movement_vectors:
		DebugDraw3D.draw_arrow(global_position, global_position+floor_n*2, Color.BROWN, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+floor_t*2, Color.OLIVE, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+floor_b*2, Color.AQUA, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+external_velocity, Color.MAGENTA, 0.1)
		DebugDraw3D.draw_arrow(global_position, global_position+i_dir, Color.CYAN, 0.1)
		DebugDraw3D.draw_text(global_position+Vector3.FORWARD+Vector3.UP, "%.2f" % velocity.length(), 64)

		if is_on_floor and !was_on_floor:
			DebugDraw3D.draw_sphere(old_transform.origin, 0.5, Color.GREEN, 1)
		elif !is_on_floor and was_on_floor:
			DebugDraw3D.draw_sphere(old_transform.origin, 0.5, Color.RED, 1)

		DebugDraw3D.draw_sphere(old_transform.origin, 0.1, Color.WHITE, 1)

func _process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_direction.x = direction.x;
	input_direction.z = direction.y;


static func apply_friction(
	p_velocity       : Vector3,
	p_friction_speed : float,
	p_delta_t        : float) -> Vector3 :

	if p_velocity == Vector3.ZERO: return Vector3.ZERO
	if is_zero_approx(p_velocity.length_squared()): return Vector3.ZERO
	if is_zero_approx(p_friction_speed): return p_velocity
	
	var friction : Vector3 = -p_velocity * p_friction_speed * p_delta_t
	var new_velocity : Vector3 = p_velocity + friction

	var dir = p_velocity.normalized()
	var new_speed = max(0, dir.dot(new_velocity))
	return dir*new_speed

static func accelerate(
	p_velocity  : Vector3,
	p_accel     : float,
	p_accel_dir : Vector3,
	p_max_speed : float,
	p_delta_t   : float
	) -> Vector3 :
	if p_accel_dir.is_zero_approx() :
		return p_velocity
	
	# Add acceleration
	var accel_speed  : float = p_accel * p_delta_t
	var new_velocity : Vector3 = p_velocity + p_accel_dir * accel_speed
	
	# Liimt length
	var max_speed : float = maxf(p_max_speed, p_velocity.length())
	new_velocity = new_velocity.limit_length(max_speed)
	
	return new_velocity
