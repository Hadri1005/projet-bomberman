extends CharacterBody3D

const SPEED = 2.0
const GRAVITY = 9.8

const GRID_MIN = 0
const GRID_MAX = 14

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
var cases_occupees := []
var direction_actuelle := "south"
var cellule_actuelle: Vector2i  # source de vérité, jamais recalculée depuis position

func _ready() -> void:
	cellule_actuelle = get_spawn_cell()
	position = Vector3(cellule_actuelle.x + 0.5, 1, cellule_actuelle.y + 0.5)
	deplacement_bot()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

func is_mur(cell: Vector2i) -> bool:
	if cell.x < GRID_MIN or cell.x > GRID_MAX or cell.y < GRID_MIN or cell.y > GRID_MAX:
		return true
	return cell.x % 2 != 0 and cell.y % 2 != 0

func direction_name(d: Vector2i) -> String:
	if d == Vector2i(1, 0):
		return "east"
	elif d == Vector2i(-1, 0):
		return "west"
	elif d == Vector2i(0, 1):
		return "south"
	else:
		return "north"

func deplacement_bot() -> void:
	while true:
		var directions: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		directions.shuffle()

		var direction_choisie: Vector2i = Vector2i.ZERO
		var cible_trouvee := false

		for d: Vector2i in directions:
			var cellule_cible: Vector2i = cellule_actuelle + d
			if not is_mur(cellule_cible):
				direction_choisie = d
				cible_trouvee = true
				break

		if not cible_trouvee:
			await get_tree().create_timer(1.0).timeout
			continue

		direction_actuelle = direction_name(direction_choisie)
		sprite.play("walk_" + direction_actuelle)

		var nouvelle_cellule: Vector2i = cellule_actuelle + direction_choisie
		var cible_xz := Vector2(nouvelle_cellule.x + 0.5, nouvelle_cellule.y + 0.5)
		# print("JE SUIS A : ", Vector2(position.x, position.z), "JE VAIS A ", cible_xz)
		while Vector2(position.x, position.z).distance_to(cible_xz) > 0.05:
			var dir2 := (cible_xz - Vector2(position.x, position.z)).normalized()
			velocity.x = dir2.x * SPEED
			velocity.z = dir2.y * SPEED
			await get_tree().physics_frame

		position.x = cible_xz.x
		position.z = cible_xz.y
		cellule_actuelle = nouvelle_cellule
		velocity.x = 0
		velocity.z = 0

		sprite.play("idle_" + direction_actuelle)
		await get_tree().create_timer(1.0).timeout

func get_spawn_cell() -> Vector2i:
	var x: int
	var z: int
	while true:
		x = randi_range(GRID_MIN + 5, GRID_MAX)
		z = randi_range(GRID_MIN + 5, GRID_MAX)
		var tmp := Vector2i(x, z)
		if is_mur(tmp):
			continue
		if tmp not in cases_occupees:
			cases_occupees.append(tmp)
			break
	return Vector2i(x, z)
