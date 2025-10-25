extends State

class_name RagdollState

var state_name : String = "Ragdoll"
var cR : Player

var ragdoll_jump_active := false
var ragdoll_jump_cooldown = Timer.new()

var center: PhysicalBone3D

var SLAM_IN_PROGRESS := false
var RAGDOLL_JUMP_FORCE := 80.0 # 120
var RAGDOLL_SPRINT_FORCE := 1.0

var RAGDOLL_ACCEL := 0.5
var RAGDOLL_DECCEL := 0.03

func _ready():
	ragdoll_jump_cooldown.wait_time = 0.5
	ragdoll_jump_cooldown.one_shot = true
	add_child(ragdoll_jump_cooldown)
	ragdoll_jump_cooldown.start()

func enter(char_ref : Player):
	cR = char_ref
	center = char_ref.godot_plush_skin.center_body

	apply_ragdoll()
	verifications()
	
func verifications():
	cR.floor_snap_length = 1.0
	if cR.jump_cooldown > 0.0: cR.jump_cooldown = -1.0
	if cR.nb_jumps_in_air_allowed < cR.nb_jumps_in_air_allowed_ref: cR.nb_jumps_in_air_allowed = cR.nb_jumps_in_air_allowed_ref
	if cR.coyote_jump_cooldown < cR.coyote_jump_cooldown_ref: cR.coyote_jump_cooldown = cR.coyote_jump_cooldown_ref
	if cR.movement_dust.emitting: cR.movement_dust.emitting = false
	
func apply_ragdoll():
	#set model to ragdoll mode
	cR.set_process(false)
	cR.set_physics_process(false)

	cR.godot_plush_skin.ragdoll = true
	center.linear_velocity = cR.velocity
	# Add a little angle if we start in the air
	if cR.floor_check.is_colliding() == false:
		center.angular_velocity = Vector3(0.0, cR.move_dir.x, 0.0) * 100

func update(_delta : float):
	check_if_ragdoll()

func physics_update(delta : float):
	#gravity_apply(delta)
	applies()
	input_management(delta)
	move(delta)

func check_if_ragdoll():
	if !cR.godot_plush_skin.ragdoll:
		transitioned.emit(self, "IdleState")
		
func gravity_apply(delta : float):
	cR.velocity.y -= cR.ragdoll_gravity * delta #apply distant gravity value to follow the model (if wanted)
	
func applies():
	if SLAM_IN_PROGRESS == true and cR.floor_check.is_colliding(): 
		SLAM_IN_PROGRESS = false
		ragdoll_jump_cooldown.start()
		cR.slam_down()
	#cR.velocity.x = 0.0
	#cR.velocity.z = 0.0
	
func input_management(delta):
	if cR.immobile: return

	if Input.is_action_just_pressed("ragdoll"):
		#if ragdoll is set to be only enable on floor
		if cR.ragdoll_on_floor_only and cR.is_on_floor():
			cR.godot_plush_skin.ragdoll = false
		#otherwise
		elif !cR.ragdoll_on_floor_only:
			cR.godot_plush_skin.ragdoll = false

		cR.velocity = center.linear_velocity
		cR.set_process(true)
		cR.set_physics_process(true)
		cR.position = center.global_position + Vector3(0.0, 0.0, 0.0)
		SLAM_IN_PROGRESS = false
	
	if Input.is_action_just_pressed(cR.jumpAction): 
		if ragdoll_jump_active == false and ragdoll_jump_cooldown.is_stopped():
			if cR.floor_check.is_colliding():
				ragdoll_jump_active = true
			elif SLAM_IN_PROGRESS == false and not Input.is_action_pressed('secondary'):
				var slam_force = -100.0
				center.linear_velocity = Vector3.ZERO
				# sqrt so it's effective close to the floor, but also when high up. Wish I knew curves better.
				center.apply_central_impulse(Vector3(0.0, slam_force * sqrt(center.position.y), 0.0) * delta)
				SLAM_IN_PROGRESS = true
	

func move(delta : float):
	var impulse: Vector3 = Vector3.ZERO
	cR.godot_plush_skin.torus.visible = !cR.floor_check.is_colliding()
	
	cR.move_dir = Input.get_vector(cR.moveLeftAction, cR.moveRightAction, cR.moveForwardAction, cR.moveBackwardAction).rotated(-cR.cam_holder.global_rotation.y)
	if Input.is_action_pressed("sprint"):
		RAGDOLL_SPRINT_FORCE = 1.0
	else:
		RAGDOLL_SPRINT_FORCE = 1.0

	#apply smooth move
	var force_x = cR.move_dir.x * cR.move_speed * RAGDOLL_ACCEL * RAGDOLL_SPRINT_FORCE
	var force_z = cR.move_dir.y * cR.move_speed * RAGDOLL_ACCEL * RAGDOLL_SPRINT_FORCE
	var force_y = 0.0
	if ragdoll_jump_active: 
		force_y = RAGDOLL_JUMP_FORCE
		ragdoll_jump_active = false
		ragdoll_jump_cooldown.start()
	elif cR.floor_check.is_colliding() == false:
		force_y = -0.5

	# Deccel
	if force_x == 0.0:
		force_x = -center.linear_velocity.x * RAGDOLL_DECCEL
	if force_z == 0.0:
		force_z = -center.linear_velocity.z * RAGDOLL_DECCEL
	
	impulse = Vector3(force_x, force_y, force_z )
	center.apply_central_impulse(impulse * delta)
	cR.position = cR.godot_plush_skin.center_col.global_position
