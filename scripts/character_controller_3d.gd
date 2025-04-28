extends CharacterBody3D

@export_group("Movement")
@export var max_speed : float = 10.0

var input_direction : Vector3 = Vector3.ZERO;

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass

func _physics_process(delta: float) -> void:
	var target_dir = input_direction.normalized()
	velocity = target_dir * max_speed

	if target_dir.length_squared() > 0:
		$pivot.basis = Basis(target_dir, Vector3.UP, target_dir.cross(Vector3.UP).normalized())

	move_and_slide()

func _process(delta: float) -> void:
	input_direction = Vector3.ZERO;
	if Input.is_action_pressed("move_right"):   input_direction.x += 1;
	if Input.is_action_pressed("move_left"):    input_direction.x -= 1;
	if Input.is_action_pressed("move_forward"): input_direction.z -= 1;
	if Input.is_action_pressed("move_back"):    input_direction.z += 1;
	


func _on_interact_volume_body_entered(body: Node3D) -> void:
	print(body)
	pass

func _on_interact_volume_body_exited(body: Node3D) -> void:
	print(body)
	pass
