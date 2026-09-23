extends CharacterBody3D


const SPEED = 5.0
@export var max_health: int = 3
var current_health: int
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
	
func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
func _on_button_pressed() -> void:
	take_damage() # Replace with function body.
