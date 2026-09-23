extends CharacterBody3D


const SPEED = 5.0
@export var max_health: int = 3
var current_health: int
var last_direction: String = "south"
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

@export var spawn_point: Vector3 = Vector3(0, 0, 0)
func _ready() -> void:
	current_health = max_health
	
func take_damage() -> void:
	current_health = clampi(current_health - 1, 0, max_health)
	global_position = spawn_point 
	print("Current Health: ", current_health)
	if current_health <= 0:
		die()
		
func die() -> void:
	print("Player died!")
	var death_screen = get_node_or_null("../mort")
	if death_screen:
		death_screen.show()
	get_tree().paused = true
	
func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		last_direction = get_cardinal_direction(direction)
		sprite.play("walk_" + last_direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		sprite.play("idle_" + last_direction)

	move_and_slide()
	
func get_cardinal_direction(dir: Vector3) -> String:
	var angle := atan2(dir.x, dir.z)
	var angle_deg := rad_to_deg(angle)
	
	if angle_deg > -45 and angle_deg <= 45:
		return "south" 
	elif angle_deg > 45 and angle_deg <= 135:
		return "east" 
	elif angle_deg > -135 and angle_deg <= -45:
		return "west" 
	else:
		return "north"
		
func _on_button_pressed() -> void:
	take_damage() # Replace with function body.
