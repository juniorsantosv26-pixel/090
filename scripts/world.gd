extends Node3D
## Mundo 3D procedimental original: exploração, missão, clima, infectados e save local.
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")
const PICKUP_SCRIPT = preload("res://scripts/pickup.gd")
const MATERIALS = preload("res://scripts/materials.gd")
const SAVE_PATH: String = "user://afterfall_01.json"
const RADIO_LOCATION: Vector3 = Vector3(16.0, 0.0, -15.0)

@onready var player = $Player
@onready var camera: Camera3D = $Camera
@onready var sun: DirectionalLight3D = $Sun
@onready var hud = $UI/HUD

var _world_environment: WorldEnvironment
var _scene_environment: Environment
var _rain: MultiMeshInstance3D
var _rain_clock: float = 0.0
var _rain_rng := RandomNumberGenerator.new()
var weather_index: int = 0
var weather_clock: float = 0.0
var daylight: float = 0.22
var scrap: int = 0
var wood: int = 0
var infected_kills: int = 0
var mission_phase: int = 0
var collected_ids: Array[String] = []
var enemies: Array = []
var pickups: Array = []
var status_note: String = "Sinal de rádio perdido. Encontre os materiais."
var status_note_clock: float = 10.0
var _save_clock: float = 0.0

func _ready() -> void:
    _rain_rng.seed = 68129
    player.hud = hud
    player.camera = camera
    player.died.connect(_on_player_died)
    _setup_environment()
    _create_terrain()
    _create_road()
    _create_ruins()
    _create_trees_and_stones()
    _create_grass()
    _create_cars_and_lighting()
    _create_radio()
    _create_pickups()
    _create_enemies()
    player.position = _spawn_position()
    _load_save()
    _set_weather(0)
    camera.global_position = player.global_position + Vector3(11.0, 15.5, 16.0)
    camera.look_at(player.global_position + Vector3(0.0, 0.7, 0.0), Vector3.UP)

func _spawn_position() -> Vector3:
    return Vector3(0.0, _height_at(0.0, 0.0) + 1.2, 0.0)

func _material(color: Color, roughness: float = 0.91, metallic: float = 0.0, surface_name: String = "") -> StandardMaterial3D:
    return MATERIALS.fetch(surface_name, color, 1.0, roughness, metallic)

func _height_at(x: float, z: float) -> float:
    var radial: float = Vector2(x, z).length()
    var rolling: float = sin(x * 0.14) * cos(z * 0.11) * 0.48
    var mountain: float = pow(smoothstep(18.0, 62.0, radial), 1.55) * (2.0 + sin(x * 0.12 + z * 0.1) * 2.0)
    return rolling + mountain

func _setup_environment() -> void:
    _world_environment = WorldEnvironment.new()
    _scene_environment = Environment.new()
    _scene_environment.background_mode = Environment.BG_COLOR
    _scene_environment.background_color = Color("6b7977")
    _scene_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    _scene_environment.ambient_light_color = Color("c0c5b9")
    _scene_environment.ambient_light_energy = 0.56
    _scene_environment.fog_enabled = true
    _scene_environment.fog_density = 0.009
    _scene_environment.fog_light_color = Color("718487")
    _world_environment.environment = _scene_environment
    add_child(_world_environment)
    var rain_mesh := BoxMesh.new()
    rain_mesh.size = Vector3(0.027, 0.66, 0.025)
    var rain_mat := _material(Color(0.55, 0.70, 0.77, 0.45), 0.3)
    rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    rain_mesh.material = rain_mat
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = rain_mesh
    multimesh.instance_count = 90
    _rain = MultiMeshInstance3D.new()
    _rain.multimesh = multimesh
    add_child(_rain)
    _rain.visible = false

