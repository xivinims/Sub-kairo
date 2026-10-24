"""Original split-root / canopy meshes. Leaf silhouettes and wing veins are geometry.

All tree roots share a known ground origin; imported bounding-box centers are
recorded explicitly, so low-hanging foliage cannot lift a trunk off its island.
"""
from geometry import *
meshes=[]
def add(m):
 assert 0<len(m.p)//3<=9500,(m.name,len(m.p)//3)
 assert np.isfinite(np.asarray(m.p)).all()
 meshes.append(m);return m

def tree(name,height,width,col,habit='round',bark=color(102,87,67)):
 wood=Mesh(name+'Bark');leaves=Mesh(name+'Leaves')
 radius=height*(.026 if habit!='willow' else .04)
 bend=height*(.048 if habit in ('orange','oak')else .025)
 def center(t):return v(math.sin(t*3.8)*bend,t*height,math.sin(t*5.2)*bend*.6)
 # The central base is embedded 0.35 studs, not seated by the canopy bounding box.
 path=[center(i*.67/10)for i in range(11)];path[0]=v(0,-.35,0)
 wood.tube(path,[radius*(1-i/13)**1.1+.06 for i in range(11)],bark,12)
 # Root flares, bark ridges and subtle spirals remain fixed in wind.
 for j in range(9):
  a=j*math.tau/9;d=v(math.cos(a),0,math.sin(a))
  wood.tube([d*radius*3.4-v(0,.32,0),d*radius*1.3+v(0,.5,0),center(.13)],[.11,radius*.38,radius*.6],tint(bark,.87+j*.018),6)
 for j in range(8):
  a=j*math.tau/8;ridge=[]
  for i in range(8):
   t=i*.51/7;r=radius*(1-t/.87);ridge.append(center(t)+v(math.cos(a+t*2)*r,0,math.sin(a+t*2)*r))
  wood.tube(ridge,[.085*(1-i/10)for i in range(8)],tint(bark,.72 if j%2 else 1.12),3)
 for i in range(18):
  a=i*2.399; t=.32+i*.025
  start=center(t);spread=width*(.34+.12*math.sin(i*1.6))*(1-.25*i/18)
  end=start+v(math.cos(a)*spread,height*(.15+.035*math.sin(i)),math.sin(a)*spread)
  if habit=='orange':end+=v(spread*.24,-height*.04,0)
  if habit=='column':end=start+v(math.cos(a)*width*.27,height*.16,math.sin(a)*width*.27)
  middle=start*.52+end*.48+v(0,height*.035,0)
  wood.tube([start,middle,end],[radius*.46,.22,.045],tint(bark,.88+i%3*.08),6)
  for twig in range(3):
   b=a+(twig-1)*.8;tip=end+v(math.cos(b)*width*.10,height*.05,math.sin(b)*width*.10)
   wood.tube([middle*.25+end*.75,tip],[.09,.018],tint(bark,.83),4)
  # 100 separate leaves per branch, no opaque polygon/ball inside the crown.
  for j in range(100):
   u=R.uniform(-1,1);b=R.uniform(0,math.tau);r=R.random()**.32
   q=v(math.cos(b)*math.sqrt(1-u*u),u,math.sin(b)*math.sqrt(1-u*u))
   radii=v(width*.19,height*.105,width*.18)
   if habit=='column':radii=v(width*.18,height*.15,width*.18)
   p=end+q*r*radii
   if habit in ('willow','pink','white','column'):
    drop=(j%10)/9*height*(.22 if habit in ('willow','column')else .10)
    p+=v(math.cos(a)*drop*.12,-drop,math.sin(a)*drop*.12)
    direction=unit(v(math.cos(b)*.28,-1,math.sin(b)*.28))
   else:direction=unit(v(math.cos(b),R.uniform(-.6,.4),math.sin(b)))
   length=height*R.uniform(.048,.072)
   if habit=='willow':length*=1.2
   leafwidth=length*(.24 if habit in ('willow','column')else .64)
   leaves.leaf(p,direction,length,leafwidth,tint(col,R.uniform(.72,1.20)),R.uniform(-1,1))
 add(wood);add(leaves)

tree('PearlBlossom',29,31,color(221,237,238),'white',color(109,107,94))
tree('RoseBlossom',38,32,color(232,157,180),'pink',color(126,113,103))
tree('EmeraldWillow',37,19,color(31,156,98),'column',color(100,107,83))
tree('AncientOak',44,39,color(91,151,53),'oak',color(101,86,60))
tree('AmberMaple',27,36,color(229,133,34),'orange',color(106,91,52))
tree('CliffCrimson',47,42,color(168,67,55),'round',color(127,112,94))
tree('LakeWillow',64,62,color(83,155,107),'willow',color(105,99,73))
wood=Mesh('HighPineBark');needles=Mesh('HighPineLeaves')
wood.tube([v(0,-.35,0),v(.4,13,0),v(-.2,30,.4),v(0,51,0)],[1.35,.86,.48,.05],color(103,81,62),11)
for i in range(32):
 a=i*2.399;y=12+i*1.12;r=(51-y)*.27;tip=v(math.cos(a)*r,y-.8,math.sin(a)*r)
 wood.tube([v(0,y,0),tip],[.22,.035],BARK,5)
 for k in range(45):
  t=R.uniform(.25,1);p=tip*t+v(0,y*(1-t),0)+v(R.uniform(-1,1)*r*.28,R.uniform(-1,1)*1.6,R.uniform(-1,1)*r*.28)
  needles.leaf(p,unit(v(math.cos(a),.25,math.sin(a))),R.uniform(1.2,2.4),R.uniform(.35,.85),tint(color(58,118,69),R.uniform(.72,1.25)),R.random()*2)
