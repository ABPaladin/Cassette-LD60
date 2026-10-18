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
    wood=s.mat((.29,.15,.072)); black=s.mat((.012,.016,.018)); door=s.mat((.12,.08,.065))
    s.node('TabletopScene','Node3D',None)
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
    s.save('scenes/tabletop.tscn')

if __name__=='__main__':
    if sys.argv[1]=='tabletop': tabletop()
