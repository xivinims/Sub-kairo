"""Convert FBX rotation channels into native Roblox bone KeyframeSequences.
Root motion/translation is deliberately excluded; this preserves the imported rig's bind positions.
"""
import sys,json,math
from pathlib import Path
import numpy as np
from xml.etree.ElementTree import Element,SubElement,ElementTree
from read_fbx import read_fbx,child,properties
source=Path(sys.argv[1]); native=json.loads(Path(sys.argv[2]).read_text()); out=Path(sys.argv[3]);out.mkdir(parents=True,exist_ok=True)
nodes=read_fbx(source); items=next(n for n in nodes if n['name']=='Objects')['children']; objs={o['props'][0]:o for o in items}
models={i:o for i,o in objs.items() if o['name']=='Model'}; names={o['props'][1].split('\0')[0]:i for i,o in models.items()};props={i:properties(o) for i,o in models.items()}
connections=[n['props'] for n in next(n for n in nodes if n['name']=='Connections')['children']]
parents={c[1]:c[2] for c in connections if c[0]=='OO' and c[1] in models and c[2] in models}
channels={};layers={};stacks={}
for c in connections:
 if c[0]=='OP' and c[1] in objs and objs[c[1]]['name']=='AnimationCurve' and c[2] in objs:
  curve=objs[c[1]];times=np.array(child(curve,'KeyTime')['props'][0],dtype=float)/46186158000.;values=np.array(child(curve,'KeyValueFloat')['props'][0],dtype=float)
  channels.setdefault(c[2],{})[c[3][-1]]=(times,values)
 if c[0]=='OO' and c[1] in objs and c[2] in objs:
  if objs[c[1]]['name']=='AnimationLayer':stacks.setdefault(c[2],[]).append(c[1])
  if objs[c[1]]['name']=='AnimationCurveNode':layers.setdefault(c[2],[]).append(c[1])
targets={c[1]:(c[2],c[3]) for c in connections if c[0]=='OP' and c[1] in objs and objs[c[1]]['name']=='AnimationCurveNode' and c[2] in models}
def rotate(v):
 x,y,z=np.radians(v);cx,sx=math.cos(x),math.sin(x);cy,sy=math.cos(y),math.sin(y);cz,sz=math.cos(z),math.sin(z)
 return np.array([[cz,-sz,0],[sz,cz,0],[0,0,1.]])@np.array([[cy,0,sy],[0,1.,0],[-sy,0,cy]])@np.array([[1.,0,0],[0,cx,-sx],[0,sx,cx]])
S=np.diag([-1.,1.,-1.]);bones={b['name']:b for b in native['bones']};children={}
for b in native['bones']:children.setdefault(b['parent'],[]).append(b['name'])
def item(parent,cls,name):
 e=SubElement(parent,'Item',{'class':cls});p=SubElement(e,'Properties');SubElement(p,'string',{'name':'Name'}).text=name;return e,p
report=[]
for sid,stack in [(i,o) for i,o in objs.items() if o['name']=='AnimationStack']:
 label=stack['props'][1].split('\0')[0].split('|')[-1];duration=properties(stack).get('LocalStop',[46186158000])[0]/46186158000
 active={}
 for lid in stacks.get(sid,[]):
  for nid in layers.get(lid,[]):
   if nid in targets and targets[nid][1]=='Lcl Rotation':active[targets[nid][0]]=channels.get(nid,{})
 root=Element('roblox',{'version':'4'});sequence,ps=item(root,'KeyframeSequence',label)
 SubElement(ps,'bool',{'name':'Loop'}).text='true' if label in ['walk','ref'] else 'false'
 SubElement(ps,'token',{'name':'Priority'}).text='2' if label=='walk' else '4'
 frames=max(2,math.ceil(duration*24)+1)
 for frame,time in enumerate(np.linspace(0,duration,frames)):
  globals={}
  def global_rotation(oid):
   if oid in globals:return globals[oid]
   v=list(props[oid].get('Lcl Rotation',[0.,0.,0.]))
   for axis,(ts,vs) in active.get(oid,{}).items():v['XYZ'.index(axis)]=float(np.interp(time,ts,vs))
   r=rotate(props[oid].get('PreRotation',[0,0,0]))@rotate(v)@rotate(props[oid].get('PostRotation',[0,0,0])).T
   globals[oid]=global_rotation(parents[oid])@r if oid in parents else r
   return globals[oid]
  key,kp=item(sequence,'Keyframe',str(frame));SubElement(kp,'float',{'name':'Time'}).text=f'{time:.7f}'
  def pose(parent,name):
   po,pp=item(parent,'Pose',name);SubElement(pp,'float',{'name':'Weight'}).text='1'
   matrix=np.eye(3)
   if name in bones and name!='Root':
    bone=bones[name];oid=names.get(name);par=names.get(bone['parent'])
    if oid is not None and par is not None:
     r=S@(global_rotation(par).T@global_rotation(oid))@S
     rest=np.array(bone['cf'][3:]).reshape(3,3)
     matrix=rest.T@r
   cf=SubElement(pp,'CoordinateFrame',{'name':'CFrame'})
   for tag in ['X','Y','Z']:SubElement(cf,tag).text='0'
   for row in range(3):
    for col in range(3):SubElement(cf,f'R{row}{col}').text=f'{matrix[row,col]:.7f}'
   for sub in children.get(name,[]):pose(po,sub)
  pose(key,'RootPart')
 path=out/(label+'.rbxmx');ElementTree(root).write(path,encoding='utf-8',xml_declaration=True)
 report.append({'name':label,'duration':duration,'frames':frames,'file':path.name,'bytes':path.stat().st_size,'bones':len(bones),'rootMotion':False,'translations':False})
(out/'animation-manifest.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
