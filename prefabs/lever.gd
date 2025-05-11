extends Node3D

@export var initially_on : bool = false
@onready var is_on = initially_on

@export_group("Animation")
@export var anim_toggle_on = "toggle-on"
@export var anim_toggle_off = "toggle-off"

func _ready() -> void:
	if initially_on:
		$AnimationPlayer.play(anim_toggle_on)
	else:
		$AnimationPlayer.play(anim_toggle_off)

func switch_on() -> void:
	if is_on: return
	$AnimationPlayer.play(anim_toggle_on)
	is_on = true

func switch_off() -> void:
	if not is_on: return
	$AnimationPlayer.play(anim_toggle_off)
	is_on = false

func switch_toggle() -> void:
	if is_on: switch_off()
	else: switch_on()