func _create_terrain() -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var limit: int = 26
    var scale: float = 2.25
    for x in range(-limit, limit):
        for z in range(-limit, limit):
            var x0: float = float(x) * scale
            var z0: float = float(z) * scale
            var x1: float = x0 + scale
            var z1: float = z0 + scale
            var a := Vector3(x0, _height_at(x0, z0), z0)
            var b := Vector3(x1, _height_at(x1, z0), z0)
            var c := Vector3(x0, _height_at(x0, z1), z1)
            var d := Vector3(x1, _height_at(x1, z1), z1)
            var biome_color: Color = Color("c0cdb6") if x0 < 14.0 else Color("c2b7a2")
            if x0 < -12.0:
                biome_color = Color("9db4a1")
            _vertex(surface, a, biome_color)
            _vertex(surface, c, biome_color)
            _vertex(surface, b, biome_color)
            _vertex(surface, b, biome_color)
            _vertex(surface, c, biome_color)
            _vertex(surface, d, biome_color)
    surface.generate_normals()
    var mesh: ArrayMesh = surface.commit()
    var mat := MATERIALS.fetch("ground", Color.WHITE, 7.0)
    mat.vertex_color_use_as_albedo = true
    var terrain := MeshInstance3D.new()
    terrain.mesh = mesh
    terrain.material_override = mat
    terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(terrain)
    var ground_collision := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    shape.shape = mesh.create_trimesh_shape()
    ground_collision.add_child(shape)
    add_child(ground_collision)

func _vertex(st: SurfaceTool, pos: Vector3, tint: Color) -> void:
    st.set_color(tint)
    st.set_uv(Vector2(pos.x * 0.08, pos.z * 0.08))
    st.add_vertex(pos)

func _solid_box(center: Vector3, ext: Vector3, color: Color, collidable: bool = true, surface_name: String = "") -> StaticBody3D:
    var node := StaticBody3D.new()
    node.position = center
    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = ext
    mesh_node.mesh = mesh
    mesh_node.material_override = _material(color, 0.91, 0.0, surface_name)
    node.add_child(mesh_node)
    if collidable:
        var shape := BoxShape3D.new()
        shape.size = ext
        var col := CollisionShape3D.new()
        col.shape = shape
        node.add_child(col)
    add_child(node)
    return node

func _create_road() -> void:
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
        var px: float = x + float(side) * (w * .27)
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

func _create_radio() -> void:
    var h: float = _height_at(RADIO_LOCATION.x, RADIO_LOCATION.z)
    _solid_box(Vector3(16, h + 1.0, -15), Vector3(2.6, 2.0, 1.4), Color("414c50"))
    _solid_box(Vector3(16, h + 3.4, -15), Vector3(0.15, 4.8, 0.15), Color("c0a466"))
    _solid_box(Vector3(16, h + 5.9, -15), Vector3(1.2, 0.12, 0.12), Color("bfa577"))
    _solid_box(Vector3(16, h + 0.75, -14.21), Vector3(1.2, 0.55, 0.11), Color("b1a674"), false)

func _create_pickups() -> void:
    var resource_positions: Array[Vector2] = [Vector2(-2, -5), Vector2(-8, 2), Vector2(7, -4), Vector2(-13, -6), Vector2(11, 11), Vector2(-8, 12), Vector2(22, -11), Vector2(-19, -9), Vector2(4, 15), Vector2(-5, 19)]
    for i in resource_positions.size():
        var p: Vector2 = resource_positions[i]
        var resource = PICKUP_SCRIPT.new()
        resource.kind = "scrap" if i % 2 == 0 else "wood"
        resource.pickup_id = "%s_%d" % [resource.kind, i]
        resource.position = Vector3(p.x, _height_at(p.x, p.y) + 0.45, p.y)
        add_child(resource)
        pickups.append(resource)

func _create_enemies() -> void:
    var positions: Array[Vector2] = [Vector2(-11, -12), Vector2(12, 5), Vector2(-22, 3), Vector2(22, -27)]
    for p in positions:
        var zombie = ENEMY_SCRIPT.new()
        zombie.target = player
        zombie.global_position = Vector3(p.x, _height_at(p.x, p.y) + 1.2, p.y)
        add_child(zombie)
        zombie.defeated.connect(_on_enemy_defeated)
        enemies.append(zombie)

