extends Area3D
## Original multi-part scavenging resource, with clear silhouette and pickup pulse.
const MATERIALS = preload("res://scripts/materials.gd")
var kind: String = "scrap"
var pickup_id: String = ""
var _clock: float = 0.0
var _visual: Node3D

func _ready() -> void:
    add_to_group("pickup")
    _visual=Node3D.new()
    add_child(_visual)
    if kind=="scrap":
        var metal: Material=MATERIALS.fetch("metal",Color("d1b4a0"),1.0,.63,.43)
        for i in range(3):
            var part:=MeshInstance3D.new()
            var sheet:=BoxMesh.new()
            sheet.size=Vector3(.41,.085,.19)
            part.mesh=sheet
            part.position=Vector3(float(i-1)*.14,float(i)*.07,0)
            part.rotation=Vector3(.14*float(i),float(i)*.7,.2*float(i-1))
            part.material_override=metal
            _visual.add_child(part)
    else:
        var timber: Material=MATERIALS.fetch("wood",Color("dfc4a5"))
        for i in range(2):
            var part:=MeshInstance3D.new()
            var log:=CylinderMesh.new()
            log.height=.68
            log.bottom_radius=.11
            log.top_radius=.12
            log.radial_segments=7
            part.mesh=log
            part.rotation.x=PI*.5
            part.rotation.y=float(i)*.26
            part.position=Vector3(float(i)*.2,.06,float(i)*.08)
            part.material_override=timber
            _visual.add_child(part)
    var area:=CollisionShape3D.new()
    var sphere:=SphereShape3D.new()
    sphere.radius=.48
    area.shape=sphere
    add_child(area)

func _process(delta: float) -> void:
    _clock+=delta
    _visual.rotation.y+=delta*.38
    _visual.position.y=sin(_clock*2.2)*.09
