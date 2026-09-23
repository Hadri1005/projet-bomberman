extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
