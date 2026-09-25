extends CharacterBody3D


const SPEED = 4.0
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
var cases_occupees := []

func _ready() -> void:
	position = get_spawn_libre()
	deplacement_bot()
	
func deplacement_bot() -> void:
	var direction
	while true:
		velocity = Vector3.ZERO
		var choix_direction := randi_range(1, 4)
		match choix_direction :
			1:
				velocity.x = SPEED
				direction = "east"
			2:
				velocity.x = -SPEED
				direction = "west"
			3:
				velocity.z = SPEED
				direction = "north"
			4:
				velocity.z = -SPEED
				direction = "south"
		sprite.play("idle_" + direction)
		move_and_slide()
		await get_tree().create_timer(2.0).timeout

func get_spawn_libre() -> Vector3:
	var x: int
	var z: int
	while true:
		x = randi_range(3, 10)
		z = randi_range(3, 6)
		if x % 2 != 0 and z % 2 != 0:
			continue
		var tmp = Vector2i(x, z)
		if tmp not in cases_occupees:
			cases_occupees.append(tmp)
			break
	return Vector3(x + 0.5, 2, z + 0.5)
