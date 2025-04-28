extends Area3D
class_name Interact

@export var root : Node;

func _ready() -> void:
	if not root:
		printerr("invalid root node; please configure the root node which handles the interaction events appropriately")
