"""One-time construction of the MCP-created prototype skeleton and new audio assets.

Refuses to replace a populated scene or existing audio. The resulting scene is
ordinary editable Godot geometry; this helper is not used at runtime.
"""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes/bedroom_prototype.tscn"
if SCENE.read_text().count("[node ") > 2:
    raise SystemExit("Scene is already populated; refusing to overwrite it.")

resources = []
nodes = []
counter = 0

def value(x):
    if isinstance(x, bool): return "true" if x else "false"
    if isinstance(x, str): return x
    return str(x)

def vec(x): return "Vector3(%s)" % ", ".join(str(v) for v in x)
def color(x): return "Color(%s)" % ", ".join(str(v) for v in (*x, 1))

def resource(kind, props, ident=None):
    global counter
    counter += 1
    ident = ident or f"{kind}_{counter}"
    resources.append(f'[sub_resource type="{kind}" id="{ident}"]\n' + "\n".join(f"{k} = {value(v)}" for k, v in props.items()))
    return f'SubResource("{ident}")'

def node(name, kind, parent=".", **props):
    par = f' parent="{parent}"' if parent is not None else ""
    nodes.append(f'[node name="{name}" type="{kind}"{par}]\n' + "\n".join(f"{k} = {value(v)}" for k, v in props.items()))
    return name if parent in (None, ".") else f"{parent}/{name}"

def mat(name, rgb, emission=None, unlit=False):
    props = {"albedo_color": color(rgb), "roughness": 0.95, "specular_mode": 2}
    if unlit: props["shading_mode"] = 0
    if emission:
        props.update(emission_enabled=True, emission=color(emission), emission_energy_multiplier=0.6)
    return resource("StandardMaterial3D", props, name)

wood = mat("Walnut", (.27, .13, .065))
wood_light = mat("WoodGrain", (.36, .20, .10))
wood_dark = mat("WoodDark", (.12, .063, .039))
wall = mat("OldWallpaper", (.26, .28, .24))
stripe = mat("WallpaperStripe", (.215, .23, .20))
black = mat("Charcoal", (.024, .03, .029))
metal = mat("OldMetal", (.26, .29, .26))
cream = mat("YellowedPlastic", (.64, .59, .43))
paper = mat("Paper", (.76, .70, .55))
red = mat("OxideRed", (.37, .095, .065))
blue = mat("Bedspread", (.10, .16, .18))
pencil_yellow = mat("PencilYellow", (.68, .42, .085))
pet_shell = mat("PetShell", (.40, .37, .49))
lcd = mat("LCD", (.32, .43, .23), (.22, .32, .13))
pixel = mat("LCDPixel", (.045, .075, .035), unlit=True)
glass = mat("NightGlass", (.028, .08, .12), (.025, .07, .12))
bulb = mat("Bulb", (.92, .72, .40), (.95, .60, .22))
led = mat("LED", (.75, .19, .045), (1, .12, .025), True)

unit_box = resource("BoxMesh", {"size": "Vector3(1, 1, 1)"})
unit_cylinder = resource("CylinderMesh", {"top_radius": .5, "bottom_radius": .5, "height": 1, "radial_segments": 8, "rings": 1})
unit_sphere = resource("SphereMesh", {"radius": .5, "height": 1, "radial_segments": 12, "rings": 6})

def mesh(name, parent, pos, size, material, shape=unit_box, rotation=None, visible=True):
    props = {"position": vec(pos), "scale": vec(size), "mesh": shape, "material_override": material}
    if rotation: props["rotation"] = vec(rotation)
    if not visible: props["visible"] = False
    return node(name, "MeshInstance3D", parent, **props)

def collider(parent, size, offset=(0, 0, 0)):
    shape = resource("BoxShape3D", {"size": vec(size)})
    node("Collision", "CollisionShape3D", parent, position=vec(offset), shape=shape)

def solid(name, parent, pos, size, material):
    body = node(name, "StaticBody3D", parent, position=vec(pos), collision_layer=1, collision_mask=0)
    mesh("Mesh", body, (0, 0, 0), size, material)
    collider(body, size)
    return body

def prop(name, pos, size, ident, offset=(0, 0, 0)):
    path = node(name, "StaticBody3D", "Props", position=vec(pos), collision_layer=2, collision_mask=0, **{"metadata/interaction": f'"{ident}"'})
    collider(path, size, offset)
    return path

def label3(name, parent, text, pos, rotation=(0, 0, 0), font_size=32, pixel_size=.0012, tint=(.75, .72, .60)):
    return node(name, "Label3D", parent, position=vec(pos), rotation=vec(rotation), text=f'"{text}"', font_size=font_size, pixel_size=pixel_size, modulate=color(tint), outline_size=0, no_depth_test=False)

