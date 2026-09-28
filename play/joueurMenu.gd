extends AnimatedSprite3D

@export var borne_gauche: float = -10.0
@export var borne_droite: float = 10.0
@export var vitesse: float = 5.0
@export var decalage: float = 0.0  

func _ready() -> void:
	play("walk_east")
	position.x = borne_gauche + decalage

func _process(delta: float) -> void:
	position.x += vitesse * delta
	if position.x > borne_droite:
		position.x -= (borne_droite - borne_gauche)
