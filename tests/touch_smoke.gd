extends SceneTree

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    if scene == null:
        push_error("FAIL: cena ausente")
        quit(1)
        return

    var level: Node = scene.instantiate()
    root.add_child(level)
    await process_frame

    var hud = level.get_node("UI/HUD")
    var player: CharacterBody3D = level.get_node("Player")
    var start: Vector3 = player.global_position

    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = true
    touch.position = hud._stick_center() + Vector2(65, -15)
    hud._input(touch)

    if hud.get_move_vector().length() < 0.4:
        push_error("FAIL: joystick sem resposta")
        quit(1)
        return

    for i in range(45):
        await physics_frame

    var end: Vector3 = player.global_position
    var distance := Vector2(end.x-start.x, end.z-start.z).length()

    if distance < 0.35:
        push_error("FAIL: personagem nao se deslocou")
        quit(1)
        return

    print("PASS: touchscreen joystick moves player")
    print("DISTANCIA: ", distance)
    quit(0)
