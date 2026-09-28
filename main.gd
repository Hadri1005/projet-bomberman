extends Node3D

const VICTOIRE_SCENE = preload("res://victoire/victoire.tscn")

@onready var player1: CharacterBody3D = $player
@onready var player2: CharacterBody3D = $player2

var pvp := false
var partie_finie := false
var p2_layer := 1
var p2_mask := 1

# --- split screen ---
var split: CanvasLayer
var cont1: SubViewportContainer
var cont2: SubViewportContainer
var cam1: Camera3D
var cam2: Camera3D
var cam_offset := Vector3(0, 8, 6)
var cam_basis := Basis(Vector3.RIGHT, deg_to_rad(-55))
var cam_fov := 70.0

func _ready() -> void:
	_setup_split_screen()
	player1.died.connect(func(_p): call_deferred("_verifier_joueurs"))
	player2.died.connect(func(_p): call_deferred("_verifier_joueurs"))
	for e in get_tree().get_nodes_in_group("enemy"):
		e.tree_exited.connect(_verifier_ennemis)
	p2_layer = player2.collision_layer
	p2_mask = player2.collision_mask
	desactiver_joueur2()

# ---------- Caméras ----------
func _setup_split_screen() -> void:
	# On récupère l'angle/la distance de ta caméra existante, puis on la supprime
	var ref: Camera3D = player1.get_node_or_null("Camera3D")
	if ref == null:
		ref = get_node_or_null("Camera3D")
	if ref:
		cam_offset = ref.global_position - player1.global_position
		cam_basis = ref.global_basis
		cam_fov = ref.fov
		ref.queue_free()

	split = CanvasLayer.new()
	split.layer = 0   # sous le HUD (qui est au-dessus)
	add_child(split)

	var v1 := _creer_vue()
	cont1 = v1[0]
	cam1 = v1[1]
	var v2 := _creer_vue()
	cont2 = v2[0]
	cam2 = v2[1]
	_appliquer_layout()

func _creer_vue() -> Array:
	var c := SubViewportContainer.new()
	c.stretch = true
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split.add_child(c)
	var vp := SubViewport.new()
	c.add_child(vp)
	var cam := Camera3D.new()
	cam.basis = cam_basis
	cam.fov = cam_fov
	vp.add_child(cam)
	cam.current = true
	return [c, cam]

func _appliquer_layout() -> void:
	cont1.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cont2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if pvp:
		cont1.anchor_right = 0.5
		cont2.anchor_left = 0.5
		cont1.offset_right = -1   # petite séparation entre les deux vues
		cont2.offset_left = 1
		cont2.show()
	else:
		cont2.hide()

func _process(_delta: float) -> void:
	if is_instance_valid(player1):
		cam1.global_position = player1.global_position + cam_offset
	if pvp and is_instance_valid(player2):
		cam2.global_position = player2.global_position + cam_offset
# ---------- Joueur 2 ----------
func _input(event: InputEvent) -> void:
	if pvp or partie_finie:
		return
	for action in ["p2_bomb", "p2_kick", "p2_left", "p2_right", "p2_up", "p2_down"]:
		if event.is_action_pressed(action):
			activer_joueur2()
			return

func desactiver_joueur2() -> void:
	player2.visible = false
	player2.process_mode = Node.PROCESS_MODE_DISABLED
	player2.remove_from_group("player")
	player2.collision_layer = 0
	player2.collision_mask = 0
	if player2.heart_container:
		player2.heart_container.hide()
	if player2.score_label:
		player2.score_label.hide()

func activer_joueur2() -> void:
	pvp = true
	player2.collision_layer = p2_layer
	player2.collision_mask = p2_mask
	player2.process_mode = Node.PROCESS_MODE_INHERIT
	player2.add_to_group("player")
	player2.visible = true
	player2.velocity = Vector3.ZERO
	player2.global_position = player2.spawn_point
	if player2.heart_container:
		player2.heart_container.show()
	if player2.score_label:
		player2.score_label.show()
	player1.kills = 0
	player1.update_score_label()
	_appliquer_layout()

# ---------- Fin de partie ----------
func _verifier_joueurs() -> void:
	if partie_finie:
		return
	if not pvp:
		if player1.current_health <= 0:
			fin_de_partie("Défaite...")
		return
	var vivants := [player1, player2].filter(func(j): return j.current_health > 0)
	if vivants.size() == 2:
		return
	if vivants.is_empty():
		fin_de_partie("Égalité !")
	else:
		fin_de_partie("%s gagne : dernier survivant !" % vivants[0].nom)

func _verifier_ennemis() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if partie_finie or not is_inside_tree():
		return
	if not get_tree().get_nodes_in_group("enemy").is_empty():
		return
	if not pvp:
		fin_de_partie("Victoire !")
	elif player1.kills > player2.kills:
		fin_de_partie("%s gagne avec %d kills !" % [player1.nom, player1.kills])
	elif player2.kills > player1.kills:
		fin_de_partie("%s gagne avec %d kills !" % [player2.nom, player2.kills])
	else:
		fin_de_partie("Égalité (%d kills chacun) !" % player1.kills)

func fin_de_partie(texte: String) -> void:
	partie_finie = true
	split.hide()
	var ecran := VICTOIRE_SCENE.instantiate()
	add_child(ecran)
	ecran.get_node("Label").text = texte
	ecran.get_node("Camera3D").make_current()
	get_tree().paused = true
