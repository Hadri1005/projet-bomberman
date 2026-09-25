extends Button


func _ready() -> void:
	# Connexion du signal pressed directement dans le code
	pressed.connect(_on_jouer_button_pressed)


func _on_jouer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
