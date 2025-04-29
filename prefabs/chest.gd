extends Node3D

@export var initially_open : bool = false;
@onready var is_open = initially_open

func _ready() -> void:
	if initially_open:
		$AnimationPlayer.play("open")
	else:
		$AnimationPlayer.play("close")

func open() -> void:
	if is_open: return
	$AnimationPlayer.play("open")
	is_open = true

func close() -> void:
	if !is_open: return
	$AnimationPlayer.play("close")
	is_open = false 
