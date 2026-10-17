extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	for index in 12:
		await process_frame
	var output_folder := ProjectSettings.globalize_path("res://").path_join("../../outputs").simplify_path()
	var result := root.get_texture().get_image().save_png(output_folder.path_join("AUTO_LAB_Realismus_Vorschau.png"))
	lab.set_hood_open(false, false)
	for index in 4:
		await process_frame
	result = max(result, root.get_texture().get_image().save_png(output_folder.path_join("AUTO_LAB_Mustang_Geschlossen.png")))
	lab.toggle_interior_mode()
	for index in 4:
		await process_frame
	result = max(result, root.get_texture().get_image().save_png(output_folder.path_join("AUTO_LAB_Innenraum_Vorschau.png")))
	print("AUTO_LAB_CAPTURE: ", output_folder, " (", result, ")")
	quit(0 if result == OK else 1)
