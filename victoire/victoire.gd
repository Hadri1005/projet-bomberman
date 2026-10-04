extends Node3D

var defaite := false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if defaite:
		$music_defaite.play()
	else:
		$music_victoire.play()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
