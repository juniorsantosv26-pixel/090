extends Control
## HUD escalável: joystick virtual e 3 botões + teclado e mouse para teste no editor.
var world
var _stick_index: int = -1
var _stick_start: Vector2 = Vector2.ZERO
var _stick_pos: Vector2 = Vector2.ZERO
var _stick_value: Vector2 = Vector2.ZERO
var _run_pointer: int = -1
var _mouse_joystick: bool = false
var _run_active: bool = false
var _touch_events: int = 0

func _ready() -> void:
    world = get_parent().get_parent() as Node3D
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
    queue_redraw()

func get_move_vector() -> Vector2:
    return _stick_value

func is_running() -> bool:
    return _run_active

func _attack_center() -> Vector2:
    return Vector2(size.x - 110.0, size.y - 125.0)

func _interact_center() -> Vector2:
    return Vector2(size.x - 235.0, size.y - 80.0)

func _dodge_center() -> Vector2:
    return Vector2(size.x - 375.0, size.y - 113.0)

func _run_center() -> Vector2:
    return Vector2(size.x - 270.0, size.y - 205.0)

func _stick_center() -> Vector2:
    return Vector2(145.0, get_viewport_rect().size.y - 140.0)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventScreenDrag:
        _touch_events += 1
    if event is InputEventScreenTouch:
        var finger := event as InputEventScreenTouch
        _pointer(finger.index, finger.position, finger.pressed)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _stick_index:
            _update_stick(drag.position)
    elif event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT:
            _pointer(-7, button.position, button.pressed)
            _mouse_joystick = button.pressed and _stick_index == -7
    elif event is InputEventMouseMotion and _mouse_joystick:
        _update_stick((event as InputEventMouseMotion).position)

func _pointer(pointer: int, pos: Vector2, pressed: bool) -> void:
    if pressed:
        if pos.distance_to(_attack_center()) < 85.0:
            world.try_attack()
        elif pos.distance_to(_interact_center()) < 70.0:
            world.try_interact()
        elif pos.distance_to(_dodge_center()) < 57.0:
            world.try_dodge()
        elif pos.distance_to(_run_center()) < 68.0:
            _run_pointer = pointer
            _run_active = true
        elif pos.x < get_viewport_rect().size.x * 0.48 and _stick_index == -1:
            _stick_index = pointer
            _stick_start = _stick_center()
            _stick_pos = pos
            _update_stick(pos)
    else:
        if pointer == _stick_index:
            _stick_index = -1
            _stick_value = Vector2.ZERO
        if pointer == _run_pointer:
            _run_pointer = -1
            _run_active = false
        if pointer == -7:
            _mouse_joystick = false

func _update_stick(pos: Vector2) -> void:
    _stick_pos = pos
    _stick_value = ((pos - _stick_start) / 75.0).limit_length(1.0)

func _circle_button(center: Vector2, radius: float, shade: Color, txt: String) -> void:
    draw_circle(center, radius, shade)
    draw_arc(center, radius - 3.0, 0.0, TAU, 44, Color(1, 1, 1, 0.47), 2.0, true)
    var f: Font = ThemeDB.fallback_font
    var fs: int = 20
    var width: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
    draw_string(f, center + Vector2(-width / 2.0, 6.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)

func _draw() -> void:
    var joystick_pos: Vector2 = _stick_start if _stick_index != -1 else _stick_center()
    draw_circle(joystick_pos, 77.0, Color(0.04, 0.08, 0.09, 0.43))
    draw_arc(joystick_pos, 76.0, 0.0, TAU, 52, Color(0.8, 0.9, 0.75, 0.38), 3.0, true)
    draw_circle(joystick_pos + _stick_value * 64.0, 35.0, Color(0.72, 0.82, 0.72, 0.65))
    _circle_button(_attack_center(), 74.0, Color(0.43, 0.13, 0.12, 0.72), "ATACAR")
    _circle_button(_interact_center(), 56.0, Color(0.12, 0.35, 0.26, 0.76), "COLETAR")
    _circle_button(_run_center(), 49.0, Color(0.27, 0.27, 0.31, 0.75), "CORRER")
    _circle_button(_dodge_center(), 53.0, Color(0.18, 0.30, 0.37, 0.78), "ESQUIVA")
    _line("FPS %d | TOUCH %d | MOVE %.2f %.2f" % [roundi(Engine.get_frames_per_second()), _touch_events, _stick_value.x, _stick_value.y], Vector2(35, 170), 16, Color.WHITE)
    if world == null:
        return
    var width: float = minf(size.x * 0.56, 735.0)
    draw_rect(Rect2(Vector2(18,18),Vector2(width,128)),Color(.015,.021,.024,.82),true)
    draw_rect(Rect2(Vector2(18,18),Vector2(4,128)),Color("bdab80"),true)
    _line("AFTERFALL  /  ECOS DA EXTINÇÃO",Vector2(37,47),21,Color("d4dacb"))
    _line(world.get_mission_text(),Vector2(36,83),18,Color("e8dfbd"))
    var values: Array[float] = [world.player.health, world.player.thirst, world.player.hunger]
    var tones: Array[Color] = [Color("d67b62"),Color("7eb7cd"),Color("bfaa7b")]
    var captions: Array[String] = ["VIDA","ÁGUA","FOME"]
    var col_size: float = (width-40.0)/3.0
    for i in range(3):
        var left: float=36.0+col_size*float(i)
        _line(captions[i],Vector2(left,105),13,Color("a8b0a7"))
        draw_rect(Rect2(Vector2(left,115),Vector2(col_size-15.0,8)),Color("353d39"),true)
        draw_rect(Rect2(Vector2(left,115),Vector2((col_size-15.0)*clampf(values[i]/100.0,0,1),8)),tones[i],true)
    _line("%s   |   %s"%[world.get_weather_label(),world.get_resource_label()],Vector2(size.x-430.0,46),16,Color("d5dbd3"))
    var hint: String = world.get_hint()
    if not hint.is_empty():
        var wid: float = minf(size.x * 0.63, 760.0)
        draw_rect(Rect2(Vector2(size.x * 0.5 - wid * 0.5, size.y - 58), Vector2(wid, 41)), Color(0.02, 0.04, 0.05, 0.73))
        _line(hint, Vector2(size.x * 0.5 - wid * 0.5 + 14, size.y - 30), 17, Color("e0e5d0"))

func _line(s: String, p: Vector2, font_size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