func _process(delta: float) -> void:
    var target_pos: Vector3 = player.global_position + Vector3(11.0, 15.5, 16.0)
    camera.global_position = camera.global_position.lerp(target_pos, minf(1.0, delta * 5.0))
    camera.look_at(player.global_position + Vector3(0, 0.7, 0), Vector3.UP)
    weather_clock += delta
    daylight = fposmod(daylight + delta / 450.0, 1.0)
    _update_lighting()
    if weather_clock > 80.0:
        weather_clock = 0.0
        _set_weather((weather_index + 1) % 3)
    _rain_clock += delta
    if weather_index == 1 and _rain_clock >= 0.095:
        _rain_clock = 0.0
        _update_rain()
    status_note_clock = maxf(0.0, status_note_clock - delta)
    _save_clock += delta
    if _save_clock >= 30.0:
        _save_clock = 0.0
        _write_save()
    _refresh_mission()

func _update_lighting() -> void:
    var daylight_factor: float = clampf(sin(daylight * TAU), 0.12, 1.0)
    sun.light_energy = daylight_factor * (0.65 if weather_index == 1 else 1.1)
    _scene_environment.ambient_light_energy = 0.38 + daylight_factor * 0.45
    var base: Color = Color("66828d") if weather_index == 0 else Color("47565c")
    if weather_index == 2:
        base = Color("85908b")
    _scene_environment.background_color = Color("19242f").lerp(base, daylight_factor)

func _set_weather(weather: int) -> void:
    weather_index = weather
    _rain.visible = weather == 1
    _scene_environment.fog_density = 0.024 if weather == 2 else 0.012 if weather == 1 else 0.005
    _note("Clima alterado: " + _weather_name(), 5.0)

func _update_rain() -> void:
    for i in range(_rain.multimesh.instance_count):
        var pos: Vector3 = player.global_position + Vector3(_rain_rng.randf_range(-23, 23), _rain_rng.randf_range(0, 13), _rain_rng.randf_range(-23, 23))
        _rain.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))

func _weather_name() -> String:
    match weather_index:
        1: return "chuva intensa"
        2: return "neblina"
        _: return "céu limpo"

func _on_enemy_defeated(enemy: CharacterBody3D) -> void:
    enemies.erase(enemy)
    infected_kills += 1
    _note("Infectado neutralizado. Continue a exploração.")
    _refresh_mission()
    _write_save()

func _on_player_died() -> void:
    player.reset_after_death(_spawn_position())
    _note("Você desmaiou. Retornou ao abrigo improvisado.", 7.0)
    _write_save()

func try_dodge() -> void:
    if player.dodge():
        _note("Esquiva!", 0.6)

func try_attack() -> void:
    if player.attack(enemies):
        _note("Ataque realizado!", 1.0)

func try_interact() -> void:
    var closest = null
    var distance: float = 2.55
    for resource in pickups:
        if not is_instance_valid(resource):
            continue
        var d: float = player.global_position.distance_to(resource.global_position)
        if d < distance:
            closest = resource
            distance = d
    if closest != null:
        if closest.kind == "scrap":
            scrap += 1
            _note("+1 sucata recolhida")
        else:
            wood += 1
            _note("+1 madeira recolhida")
        collected_ids.append(closest.pickup_id)
        pickups.erase(closest)
        closest.queue_free()
        _refresh_mission()
        _write_save()
        return
    var radio_pos := Vector3(RADIO_LOCATION.x, _height_at(RADIO_LOCATION.x, RADIO_LOCATION.z) + 1.0, RADIO_LOCATION.z)
    if player.global_position.distance_to(radio_pos) <= 4.5:
        if mission_phase == 2:
            mission_phase = 3
            _note("Frequência 17 reativada. Sinal recebido de Aurora!", 12.0)
            _write_save()
        else:
            _note("O transmissor necessita materiais e uma área segura.", 4.0)
        return
    _note("Aproxime-se de recursos ou do transmissor.", 2.7)

