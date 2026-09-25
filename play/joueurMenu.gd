extends AnimatedSprite3D

# Bornes en unites monde (ajuste selon ta scene)
@export var borne_gauche: float = -10.0
@export var borne_droite: float = 10.0
@export var vitesse: float = 5.0  # unites monde/seconde

func _ready() -> void:
	play("walk_east")
	position.x = borne_gauche  # demarre a gauche

func _process(delta: float) -> void:
	position.x += vitesse * delta

	# Quand il atteint le bord droit, repart de gauche
	if position.x > borne_droite:
		position.x = borne_gauche