# Renders the 3D piece shapes and the bomb for Bubblop with Blender.
#
#   "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe" -b -P tools/blender/make_pieces.py
#   python tools/blender/split_layers.py
#
# Every shape is rendered in three passes so the game can paint it in any
# ball colour:
#   <name>_body.png    the coloured part, lit in plain white (tinted in game)
#   <name>_gloss.png   the coloured part's highlights only
#   <name>_detail.png  parts that keep their own colours (ears, leaves, sprinkles)
# The bomb is one full-colour render (bomb.png).
#
# Camera and light match the ball shader: orthographic, light from the top
# left. A piece fills a 2.0-unit circle (one ball radius = 1.0).

import math
import os
import random

import bpy
from mathutils import Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "app", "build", "pieces_raw")
SIZE = 256
# One ball radius is 1.0; the frame shows 1.45 radii either side, like the
# game's sprites (OrbSprites.pad).
PAD = 1.45


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.cycles.device = "CPU"
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"

    world = bpy.data.worlds.new("world")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.3

    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = PAD * 2
    cam = bpy.data.objects.new("cam", cam_data)
    cam.location = (0, -10, 0)
    cam.rotation_euler = (math.radians(90), 0, 0)
    scene.collection.objects.link(cam)
    scene.camera = cam

    # Key light from the top left, a little in front (like the shader's).
    key = bpy.data.lights.new("key", "AREA")
    key.energy = 900
    key.size = 4
    key_obj = bpy.data.objects.new("key", key)
    key_obj.location = (-4, -6, 5.5)
    key_obj.rotation_euler = Vector((4, 6, -5.5)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(key_obj)
    return scene


def material(name, color=(1, 1, 1), rough=0.45, spec=0.5, metal=0.0, emission=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Specular IOR Level"].default_value = spec
    bsdf.inputs["Metallic"].default_value = metal
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = 1.0
    return mat


def holdout(name="holdout"):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    hold = nodes.new("ShaderNodeHoldout")
    mat.node_tree.links.new(hold.outputs[0], out.inputs[0])
    return mat


def smooth(obj, level=2):
    mod = obj.modifiers.new("sub", "SUBSURF")
    mod.levels = level
    mod.render_levels = level
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def sphere(loc=(0, 0, 0), scale=(1, 1, 1), segments=48):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=segments // 2, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def cone(loc, r1, r2, depth, rot=(0, 0, 0), vertices=32):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth, location=loc,
                                    rotation=rot)
    obj = bpy.context.object
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def cylinder(loc, r, depth, rot=(0, 0, 0), vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=r, depth=depth, location=loc, rotation=rot)
    obj = bpy.context.object
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def torus(loc, major, minor, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, location=loc, rotation=rot,
                                     major_segments=64, minor_segments=24)
    obj = bpy.context.object
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


R = math.radians

# Piece builders: each returns (body objects, detail objects with materials).
# Front is -Y (towards the camera), up is +Z.


def kitty():
    head = sphere(scale=(1.0, 0.9, 0.9))
    ears = [cone((s * 0.56, 0, 0.78), 0.4, 0.04, 0.72, rot=(0, R(s * 24), 0)) for s in (-1, 1)]
    pink = material("pink", (1.0, 0.62, 0.72), rough=0.6)
    inner = []
    for s in (-1, 1):
        e = cone((s * 0.55, -0.2, 0.76), 0.24, 0.02, 0.5, rot=(0, R(s * 24), 0))
        e.data.materials.append(pink)
        inner.append(e)
    return [head, *ears], inner


def bunny():
    head = sphere(loc=(0, 0, -0.12), scale=(0.95, 0.88, 0.85))
    ears = [sphere(loc=(s * 0.34, 0.05, 0.78), scale=(0.2, 0.14, 0.52)) for s in (-1, 1)]
    for s, e in zip((-1, 1), ears):
        e.rotation_euler = (0, R(s * 12), 0)
    pink = material("pink", (1.0, 0.66, 0.76), rough=0.6)
    inner = []
    for s in (-1, 1):
        e = sphere(loc=(s * 0.34, -0.06, 0.78), scale=(0.1, 0.06, 0.38))
        e.rotation_euler = (0, R(s * 12), 0)
        e.data.materials.append(pink)
        inner.append(e)
    return [head, *ears], inner


def bear():
    head = sphere(loc=(0, 0, -0.05), scale=(1.0, 0.9, 0.92))
    ears = [sphere(loc=(s * 0.66, 0.05, 0.66), scale=(0.3, 0.22, 0.3)) for s in (-1, 1)]
    tan = material("tan", (0.98, 0.86, 0.72), rough=0.6)
    inner = []
    for s in (-1, 1):
        e = sphere(loc=(s * 0.66, -0.14, 0.66), scale=(0.16, 0.06, 0.16))
        e.data.materials.append(tan)
        inner.append(e)
    return [head, *ears], inner


def frog():
    body = sphere(loc=(0, 0, -0.12), scale=(1.02, 0.85, 0.8))
    bumps = [sphere(loc=(s * 0.48, -0.05, 0.56), scale=(0.34, 0.3, 0.32)) for s in (-1, 1)]
    cheek = material("cheek", (1.0, 0.6, 0.66), rough=0.7)
    cheeks = []
    for s in (-1, 1):
        c = sphere(loc=(s * 0.62, -0.68, -0.32), scale=(0.16, 0.05, 0.1))
        c.data.materials.append(cheek)
        cheeks.append(c)
    return [body, *bumps], cheeks


def donut():
    # Seen from the front and a little above: dough below, coloured icing on top.
    tilt = (R(62), 0, 0)
    dough = torus((0, 0, 0), 0.62, 0.36, rot=tilt)
    dough.data.materials.append(material("dough", (0.93, 0.72, 0.45), rough=0.7))
    icing = torus((0, -0.06, 0.05), 0.62, 0.33, rot=tilt)
    icing.scale = (1.04, 1.04, 0.9)
    random.seed(4)
    sprinkles = []
    colors = [(1, 1, 1), (1.0, 0.85, 0.3), (0.35, 0.8, 1.0), (1.0, 0.45, 0.6), (0.6, 1.0, 0.6)]
    for i in range(22):
        a = random.uniform(0, math.tau)
        rr = random.uniform(0.42, 0.86)
        x = math.cos(a) * rr
        y = math.sin(a) * rr
        # Onto the tilted icing's top surface.
        p = Vector((x, y, 0.3))
        p.rotate(dough.rotation_euler)
        s = cylinder((p.x, p.y - 0.02, p.z), 0.035, 0.16, rot=(R(62), 0, random.uniform(0, math.pi)))
        s.rotation_euler.rotate_axis("Y", random.uniform(0, math.pi))
        s.data.materials.append(material(f"spr{i}", colors[i % len(colors)], rough=0.4))
        sprinkles.append(s)
    return [icing], [dough, *sprinkles]


def cupcake():
    wrapper = cone((0, 0, -0.55), 0.58, 0.8, 0.82, rot=(R(180), 0, 0), vertices=24)
    wrapper.data.materials.append(material("wrapper", (1.0, 0.97, 0.92), rough=0.55))
    frost = [
        torus((0, 0, -0.02), 0.62, 0.26),
        torus((0, 0, 0.26), 0.44, 0.22),
        torus((0, 0, 0.5), 0.24, 0.18),
        sphere(loc=(0, 0, 0.66), scale=(0.17, 0.17, 0.2)),
    ]
    for f in frost[:3]:
        f.rotation_euler = (R(8), 0, 0)
    return frost, [wrapper]


def macaron():
    top = sphere(loc=(0, 0, 0.32), scale=(0.98, 0.98, 0.42))
    bottom = sphere(loc=(0, 0, -0.32), scale=(0.98, 0.98, 0.42))
    for s in (top, bottom):
        s.rotation_euler = (R(-14), 0, 0)
    filling = cylinder((0, 0, 0), 0.9, 0.24, rot=(R(-14), 0, 0))
    smooth(filling, 1)
    filling.data.materials.append(material("filling", (1.0, 0.96, 0.88), rough=0.7))
    return [top, bottom], [filling]


def planet():
    globe = sphere(scale=(0.8, 0.8, 0.8))
    # Tilted towards the camera and to one side, like Saturn's.
    ring = torus((0, 0, 0), 1.12, 0.08, rot=(R(-16), R(-20), 0))
    ring.scale = (1.0, 1.0, 0.6)
    ring.data.materials.append(material("ring", (1.0, 0.9, 0.62), rough=0.35, metal=0.3))
    return [globe], [ring]


def gem():
    # A brilliant cut seen from the side: a short crown over a deep pavilion.
    crown = cone((0, 0, 0.32), 0.98, 0.56, 0.44, vertices=10)
    pavilion = cone((0, 0, -0.42), 0.98, 0.02, 1.06, rot=(0, 0, 0), vertices=10)
    pavilion.rotation_euler = (R(180), 0, 0)
    pavilion.location.z = -0.43
    for obj in (crown, pavilion):
        for p in obj.data.polygons:
            p.use_smooth = False
        obj.rotation_euler.z += R(18)
    return [crown, pavilion], []


def moon():
    body = sphere(scale=(0.96, 0.96, 0.96), segments=64)
    # Craters: shallow dents carved with spheres.
    for (x, z, r) in [(-0.32, 0.28, 0.32), (0.4, -0.18, 0.26), (-0.12, -0.48, 0.2), (0.3, 0.48, 0.16)]:
        y = -math.sqrt(max(0.0, 0.92 - x * x - z * z)) - 0.06
        cutter = sphere(loc=(x, y, z), scale=(r, r, r))
        mod = body.modifiers.new("crater", "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.object = cutter
        cutter.hide_render = True
    return [body], []


def strawberry():
    berry = sphere(loc=(0, 0, -0.08), scale=(0.9, 0.82, 0.98))
    taper = berry.modifiers.new("taper", "SIMPLE_DEFORM")
    taper.deform_method = "TAPER"
    taper.factor = 0.75
    taper.deform_axis = "Z"
    seed_mat = material("seed", (1.0, 0.93, 0.55), rough=0.4)
    seeds = []
    for i, (x, z) in enumerate([(-0.45, 0.35), (0.0, 0.42), (0.45, 0.35), (-0.25, 0.0), (0.25, 0.0),
                                (-0.5, -0.05), (0.5, -0.05), (0.0, -0.35), (-0.25, -0.5), (0.25, -0.5)]):
        y = -math.sqrt(max(0.05, 0.85 - x * x * 0.9 - z * z * 0.6)) * 0.86
        s = sphere(loc=(x, y, z), scale=(0.04, 0.03, 0.065), segments=12)
        s.data.materials.append(seed_mat)
        seeds.append(s)
    green = material("leaf", (0.3, 0.75, 0.32), rough=0.55)
    leaves = []
    for i in range(5):
        a = i * math.tau / 5
        leaf = sphere(loc=(math.cos(a) * 0.3, math.sin(a) * 0.3 - 0.05, 0.78), scale=(0.28, 0.12, 0.05))
        leaf.rotation_euler = (R(10), 0, a)
        leaf.data.materials.append(green)
        leaves.append(leaf)
    stem = cylinder((0, 0, 0.92), 0.05, 0.22)
    stem.data.materials.append(green)
    return [berry], [*seeds, *leaves, stem]


def apple():
    body = sphere(loc=(0, 0, -0.08), scale=(0.98, 0.9, 0.86))
    dent = sphere(loc=(0, 0, 0.8), scale=(0.3, 0.3, 0.2))
    mod = body.modifiers.new("dent", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = dent
    dent.hide_render = True
    smooth(body, 1)
    brown = material("stem", (0.45, 0.28, 0.15), rough=0.7)
    stem = cylinder((0.04, 0, 0.82), 0.05, 0.36, rot=(0, R(14), 0))
    stem.data.materials.append(brown)
    leaf = sphere(loc=(0.32, -0.02, 0.88), scale=(0.3, 0.06, 0.13))
    leaf.rotation_euler = (0, R(-28), 0)
    leaf.data.materials.append(material("leaf", (0.36, 0.78, 0.3), rough=0.5))
    return [body], [stem, leaf]


def cherry():
    body = sphere(loc=(0, 0, -0.2), scale=(0.86, 0.82, 0.8))
    green = material("stem", (0.36, 0.62, 0.22), rough=0.6)
    bpy.ops.curve.primitive_bezier_curve_add(location=(0, 0, 0))
    curve = bpy.context.object
    curve.data.bevel_depth = 0.045
    curve.data.bevel_resolution = 4
    pts = curve.data.splines[0].bezier_points
    pts[0].co = (0, 0, 0.5)
    pts[0].handle_left = (0, 0, 0.3)
    pts[0].handle_right = (0.05, 0, 0.8)
    pts[1].co = (0.45, 0, 1.05)
    pts[1].handle_left = (0.25, 0, 1.0)
    pts[1].handle_right = (0.6, 0, 1.1)
    curve.data.materials.append(green)
    leaf = sphere(loc=(0.56, -0.02, 1.0), scale=(0.24, 0.05, 0.1))
    leaf.rotation_euler = (0, R(-20), 0)
    leaf.data.materials.append(material("leaf", (0.36, 0.78, 0.3), rough=0.5))
    return [body], [curve, leaf]


PIECES = {
    "kitty": kitty, "bunny": bunny, "bear": bear, "frog": frog,
    "donut": donut, "cupcake": cupcake, "macaron": macaron,
    "planet": planet, "gem": gem, "moon": moon,
    "strawberry": strawberry, "apple": apple, "cherry": cherry,
}


def render(scene, path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def make_piece(name, build):
    scene = reset()
    body, details = build()
    white = material("white", (1, 1, 1), rough=0.55, spec=0.0)
    gloss = material("gloss", (0, 0, 0), rough=0.18, spec=1.0)
    if name == "moon":
        # Matte, like rock: crater rims would catch sharp highlights.
        white = material("white", (1, 1, 1), rough=0.8, spec=0.0)
        gloss = material("gloss", (0, 0, 0), rough=0.6, spec=0.3)
    if name == "gem":
        white = material("white", (1, 1, 1), rough=0.3, spec=0.0)
        gloss = material("gloss", (0, 0, 0), rough=0.05, spec=1.0)
    hold = holdout()

    def assign(objs, mat):
        for obj in objs:
            obj.data.materials.clear()
            obj.data.materials.append(mat)

    detail_mats = {obj.name: list(obj.data.materials) for obj in details}

    # Body: coloured part in white, details cut out where they cover it.
    assign(body, white)
    assign(details, hold)
    render(scene, os.path.join(OUT, f"{name}_body.png"))
    # Gloss: highlights of the coloured part only, from the key light alone
    # (the sky would turn the whole piece grey).
    world_strength = scene.world.node_tree.nodes["Background"].inputs[1]
    world_strength.default_value = 0.0
    assign(body, gloss)
    render(scene, os.path.join(OUT, f"{name}_gloss.png"))
    world_strength.default_value = 0.3
    # Details in their own colours, the body cut out where it covers them.
    if details:
        assign(body, hold)
        for obj in details:
            obj.data.materials.clear()
            for m in detail_mats[obj.name]:
                obj.data.materials.append(m)
        render(scene, os.path.join(OUT, f"{name}_detail.png"))


def make_bomb():
    scene = reset()
    ball = sphere(loc=(0, 0, -0.08), scale=(0.9, 0.9, 0.9), segments=64)
    ball.data.materials.append(material("iron", (0.07, 0.07, 0.1), rough=0.22, spec=0.8))
    cap = cylinder((0, 0, 0.82), 0.28, 0.22)
    cap.data.materials.append(material("cap", (0.65, 0.66, 0.72), rough=0.25, metal=0.9))
    bpy.ops.curve.primitive_bezier_curve_add(location=(0, 0, 0))
    fuse = bpy.context.object
    fuse.data.bevel_depth = 0.06
    fuse.data.bevel_resolution = 4
    pts = fuse.data.splines[0].bezier_points
    pts[0].co = (0, 0, 0.9)
    pts[0].handle_left = (0, 0, 0.7)
    pts[0].handle_right = (0.0, 0, 1.15)
    pts[1].co = (0.42, 0, 1.25)
    pts[1].handle_left = (0.2, 0, 1.25)
    pts[1].handle_right = (0.6, 0, 1.25)
    fuse.data.materials.append(material("fuse", (0.85, 0.72, 0.5), rough=0.8))
    # A soft white sheen strip so the bomb reads on the dark board too.
    render(scene, os.path.join(OUT, "bomb.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    only = os.environ.get("POP_PIECES")
    for name, build in PIECES.items():
        if only and name not in only.split(","):
            continue
        make_piece(name, build)
    if not only or "bomb" in only.split(","):
        make_bomb()
