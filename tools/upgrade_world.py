from pathlib import Path
p=Path(__file__).resolve().parents[1]/'scripts/world.gd'
s=p.read_text()
s=s.replace('const PICKUP_SCRIPT = preload("res://scripts/pickup.gd")','const PICKUP_SCRIPT = preload("res://scripts/pickup.gd")\nconst MATERIALS = preload("res://scripts/materials.gd")')
s=s.replace('    _create_trees_and_stones()\n', '    _create_trees_and_stones()\n    _create_grass()\n    _create_cars_and_lighting()\n')
a=s.index('func _material(');b=s.index('func _height_at(',a)
s=s[:a]+'''func _material(color: Color, roughness: float = 0.91, metallic: float = 0.0, surface_name: String = "") -> StandardMaterial3D:
    return MATERIALS.fetch(surface_name, color, 1.0, roughness, metallic)

'''+s[b:]
s=s.replace('    _scene_environment.fog_density = 0.006','    _scene_environment.fog_density = 0.009')
s=s.replace('    _scene_environment.background_color = Color("667b7c")','    _scene_environment.background_color = Color("6b7977")')
s=s.replace('    _scene_environment.ambient_light_energy = 0.7','    _scene_environment.ambient_light_energy = 0.56')
s=s.replace('    surface.generate_normals()','    surface.generate_normals()')
s=s.replace('    var mat := _material(Color.WHITE)\n    mat.vertex_color_use_as_albedo = true','    var mat := MATERIALS.fetch("ground", Color.WHITE, 7.0)\n    mat.vertex_color_use_as_albedo = true')
s=s.replace('    st.set_color(tint)\n    st.add_vertex(pos)','    st.set_color(tint)\n    st.set_uv(Vector2(pos.x * 0.08, pos.z * 0.08))\n    st.add_vertex(pos)')
s=s.replace('func _solid_box(center: Vector3, ext: Vector3, color: Color, collidable: bool = true) -> StaticBody3D:', 'func _solid_box(center: Vector3, ext: Vector3, color: Color, collidable: bool = true, surface_name: String = "") -> StaticBody3D:')
s=s.replace('    mesh_node.material_override = _material(color)','    mesh_node.material_override = _material(color, 0.91, 0.0, surface_name)')
a=s.index('func _create_road() -> void:');b=s.index('func _create_radio()',a)
s=s[:a]+'''func _create_road() -> void:
    # Continual road mesh follows the terrain to avoid hovering solid-box slabs.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for n in range(-115, 115):
        var z0: float = float(n) * 0.5
        var z1: float = float(n + 1) * 0.5
        var v0 := Vector3(3.9, _height_at(3.9, z0) + 0.035, z0)
        var v1 := Vector3(8.0, _height_at(8.0, z0) + 0.035, z0)
        var v2 := Vector3(3.9, _height_at(3.9, z1) + 0.035, z1)
        var v3 := Vector3(8.0, _height_at(8.0, z1) + 0.035, z1)
        for point in [v0, v2, v1, v1, v2, v3]:
            st.set_uv(Vector2(point.x * 0.21, point.z * 0.21))
            st.add_vertex(point)
    st.generate_normals()
    var road := MeshInstance3D.new()
    road.mesh = st.commit()
    road.material_override = MATERIALS.fetch("asphalt", Color("e5dfd1"), 2.0)
    road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(road)
    for i in range(-10, 11):
        if i % 4 == 0:
            continue
        var z: float = float(i) * 5.0
        _solid_box(Vector3(5.95, _height_at(5.95, z) + 0.062, z), Vector3(0.12, 0.012, 1.35), Color("a8a08a"), false)
    # Broken road shoulders and cracked foundation.
    for i in range(-10, 11):
        var z: float = float(i) * 5.0
        for side in [-1, 1]:
            var x: float = 3.8 if side == -1 else 8.1
            _solid_box(Vector3(x, _height_at(x, z) + 0.06, z), Vector3(0.16, 0.13, 3.8), Color("959384"), false, "concrete")

func _create_ruins() -> void:
    var points: Array[Vector2] = [Vector2(16, 7), Vector2(19, -3), Vector2(28, 15), Vector2(28, -19), Vector2(-20, 20), Vector2(-24, -22), Vector2(10, 32)]
    for i in range(points.size()):
        _building(points[i].x, points[i].y, i)
    for i in range(12):
        var x: float = -8.0 + float(i) * 2.1
        if i == 6 or i == 7:
            continue
        _solid_box(Vector3(x, _height_at(x, 15.0) + 1.0, 15.0), Vector3(.20, 2.0, .2), Color("666052"), true, "metal")

func _building(x: float, z: float, idx: int) -> void:
    var y: float = _height_at(x,z)
    var dark := Color("9c9480") if idx % 2 == 0 else Color("7c857d")
    var wall_h: float = 3.7 + float(idx % 3) * 0.8
    var w: float = 6.2
    var d: float = 5.4
    # Accessible interior and real openings, instead of full cubes with painted windows.
    _solid_box(Vector3(x,y+.10,z), Vector3(w+.7,.2,d+.7), Color("85867f"), true, "concrete")
    _solid_box(Vector3(x-w*.5+.18,y+wall_h*.5,z), Vector3(.36,wall_h,d), dark, true, "plaster")
    _solid_box(Vector3(x+w*.5-.18,y+wall_h*.5,z), Vector3(.36,wall_h,d), dark, true, "plaster")
    _solid_box(Vector3(x,y+wall_h*.5,z-d*.5+.2), Vector3(w,.4+wall_h*.23,.40), dark, true, "plaster")
    for side in [-1,1]:
        px: float = x + float(side) * (w * .27)
        _solid_box(Vector3(px,y+wall_h*.44,z-d*.5+.2), Vector3(w*.32,wall_h*.65,.37), dark, true, "plaster")
        _solid_box(Vector3(px,y+wall_h*.85,z+d*.5-.2), Vector3(w*.34,wall_h*.29,.37), dark, true, "plaster")
    # Structural header, partially collapsed roof and exposed beams.
    _solid_box(Vector3(x,y+wall_h*.86,z-d*.5+.2), Vector3(w*.37,.35,.42), Color("a8a492"), true, "concrete")
    _solid_box(Vector3(x-w*.24,y+wall_h+.07,z), Vector3(w*.52,.16,d+.1), Color("757672"), true, "concrete")
    _solid_box(Vector3(x-w*.42,y+wall_h+.25,z-d*.24), Vector3(.19,.35,d*.52), Color("595c58"), true, "metal")
    for k in range(3):
        var zz: float = z-d*.35+float(k)*d*.32
        var xx: float = x + w*.48
        _solid_box(Vector3(xx,y+.14,zz), Vector3(.7,.22,.62), Color("70736b"), true, "stone")
    # Intermittent debris around entrances.
    for k in range(7):
        var a: float = float(k) * 2.13 + idx*.8
        var rx: float = x + cos(a) * (w*.66+float(k%2))
        var rz: float = z + sin(a) * (d*.62+float(k%3)*.22)
        _solid_box(Vector3(rx,_height_at(rx,rz)+.12,rz), Vector3(.34+float(k%3)*.2,.22,.51), Color("8f8980"), true, "concrete")

func _create_trees_and_stones() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261015
    for i in range(70):
        var x: float = rng.randf_range(-49.0, 48.0)
        var z: float = rng.randf_range(-49.0, 48.0)
        if Vector2(x,z).length()<11.0 or absf(x-6.0)<5.7:
            continue
        if Vector2(x-16.0,z+15.0).length()<7.0:
            continue
        _tree(x,z,rng.randf_range(3.6,8.5),i%8==0)
    for i in range(77):
        var x: float = rng.randf_range(-48,48)
        var z: float = rng.randf_range(-48,48)
        if Vector2(x,z).length()<4.0:
            continue
        var rock: StaticBody3D = _solid_box(Vector3(x,_height_at(x,z)+.28,z),Vector3(.5,.56,.83),Color("bbb9aa"),true,"stone")
        rock.rotation_degrees.y = rng.randf_range(-85,85)
        rock.rotation_degrees.z = rng.randf_range(-15,15)

func _tree(x: float,z: float,height: float,dead: bool) -> void:
    var y: float = _height_at(x,z)
    var root := StaticBody3D.new()
    root.position = Vector3(x,y,z)
    var shaft := MeshInstance3D.new()
    var trunk := CylinderMesh.new()
    trunk.top_radius = .11
    trunk.bottom_radius = .33
    trunk.height = height*.78
    trunk.radial_segments = 7
    shaft.mesh = trunk
    shaft.position.y = height*.39
    shaft.material_override = MATERIALS.fetch("bark",Color("b7ab9b"))
    root.add_child(shaft)
    var hit := CollisionShape3D.new()
    var cylinder := CylinderShape3D.new()
    cylinder.radius = .29
    cylinder.height = height*.78
    hit.shape = cylinder
    hit.position.y = height*.39
    root.add_child(hit)
    add_child(root)
    if dead:
        return
    # 6 varied canopy clusters with low vertex count; textured, layered crowns.
    var crown_mat := MATERIALS.fetch("foliage",Color("a7bbaa"))
    for i in range(6):
        var cluster := MeshInstance3D.new()
        var globe := SphereMesh.new()
        globe.radius = 1.0
        globe.height = 2.0
        globe.radial_segments = 9
        globe.rings = 5
        cluster.mesh = globe
        cluster.material_override = crown_mat
        var t: float = float(i)*2.4
        var width: float = .7+float(i%3)*.16
        cluster.scale = Vector3(width,1.08+float(i%2)*.16,width)
        cluster.position = Vector3(cos(t)*.59,height*.59+float(i%3)*.44,sin(t)*.57)
        root.add_child(cluster)

func _create_grass() -> void:
    var mesh := QuadMesh.new()
    mesh.size = Vector2(.63,1.2)
    mesh.material = MATERIALS.leaves("grass_blade")
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = mesh
    multimesh.instance_count = 1100
    var rng := RandomNumberGenerator.new()
    rng.seed=9852
    for i in range(multimesh.instance_count):
        var x: float = rng.randf_range(-51,51)
        var z: float = rng.randf_range(-51,51)
        if absf(x-6.0)<3.0:
            x+=4.0
        var scale: float = rng.randf_range(.52,1.32)
        var basis := Basis(Vector3.UP,rng.randf_range(-PI,PI))
        basis = basis.scaled(Vector3(scale,scale,scale))
        multimesh.set_instance_transform(i,Transform3D(basis,Vector3(x,_height_at(x,z)+scale*.56,z)))
    var grass := MultiMeshInstance3D.new()
    grass.multimesh = multimesh
    grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(grass)

func _create_cars_and_lighting() -> void:
    for i in range(5):
        var z: float = -38.0 + float(i)*16.0
        var x: float = 5.7 if i%2==0 else 9.7
        _car(x,z,i)
    for i in range(4):
        var z: float = -32.0 + float(i)*22.0
        var x: float = 10.15
        var y: float = _height_at(x,z)
        _solid_box(Vector3(x,y+2.35,z),Vector3(.17,4.7,.17),Color("99968d"),true,"metal")
        _solid_box(Vector3(x-.68,y+4.55,z),Vector3(1.50,.13,.16),Color("898780"),false,"metal")
        _solid_box(Vector3(x-1.31,y+4.46,z),Vector3(.52,.22,.42),Color("c0a573"),false,"metal")
        if i==0:
            var light := OmniLight3D.new()
            light.position = Vector3(x-1.25,y+4.20,z)
            light.light_color=Color("ffc983")
            light.light_energy=.55
            light.omni_range=8.0
            light.shadow_enabled=false
            add_child(light)

func _car(x: float,z: float,idx: int) -> void:
    var y: float = _height_at(x,z)
    var metal: Color = Color("7b7772") if idx%2==0 else Color("6c826e")
    var root := Node3D.new()
    root.position = Vector3(x,y+.45,z)
    root.rotation.y = float(idx%3-1)*.22
    add_child(root)
    # Each car is a small collection of separate meshes and wheels (no single cube).
    var parts := [
        [Vector3(0,.4,0),Vector3(1.70,.54,3.55),metal,"metal"],
        [Vector3(0,.90,-.18),Vector3(1.46,.58,1.75),Color("9d9789"),"metal"],
        [Vector3(0,.94,-1.08),Vector3(1.39,.25,.17),Color("333c3c"),"metal"],
        [Vector3(0,.87,.62),Vector3(1.40,.24,.17),Color("323b3c"),"metal"],
        [Vector3(0,.28,-1.82),Vector3(1.69,.16,.16),Color("626360"),"metal"],
        [Vector3(0,.28,1.82),Vector3(1.69,.16,.16),Color("626360"),"metal"]
    ]
    for item in parts:
        var part := MeshInstance3D.new()
        var m := BoxMesh.new()
        m.size=item[1]
        part.mesh=m
        part.position=item[0]
        part.material_override=MATERIALS.fetch(item[3],item[2])
        root.add_child(part)
    for side in [-1,1]:
        for axle in [-1,1]:
            var wheel := MeshInstance3D.new()
            var tube := CylinderMesh.new()
            tube.top_radius=.42
            tube.bottom_radius=.42
            tube.height=.24
            wheel.mesh=tube
            wheel.rotation.z=PI*.5
            wheel.position=Vector3(float(side)*.91,.02,float(axle)*1.12)
            wheel.material_override=MATERIALS.fetch("fabric",Color("3b3b3b"))
            root.add_child(wheel)

'''+s[b:]
# fix unsupported inline variable declaration as introduced
s=s.replace('        px: float =', '        var px: float =')
# sun shadows with soft lighting and immediate mobile foot lighting
s=s.replace('    var multimesh := MultiMesh.new()','    var multimesh := MultiMesh.new()')
p.write_text(s)
