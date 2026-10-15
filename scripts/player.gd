extends CharacterBody3D
## AFTERFALL survivor: proportional procedural stand-in, momentum, melee, dodge, locomotion.
signal health_changed(value: float)
signal died
const MATERIALS = preload("res://scripts/materials.gd")

@export var walking_speed: float = 4.6
@export var running_speed: float = 7.8
var health: float = 100.0
var thirst: float = 100.0
var hunger: float = 100.0
var facing: Vector3 = Vector3(0,0,-1)
var hud # HUD script adds get_move_vector() and is_running(). Do not type this as bare Control.
var camera: Camera3D
var _attack_cooldown: float = 0.0
var _hurt_cooldown: float = 0.0
var _dodge_cooldown: float = 0.0
var _dodge_timer: float = 0.0
var _attack_anim: float = 0.0
var _stride: float = 0.0
var _visual: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D

func _ready() -> void:
    add_to_group("survivor")
    _build_character()
    var col := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = .32
    cap.height = 1.83
    col.shape = cap
    add_child(col)

func _part(parent: Node3D, geometry: Mesh, at: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh_node := MeshInstance3D.new()
    mesh_node.mesh = geometry
    mesh_node.position = at
    mesh_node.rotation = rot
    mesh_node.material_override = mat
    parent.add_child(mesh_node)
    return mesh_node

func _capsule(radius: float, height: float) -> CapsuleMesh:
    var m := CapsuleMesh.new()
    m.radius = radius
    m.height = height
    m.radial_segments = 10
    m.rings = 5
    return m

func _sphere(radius: float, height: float) -> SphereMesh:
    var m := SphereMesh.new()
    m.radius = radius
    m.height = height
    m.radial_segments = 12
    m.rings = 6
    return m

func _build_character() -> void:
    _visual = Node3D.new()
    add_child(_visual)
    var fabric: Material = MATERIALS.fetch("fabric",Color("b0b8a5"))
    var dark: Material = MATERIALS.fetch("fabric",Color("6e756d"))
    var skin: Material = MATERIALS.fetch("skin",Color("e2c9b1"))
    var armor: Material = MATERIALS.fetch("metal",Color("727c71"))
    var leather: Material = MATERIALS.fetch("wood",Color("65605b"))
    # Waist, chest and neck. Proportions establish a human silhouette rather than cubes.
    var chest: MeshInstance3D = _part(_visual,_capsule(.34,.78),Vector3(0,.23,0),fabric)
    chest.scale = Vector3(1.08,1.0,.78)
    var waist: MeshInstance3D = _part(_visual,_capsule(.27,.35),Vector3(0,-.27,0),dark)
    waist.scale.z = .84
    _part(_visual,_capsule(.105,.22),Vector3(0,.72,0),skin)
    _part(_visual,_sphere(.23,.44),Vector3(0,.93,-.015),skin)
    var hair: MeshInstance3D = _part(_visual,_sphere(.233,.20),Vector3(0,1.11,.008),dark)
    hair.scale = Vector3(1.02,1.0,1.04)
    _part(_visual,_capsule(.09,.30),Vector3(.0,.96,-.203),dark,Vector3(PI*.5,0,0)) # mask
    # Shoulder-mounted arm rigs pivot during walk/combat.
    _left_arm = Node3D.new()
    _left_arm.position = Vector3(-.43,.53,0)
    _visual.add_child(_left_arm)
    _part(_left_arm,_capsule(.125,.55),Vector3(0,-.27,0),fabric)
    _part(_left_arm,_capsule(.11,.24),Vector3(0,-.60,0),skin)
    _right_arm = Node3D.new()
    _right_arm.position = Vector3(.43,.53,0)
    _visual.add_child(_right_arm)
    _part(_right_arm,_capsule(.125,.55),Vector3(0,-.27,0),fabric)
    _part(_right_arm,_capsule(.11,.24),Vector3(0,-.60,0),dark)
    # Lower-body gait rigs.
    _left_leg = Node3D.new()
    _left_leg.position=Vector3(-.18,-.38,0)
    _visual.add_child(_left_leg)
    _part(_left_leg,_capsule(.15,.59),Vector3(0,-.32,0),dark)
    _part(_left_leg,_capsule(.15,.27),Vector3(0,-.74,-.075),leather)
    _right_leg = Node3D.new()
    _right_leg.position=Vector3(.18,-.38,0)
    _visual.add_child(_right_leg)
    _part(_right_leg,_capsule(.15,.59),Vector3(0,-.32,0),dark)
    _part(_right_leg,_capsule(.15,.27),Vector3(0,-.74,-.075),leather)
    # Backpack with straps + chest protector, simple handmade stand-in.
    var backpack := BoxMesh.new()
    backpack.size = Vector3(.53,.69,.31)
    _part(_visual,backpack,Vector3(0,.15,.34),leather)
    var vest := BoxMesh.new()
    vest.size=Vector3(.55,.55,.09)
    _part(_visual,vest,Vector3(0,.29,-.26),armor)
    var belt := BoxMesh.new()
    belt.size=Vector3(.63,.10,.37)
    _part(_visual,belt,Vector3(0,-.29,0),leather)

func _physics_process(delta: float) -> void:
    if hud == null or camera == null:
        return
    _attack_cooldown = maxf(0.0,_attack_cooldown-delta)
    _hurt_cooldown = maxf(0.0,_hurt_cooldown-delta)
    _dodge_cooldown = maxf(0.0,_dodge_cooldown-delta)
    _dodge_timer = maxf(0.0,_dodge_timer-delta)
    _attack_anim = maxf(0.0,_attack_anim-delta*3.5)
    var move: Vector2 = hud.get_move_vector()
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move.x-=1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move.x+=1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move.y-=1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move.y+=1.0
    move=move.limit_length(1.0)
    var right: Vector3=camera.global_transform.basis.x
    right.y=0.0
    right=right.normalized()
    var forward: Vector3=-camera.global_transform.basis.z
    forward.y=0.0
    forward=forward.normalized()
    var direction: Vector3=(right*move.x-forward*move.y).normalized()
    var sprint: bool = hud.is_running() or Input.is_key_pressed(KEY_SHIFT)
    var speed: float = running_speed if sprint else walking_speed
    if _dodge_timer > 0.0:
        direction=facing
        speed=11.5
    var rate: float = 28.0 if _dodge_timer>0.0 else 19.0
    velocity.x=move_toward(velocity.x,direction.x*speed,rate*delta)
    velocity.z=move_toward(velocity.z,direction.z*speed,rate*delta)
    velocity.y=-.1 if is_on_floor() else velocity.y-16.0*delta
    move_and_slide()
    if direction.length_squared()>.005:
        facing=direction
        _visual.rotation.y=lerp_angle(_visual.rotation.y,atan2(-facing.x,-facing.z),delta*11.0)
    var moving: float=clampf(Vector2(velocity.x,velocity.z).length()/running_speed,0.0,1.0)
    _stride+=delta*(11.5 if sprint else 8.1)*moving
    var step: float=sin(_stride)*moving
    _left_leg.rotation.x=lerpf(_left_leg.rotation.x,step*.54,delta*12.0)
    _right_leg.rotation.x=lerpf(_right_leg.rotation.x,-step*.54,delta*12.0)
    _left_arm.rotation.x=lerpf(_left_arm.rotation.x,-step*.28,delta*10.0)
    _right_arm.rotation.x=lerpf(_right_arm.rotation.x,step*.22-_attack_anim*1.2,delta*12.0)
    _visual.position.y=absf(sin(_stride))*.035*moving
    hunger=maxf(0.0,hunger-.045*delta)
    thirst=maxf(0.0,thirst-(0.09 if sprint else 0.06)*delta)
    if hunger<=0.0 or thirst<=0.0:
        take_damage(1.8*delta)

func attack(enemies: Array) -> bool:
    if _attack_cooldown>0.0:
        return false
    _attack_cooldown=.61
    _attack_anim=.8
    var target = null # actual instance is enemy.gd; CharacterBody3D lacks take_damage() in static API
    var best: float = 2.35
    for enemy in enemies:
        if not is_instance_valid(enemy): continue
        var offset: Vector3=enemy.global_position-global_position
        var flat:=Vector3(offset.x,0.0,offset.z)
        var length: float=flat.length()
        if length<best and (length<1.0 or facing.dot(flat.normalized())>0.05):
            target=enemy
            best=length
    if target!=null:
        target.take_damage(55.0)
        return true
    return false

func dodge() -> bool:
    if _dodge_cooldown>0.0 or _dodge_timer>0.0:
        return false
    _dodge_timer=.30
    _dodge_cooldown=1.45
    _hurt_cooldown=.34
    return true

func take_damage(amount: float) -> void:
    if _hurt_cooldown>0.0:
        return
    _hurt_cooldown=.48
    health=maxf(0.0,health-amount)
    health_changed.emit(health)
    if health<=0.0: died.emit()

func reset_after_death(spawn: Vector3) -> void:
    global_position=spawn
    health=100.0
    hunger=75.0
    thirst=75.0
    _hurt_cooldown=1.8
    velocity=Vector3.ZERO
    health_changed.emit(health)
