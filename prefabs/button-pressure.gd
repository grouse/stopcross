extends MyButton


func _on_triggervolume_area_entered(area: Area3D) -> void:
	print("area entered")
	pass # Replace with function body.


func _on_triggervolume_area_exited(area: Area3D) -> void:
	print("area exited")
	pass # Replace with function body.


func _on_triggervolume_body_entered(body: Node3D) -> void:
	print("body entered")
	pass # Replace with function body.


func _on_triggervolume_body_exited(body: Node3D) -> void:
	print("body exited")
	pass # Replace with function body.