func _refresh_mission() -> void:
    if mission_phase == 0 and scrap >= 3 and wood >= 2:
        mission_phase = 1
        _note("Materiais recuperados. Neutralize um infectado.", 8.0)
        _write_save()
    if mission_phase == 1 and infected_kills >= 1:
        mission_phase = 2
        _note("Área segura. Vá até o transmissor na estrada.", 8.0)
        _write_save()

func _note(message: String, duration: float = 4.0) -> void:
    status_note = message
    status_note_clock = duration

func get_hint() -> String:
    return status_note if status_note_clock > 0 else ""

func get_resource_label() -> String:
    return "Sucata %d   Madeira %d" % [scrap, wood]

func get_weather_label() -> String:
    return _weather_name()

func get_status_text() -> String:
    return "VIDA %d  •  ÁGUA %d  •  FOME %d  •  SUCATA %d  •  MADEIRA %d  •  %s" % [roundi(player.health), roundi(player.thirst), roundi(player.hunger), scrap, wood, _weather_name()]

func get_mission_text() -> String:
    match mission_phase:
        0: return "MISSÃO 1: Recolha sucata %d/3 e madeira %d/2" % [mini(scrap, 3), mini(wood, 2)]
        1: return "MISSÃO 2: Neutralize um infectado %d/1" % [mini(infected_kills, 1)]
        2: return "MISSÃO 3: Vá ao rádio perto da estrada e toque COLETAR"
        _: return "CAPÍTULO 1 COMPLETO • Aurora respondeu à Frequência 17"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_SPACE: try_attack()
            KEY_Q: try_dodge()
            KEY_E: try_interact()
            KEY_F5:
                _write_save()
                _note("Jogo salvo localmente", 3.0)
            KEY_F9:
                _load_save()
                _note("Salvamento recarregado", 3.0)
            KEY_C:
                _set_weather((weather_index + 1) % 3)

func _write_save() -> void:
    if not is_inside_tree():
        return
    var data: Dictionary = {
        "schema": 1,
        "position": [player.global_position.x, player.global_position.y, player.global_position.z],
        "health": player.health,
        "thirst": player.thirst,
        "hunger": player.hunger,
        "scrap": scrap,
        "wood": wood,
        "kills": infected_kills,
        "mission": mission_phase,
        "collected": collected_ids,
        "daylight": daylight
    }
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(data))
        f.close()

func _load_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var text: String = FileAccess.get_file_as_string(SAVE_PATH)
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary) or parsed.get("schema", 0) != 1:
        _note("Salvamento inválido; uma nova sessão foi iniciada.")
        return
    scrap = maxi(0, int(parsed.get("scrap", 0)))
    wood = maxi(0, int(parsed.get("wood", 0)))
    infected_kills = maxi(0, int(parsed.get("kills", 0)))
    mission_phase = clampi(int(parsed.get("mission", 0)), 0, 3)
    player.health = clampf(float(parsed.get("health", 100.0)), 1.0, 100.0)
    player.thirst = clampf(float(parsed.get("thirst", 100.0)), 0.0, 100.0)
    player.hunger = clampf(float(parsed.get("hunger", 100.0)), 0.0, 100.0)
    daylight = clampf(float(parsed.get("daylight", 0.22)), 0.0, 1.0)
    var pos: Array = parsed.get("position", [])
    if pos.size() == 3:
        var p := Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
        if absf(p.x) < 56.0 and absf(p.z) < 56.0:
            player.global_position = p
    collected_ids.clear()
    var already_collected: Array = parsed.get("collected", [])
    for id in already_collected:
        if id is String and not collected_ids.has(id):
            collected_ids.append(id)
    for pickup in pickups.duplicate():
        if collected_ids.has(pickup.pickup_id):
            pickups.erase(pickup)
            pickup.queue_free()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
        if is_inside_tree() and is_instance_valid(player):
            _write_save()
