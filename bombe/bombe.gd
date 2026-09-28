extends CharacterBody3D

const TILE_SIZE = 1.0
const KICK_SPEED = 6.0
const FUSE_TIME = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const EXPLOSION_SCENE = preload("res://explosion/explosion.tscn")
var is_moving = false
var move_direction = Vector3.ZERO
var blink_tween: Tween = null

var ignored_players: Array[Node3D] = []

var grid_map: GridMap
@export var ground_item: int = 3 
@export var destructible_wall_item: int = 5  
@export var ground_orientation: int = 23
@export var explosion_radius: int = 1 


const DIRECTIONS := [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1),
]

func _ready():
	grid_map = get_tree().get_first_node_in_group("grid_map")
	if grid_map == null:
		# Plan B : on cherche n'importe quelle GridMap dans la scène
		grid_map = _find_grid_map(get_tree().current_scene)
	if grid_map == null:
		push_warning("Bombe : aucune GridMap trouvée (groupe 'grid_map' manquant ?)")
	$Timer.wait_time = FUSE_TIME
	$Timer.one_shot = true
	$Timer.start()
	$Timer.timeout.connect(_on_timer_timeout)
	var blink_timer = Timer.new()
	add_child(blink_timer)
	blink_timer.wait_time = FUSE_TIME - 1.5
	blink_timer.one_shot = true
	blink_timer.timeout.connect(start_blinking)
	blink_timer.start()

func _find_grid_map(node: Node) -> GridMap:
	if node is GridMap:
		return node
	for child in node.get_children():
		var found = _find_grid_map(child)
		if found:
			return found
	return null


func _physics_process(delta):
	for player in ignored_players.duplicate():
		if not is_instance_valid(player):
			ignored_players.erase(player)
			continue
		var dist = player.global_position - global_position
		dist.y = 0
		if dist.length() > TILE_SIZE * 0.9:
			ignored_players.erase(player)
			remove_collision_exception_with(player)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if is_moving:
		velocity.x = move_direction.x * KICK_SPEED
		velocity.z = move_direction.z * KICK_SPEED
		move_and_slide()
		if is_on_wall():
			call_deferred("explode")
			is_moving = false
	else:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()

func snap_to_grid():
	var pos = global_position
	global_position = Vector3(
		round(pos.x / TILE_SIZE) * TILE_SIZE,
		pos.y,
		round(pos.z / TILE_SIZE) * TILE_SIZE
	)

func kick(direction: Vector3):
	if is_moving:
		return
	move_direction = get_cardinal_vector(direction)
	is_moving = true
	$Timer.paused = true

func get_cardinal_vector(dir: Vector3) -> Vector3:
	if abs(dir.x) > abs(dir.z):
		return Vector3(sign(dir.x), 0, 0)
	else:
		return Vector3(0, 0, sign(dir.z))

func ignore_player(player: Node3D):
	if not ignored_players.has(player):
		ignored_players.append(player)
	add_collision_exception_with(player)

func _on_timer_timeout():
	explode()

func explode():
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if blink_tween:
		blink_tween.kill()

	if grid_map == null:
		var explosion = EXPLOSION_SCENE.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		queue_free()
		return

	var origin_cell := grid_map.local_to_map(grid_map.to_local(global_position))
	var hit_cells: Array[Vector3i] = [origin_cell]

	_spawn_explosion(origin_cell)

	for dir in DIRECTIONS:
		for i in range(1, explosion_radius + 1):
			var cell: Vector3i = origin_cell + dir * i
			if _destroy_wall_at(cell):
				_spawn_explosion(cell)
				hit_cells.append(cell)
				break
			if _is_solid(cell):
				break
			_spawn_explosion(cell)
			hit_cells.append(cell)

	_hit_entities_in(hit_cells)
	queue_free()
	
func _hit_entities_in(cells: Array[Vector3i]) -> void:
	# Ennemis : disparaissent
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if _is_in_cells(enemy, cells):
			enemy.queue_free()

	# Joueurs : prennent des dégâts
	for player in get_tree().get_nodes_in_group("player"):
		if _is_in_cells(player, cells) and player.has_method("take_damage"):
			player.take_damage()

func _is_in_cells(body: Node3D, cells: Array[Vector3i]) -> bool:
	if not is_instance_valid(body) or body.is_queued_for_deletion():
		return false
	var body_cell := grid_map.local_to_map(grid_map.to_local(body.global_position))
	for cell in cells:
		if cell.x == body_cell.x and cell.z == body_cell.z:
			return true
	return false

func _spawn_explosion(cell: Vector3i) -> void:
	var explosion = EXPLOSION_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion)
	var pos := grid_map.to_global(grid_map.map_to_local(cell))
	pos.y = global_position.y
	explosion.global_position = pos

func _destroy_wall_at(cell: Vector3i) -> bool:
	for dy in [0, 1, -1]:
		var c := Vector3i(cell.x, cell.y + dy, cell.z)
		if grid_map.get_cell_item(c) == destructible_wall_item:
			grid_map.set_cell_item(c, ground_item, ground_orientation)
			return true
	return false

func _is_solid(cell: Vector3i) -> bool:
	for dy in [0, 1, -1]:
		var item := grid_map.get_cell_item(Vector3i(cell.x, cell.y + dy, cell.z))
		if item != GridMap.INVALID_CELL_ITEM and item != ground_item:
			return true
	return false
	
func start_blinking():
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property($Sprite3D, "modulate", Color.RED, 0.15)
	blink_tween.tween_property($Sprite3D, "modulate", Color.WHITE, 0.15)
