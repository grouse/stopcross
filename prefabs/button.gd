extends Node3D
class_name MyButton

@export var initially_on : bool = false
@export var opens_node : Node

@export_group("Animation")
@export var anim_toggle_on = "toggle-on"
@export var anim_toggle_off = "toggle-off"

@onready var is_on = initially_on

func _ready() -> void:
	if initially_on:
		$AnimationPlayer.play(anim_toggle_on)
	else:
		$AnimationPlayer.play(anim_toggle_off)

func switch_on() -> void:
	if is_on: return
	$AnimationPlayer.play(anim_toggle_on)
	is_on = true
	if opens_node: opens_node.open()

func switch_off() -> void:
	if not is_on: return
	$AnimationPlayer.play(anim_toggle_off)
	is_on = false
	if opens_node: opens_node.close()

func switch_toggle() -> void:
	if is_on: switch_off()
	else: switch_on()
