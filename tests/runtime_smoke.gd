extends SceneTree
## To run in a Godot executable (not a standalone Python test):
## godot --headless --path . --script res://tests/runtime_smoke.gd
func _initialize() -> void:
    call_deferred("_run_smoke")

func _run_smoke() -> void:
    var world_scene: PackedScene = load("res://scenes/main.tscn")
    if world_scene == null:
        push_error("FAIL: main scene not loadable")
        quit(1)
        return
    var world: Node = world_scene.instantiate()
    root.add_child(world)
    await process_frame
    if world == null or not is_instance_valid(world.get_node_or_null("Player")):
        push_error("FAIL: player missing")
        quit(1)
        return
    if not world.has_method("try_attack") or not world.has_method("try_dodge"):
        push_error("FAIL: combat API missing")
        quit(1)
        return
    print("PASS: AFTERFALL 0.3.1 scene loads, player and world methods available")
    quit(0)
