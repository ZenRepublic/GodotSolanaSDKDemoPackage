extends Button

@export_file("*.tscn") var path_to_scene:String

func _on_pressed() -> void:
	get_tree().change_scene_to_file(path_to_scene)
