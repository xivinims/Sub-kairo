import bpy
import sys
import math
from mathutils import Vector

# Use Blender's matching system Python stdlib for the FBX/glTF exporters.
sys.path.insert(0, '/usr/lib/python3.12')
sys.path.insert(1, '/usr/lib/python3.12/lib-dynload')
sys.path.insert(2, '/usr/lib/python3/dist-packages')

# Still Here / 1940s hotel lobby: compact, low-poly art-deco bellhop cart.
# Run: blender -b --python make_blender_bellhop_cart.py

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    if collection.name != 'Collection':
        bpy.data.collections.remove(collection)

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 1000
scene.render.resolution_y = 850
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.film_transparent = True
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'Medium High Contrast'
scene.world.color = (0.045, 0.035, 0.025)

asset = bpy.data.collections.new('STILL HERE - Bellhop Cart')
scene.collection.children.link(asset)
preview = bpy.data.collections.new('Preview Set - do not export')
scene.collection.children.link(preview)

def material(name, color, metallic=0.0, roughness=0.42):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    return mat

brass = material('Aged brass', (0.46, 0.27, 0.095), 0.78, 0.28)
brass_light = material('Polished brass edges', (0.78, 0.53, 0.22), 0.82, 0.22)
wood = material('Dark walnut', (0.19, 0.075, 0.033), 0.05, 0.34)
wood_edge = material('Walnut edge highlights', (0.34, 0.14, 0.055), 0.06, 0.31)
leather = material('Oxblood leather', (0.20, 0.046, 0.031), 0.0, 0.55)
leather_light = material('Warm leather piping', (0.48, 0.18, 0.075), 0.0, 0.48)
fabric = material('Cream luggage fabric', (0.63, 0.48, 0.30), 0.0, 0.78)
fabric_dark = material('Luggage seams', (0.29, 0.16, 0.08), 0.0, 0.7)
rubber = material('Wheel rubber', (0.035, 0.027, 0.022), 0.0, 0.72)
ivory = material('Enamel label', (0.79, 0.69, 0.48), 0.15, 0.34)

def move_to(obj, collection=asset):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    collection.objects.link(obj)
    return obj

def bevel(obj, amount=0.06, segments=2):
    mod = obj.modifiers.new('Soft crafted edges', 'BEVEL')
    mod.width = amount
    mod.segments = segments
    mod2 = obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
    return obj

def cube(name, location, scale, mat, bevel_amount=0.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = move_to(bpy.context.object)
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel_amount:
        bevel(obj, bevel_amount)
    return obj

def cylinder(name, location, radius, depth, mat, axis='Z', vertices=20, bevel_amount=0.015):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = move_to(bpy.context.object)
    obj.name = name
    if axis == 'X':
        obj.rotation_euler[1] = math.pi / 2
    elif axis == 'Y':
        obj.rotation_euler[0] = math.pi / 2
    obj.data.materials.append(mat)
    if bevel_amount:
        bevel(obj, bevel_amount, 2)
    return obj

def torus(name, location, major_radius, minor_radius, mat, axis='Y'):
    bpy.ops.mesh.primitive_torus_add(major_segments=24, minor_segments=8,
                                     major_radius=major_radius, minor_radius=minor_radius,
                                     location=location)
    obj = move_to(bpy.context.object)
    obj.name = name
    if axis == 'Y':
        obj.rotation_euler[0] = math.pi / 2
    elif axis == 'X':
        obj.rotation_euler[1] = math.pi / 2
    obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj

def beam(name, a, b, radius, mat, vertices=12):
    midpoint = (Vector(a) + Vector(b)) * 0.5
    direction = Vector(b) - Vector(a)
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                        depth=direction.length, location=midpoint)
    obj = move_to(bpy.context.object)
    obj.name = name
    obj.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
    obj.data.materials.append(mat)
    bevel(obj, 0.012, 2)
    return obj

# Main trolley platform and inset wood panel.
cube('Raised walnut luggage deck', (0, 0, 0.78), (1.55, 1.02, 0.18), wood, 0.11)
cube('Deck brass front edge', (0, -0.515, 0.79), (1.38, 0.025, 0.09), brass_light, 0.012)
cube('Deck brass rear edge', (0, 0.515, 0.79), (1.38, 0.025, 0.09), brass_light, 0.012)
for x in (-0.68, 0.68):
    for y in (-0.40, 0.40):
        cylinder('Brass deck rivet', (x, y, 0.883), 0.035, 0.018, brass_light, vertices=12, bevel_amount=0.004)

# Four slim art-deco uprights with stepped collars and an arched handle.
for x in (-0.64, 0.64):
    for y in (-0.39, 0.39):
        beam('Brass upright', (x, y, 0.87), (x, y, 3.32), 0.038, brass, 12)
        cylinder('Upright foot collar', (x, y, 0.98), 0.065, 0.095, brass_light, vertices=16)
        cylinder('Upright top collar', (x, y, 3.19), 0.057, 0.10, brass_light, vertices=16)
        cylinder('Upright finial', (x, y, 3.38), 0.052, 0.10, brass_light, vertices=16)
for y in (-0.39, 0.39):
    beam('Upper luggage rail', (-0.64, y, 3.25), (0.64, y, 3.25), 0.04, brass_light, 16)
    if y > 0:
        beam('Rear luggage retaining rail', (-0.64, y, 1.52), (0.64, y, 1.52), 0.025, brass, 12)

