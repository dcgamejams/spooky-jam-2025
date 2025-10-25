extends Node3D

@onready var godot_plush_mesh = $GodotPlushModel/Rig/Skeleton3D/GodotPlushMesh
@onready var physical_bone_simulator_3d = %PhysicalBoneSimulator3D
@onready var animation_tree : AnimationTree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

@onready var center_body: PhysicalBone3D  = $"GodotPlushModel/Rig/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone DEF-hips"
@onready var center_col: CollisionShape3D = $"GodotPlushModel/Rig/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone DEF-hips/CollisionShape3D"

@onready var cR: CharacterBody3D = get_parent().get_parent()
@onready var torus: MeshInstance3D = %TorusIndicator

var ragdoll : bool = false : set = set_ragdoll
var squash_and_stretch = 1.0 : set = set_squash_and_stretch

signal footstep(intensity : float)

func _ready():
	set_ragdoll(ragdoll)
	apply_no_weights()
	%TorusIndicator.top_level = true

func apply_new_weights():
	for child in %PhysicalBoneSimulator3D.get_children():
		var bone: PhysicalBone3D = child
		bone.mass = 0.01

	center_body.mass = 0.1

func apply_no_weights():
	for child in %PhysicalBoneSimulator3D.get_children():
		var bone: PhysicalBone3D = child
		bone.mass = 0.005
		bone.friction  = 0.01
		bone.get_node('CollisionShape3D').disabled = true

	center_body.mass = 0.15
	center_body.friction = 0.8
	center_body.get_node('CollisionShape3D').disabled = false
	
		#bone.gravity_scale = 0.01
		#bone.friction  = 0.0
		#bone.mass = 5.0
		##bone.angular_damp = 50.0
		##bone.angular_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
		##bone.linear_damp = 50.0
		##bone.linear_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE

func set_ragdoll(value : bool) -> void:
	#manage the ragdoll appliements to the model, to call when wanting to go in/out ragdoll mode
	ragdoll = value
	#%EarBubbles.visible = value
	%Bubble.visible = value
	if !is_inside_tree(): return
	physical_bone_simulator_3d.active = ragdoll
	animation_tree.active = !ragdoll
	
	if ragdoll:
		physical_bone_simulator_3d.physical_bones_start_simulation()
	else: 
		physical_bone_simulator_3d.physical_bones_stop_simulation()

	#if is_multiplayer_authority():
		#sync_set_ragdoll.rpc(value)

#@rpc('call_remote', 'authority')
#func sync_set_ragdoll(value):
	##ragdoll = value
	#if !is_inside_tree(): return
	#physical_bone_simulator_3d.active = value
	#animation_tree.active = !value
#
	#if value: 
		#physical_bone_simulator_3d.physical_bones_start_simulation()
		#cR.set_physics_process(true)
	#else: 
		#physical_bone_simulator_3d.physical_bones_stop_simulation()
		#cR.set_physics_process(false)

# This is a cool trick.
# Calling an RPC to other machines but only effecting my puppet.
# I am authority, I'm the only one calling set_state()
# I remote out, with authority, calling on the node matching myself.
func set_state(state_name : String) -> void:
	#set current state of the model state machine (which manage the differents animations)
	state_machine.travel(state_name)
	if is_multiplayer_authority():
		sync_set_state.rpc(state_name)

@rpc('call_remote', 'authority')
func sync_set_state(state_name):
	state_machine.travel(state_name)
	
func set_squash_and_stretch(value : float) -> void:
	#squash and stretch the model
	squash_and_stretch = value
	var negative = 1.0 + (1.0 - squash_and_stretch)
	godot_plush_mesh.scale = Vector3(negative, squash_and_stretch, negative)
	%Bubble.scale = Vector3(negative, squash_and_stretch, negative)
	%EarBubbles.scale = Vector3(negative, squash_and_stretch, negative)

func emit_footstep(intensity : float = 1.0) -> void:
	#call foostep signal in charge of emitting the footstep audio effects
	footstep.emit(intensity)

#func set_mesh_color(new_color: Color):
	#var plush = $GodotPlushModel/Rig/Skeleton3D/GodotPlushMesh
	#for i in 3:
		#var mesh_material: ShaderMaterial = plush.get_active_material(i)
		#var new_mat = mesh_material.duplicate()
		#new_mat['shader_parameter/custom_color'] = new_color
		#plush.set_surface_override_material(i, new_mat)
func wave():
	animation_tree["parameters/WaveOneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	if is_multiplayer_authority(): sync_wave.rpc()

@rpc('call_remote', 'authority')
func sync_wave():
	animation_tree["parameters/WaveOneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func line(pos1: Vector3, pos2: Vector3, line_color = Color.WHITE, persist_ms = 1):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = line_color

	return await final_cleanup(mesh_instance, persist_ms)
	
func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	get_tree().get_root().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
		
@onready var ray_cast_down = %RayCast3D
		
func _process(_delta):
	if ray_cast_down.is_colliding:
		line(global_position, ray_cast_down.get_collision_point())
		%TorusIndicator.position = ray_cast_down.get_collision_point()

#func set_name_tag(username_text: String):
	#%NametagPlush.text = username_text
