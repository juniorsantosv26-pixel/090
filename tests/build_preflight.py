"""Preflight for native APK pipeline. Static only; doesn't claim runtime success."""
from pathlib import Path
import sys
import re
import json
root = Path(__file__).resolve().parents[1]
errors=[]
project=(root/'project.godot').read_text()
preset=(root/'export_presets.cfg').read_text()
def check(ok,message):
    print(('PASS ' if ok else 'FAIL ')+message)
    if not ok: errors.append(message)
check('run/main_scene="res://scenes/main.tscn"' in project,'main scene')
check('window/handheld/orientation=0' in project,'landscape orientation')
check('renderer/rendering_method="gl_compatibility"' in project,'Android-friendly GL renderer')
check('platform="Android"' in preset and 'export_path="build/AFTERFALL-0.3.1-debug.apk"' in preset,'APK Android preset')
check('architectures/arm64-v8a=true' in preset and 'architectures/armeabi-v7a=false' in preset,'ARM64 only')
check('package/unique_name="com.afterfall.survival"' in preset,'original application id')
check('permissions/internet=false' in preset,'no internet permission')
check((root/'assets/icon192.png').exists() and (root/'assets/icon432.png').exists(),'launcher icons')
check((root/'scenes/main.tscn').exists(),'main scene file')
for script in sorted((root/'scripts').glob('*.gd')):
    check(bool(script.read_text().strip()),f'script {script.name}')
for resource in re.findall(r'"(res://[^"\s]+)"', (root/'scenes/main.tscn').read_text()):
    check((root/resource[6:]).exists(),f'scene resource {resource}')
check(len(list((root/'assets/textures').glob('*.png')))>=26,'procedural texture files')
check((root/'.github/workflows/android-apk.yml').exists(),'GitHub CI definition')
print(json.dumps({'checks_failed':errors, 'APK_COMPILED':False},ensure_ascii=False))
sys.exit(1 if errors else 0)