# Large dark-rubber wheels with brass hubs and inset rings.
for x in (-0.53, 0.53):
    torus('Solid trolley wheel', (x, 0, 0.43), 0.34, 0.085, rubber, axis='Y')
    cylinder('Brass wheel hub', (x, -0.095, 0.43), 0.12, 0.08, brass, axis='Y', vertices=20)
    cylinder('Hub cap', (x, -0.145, 0.43), 0.062, 0.035, brass_light, axis='Y', vertices=20)
    torus('Fine wheel sidewall', (x, -0.055, 0.43), 0.24, 0.014, brass, axis='Y')
    for j in range(8):
        a = j * math.tau / 8
        cylinder('Hub pin', (x + math.cos(a)*0.086, -0.148, 0.43 + math.sin(a)*0.086),
                 0.012, 0.012, brass_light, axis='Y', vertices=8, bevel_amount=0.002)
beam('Wheel axle', (-0.55, 0, 0.43), (0.55, 0, 0.43), 0.055, brass, 16)

# One neatly strapped vintage suitcase, slightly angled for a lived-in lobby look.
suitcase = cube('Oxblood leather suitcase', (0.06, 0.04, 1.52), (1.17, 0.69, 0.94), leather, 0.13)
suitcase.rotation_euler[1] = math.radians(-5)
for x in (-0.36, 0.48):
    strap = cube('Leather suitcase strap', (x, -0.315, 1.52), (0.09, 0.024, 0.84), leather_light, 0.018)
    strap.rotation_euler[1] = math.radians(-5)
for z in (1.21, 1.83):
    cube('Suitcase front piping', (0.06, -0.316, z), (1.02, 0.025, 0.035), fabric_dark, 0.015)
cube('Luggage maker plaque', (0.08, -0.352, 1.51), (0.32, 0.035, 0.16), brass_light, 0.025)
cube('Enamel hotel luggage tag', (0.08, -0.375, 1.51), (0.23, 0.018, 0.095), ivory, 0.015)
tag_data = bpy.data.curves.new('HOTEL tag lettering', type='FONT')
tag_data.body = 'HOTEL'
tag_data.align_x = 'CENTER'
tag_data.align_y = 'CENTER'
tag_data.size = 0.048
tag_data.extrude = 0.001
tag = bpy.data.objects.new('HOTEL luggage tag lettering', tag_data)
asset.objects.link(tag)
tag.location = (0.08, -0.388, 1.51)
tag.rotation_euler[0] = math.radians(90)
tag.data.materials.append(fabric_dark)
for x in (-0.46, 0.58):
    for z in (1.13, 1.91):
        cylinder('Suitcase brass corner cap', (x, -0.324, z), 0.04, 0.022, brass_light, axis='Y', vertices=12)
for y in (-0.19, 0.25):
    beam('Suitcase leather carry handle support', (-0.05, y, 2.01), (-0.05, y, 2.20), 0.035, brass, 10)
beam('Suitcase leather carry handle', (-0.05, -0.19, 2.20), (-0.05, 0.25, 2.20), 0.04, leather_light, 12)

# Small polished brass luggage bell fixed to the front-left corner of the deck.
cylinder('Service bell plinth', (-0.52, -0.39, 0.91), 0.105, 0.045, brass_light, vertices=24)
bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=10, radius=1,
                                    location=(-0.52, -0.39, 1.00))
bell = move_to(bpy.context.object)
bell.name = 'Service bell dome'
bell.scale = (0.075, 0.075, 0.07)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bell.data.materials.append(brass_light)
for p in bell.data.polygons:
    p.use_smooth = True
cylinder('Service bell button', (-0.52, -0.39, 1.075), 0.027, 0.025, brass_light, vertices=16)

# Preview-only studio floor, lighting and camera.
floor_mat = material('Preview charcoal', (0.038, 0.032, 0.028), 0.0, 0.8)
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0.0))
floor = move_to(bpy.context.object, preview)
floor.name = 'Preview floor - not exported'
floor.data.materials.append(floor_mat)

def area_light(name, location, energy, size, color):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = energy
    data.shape = 'DISK'
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    preview.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0, 0, 1.55)) - obj.location).to_track_quat('-Z', 'Y').to_euler()

area_light('Warm key', (3, -5, 7), 780, 5, (1.0, 0.77, 0.49))
area_light('Cool fill', (-4, -1, 4), 430, 4, (0.58, 0.69, 1.0))
area_light('Gold rim', (1, 4, 5), 900, 3, (1.0, 0.61, 0.25))
camera_data = bpy.data.cameras.new('Preview camera')
camera = bpy.data.objects.new('Preview camera', camera_data)
preview.objects.link(camera)
camera.location = (5.6, -8.5, 5.2)
target = Vector((0, 0, 1.72))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 5.5
scene.camera = camera
scene.render.filepath = '//still-here-bellhop-cart-preview.png'

# Save a clean modelling project, plus game-engine interchange files.
bpy.ops.wm.save_as_mainfile(filepath='still-here-bellhop-cart.blend')
bpy.ops.render.render(write_still=True)

def export_selected(filepath, operator, **kwargs):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in asset.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = asset.objects[0]
    operator(filepath=filepath, use_selection=True, **kwargs)

export_selected('still-here-bellhop-cart.glb', bpy.ops.export_scene.gltf,
                export_format='GLB', export_apply=True)
export_selected('still-here-bellhop-cart.fbx', bpy.ops.export_scene.fbx,
                apply_scale_options='FBX_SCALE_UNITS', axis_forward='-Z', axis_up='Y',
                add_leaf_bones=False, bake_anim=False, path_mode='COPY')
print('Created Bellhop Cart asset:', len(asset.objects), 'objects; Blender', bpy.app.version_string)
