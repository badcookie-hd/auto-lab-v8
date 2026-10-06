"""Generate the original, bevelled AUTO//LAB sedan shell in Blender.

Run from the project root with Blender 5+: blender --background --python tools/build_body.py
"""

import math
from pathlib import Path

import bpy


OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "sedan_body.glb"
HOOD_OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "sedan_hood.glb"


def godot_to_blender(x, y, z):
    return (x, -z, y)


def signed_power(value, exponent):
    return math.copysign(abs(value) ** exponent, value)


def cutter_cube(name, location, dimensions):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    cutter = bpy.context.object
    cutter.name = name
    cutter.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return cutter


def subtract(body, cutter):
    modifier = body.modifiers.new("Cut_" + cutter.name, "BOOLEAN")
    modifier.operation = "DIFFERENCE"
    modifier.solver = "EXACT"
    modifier.object = cutter
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.data.objects.remove(cutter, do_unlink=True)


bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

# Sections are X, height centre, vertical radius, half-width in Godot space.
sections = [
    (-2.72, 0.83, 0.31, 0.66),
    (-2.52, 0.91, 0.42, 0.96),
    (-2.08, 0.95, 0.49, 1.11),
    (-1.20, 0.95, 0.50, 1.16),
    (-0.28, 0.94, 0.49, 1.17),
    (0.15, 0.92, 0.49, 1.18),
    (1.48, 0.94, 0.48, 1.16),
    (2.28, 0.91, 0.42, 1.03),
    (2.70, 0.84, 0.30, 0.73),
]
segments = 48
vertices = []
faces = []
for x, center, radius, width in sections:
    for j in range(segments):
        angle = 2 * math.pi * j / segments
        y = center + signed_power(math.sin(angle), 0.72) * radius
        z = signed_power(math.cos(angle), 0.72) * width
        vertices.append(godot_to_blender(x, y, z))
for i in range(len(sections) - 1):
    for j in range(segments):
        n = (j + 1) % segments
        faces.append((i * segments + j, i * segments + n, (i + 1) * segments + n, (i + 1) * segments + j))
faces.append(tuple(reversed(range(segments))))
faces.append(tuple((len(sections) - 1) * segments + j for j in range(segments)))

mesh = bpy.data.meshes.new("SedanShellMesh")
mesh.from_pydata(vertices, [], faces)
mesh.update()
body = bpy.data.objects.new("SedanShell", mesh)
bpy.context.collection.objects.link(body)
bpy.context.view_layer.objects.active = body

# Wheel wells are cut through the body before fender bevels are applied.
for x in (-1.72, 1.72):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.69, depth=3.0, location=(x, 0, 0.63), rotation=(math.pi / 2, 0, 0))
    subtract(body, bpy.context.object)

# Open cavities allow the separate animated bonnet and the explorable cabin.
subtract(body, cutter_cube("EngineBay", (-1.38, 0, 1.49), (2.28, 1.76, 1.35)))
subtract(body, cutter_cube("CabinOpening", (0.81, 0, 1.61), (2.10, 1.73, 1.05)))

bevel = body.modifiers.new("SoftPressedMetalEdges", "BEVEL")
bevel.width = 0.045
bevel.segments = 3
bevel.affect = "EDGES"
bpy.context.view_layer.objects.active = body
bpy.ops.object.modifier_apply(modifier=bevel.name)
for polygon in body.data.polygons:
    polygon.use_smooth = True

paint = bpy.data.materials.new("GraphiteBlueMetallic")
paint.diffuse_color = (0.067, 0.137, 0.184, 1.0)
paint.use_nodes = True
shader = paint.node_tree.nodes.get("Principled BSDF")
shader.inputs["Base Color"].default_value = (0.067, 0.137, 0.184, 1.0)
shader.inputs["Metallic"].default_value = 0.62
shader.inputs["Roughness"].default_value = 0.29
shader.inputs["Coat Weight"].default_value = 0.28
shader.inputs["Coat Roughness"].default_value = 0.16
body.data.materials.append(paint)

bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", use_selection=True)
print("AUTO_LAB_BODY:", OUTPUT)

# A thin sculpted bonnet, authored around the separate Godot hood area origin.
# X runs from the front edge (-1.09) to the hinge-side edge (+1.09).
hood_sections = [
    (-1.09, 0.91, -0.025),
    (-0.50, 0.98, 0.015),
    (0.32, 1.02, 0.030),
    (1.09, 1.02, 0.025),
]
hood_vertices = []
hood_faces = []
for lower in (False, True):
    for x, half_width, height in hood_sections:
        for side in (-1, 0, 1):
            surface_height = height + (0.018 if side == 0 else 0.0)
            if lower:
                surface_height -= 0.075
            hood_vertices.append(godot_to_blender(x, surface_height, side * half_width))
count = len(hood_sections) * 3
for index in range(len(hood_sections) - 1):
    for side in range(2):
        a = index * 3 + side
        b = (index + 1) * 3 + side
        hood_faces.append((a, b, b + 1, a + 1))
        hood_faces.append((a + count + 1, b + count + 1, b + count, a + count))
for index in range(len(hood_sections) - 1):
    left = index * 3
    next_left = (index + 1) * 3
    hood_faces.append((left, left + count, next_left + count, next_left))
    hood_faces.append((left + 2, next_left + 2, next_left + count + 2, left + count + 2))
for side in range(2):
    hood_faces.append((side, side + 1, side + count + 1, side + count))
    end = (len(hood_sections) - 1) * 3 + side
    hood_faces.append((end, end + count, end + count + 1, end + 1))

hood_mesh = bpy.data.meshes.new("BonnetMesh")
hood_mesh.from_pydata(hood_vertices, [], hood_faces)
hood_mesh.update()
hood = bpy.data.objects.new("Bonnet", hood_mesh)
bpy.context.collection.objects.link(hood)
hood.data.materials.append(paint)
bpy.context.view_layer.objects.active = hood
edge_bevel = hood.modifiers.new("RolledBonnetEdges", "BEVEL")
edge_bevel.width = 0.018
edge_bevel.segments = 3
bpy.ops.object.modifier_apply(modifier=edge_bevel.name)
for polygon in hood.data.polygons:
    polygon.use_smooth = True
bpy.ops.object.select_all(action="DESELECT")
hood.select_set(True)
bpy.context.view_layer.objects.active = hood
bpy.ops.export_scene.gltf(filepath=str(HOOD_OUTPUT), export_format="GLB", use_selection=True)
print("AUTO_LAB_HOOD:", HOOD_OUTPUT)