add(wood);add(needles)

for name,col in [('FallingLeaf',color(141,173,65)),('FallingPetal',color(239,182,197))]:
 m=Mesh(name);m.leaf(v(0,.04,0),v(0,.08,1),.65,.3,col)
 m.tube([v(0,.055,-.3),v(0,.09,.3)],[.012,.004],tint(col,.65),3);add(m)
cone=Mesh('PineCone');cone.blob(v(0,.37,0),v(.22,.38,.22),color(87,55,30),9,5,True)
for i in range(7):
 for j in range(8):
  a=j*math.tau/8+i*.4;r=.23*math.sin((i+1)/8*math.pi)
  cone.leaf(v(math.cos(a)*r,.06+i*.1,math.sin(a)*r),v(math.cos(a)*.6,.9,math.sin(a)*.6),.21,.16,color(139+i%2*24,95+i%2*14,51))
add(cone)
for name,col in [('Apple',color(192,48,37)),('Orange',color(243,143,31))]:
 m=Mesh(name);m.blob(v(0,.45,0),v(.44,.43,.43),col,16,9,True)
 m.tube([v(0,.78,0),v(.04,1.02,.015)],[.045,.022],BARK,5)
 m.leaf(v(.16,.91,.02),v(1,.2,.2),.42,.2,color(70,121,43));add(m)

def wing(name,main):
 m=Mesh(name)
 # Two hand-shaped lobes, black border, cream spots, branching vein network.
 for center,outline in [((.48,-.36),[(.07,0),(.26,-.38),(.52,-.94),(.94,-1.22),(1.31,-1.14),(1.44,-.84),(1.35,-.5),(.98,-.25),(.45,.06)]),((.45,.37),[(.07,0),(.42,.03),(.92,.2),(1.08,.47),(.95,.82),(.58,.91),(.27,.64),(.09,.30)])]:
  c=v(center[0],0,center[1]);points=[v(x,0,z)for x,z in outline]
  for i,p in enumerate(points):
   q=points[(i+1)%len(points)];a=c+(p-c)*.87;b=c+(q-c)*.87
   m.tri(c,a,b,tint(main,.78+(i%3)*.12));m.quad(a,p,q,b,color(32,31,38))
   delta=p-c;m.tube([v(.07,.012,0),c*.6+p*.4+v(0,.012,0),p*.86+c*.14+v(0,.012,0)],[.013,.010,.005],color(39,35,40),3)
   if i>1:
    spot=c+(p-c)*.93;m.blob(spot+v(0,.016,0),v(.035,.008,.045),color(244,226,181),5,2)
 add(m)
wing('ButterflyAmberWing',color(221,137,35));wing('ButterflyBlueWing',color(55,153,203))
body=Mesh('ButterflyBody');body.blob(v(0,0,0),v(.065,.06,.4),color(40,32,31),7,5,True)
for s in [-1,1]:body.tube([v(0,0,-.3),v(s*.06,.08,-.48),v(s*.16,.09,-.59)],[.013,.009,.005],color(38,31,28),4)
add(body)
ring=Mesh('WaterRipple')
for i in range(64):
 a=i*math.tau/64;b=(i+1)*math.tau/64
 ring.quad(v(math.cos(a),0,math.sin(a)),v(math.cos(b),0,math.sin(b)),v(math.cos(b)*.955,.012,math.sin(b)*.955),v(math.cos(a)*.955,.012,math.sin(a)*.955),color(182,222,223))
add(ring)
star=Mesh('DizzyStar')
points=[v(math.cos(i*math.pi/5)*(.32 if i%2==0 else .14),math.sin(i*math.pi/5)*(.32 if i%2==0 else .14),0)for i in range(10)]
for i in range(10):star.tri(v(0,0,.06),points[i],points[(i+1)%10],color(255,221,74));star.tri(v(0,0,-.06),points[(i+1)%10],points[i],color(233,179,35))
add(star)
exec(Path(__file__).with_name('export_geometry.py').read_text())
# MeshPart import uses each bounding-box center. Store all three axes, not only Y.
meta={m.name:dict(center=((np.min(m.p,0)+np.max(m.p,0))/2).tolist(),size=(np.max(m.p,0)-np.min(m.p,0)).tolist())for m in meshes}
lines=['return {']
for name,r in meta.items():lines.append('[%r]={center=Vector3.new(%s),size=Vector3.new(%s)},'%(name,','.join('%.6f'%n for n in r['center']),','.join('%.6f'%max(n,.012)for n in r['size'])))
lines.append('}');Path(__file__).with_name('mesh-meta.luau').write_text('\n'.join(lines)+'\n')