node("CassetteBedroom", "Node3D", None, script='ExtResource("1_script")')
node("Room", "Node3D")
solid("Floor", "Room", (0, -.08, .5), (6, .16, 6), wood_dark)
solid("BackWall", "Room", (0, 1.5, -1.8), (6, 3, .15), wall)
solid("LeftWall", "Room", (-3, 1.5, .5), (.15, 3, 6), wall)
solid("RightWall", "Room", (3, 1.5, .5), (.15, 3, 6), wall)
mesh("Ceiling", "Room", (0, 3, .5), (6, .1, 6), wood_dark)
for i in range(22):
    mesh(f"Floorboard{i:02}", "Room", (-2.86 + i * .27, .012, .5), (.255, .025, 5.9), wood if i % 3 else wood_light)
for i in range(40):
    mesh(f"Wallpaper{i:02}", "Room", (-2.95 + i * .15, 1.55, -1.715), (.025, 2.85, .008), stripe)
mesh("Skirting", "Room", (0, .12, -1.69), (6, .20, .05), wood_dark)
mesh("PictureFrame", "Room", (-.72, 1.83, -1.66), (.48, .65, .065), wood_dark)
mesh("FadedPicture", "Room", (-.72, 1.83, -1.62), (.39, .54, .012), cream)
mesh("PictureSilhouette", "Room", (-.72, 1.81, -1.61), (.19, .32, .01), wood_dark, unit_sphere)
mesh("PictureHead", "Room", (-.72, 2.01, -1.60), (.115, .13, .01), black, unit_sphere)

# Window with opaque night panes and a few distant lights.
window = node("Window", "Node3D", "Room", position=vec((.84, 1.85, -1.66)))
mesh("Frame", window, (0, 0, 0), (1.18, 1.32, .12), wood_dark)
mesh("Glass", window, (0, 0, .075), (1.04, 1.17, .02), glass)
mesh("Mullion", window, (0, 0, .10), (.055, 1.2, .04), metal)
mesh("Crossbar", window, (0, 0, .10), (1.09, .05, .04), metal)
mesh("Sill", window, (0, -.70, .10), (1.40, .10, .30), wood)
for i in range(4):
    mesh(f"DistantLight{i}", window, (-.41 + .24 * i, -.36 + .08 * (i % 2), .09), (.012, .022, .004), bulb)
for side in (-1, 1):
    for fold in range(4):
        mesh(f"Curtain{side}_{fold}", window, (side * (.67 + fold * .08), -.05, .14 + .03 * (fold % 2)), (.085, 1.63, .09), blue)

mesh("ClosedDoor", "Room", (-2.0, 1.04, -1.64), (.9, 2.08, .09), wood_dark)
for x in (-2.49, -1.51): mesh("DoorFrame" + str(x), "Room", (x, 1.1, -1.58), (.07, 2.2, .07), wood)
mesh("DoorHeader", "Room", (-2, 2.21, -1.58), (1.05, .08, .07), wood)
mesh("DoorHandle", "Room", (-1.70, .99, -1.55), (.08, .06, .1), metal, unit_sphere)
bed = node("Bed", "Node3D", "Room", position=vec((2.05, 0, .20)))
mesh("Frame", bed, (0, .28, 0), (1.25, .20, 2.20), wood_dark)
mesh("Mattress", bed, (0, .48, 0), (1.18, .22, 2.09), cream)
mesh("Blanket", bed, (0, .61, .27), (1.20, .10, 1.55), blue)
mesh("Pillow", bed, (0, .65, -.72), (.80, .15, .39), paper)
mesh("Headboard", bed, (0, .58, -1.12), (1.30, 1.05, .12), wood)
for i in range(5): mesh(f"BlanketSeam{i}", bed, (-.48 + i * .24, .665, .27), (.017, .01, 1.5), metal)

# A worn wooden writing desk, with separate strips and drawer fronts.
desk = node("Desk", "Node3D")
solid("Top", desk, (0, .73, 0), (2.70, .10, 1.28), wood)
for i in range(7): mesh(f"Grain{i}", desk, (0, .783, -.54 + i * .18), (2.63, .003, .012), wood_light if i % 2 else wood_dark)
for x in (-1.19, 1.19):
    for z in (-.48, .48): mesh(f"Leg{x}_{z}", desk, (x, .35, z), (.12, .70, .12), wood_dark)
