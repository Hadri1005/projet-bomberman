extends Node3D

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("explosion")

func _on_animation_finished():
	queue_free()
