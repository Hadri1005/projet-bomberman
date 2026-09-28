# bonus.gd
extends Area3D

enum TypeBonus { BOMBE_SUP, PORTEE }

@export var type: TypeBonus = TypeBonus.BOMBE_SUP

# Sprites pour chaque type de bonus
@export var sprite_bombe: Texture2D
@export var sprite_portee: Texture2D

func _ready() -> void:
	match type:
		TypeBonus.BOMBE_SUP:
			$Sprite3D.texture = sprite_bombe
		TypeBonus.PORTEE:
			$Sprite3D.texture = sprite_portee

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	print("body entered: ", body.name, " | is player: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		appliquer_effet(body)
		queue_free()

func appliquer_effet(joueur: Node3D) -> void:
	match type:
		TypeBonus.BOMBE_SUP:
			if joueur.has_method("add_bomb_capacity"):
				joueur.add_bomb_capacity(1)
		TypeBonus.PORTEE:
			pass