mesh("FrontApron", desk, (0, .61, .53), (2.48, .19, .09), wood_dark)
for i in range(3):
    mesh(f"Drawer{i}", desk, (-.82 + .82 * i, .61, .59), (.76, .15, .05), wood)
    mesh(f"DrawerPull{i}", desk, (-.82 + .82 * i, .61, .63), (.18, .025, .045), metal)

node("Props", "Node3D")
player = prop("CassettePlayer", (-.56, .89, -.24), (.78, .25, .47), "player")
mesh("Housing", player, (0, 0, 0), (.76, .20, .44), black)
mesh("Faceplate", player, (0, .104, 0), (.72, .012, .40), metal)
mesh("TapeWell", player, (.14, .115, -.025), (.33, .015, .25), black)
mesh("LoadedTape", player, (.14, .13, -.025), (.29, .012, .18), cream, visible=False)
for side, x in (("Left", .065), ("Right", .215)):
    reel = mesh("Reel" + side, player, (x, .145, -.025), (.065, .012, .065), black, unit_cylinder)
    mesh("Spoke", reel, (0, .6, 0), (.18, .15, .95), cream)
for i in range(9): mesh(f"SpeakerSlot{i}", player, (-.22, .115, -.15 + i * .034), (.18, .01, .012), black)
for i in range(5): mesh(f"Button{i}", player, (-.22 + i * .095, .105, .184), (.074, .032, .055), red if i == 0 else cream)
mesh("PlayIndicator", player, (.31, .12, .16), (.025, .016, .025), led, visible=False)
label3("Brand", player, "PORTABLE / 90", (0, .02, .226), font_size=24, pixel_size=.00075)
node("TapeAudio", "AudioStreamPlayer3D", player, stream='ExtResource("3_tape")', volume_db=-18.0, unit_size=1.5, max_distance=8.0)

cassette = prop("Cassette", (-.69, .81, .31), (.32, .085, .22), "cassette")
mesh("Shell", cassette, (0, 0, 0), (.28, .046, .18), black)
mesh("Sticker", cassette, (0, .025, 0), (.255, .005, .13), cream)
mesh("RedStripe", cassette, (0, .03, -.04), (.25, .004, .025), red)
for x in (-.067, .067): mesh("Spool" + str(x), cassette, (x, .034, .01), (.048, .008, .048), black, unit_cylinder)
label3("Side", cassette, "A", (-.10, .036, .036), (-math.pi / 2, 0, 0), font_size=28, pixel_size=.0009)

book = prop("Sketchbook", (.32, .807, .23), (.65, .065, .46), "sketchbook")
mesh("Cover", book, (0, -.005, 0), (.64, .035, .46), black)
mesh("Pages", book, (0, .016, 0), (.61, .015, .43), paper)
mesh("Spine", book, (-.26, .028, 0), (.012, .008, .43), wood_dark)
for i in range(9): mesh(f"Binding{i}", book, (-.29, .03, -.18 + i * .045), (.045, .009, .012), metal)
label3("PageHeading", book, "OCT. 17   /   STUDY 01", (.02, .027, -.15), (-math.pi / 2, 0, 0), font_size=24, pixel_size=.00065, tint=(.22, .23, .20))
draw = node("Drawing", "Node3D", book)
for i in range(3): node(f"Stage{i}", "Node3D", draw, visible=False)
def stroke(name, parent, x, z, sx, sz, angle=0):
    mesh(name, parent, (x, .027, z), (sx, .002, sz), wood_dark, rotation=(0, angle, 0))
for i, (x,z,sx,sz) in enumerate([(-.14,.03,.003,.20),(.17,.03,.003,.20),(.015,-.07,.31,.003),(.015,.13,.31,.003)]):
    stroke(f"RoomLine{i}", draw + "/Stage0", x,z,sx,sz)
for i, (x,z,sx,sz) in enumerate([(.03,.01,.003,.10),(.13,.01,.003,.10),(.08,-.04,.10,.003),(.08,.06,.10,.003),(.08,.01,.003,.10)]):
    stroke(f"WindowLine{i}", draw + "/Stage1", x,z,sx,sz)
mesh("Figure", draw + "/Stage2", (.105, .029, .025), (.017, .002, .05), wood_dark)
mesh("Head", draw + "/Stage2", (.105, .029, -.008), (.021, .002, .02), wood_dark, unit_cylinder)

