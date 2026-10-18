"""Build only the new rebuild scenes; third-party assets are never written.
Scene nodes remain ordinary editable Godot nodes. Run individual named phases.
"""
from pathlib import Path
import sys
import re
ROOT=Path(__file__).resolve().parents[1]

class Scene:
    def __init__(self): self.ext=[]; self.resources=[]; self.nodes=[]
    def external(self, kind, path):
        ident=str(len(self.ext)+1)
        self.ext.append(f'[ext_resource type="{kind}" path="res://{path}" id="{ident}"]')
        return f'ExtResource("{ident}")'
    def resource(self,kind,**props):
        ident=str(len(self.resources)+1)
        self.resources.append(f'[sub_resource type="{kind}" id="{ident}"]\n'+self.props(props))
        return f'SubResource("{ident}")'
    def props(self, props):
        return re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', '\n'.join(f'{k} = {str(v).lower() if isinstance(v,bool) else v}' for k,v in props.items()))
    def node(self,name,kind,parent='.',**props):
        p=f' parent="{parent}"' if parent is not None else ''
        self.nodes.append(f'[node name="{name}" type="{kind}"{p}]\n'+self.props(props))
        return name if parent in (None,'.') else parent+'/'+name
    def instance(self,name,ref,parent='.',**props):
        self.nodes.append(f'[node name="{name}" parent="{parent}" instance={ref}]\n'+self.props(props))
    def mat(self,rgb):
        return self.resource('StandardMaterial3D',albedo_color='Color('+','.join(map(str,(*rgb,1)))+')',roughness=.9)
    def box(self,name,parent,pos,size,material):
        mesh=self.resource('BoxMesh',size=v(size))
        return self.node(name,'MeshInstance3D',parent,position=v(pos),mesh=mesh,material_override=material)
    def save(self,path):
        p=ROOT/path; p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(f'[gd_scene load_steps={1+len(self.ext)+len(self.resources)} format=3]\n\n'+'\n\n'.join(self.ext+self.resources+self.nodes)+'\n',encoding='utf-8')
def v(values): return 'Vector3('+','.join(map(str,values))+')'

def tabletop():
    s=Scene(); camera=s.external('Script','scripts/tabletop_camera.gd')
    game=s.external('Script','scripts/tabletop.gd'); inspect=s.external('Script','scripts/inspect_controller.gd')
    wood=s.mat((.29,.15,.072)); black=s.mat((.012,.016,.018)); door=s.mat((.12,.08,.065))
    s.node('TabletopScene','Node3D',None,script=game)
    s.box('Tabletop','.',(0,-.16,0),(8,.3,6),wood)
    s.box('Floor','.',(0,-1.6,0),(14,.1,14),black)
    s.box('BackWall','.',(0,.3,5.5),(10,4,.15),black)
    pivot=s.node('DoorPivot','Node3D',position=v((-1,.0,5.35)))
    s.box('Door',pivot,(.6,-.1,0),(1.2,2.8,.12),door)
    env=s.resource('Environment',background_mode=1,background_color='Color(.008,.009,.014,1)',ambient_light_source=3,ambient_light_color='Color(.48,.43,.36,1)',ambient_light_energy=.45)
    s.node('Environment','WorldEnvironment',environment=env)
    s.node('TableLight','OmniLight3D',position=v((-.3,3,0)),light_color='Color(1,.73,.44,1)',light_energy=2.2,omni_range=7.0)
    s.node('RimLight','OmniLight3D',position=v((2,2,-2)),light_color='Color(.38,.46,.65,1)',light_energy=.55,omni_range=6.0)
    s.node('TabletopCamera','Camera3D',script=camera,current=True,fov=42.0,near=.03)
    s.node('Objects','Node3D')
    for name,position in [('Cassette',(-2.15,.10,-1.05)),('Pencil',(-2.45,.11,1.45)),('Sketchbook',(2.25,.1,-1.35)),('Tamagotchi',(2.5,.12,1.55))]:
        ref=s.external('PackedScene','scenes/objects/'+name.lower()+'.tscn')
        s.instance(name,ref,'Objects',position=v(position))
    s.node('InspectController','Node',script=inspect,camera_path='NodePath("../TabletopCamera")')
    s.save('scenes/tabletop.tscn')

