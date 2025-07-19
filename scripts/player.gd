extends "res://scripts/character_controller_3d.gd"
var chests : Array[Node]
var levers : Array[Node]

func _process(delta: float) -> void:
	super(delta)

	if chests.size() > 0:
		if Input.is_action_just_pressed("interact_open"):
			var chest = chests.back()
			chest.open()

	if levers.size() > 0:
		if Input.is_action_just_pressed("interact_open"):
			var lever = levers.back()
			lever.switch_toggle()

func _physics_process(delta : float) -> void:
	super(delta)

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