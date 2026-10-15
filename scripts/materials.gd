extends RefCounted
## Reusable original PBR-ish materials. Texture names map to files in assets/textures.
static var _pool: Dictionary = {}

static func fetch(kind: String, tint: Color = Color.WHITE, tiles: float = 1.0, roughness: float = 0.92, metalness: float = 0.0) -> StandardMaterial3D:
    var key: String = "%s:%s:%f:%f:%f" % [kind, tint.to_html(), tiles, roughness, metalness]
    if _pool.has(key):
        return _pool[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = roughness
    material.metallic = metalness
    material.uv1_scale = Vector3(tiles, tiles, 1.0)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    if not kind.is_empty():
        var tex_path: String = "res://assets/textures/%s.png" % kind
        if ResourceLoader.exists(tex_path):
            material.albedo_texture = load(tex_path)
        var normal_path: String = "res://assets/textures/%s_n.png" % kind
        if ResourceLoader.exists(normal_path):
            material.normal_enabled = true
            material.normal_texture = load(normal_path)
            material.normal_scale = 0.72
    _pool[key] = material
    return material

static func leaves(kind: String = "shrub") -> StandardMaterial3D:
    var key: String = "leaf_alpha_" + kind
    if _pool.has(key):
        return _pool[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load("res://assets/textures/%s.png" % kind)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
    mat.alpha_scissor_threshold = 0.42
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.roughness = 1.0
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    _pool[key] = mat
    return mat
