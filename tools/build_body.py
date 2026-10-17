"""Generate the detailed, original AUTO//LAB sedan shell in Blender.

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


def material(name, color, metallic=0.0, roughness=0.5, coat=0.0):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1.0)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Coat Weight"].default_value = coat
    return result


def bevel_box(name, location, dimensions, finish, radius=0.025):
    """A small pressed or machined part, supplied in Godot coordinates."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=godot_to_blender(*location))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (dimensions[0], dimensions[2], dimensions[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(finish)
    modifier = obj.modifiers.new("PressedEdges", "BEVEL")
    modifier.width = radius
    modifier.segments = 3
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    normals = obj.modifiers.new("WeightedNormals", "WEIGHTED_NORMAL")
    bpy.ops.object.modifier_apply(modifier=normals.name)
    return obj


def trim_line(name, points, finish, thickness=0.008):
    curve = bpy.data.curves.new(name, type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 12
    curve.bevel_depth = thickness
    curve.bevel_resolution = 3
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, position in zip(spline.points, points):
        point.co = (*godot_to_blender(*position), 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(finish)
    return obj


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

paint = material("MidnightGraphitePaint", (0.064, 0.112, 0.145), 0.68, 0.23, 0.42)
trim = material("SatinBlackTrim", (0.014, 0.019, 0.024), 0.18, 0.39)
dark_chrome = material("DarkChrome", (0.28, 0.33, 0.35), 0.88, 0.25)
rubber = material("WindowAndBodySeals", (0.009, 0.012, 0.015), 0.0, 0.82)
body.data.materials.clear()
body.data.materials.append(paint)
for polygon in body.data.polygons:
    polygon.material_index = 0

# A coherent nose replaces the old collection of overhanging rectangular bars.
bevel_box("LowerBumper", (-2.615, 0.56, 0), (0.20, 0.22, 1.80), paint, 0.065)
bevel_box("RecessedGrille", (-2.738, 0.85, 0), (0.035, 0.28, 1.20), trim, 0.016)
for height in (0.765, 0.835, 0.905):
    bevel_box("GrilleBlade", (-2.766, height, 0), (0.025, 0.013, 1.09), dark_chrome, 0.006)
bevel_box("LowerIntake", (-2.716, 0.52, 0), (0.025, 0.082, 1.25), trim, 0.015)
bevel_box("RearBumper", (2.595, 0.56, 0), (0.20, 0.21, 1.75), paint, 0.06)
bevel_box("RearDiffuser", (2.707, 0.45, 0), (0.03, 0.08, 1.26), trim, 0.018)


def body_width_at(x, height):
    for index in range(len(sections) - 1):
        a, b = sections[index], sections[index + 1]
        if a[0] <= x <= b[0]:
            blend = (x - a[0]) / (b[0] - a[0])
            center = a[1] * (1 - blend) + b[1] * blend
            radius = a[2] * (1 - blend) + b[2] * blend
            width = a[3] * (1 - blend) + b[3] * blend
            sine = min(abs((height - center) / radius), 0.999) ** (1.0 / 0.72)
            return width * (max(0.0, 1.0 - sine * sine) ** 0.5) ** 0.72
    return 0.7


for side in (-1, 1):
    # Fine, surface-following panel gaps rather than floating vertical strips.
    for door_x in (-0.13, 0.87, 1.87):
        points = [(door_x, h, side * (body_width_at(door_x, h) + 0.009))
                  for h in (0.72, 0.80, 0.88, 0.96, 1.04)]
        trim_line("DoorShutLine", points, rubber, 0.004)
    for start, end in ((-0.10, 0.84), (0.90, 1.82)):
        trim_line("DoorLowerCrease", [(x, 0.79, side * (body_width_at(x, 0.79) + 0.006))
                                       for x in (start, (start + end) / 2, end)], dark_chrome, 0.003)
    trim_line("WindowBelt", [(x, 1.075, side * (body_width_at(x, 1.075) + 0.012))
                              for x in (-0.25, 0.0, 0.4, 0.85, 1.3, 1.75)], dark_chrome, 0.007)
    for wheel_x in (-1.72, 1.72):
        points = []
        for index in range(25):
            angle = math.pi * index / 24
            x = wheel_x + math.cos(angle) * 0.705
            height = 0.63 + math.sin(angle) * 0.705
            points.append((x, height, side * (body_width_at(x, height) + 0.018)))
        trim_line("PressedWheelArch", points, paint, 0.016)

bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    obj.select_set(True)
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
# A tapered central press line and underside bracing read correctly while the hood opens.
trim_line("BonnetPressLine", [(-1.03, 0.044, 0), (-0.51, 0.074, 0), (0.33, 0.088, 0), (1.02, 0.083, 0)], paint, 0.008)
for side in (-1, 1):
    trim_line("BonnetUnderBrace", [(-0.96, -0.052, side * 0.64), (0.06, -0.051, side * 0.72), (1.0, -0.047, side * 0.63)], trim, 0.025)
bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    if obj == hood or obj.name.startswith("Bonnet"):
        obj.select_set(True)
bpy.context.view_layer.objects.active = hood
bpy.ops.export_scene.gltf(filepath=str(HOOD_OUTPUT), export_format="GLB", use_selection=True)
print("AUTO_LAB_HOOD:", HOOD_OUTPUT)