pencil = prop("Pencil", (.87, .81, .30), (.12, .075, .40), "pencil")
mesh("Shaft", pencil, (0, 0, 0), (.022, .32, .022), pencil_yellow, unit_cylinder, (math.pi/2, 0, 0))
tip = resource("CylinderMesh", {"top_radius": 0, "bottom_radius": .012, "height": .045, "radial_segments": 6})
mesh("Tip", pencil, (0, 0, -.18), (1,1,1), wood_light, tip, (-math.pi/2, 0, 0))
mesh("Graphite", pencil, (0, 0, -.205), (.008, .014, .008), black, unit_cylinder, (math.pi/2, 0, 0))
mesh("Eraser", pencil, (0, 0, .17), (.026, .035, .026), red, unit_cylinder, (math.pi/2, 0, 0))

pet = prop("Tamagotchi", (.76, .93, -.29), (.27, .32, .15), "pet")
mesh("EggShell", pet, (0, 0, 0), (.25, .31, .13), pet_shell, unit_sphere)
mesh("ScreenBezel", pet, (0, .018, .058), (.165, .15, .025), black)
mesh("Screen", pet, (0, .018, .073), (.142, .125, .008), lcd)
face = node("Face", "Node3D", pet)
pattern = ["0011100", "0111110", "1101011", "1111111", "0111110", "0100010"]
for y, row in enumerate(pattern):
    for x, cell in enumerate(row):
        if cell == "1": mesh(f"Pixel{x}_{y}", face, ((x-3)*.013, .045-y*.013, .080), (.012, .012, .004), pixel)
heart = node("Heart", "Node3D", pet, visible=False)
for x, y in ((0,0),(2,0),(-1,1),(0,1),(1,1),(2,1),(3,1),(0,2),(1,2),(2,2),(1,3)):
    mesh(f"Heart{x}_{y}", heart, (-.055+x*.006, .069-y*.006, .081), (.005, .005, .004), pixel)
for i in range(3): mesh(f"Button{i}", pet, (-.056 + i*.056, -.08, .062), (.026, .026, .016), cream, unit_sphere)
label3("PetBrand", pet, "TAMA", (0,.115,.053), font_size=20, pixel_size=.001)
node("ChirpAudio", "AudioStreamPlayer3D", pet, stream='ExtResource("5_chirp")', volume_db=-16.0, unit_size=1.5)

lamp = prop("Lamp", (-1.08, .80, -.39), (.32, .66, .32), "lamp", (0,.29,0))
mesh("Base", lamp, (0,.01,0), (.28,.035,.28), black, unit_cylinder)
mesh("Stem", lamp, (0,.28,0), (.025,.53,.025), metal, unit_cylinder)
shade = resource("CylinderMesh", {"top_radius": .11, "bottom_radius": .22, "height": .25, "radial_segments": 8, "rings": 1})
mesh("Shade", lamp, (0,.58,0), (1,1,1), cream, shade)
mesh("Glow", lamp, (0,.455,0), (.34,.008,.34), bulb, unit_cylinder)

node("Lighting", "Node3D")
env = resource("Environment", {"background_mode": 1, "background_color": color((.012,.018,.023)), "ambient_light_source": 3, "ambient_light_color": color((.24,.30,.38)), "ambient_light_energy": .32, "tonemap_mode": 0})
node("WorldEnvironment", "WorldEnvironment", "Lighting", environment=env)
node("DeskLight", "OmniLight3D", "Lighting", position=vec((-1.08,1.22,-.39)), light_color=color((1,.70,.39)), light_energy=2.0, omni_range=3.8, omni_attenuation=1.4, shadow_enabled=True, shadow_bias=.025)
node("WindowLight", "OmniLight3D", "Lighting", position=vec((.84,1.88,-1.23)), light_color=color((.30,.52,.78)), light_energy=.70, omni_range=4.5, shadow_enabled=True)
node("DeskBounce", "OmniLight3D", "Lighting", position=vec((.2,1.62,.75)), light_color=color((.66,.68,.58)), light_energy=.32, omni_range=2.8)

node("Seat", "Node3D", position=vec((0,1.28,1.65)))
node("Camera3D", "Camera3D", "Seat", rotation=vec((-.30,0,0)), current=True, fov=67.0, near=.035, far=30.0)
node("InteractionRay", "RayCast3D", "Seat/Camera3D", target_position=vec((0,0,-3.2)), collision_mask=3, enabled=True)
node("RoomTone", "AudioStreamPlayer", stream='ExtResource("4_room")', autoplay=True, volume_db=-25.0)
node("ClickAudio", "AudioStreamPlayer", stream='ExtResource("6_click")', volume_db=-17.0)

node("Analog", "CanvasLayer", layer=1)
shader_mat = resource("ShaderMaterial", {"shader": 'ExtResource("2_shader")'})
node("Screen", "ColorRect", "Analog", material=shader_mat, anchors_preset=15, anchor_right=1.0, anchor_bottom=1.0, grow_horizontal=2, grow_vertical=2, mouse_filter=2)
node("HUD", "CanvasLayer", layer=2)

