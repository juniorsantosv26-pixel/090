"""Honest *static* QA; NOT a substitute for opening the game in Godot."""
import re, zipfile, zlib, struct
from pathlib import Path
P=Path(__file__).resolve().parents[1]
checks=[]
def check(name,ok):
    checks.append((name,bool(ok)))
    print(('PASS' if ok else 'FAIL'),name)
project=(P/'project.godot').read_text()
world=(P/'scripts/world.gd').read_text()
player=(P/'scripts/player.gd').read_text()
hud=(P/'scripts/hud.gd').read_text()
check('main scene assigned', 'run/main_scene="res://scenes/main.tscn"' in project)
check('landscape orientation', 'window/handheld/orientation=0' in project)
check('renderer compatibility', 'gl_compatibility' in project)
check('touch joystick', 'InputEventScreenTouch' in hud and 'get_move_vector' in hud)
check('multitouch drag', 'InputEventScreenDrag' in hud)
check('combat and dodge', 'func attack(' in player and 'func dodge(' in player)
check('custom script API not typed as base Control', 'var hud: Control' not in player)
check('enemy target custom take_damage not typed base CharacterBody3D', 'var target: CharacterBody3D' not in (P/'scripts/enemy.gd').read_text())
check('movement acceleration', 'move_toward(velocity.x' in player)
check('enemy avoids obstacles', 'PhysicsRayQueryParameters3D' in (P/'scripts/enemy.gd').read_text())
check('mission', 'func _refresh_mission' in world and 'Frequência 17' in world)
check('local save', 'user://afterfall_01.json' in world)
check('custom shaders materials', 'MATERIALS.fetch' in world and 'normal_texture' in (P/'scripts/materials.gd').read_text())
check('grass instancing', 'func _create_grass' in world and 'MultiMesh.new()' in world)
check('rain and weather', 'func _update_rain' in world and 'func _set_weather' in world)
check('geometry with collision', 'func _create_terrain' in world and 'mesh.create_trimesh_shape()' in world)
check('editable procedural texture source', (P/'tools/make_textures.py').exists())
check('Godot engine smoke test provided', (P/'tests/runtime_smoke.gd').exists())
scene=(P/'scenes/main.tscn').read_text()
paths=re.findall(r'path="(res://[^\"]+)"',scene)
paths+=re.findall(r'(?:load|preload)\("(res://[^\"]+)"\)', '\n'.join(x.read_text() for x in (P/'scripts').glob('*.gd')))
check('static resources resolvable', all((P/x[6:]).exists() for x in paths))
textures=list((P/'assets/textures').glob('*.png'))
def verify_png(path: Path) -> bool:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        return False
    offset, valid_header, valid_end = 8, False, False
    while offset + 12 <= len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        end = offset + 12 + length
        if end > len(data):
            return False
        payload = data[offset + 8:offset + 8 + length]
        expected = struct.unpack(">I", data[offset + 8 + length:end])[0]
        if zlib.crc32(kind + payload) & 0xFFFFFFFF != expected:
            return False
        if kind == b"IHDR": valid_header = length == 13
        if kind == b"IEND":
            valid_end = True
            break
        offset = end
    return valid_header and valid_end
try:
    ok = len(textures) >= 26 and all(verify_png(f) for f in textures)
except Exception:
    ok = False
check('26 or more unbroken textures',ok)
check('source contains zero source-game assets',not list(P.rglob('*.obb')) and not list(P.rglob('*.apk')))
assert all(y for x,y in checks), 'Static QA failed: '+','.join(x for x,y in checks if not y)
print('%s/%s static tests PASSED | Godot runtime not tested' % (len(checks),len(checks)))
