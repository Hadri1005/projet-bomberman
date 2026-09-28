extends CharacterBody3D

const SPEED = 2.0
const GRAVITY = 9.8
const GRID_MIN = 0
const GRID_MAX = 14
const TIMEOUT_DEPLACEMENT = 3.0

static var cellules_reservees: Dictionary = {}

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
var direction_actuelle := "south"
var cellule_actuelle: Vector2i

func _ready() -> void:
	cellule_actuelle = get_spawn_cell()
	cellules_reservees[cellule_actuelle] = self
	position = Vector3(cellule_actuelle.x + 0.5, 1, cellule_actuelle.y + 0.5)
	deplacement_bot()

func _exit_tree() -> void:
	liberer_mes_cellules()

func liberer_mes_cellules() -> void:
	for cell in cellules_reservees.keys():
		if cellules_reservees[cell] == self:
			cellules_reservees.erase(cell)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

func is_mur(cell: Vector2i) -> bool:
	if cell.x < GRID_MIN or cell.x > GRID_MAX or cell.y < GRID_MIN or cell.y > GRID_MAX:
		return true
	return cell.x % 2 != 0 and cell.y % 2 != 0

func is_libre(cell: Vector2i) -> bool:
	return not is_mur(cell) and not cellules_reservees.has(cell)

func direction_name(d: Vector2i) -> String:
	if d == Vector2i(1, 0):
		return "east"
	elif d == Vector2i(-1, 0):
		return "west"
	elif d == Vector2i(0, 1):
		return "south"
	else:
		return "north"

func aller_vers(cible: Vector2, timeout: float) -> bool:
	var ecoule := 0.0
	while Vector2(position.x, position.z).distance_to(cible) > 0.05:
		if ecoule > timeout:
			return false
		var dir2 := (cible - Vector2(position.x, position.z)).normalized()
		velocity.x = dir2.x * SPEED
		velocity.z = dir2.y * SPEED
		await get_tree().physics_frame
		if not is_inside_tree():
			return false
		ecoule += get_physics_process_delta_time()
	return true

func deplacement_bot() -> void:
	while is_inside_tree():
		var directions: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		directions.shuffle()

		var direction_choisie := Vector2i.ZERO
		var cible_trouvee := false
		for d: Vector2i in directions:
			if is_libre(cellule_actuelle + d):
				direction_choisie = d
				cible_trouvee = true
				break

		if not cible_trouvee:
			await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
			continue

		var nouvelle_cellule: Vector2i = cellule_actuelle + direction_choisie
		cellules_reservees[nouvelle_cellule] = self

		direction_actuelle = direction_name(direction_choisie)
		sprite.play("walk_" + direction_actuelle)

		var cible_xz := Vector2(nouvelle_cellule.x + 0.5, nouvelle_cellule.y + 0.5)
		var ok: bool = await aller_vers(cible_xz, TIMEOUT_DEPLACEMENT)
		if not is_inside_tree():
			return

		if ok:
			position.x = cible_xz.x
			position.z = cible_xz.y
			cellules_reservees.erase(cellule_actuelle)
			cellule_actuelle = nouvelle_cellule
		else:
			cellules_reservees.erase(nouvelle_cellule)
			var retour := Vector2(cellule_actuelle.x + 0.5, cellule_actuelle.y + 0.5)
			await aller_vers(retour, TIMEOUT_DEPLACEMENT)
			if not is_inside_tree():
				return
			position.x = retour.x
			position.z = retour.y

		velocity.x = 0
		velocity.z = 0
		sprite.play("idle_" + direction_actuelle)
		await get_tree().create_timer(0.5).timeout

func get_spawn_cell() -> Vector2i:
	while true:
		var tmp := Vector2i(
			randi_range(GRID_MIN + 5, GRID_MAX),
			randi_range(GRID_MIN + 5, GRID_MAX))
		if is_libre(tmp):
			return tmp
	return Vector2i.ZERO
