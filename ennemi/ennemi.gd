extends CharacterBody3D

const SPEED = 2.0
const GRAVITY = 9.8
const GRID_MIN = 0
const GRID_MAX = 14
const TIMEOUT_DEPLACEMENT = 3.0
const DIRECTIONS: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

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
		var direction_choisie := Vector2i.ZERO

		if randf() < 0.5:
			direction_choisie = direction_vers_player()

		if direction_choisie == Vector2i.ZERO:
			direction_choisie = direction_aleatoire_libre()

		if direction_choisie == Vector2i.ZERO:
			await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
			continue

		var nouvelle_cellule: Vector2i = cellule_actuelle + direction_choisie
		cellules_reservees[nouvelle_cellule] = self

		sprite.play("walk")

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
		sprite.play("idle")
		await get_tree().create_timer(0.5).timeout

func get_spawn_cell() -> Vector2i:
	while true:
		var tmp := Vector2i(
			randi_range(GRID_MIN + 5, GRID_MAX),
			randi_range(GRID_MIN + 5, GRID_MAX))
		if is_libre(tmp):
			return tmp
	return Vector2i.ZERO

func direction_vers_player() -> Vector2i:
	var joueur := get_tree().get_first_node_in_group("player") as Node3D
	if joueur == null:
		return Vector2i.ZERO

	var cible := Vector2i(floori(joueur.global_position.x), floori(joueur.global_position.z))

	var meilleure := Vector2i.ZERO
	var meilleure_dist := Vector2(cellule_actuelle - cible).length()
	for d: Vector2i in DIRECTIONS:
		var voisin: Vector2i = cellule_actuelle + d
		if not is_libre(voisin):
			continue
		var dist := Vector2(voisin - cible).length()
		if dist < meilleure_dist:
			meilleure_dist = dist
			meilleure = d
	return meilleure
	
func direction_aleatoire_libre() -> Vector2i:
	var libres := DIRECTIONS.filter(func(d: Vector2i) -> bool: return is_libre(cellule_actuelle + d))
	if libres.is_empty():
		return Vector2i.ZERO
	return libres.pick_random()
