extends Node3D

@export var initially_open : bool = false;
var is_open = false;

func _ready() -> void:
	if initially_open:
		$AnimationPlayer.play("open")
	else:
		$AnimationPlayer.play("close")

func open() -> void:
	if is_open: return
	$AnimationPlayer.play("open")
	pass

func close() -> void:
	if not is_open: return
	$AnimationPlayer.play("close")
	pass
