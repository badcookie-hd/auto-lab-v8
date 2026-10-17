"""Align the CC BY 4.0 Mustang GT visual asset with AUTO//LAB's V8 coordinates.

Run from the project root with Blender 5+: blender --background --python tools/prepare_mustang.py
The original asset and license are documented in assets/ATTRIBUTION.md.
"""

from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source_assets" / "mustang-2005.glb"
SHELL = ROOT / "assets" / "mustang_shell.glb"
HOOD = ROOT / "assets" / "mustang_hood.glb"
WHEELS = ROOT / "assets" / "mustang_wheels.glb"
INTERIOR = ROOT / "assets" / "mustang_interior.glb"

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))

groups = {"shell": [], "hood": [], "wheels": [], "interior": []}
for obj in list(bpy.context.scene.objects):
    if obj.type != "MESH":
        continue
    name = obj.name.lower()
    if name == "cube" or name.startswith("radiator_"):
        bpy.data.objects.remove(obj, do_unlink=True)
        continue
    if name.startswith(("hood_",)):
        group = "hood"
    elif name.startswith(("frdperofrmcrim", "tire")):
        group = "wheels"
    elif name.startswith((
        "body_", "sideskirt_", "headlight housing_", "tailight_", "bottm_",
        "glass_", "rearbadge_", "leftdoor_", "rightdoor_", "roof_", "fenders_",
        "msngv6front bumper_", "msngv6rearbumper_", "trunk_", "cylinder003_",
        "exhaust_tip_", "fronteng_",
    )):
        group = "shell"
    else:
        # Original cabin meshes replace the old block-built cabin visually.
        # AUTO//LAB keeps its interactive areas and educational behaviour.
        group = "interior"
    matrix = obj.matrix_world.copy()
    for vertex in obj.data.vertices:
        original = matrix @ vertex.co
        # Source: Blender X lateral / Y longitudinal / Z vertical.
        # Target Blender: X front-to-rear / Y lateral / Z vertical.
        result = Vector((original.y * 1.25, -original.x * 1.35, original.z * 1.8))
        if group == "hood":
            result.x += 0.87
            result.z -= 1.70
        vertex.co = result
    obj.parent = None
    obj.matrix_world.identity()
    groups[group].append(obj)

for group, path in (("shell", SHELL), ("hood", HOOD), ("wheels", WHEELS), ("interior", INTERIOR)):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in groups[group]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = groups[group][0]
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True)
    print("AUTO_LAB_MUSTANG:", group, len(groups[group]), path)
