extends CharacterBody3D
## Infected enemy with patrol, chase, obstacle check and stagger animation.
signal defeated(enemy: CharacterBody3D)
const MATERIALS = preload("res://scripts/materials.gd")
var target # the player script provides take_damage() beyond CharacterBody3D
var health: float=100.0
var _strike_time: float=0.0
var _origin: Vector3
var _roam_time: float=0.0
var _roam: Vector3=Vector3.ZERO
var _body: Node3D
var _gait: float=0.0
var _left_leg: Node3D
var _right_leg: Node3D
var _stagger: float=0.0

func _ready() -> void:
    _origin=global_position
    _body=Node3D.new()
    add_child(_body)
    var cloth: Material=MATERIALS.fetch("fabric",Color("8d8f7b"))
    var flesh: Material=MATERIALS.fetch("skin",Color("7b947b"))
    var body_mesh:=CapsuleMesh.new()
    body_mesh.radius=.30
    body_mesh.height=.83
    _part(_body,body_mesh,Vector3(0,.16,0),cloth)
    var skull:=SphereMesh.new()
    skull.radius=.24
    skull.height=.47
    _part(_body,skull,Vector3(0,.84,-.06),flesh)
    for side in [-1,1]:
        var arm:=CapsuleMesh.new()
        arm.radius=.115
        arm.height=.73
        _part(_body,arm,Vector3(float(side)*.43,.05,-.09),flesh)
    _left_leg=Node3D.new()
    _right_leg=Node3D.new()
    _body.add_child(_left_leg)
    _body.add_child(_right_leg)
    _left_leg.position=Vector3(-.17,-.33,0)
    _right_leg.position=Vector3(.17,-.33,0)
    for rig in [_left_leg,_right_leg]:
        var leg:=CapsuleMesh.new()
        leg.radius=.14
        leg.height=.78
        _part(rig,leg,Vector3(0,-.38,0),cloth)
    var col:=CollisionShape3D.new()
    var shape:=CapsuleShape3D.new()
    shape.radius=.36
    shape.height=1.72
    col.shape=shape
    add_child(col)

func _part(parent: Node3D, geometry: Mesh, pos: Vector3, mat: Material) -> void:
    var instance:=MeshInstance3D.new()
    instance.mesh=geometry
    instance.material_override=mat
    instance.position=pos
    parent.add_child(instance)

func _physics_process(delta: float) -> void:
    if target==null or not is_instance_valid(target):
        return
    _strike_time=maxf(0.0,_strike_time-delta)
    _stagger=maxf(0.0,_stagger-delta)
    _roam_time-=delta
    var relative: Vector3=target.global_position-global_position
    relative.y=0.0
    var distance: float=relative.length()
    var dir:=Vector3.ZERO
    var speed: float=0.0
    if distance<11.0:
        if distance>1.42:
            dir=relative.normalized()
            speed=3.15 if distance>3.0 else 2.3
            # Shallow forward rays let enemies steer away from wall obstacles.
            var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.5,global_position+Vector3.UP*.5+dir*1.3)
            query.exclude=[get_rid(),target.get_rid()]
            var hit: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
            if not hit.is_empty():
                dir=dir.rotated(Vector3.UP,.85 if get_instance_id()%2==0 else -.85)
        elif _strike_time<=0.0:
            _strike_time=1.28
            target.take_damage(10.0)
    else:
        if _roam_time<=0.0:
            _roam_time=randf_range(2.0,4.0)
            var home: Vector3=_origin-global_position
            home.y=0.0
            if home.length()>5.2:
                _roam=home.normalized()
            else:
                var angle: float=randf_range(-PI,PI)
                _roam=Vector3(cos(angle),0,sin(angle))
        dir=_roam
        speed=1.0
    if _stagger>0.0:
        speed*=.2
    velocity.x=move_toward(velocity.x,dir.x*speed,10.0*delta)
    velocity.z=move_toward(velocity.z,dir.z*speed,10.0*delta)
    velocity.y=-.1 if is_on_floor() else velocity.y-16.0*delta
    move_and_slide()
    if dir.length_squared()>.01:
        _body.rotation.y=lerp_angle(_body.rotation.y,atan2(-dir.x,-dir.z),7.0*delta)
    _gait+=delta*7.0
    _left_leg.rotation.x=sin(_gait)*.3 if speed>0.1 else 0.0
    _right_leg.rotation.x=-sin(_gait)*.3 if speed>0.1 else 0.0

func take_damage(amount: float) -> void:
    health-=amount
    _stagger=.18
    if health<=0.0:
        defeated.emit(self)
        queue_free()
