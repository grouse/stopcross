extends Node3D

@export var initially_open : bool = false

@export_group("Animation")
@export var anim_close = "close"
@export var anim_open = "open"


var is_open : bool = false

func _ready() -> void:
	if initially_open: open()
	else: close()

func open() -> void:
	if is_open: return
	$AnimationPlayer.play(anim_open)
	is_open = true 
	
func close() -> void:
	if not is_open: return
	$AnimationPlayer.play(anim_close)
	is_open = false