def label(name, text, rect, size=12, align=0, tint=(.79,.77,.64), parent="HUD"):
    x,y,w,h = rect
    return node(name, "Label", parent, offset_left=x, offset_top=y, offset_right=x+w, offset_bottom=y+h, mouse_filter=2, text=f'"{text}"', horizontal_alignment=align, **{"theme_override_font_sizes/font_size":size,"theme_override_colors/font_color":color(tint),"theme_override_colors/font_shadow_color":"Color(0, 0, 0, 0.9)","theme_override_constants/shadow_offset_x":1,"theme_override_constants/shadow_offset_y":1})

label("Title", "C A S S E T T E", (20,15,220,24), 19)
label("Subtitle", "BEDROOM STUDY     /     01", (21,40,260,18), 9, tint=(.49,.53,.49))
label("TapeStatus", "SIDE A  /  NO TAPE", (400,20,220,20), 10, 2)
label("Inventory", "IN HAND  /  —", (320,42,300,18), 10, 2, (.49,.53,.49))
label("Reticle", "·", (310,168,20,24), 18, 1)
label("Prompt", "", (30,268,580,22), 13, 1, (.88,.81,.60))
label("Message", "", (20,296,600,21), 12, 1)
label("Controls", "MOUSE  look      E / LMB  interact      ESC  release mouse      R  reset", (20,334,600,16), 10, 1, (.54,.57,.53))
node("PausePanel", "ColorRect", "HUD", visible=False, anchors_preset=15, anchor_right=1.0, anchor_bottom=1.0, color="Color(0.015, 0.02, 0.025, 0.94)", mouse_filter=2)
label("PauseTitle", "C A S S E T T E", (20,124,600,32), 26, 1, parent="HUD/PausePanel")
label("PauseInstructions", "Click or press ESC to return to the desk.\n\nMouse to look  /  E or left click to interact\nR to start again", (20,175,600,100), 13, 1, parent="HUD/PausePanel")

# Deterministic original placeholder sounds, with no downloaded dependencies.
audio_dir = ROOT / "audio/prototype"
audio_dir.mkdir(parents=True, exist_ok=True)
rng = random.Random(60)
rate = 22050
def audio(name, seconds, sample):
    path = audio_dir / f"{name}.wav"
    if path.exists(): raise SystemExit(f"Refusing to overwrite {path}")
    frames = bytearray()
    count = int(seconds * rate)
    for i in range(count):
        t = i / rate
        envelope = min(1.0, t/.025, (seconds-t)/.04)
        amplitude = max(-.95, min(.95, sample(t))) * envelope
        frames.extend(struct.pack("<h", int(amplitude * 32767)))
    with wave.open(str(path), "wb") as out:
        out.setparams((1, 2, rate, 0, "NONE", "not compressed"))
        out.writeframes(frames)

audio("room", 8, lambda t: .24*math.sin(2*math.pi*49*t) + .07*math.sin(2*math.pi*98*t) + rng.uniform(-.018,.018))
audio("tape", 12, lambda t: rng.uniform(-.10,.10) + .12*math.sin(2*math.pi*146.83*t+ .16*math.sin(2*math.pi*.5*t)) + .07*math.sin(2*math.pi*155.56*t) + .055*math.sin(2*math.pi*220*t)*(0.5+0.5*math.sin(2*math.pi*.25*t)))
audio("chirp", .28, lambda t: .24*math.sin(2*math.pi*(880 if t < .12 else 1174)*t)*math.exp(-t*4))
audio("click", .07, lambda t: rng.uniform(-.4,.4)*math.exp(-t*65))

ext = ['[ext_resource type="Script" path="res://scripts/bedroom.gd" id="1_script"]', '[ext_resource type="Shader" path="res://shaders/analog.gdshader" id="2_shader"]']
for ident, sound in (("3_tape","tape"),("4_room","room"),("5_chirp","chirp"),("6_click","click")):
    # External WAVs stay compact in the scene; loop flags are set in _ready.
    ext.append(f'[ext_resource type="AudioStream" path="res://audio/prototype/{sound}.wav" id="{ident}"]')

content = f'[gd_scene load_steps={len(resources)+len(ext)+1} format=3]\n\n' + "\n\n".join(ext+resources+nodes) + "\n"
SCENE.write_text(content, encoding="utf-8")
print(f"Built {len(nodes)} scene nodes, {len(resources)} resources, and 4 original audio clips.")
