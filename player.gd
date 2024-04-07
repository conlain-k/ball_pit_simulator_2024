extends CharacterBody2D

const PIX_TO_METER = 1000

# how much we accelerate each frame
# 0 to 60 in 1 second
@export var accel_rate = 5 * PIX_TO_METER # How fast the player will move (pixels/sec).
@export var max_speed_x = 2 * PIX_TO_METER # How fast the player will move (pixels/sec).
@export var min_speed_x = 0.1 * PIX_TO_METER # How fast the player will move (pixels/sec).

@export var jump_vel = 2 * PIX_TO_METER

# accel due to gravity
const GRAVITY = 9.8 * PIX_TO_METER * 0.5

# keep 90% of speed each frame
const DAMPING = 0.95
var screen_size # Size of the game window.

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size

	#hide()

func get_input():
	var accel = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		accel.x = accel_rate
	if Input.is_action_pressed("move_left"):
		accel.x = -accel_rate
		
	#if is_on_floor() and Input.is_action_pressed("move_up"):
		#accel.y = -jump_accel
		
	# animate on motion
	if accel.length() > 0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	accel.y += GRAVITY

	return accel
	
func _calc_vel(accel, delta):
	if is_on_floor() and Input.is_action_pressed("move_up"):
		velocity.y += -jump_vel
		
	# add motion and gravity
	velocity += accel*delta
	
	if is_on_floor() and accel.x == 0:
		# damp horiz velocity when we're not accelerating
		velocity.x *= DAMPING
		if abs(velocity.x) < min_speed_x:
			velocity.x = 0
	
	
	# Set horizontal speed limit
	velocity.x = clamp(velocity.x, -max_speed_x, max_speed_x)
	
func _handle_collisions():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		log(i)

		if c.get_collider() is RigidBody2D:
			var dir = -c.get_normal(); # use negative normal
			# also add a little bit of upwards thrust if we would go up anyways
			if dir.y < 0:
				dir = (dir + Vector2(0, -0.5)).normalized()
			c.get_collider().apply_central_impulse(200 * dir) 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var accel = get_input()
	#if accel.length() == 0:
		## only damp when not accelerating
		#velocity = DAMPING * velocity
		#if velocity.length() < min_speed:
			#velocity = Vector2.ZERO
	#else:
	_calc_vel(accel, delta)

	#if velocity.length() > max_speed:
		## clamp speed to max
		#velocity = velocity.normalized() * max_speed
		
	# now do physics
	move_and_slide()
	
	_handle_collisions()

	# change direction based on acceleration
	if velocity.y != 0 and abs(accel.y) > 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = accel.y > 0
	elif velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		# See the note below about boolean assignment.
		$AnimatedSprite2D.flip_h = velocity.x < 0