def objects():
    for name, size in [('Cassette',(.95,.18,.62)),('Pencil',(1.1,.13,.14)),('Sketchbook',(1.0,.16,1.2)),('Tamagotchi',(.62,.18,.75))]:
        s=Scene(); script=s.external('Script','scripts/'+({'Cassette':'cassette','Sketchbook':'sketchbook','Tamagotchi':'tamagotchi'}.get(name,'interactable'))+'.gd')
        black=s.mat((.035,.04,.04)); paper=s.mat((.69,.64,.48)); red=s.mat((.26,.055,.07)); green=s.mat((.30,.40,.21))
        s.node(name,'StaticBody3D',None,script=script,object_id='"'+name.lower()+'"',display_name='"'+name.upper()+'"',collision_layer=2,collision_mask=0,inspect_distance=1.45 if name=='Sketchbook' else 1.2)
        shape=s.resource('BoxShape3D',size=v(size))
        s.node('Collision','CollisionShape3D',shape=shape)
        s.node('Visual','Node3D',rotation=v((0,0,1.5707963)) if name=='Pencil' else v((0,0,0)))
        model=s.node('Model','Node3D','Visual')
        if name=='Cassette':
            audio=s.external('Script','scripts/tape_audio_controller.gd')
            s.node('TapeAudioController','Node',script=audio)
            s.box('Shell',model,(0,0,0),(.95,.12,.62),black)
            s.box('Label',model,(0,.066,-.17),(.84,.01,.17),paper)
            for side,x in [('Left',-.22),('Right',.22)]:
                reel=s.node('Reel'+side,'Node3D','Visual',position=v((x,.085,.035)))
                disk=s.resource('CylinderMesh',top_radius=.13,bottom_radius=.13,height=.015,radial_segments=12)
                s.node('ReelMesh','MeshInstance3D',reel,mesh=disk,material_override=paper)
                s.box('Spoke',reel,(0,.015,0),(.025,.015,.20),black)
            s.node('PencilSocket','Marker3D','Visual/ReelLeft',position=v((0,.02,0)))
        elif name=='Pencil':
            rod=s.resource('CylinderMesh',top_radius=.032,bottom_radius=.032,height=1.0,radial_segments=6)
            s.node('Shaft','MeshInstance3D',model,mesh=rod,material_override=paper)
            s.box('Lead',model,(0,-.53,0),(.025,.08,.025),black)
        elif name=='Sketchbook':
            s.box('Back',model,(0,-.04,0),(1,.06,1.2),red)
            s.box('Pages',model,(0,0,0),(.94,.04,1.14),paper)
            s.node('CoverPivot','Node3D','Visual',position=v((-.5,.04,0)))
            s.box('Cover','Visual/CoverPivot',(.5,0,0),(1,.045,1.2),red)
            s.node('PageSurface','Node3D','Visual',position=v((0,.03,0)))
        else:
            egg=s.resource('SphereMesh',radius=.5,height=1.0,radial_segments=10,rings=6)
            s.node('Shell','MeshInstance3D',model,mesh=egg,material_override=paper,scale=v((.62,.14,.75)))
            s.box('LCD','Visual',(0,.10,-.065),(.41,.02,.35),green)
            s.node('Screen','Label3D','Visual',position=v((0,.116,-.065)),rotation=v((-1.5707963,0,0)),text='"00"',font_size=48,pixel_size=.004,outline_size=0,modulate='Color(.04,.07,.02,1)')
            for i in range(3):
                b=s.node('Button'+str(i),'StaticBody3D','Visual',position=v((-.18+i*.18,.10,.23)),collision_layer=4,collision_mask=0,**{'metadata/button_index':i})
                s.box('Cap',b,(0,0,0),(.10,.045,.10),black)
                shape=s.resource('BoxShape3D',size=v((.13,.07,.13)))
                s.node('Collision','CollisionShape3D',b,shape=shape)
        s.save('scenes/objects/'+name.lower()+'.tscn')

def menu():
    s=Scene(); script=s.external('Script','scripts/main_menu.gd')
    cassette=s.external('PackedScene','scenes/objects/cassette.tscn')
    s.node('MainMenu','Node3D',None,script=script)
    s.instance('Cassette',cassette,scale=v((1.6,1.6,1.6)))
    s.node('Camera3D','Camera3D',position=v((0,1.8,2.4)),current=True,fov=45.0)
    env=s.resource('Environment',background_mode=1,background_color='Color(.006,.007,.011,1)',ambient_light_source=3,ambient_light_energy=.35)
    s.node('Environment','WorldEnvironment',environment=env)
    s.node('Light','OmniLight3D',position=v((-.8,2,1)),light_color='Color(1,.72,.43,1)',light_energy=2.0,omni_range=7.0)
    s.save('scenes/main_menu.tscn')
    s=Scene(); script=s.external('Script','scripts/intro_sequence.gd')
    s.node('IntroSequence','Control',None,script=script)
    s.save('scenes/intro_sequence.tscn')
    s=Scene(); script=s.external('Script','scripts/game_manager.gd')
    s.node('GameManager','Node',None,script=script)
    s.save('scenes/game.tscn')

if __name__=='__main__':
    if sys.argv[1]=='objects': objects()
    if sys.argv[1]=='tabletop': tabletop()
    if sys.argv[1]=='menu': menu()
