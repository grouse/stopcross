extends CharacterBody3D

@export_group("Movement")
@export var max_speed : float = 10.0

var input_direction : Vector3 = Vector3.ZERO;

var chests : Array[Node]

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
