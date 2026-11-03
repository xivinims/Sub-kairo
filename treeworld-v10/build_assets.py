"""Deterministic, original geometry for the nine user reference environments.

No downloaded legacy tree models; vertex colors, actual leaf silhouettes,
beveled rock silhouettes and small reusable meshes keep texture memory low.
Outputs one GLB library with named meshes and a geometry report.
"""
from pathlib import Path
import json, math, random, struct, hashlib
import numpy as np

OUT=Path(__file__).parent/'assets'
OUT.mkdir(exist_ok=True)
R=random.Random(20102026)
def v(x,y=0,z=0):return np.array([x,y,z],dtype=float)
def unit(a):
 n=np.linalg.norm(a)
 return a/max(n,1e-8)
def tint(c,s=1):return tuple(max(0,min(1,x*s)) for x in c)
def color(r,g,b):return (r/255,g/255,b/255)
BARK=color(89,72,52)
GREEN=color(106,160,48)
DARK_GREEN=color(55,108,49)

class Mesh:
 def __init__(self,name):self.name=name;self.p=[];self.n=[];self.c=[]
 def tri(self,a,b,c,col):
  a,b,c=np.asarray(a),np.asarray(b),np.asarray(c)
  n=unit(np.cross(b-a,c-a))
  if np.linalg.norm(n)<.5:return
  self.p.extend((a,b,c));self.n.extend((n,n,n));self.c.extend(((*col,1),)*3)
 def quad(self,a,b,c,d,col):self.tri(a,b,c,col);self.tri(a,c,d,col)
 def tube(self,points,radii,col,sides=7,phase=0):
  points=[np.asarray(p) for p in points];rings=[]
  for i,p in enumerate(points):
   d=unit(points[min(i+1,len(points)-1)]-points[max(i-1,0)])
   ref=v(0,0,1) if abs(d[2])<.9 else v(1,0,0)
   right=unit(np.cross(d,ref));forward=unit(np.cross(right,d))
   rings.append([p+radii[i]*(math.cos(j*2*math.pi/sides+phase)*right+math.sin(j*2*math.pi/sides+phase)*forward) for j in range(sides)])
  for i in range(len(rings)-1):
   for j in range(sides):self.quad(rings[i][j],rings[i][(j+1)%sides],rings[i+1][(j+1)%sides],rings[i+1][j],tint(col,.82+.25*(j%3)/2))
  for j in range(1,sides-1):self.tri(rings[-1][0],rings[-1][j],rings[-1][j+1],col)
 def leaf(self,p,d,length,width,col,roll=0):
  p=np.asarray(p);d=unit(d)
  ref=v(0,1,0) if abs(d[1])<.92 else v(0,0,1)
  a=unit(np.cross(d,ref));b=unit(np.cross(a,d))
  a=a*math.cos(roll)+b*math.sin(roll)
  normal=unit(np.cross(d,a))
  base=p-d*length*.4;tip=p+d*length*.6
  ridge=p+normal*width*.18
  left=p+a*width*.5;right=p-a*width*.5
  self.tri(base,left,ridge,tint(col,.88));self.tri(left,tip,ridge,col)
  self.tri(base,ridge,right,col);self.tri(right,ridge,tip,tint(col,1.09))
 def blob(self,center,size,col,sides=9,rings=4,smooth=False):
  center=np.asarray(center);size=np.asarray(size);pts=[]
  for j in range(rings+1):
   lat=math.pi*j/rings;row=[]
   for i in range(sides):
    a=i*math.pi*2/sides
    k=(1+.035*math.sin(a*3+lat*2)) if smooth else R.uniform(.85,1.13)
    row.append(center+size*v(math.sin(lat)*math.cos(a),math.cos(lat),math.sin(lat)*math.sin(a))*k)
   pts.append(row)
  for j in range(rings):
   for i in range(sides):
    before=len(self.p)
    self.quad(pts[j][i],pts[j][(i+1)%sides],pts[j+1][(i+1)%sides],pts[j+1][i],tint(col,R.uniform(.95,1.05) if smooth else R.uniform(.82,1.13)))
    if smooth:
     for q in range(before,len(self.p)):self.n[q]=unit((self.p[q]-center)/np.maximum(size*size,.001))
 def beveled_block(self,center,size,col,bevel=.13):
  center=np.asarray(center);half=np.asarray(size)*.5;b=min(half)*bevel;corners={}
  from itertools import product
  for signs in product([-1,1],repeat=3):
   for axis in range(3):
    q=(half-b)*np.array(signs);q[axis]=half[axis]*signs[axis]
    corners[signs,axis]=center+q
  for axis in range(3):
   other=[j for j in range(3)if j!=axis]
   for side in [-1,1]:
    vs=[]
    for aa,bb in [(-1,-1),(1,-1),(1,1),(-1,1)]:
     signs=[0,0,0];signs[axis]=side;signs[other[0]]=aa;signs[other[1]]=bb
     vs.append(corners[tuple(signs),axis])
    self.quad(*vs,tint(col,.92 if axis==0 else 1))
  for along in range(3):
   a,baxis=[j for j in range(3)if j!=along]
   for sa,sb in product([-1,1],repeat=2):
    low=[0,0,0];low[along]=-1;low[a]=sa;low[baxis]=sb
    hi=low.copy();hi[along]=1;low=tuple(low);hi=tuple(hi)
    self.quad(corners[low,a],corners[hi,a],corners[hi,baxis],corners[low,baxis],tint(col,1.05))
  for signs in product([-1,1],repeat=3):self.tri(corners[signs,0],corners[signs,1],corners[signs,2],tint(col,.9))
 def box(self,lo,hi,col):
  lo=np.asarray(lo);hi=np.asarray(hi)
  p=[np.array([hi[0] if i&1 else lo[0],hi[1] if i&2 else lo[1],hi[2] if i&4 else lo[2]]) for i in range(8)]
  for a,b,c,d in [(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)]:self.quad(p[a],p[b],p[c],p[d],col)
 def stats(self):
  p=np.asarray(self.p);return dict(name=self.name,triangles=len(p)//3,vertices=len(p),min=p.min(0).round(4).tolist(),max=p.max(0).round(4).tolist())

meshes=[]
def add(m):
 assert len(m.p)//3<=9500,(m.name,len(m.p)//3)
 assert np.isfinite(np.asarray(m.p)).all(),m.name
 assert np.asarray(m.c).min()>=0 and np.asarray(m.c).max()<=1,m.name
 meshes.append(m);return m

def trunk(m,height,radius,col=BARK,bend=1.8):
 points=[v(math.sin(i*.75)*bend,height*i/7,math.cos(i*.8)*bend*.4) for i in range(8)]
 radii=[radius*(1-i/8)**1.25+.05 for i in range(8)]
 m.tube(points,radii,col,9)
 for i in range(7):
  a=i*math.pi*2/7
  m.tube([v(math.cos(a)*radius*2.8,.08,math.sin(a)*radius*2.8),v(math.cos(a)*radius*.9,radius*.9,math.sin(a)*radius*.9),points[1]], [.13,radius*.42,radius*.65],col,5)
 return points

def crown(m,center,radii,col,count=90,leafsize=1.4):
 center=np.asarray(center);radii=np.asarray(radii)
 m.blob(center,radii*.72,tint(col,.83),10,4,True)
 for _ in range(count):
  a=R.uniform(0,2*math.pi);u=R.uniform(-.9,.9);q=math.sqrt(1-u*u)
  normal=v(q*math.cos(a),u,q*math.sin(a))
  p=center+normal*radii*R.uniform(.65,1.08)
  d=unit(v(normal[0],R.uniform(-.45,.35),normal[2]))
  m.leaf(p,d,R.uniform(.7,1.4)*leafsize,leafsize*.55,tint(col,R.uniform(.78,1.2)),R.uniform(-1,1))

def deciduous(name,height,col,trunkcol=BARK,slender=False):
 m=Mesh(name);trunk(m,height*.77,height*(.018 if slender else .028),trunkcol,bend=.7 if slender else 1.8)
 n=10 if slender else 11
 for i in range(n):
  a=i*2.4;h=height*(.4+i*.043);r=height*(.16 if slender else .22)*(1-.42*i/n)
  start=v(0,h,0);end=v(math.cos(a)*r,h+height*.11,math.sin(a)*r)
  m.tube([start,start*.45+end*.55+v(0,.7,0),end],[height*.012,.18,.04],trunkcol,5)
  crown(m,end,v(r*.85,height*.1,r*.72),col,52 if slender else 76,1.35 if slender else 1.9)
 if slender:
  for i in range(14):
   y=height*.6*i/14;a=i*2.4;r=height*.018*(1-y/(height*.85))
   m.tube([v(math.cos(a)*r,y,math.sin(a)*r),v(math.cos(a+.7)*r,y+.1,math.sin(a+.7)*r)],[.055,.04],color(49,50,41),3)
 return add(m)

deciduous('MeadowBirch',35,color(151,202,69),color(189,182,149),True)
deciduous('ValleyOak',31,color(121,183,45))
deciduous('ForestBroadleaf',43,color(80,127,53),color(88,78,61))

pine=Mesh('LayeredPine');trunk(pine,51,1.05,color(92,77,56),.5)
for layer in range(9):
 y=14+layer*4.15;r=(9-layer)*1.1+1
 # A recessed foliage core closes the canopy; fine fronds form its silhouette.
 for k in range(12):
  a=k*math.pi/6;b=(k+1)*math.pi/6
  pine.tri(v(0,y+5,0),v(math.cos(a)*r*.81,y-1.9,math.sin(a)*r*.81),v(math.cos(b)*r*.81,y-1.9,math.sin(b)*r*.81),tint(DARK_GREEN,.82+.12*(k%3)))
 for j in range(10):
  a=j*math.pi*2/10+layer*.27
  start=v(0,y,0);tip=v(math.cos(a)*r,y-2.6,math.sin(a)*r)
  pine.tube([start,tip],[.21,.025],BARK,4)
  for k in range(4):
   p=start+(tip-start)*(k+1)/4
   for side in [-1,1]:
    d=unit(v(math.cos(a+side*.5),-.35,math.sin(a+side*.5)))
    pine.leaf(p,d,4.8*(1-layer*.055),2.5,tint(DARK_GREEN,R.uniform(.8,1.15)),.3)
add(pine)

poplar=Mesh('RiverPoplar');trunk(poplar,29,.52,color(101,99,66),.25)
for i in range(5):
 crown(poplar,v(math.sin(i)*.45,12+i*3.5,math.cos(i)*.3),v(3.2-i*.28,5,2.9-i*.25),color(72,129,71),45,1.1)
add(poplar)

willow=Mesh('GreatWillow');trunk(willow,58,5,color(65,84,72),3)
for i in range(12):
 a=i*2.399;r=R.uniform(18,30);start=v(0,34+R.uniform(-6,12),0);end=v(math.cos(a)*r,62+R.uniform(-5,9),math.sin(a)*r)
 willow.tube([start,(start+end)*.5+v(0,6,0),end],[2.2,.9,.15],color(67,84,68),6)
 willow.blob(end,v(13,10,12),color(64,133,89),12,6,True)
 for j in range(34):
  aa=R.uniform(0,2*math.pi);u=R.uniform(-.8,.9);q=math.sqrt(1-u*u)
  pp=end+v(math.cos(aa)*q*13,u*10,math.sin(aa)*q*12)
  willow.leaf(pp,unit(v(math.cos(aa),-.6,math.sin(aa))),4.3,1.65,color(88,157,91),R.uniform(-.5,.5))
 for j in range(5):
  aa=a+j*.55;top=end+v(math.cos(aa)*8,R.uniform(-2,7),math.sin(aa)*8)
  bottom=top+v(math.cos(aa)*3,-R.uniform(14,28),math.sin(aa)*3)
  willow.tube([top,top*.55+bottom*.45+v(2,0,0),bottom],[.14,.06,.015],color(71,102,58),3)
  for k in range(12):
   p=top+(bottom-top)*k/12
   willow.leaf(p+v(math.sin(k)*.6,0,math.cos(k)*.6),unit(v(math.sin(k)*.4,-1,math.cos(k)*.4)),3.7,1.1,color(91+R.randrange(30),159+R.randrange(22),78),R.uniform(-1,1))
add(willow)

blue=Mesh('BlueForestCedar');trunk(blue,66,1.6,color(52,79,93),.7)
for i in range(10):
 a=i*2.4;end=v(math.cos(a)*7,46+i*1.6,math.sin(a)*7)
 blue.tube([v(0,42+i*1.8,0),end],[.6,.08],color(40,65,79),5)
 crown(blue,end,v(5,4,5),color(35,92,90),26,1.2)
for i in range(5):
 a=i*1.24;pts=[]
 for j in range(13):
  t=j/12;rr=4.5+math.sin(t*math.pi)*1.5
  pts.append(v(math.cos(a+t*1.5)*rr,53-29*t,math.sin(a+t*1.5)*rr))
 blue.tube(pts,[.12]*13,color(37,67,76),4)
add(blue)

sakura=Mesh('SunsetSakura');trunk(sakura,24,1.3,color(135,94,64),2.5)
for i in range(9):
 a=i*2.399;r=R.uniform(6,12);end=v(math.cos(a)*r,24+R.uniform(-2,7),math.sin(a)*r)
 sakura.tube([v(0,13+i*.7,0),end*.6+v(0,7,0),end],[.65,.26,.06],color(133,89,62),6)
 sakura.blob(end,v(7,6,7),color(215,143,153),14,7,True)
 for j in range(28):
  aa=R.uniform(0,math.pi*2);u=R.uniform(-1,1);q=math.sqrt(1-u*u)
  p=end+v(math.cos(aa)*q,u,math.sin(aa)*q)*R.uniform(4.8,7.4)
  for k in range(5):
   a2=k*math.pi*2/5
   sakura.leaf(p+v(math.cos(a2)*.45,0,math.sin(a2)*.45),v(math.cos(a2),.15,math.sin(a2)),1.7,.9,color(230+R.randrange(20),165+R.randrange(25),177+R.randrange(20)))
add(sakura)

orange=Mesh('SparseOrangeMaple');trunk(orange,20,.5,color(63,60,53),2.4)
for i in range(7):
 a=i*2.4;end=v(math.cos(a)*7,10+i*1.8,math.sin(a)*7)
 orange.tube([v(0,7+i,0),end],[.22,.02],color(63,60,53),4)
 for j in range(22):
  p=end+v(R.uniform(-2.5,2.5),R.uniform(-1.5,2),R.uniform(-2.5,2.5))
  orange.leaf(p,v(R.uniform(-1,1),.2,R.uniform(-1,1)),.9,.75,color(190+R.randrange(45),62+R.randrange(40),33))
add(orange)

palm=Mesh('CanalPalm');trunk(palm,37,.75,color(90,103,88),1.4)
for i in range(9):
 a=i*math.pi*2/9;points=[]
 for j in range(7):
  t=j/6;points.append(v(math.cos(a)*16*t,37+6*math.sin(t*math.pi)-7*t*t,math.sin(a)*16*t))
 for j in range(6):
  right=v(-math.sin(a),0,math.cos(a))*(2.8*(1-j/7))
  palm.quad(points[j]-right,points[j]+right,points[j+1]+right*.75,points[j+1]-right*.75,color(65,117,83))
add(palm)

block=Mesh('CanalBlockTree');trunk(block,29,1.7,color(55,72,67),.9)
for side in [-1,1]:block.tube([v(0,17,0),v(side*5,26,0),v(side*6,32,0)],[1.2,.9,.5],color(51,73,66),4)
for lo,hi in [((-12,25,-7),(4,32,7)),((-3,32,-8),(14,40,7)),((-8,37,-6),(8,44,6)),((-13,30,4),(0,36,14))]:block.box(lo,hi,color(73,118,88))
for i in range(11):
 x,z=R.uniform(-10,10),R.uniform(-5,10);y=R.uniform(25,31)
 block.tube([v(x,y,z),v(x+.2,y-R.uniform(8,20),z)],[.08,.06],color(56,98,77),3)
add(block)

def blade(m,x,z,h,a,w,col):
 d=v(math.cos(a),0,math.sin(a));right=v(-math.sin(a),0,math.cos(a))
 p=v(x,0,z);mid=p+d*h*.17+v(0,h*.55,0);tip=p+d*h*.48+v(0,h,0)
 m.quad(p-right*w,p+right*w,mid+right*w*.65,mid-right*w*.65,tint(col,.76))
 m.tri(mid-right*w*.65,mid+right*w*.65,tip,col)
for name,count,height in [('GrassPatch',105,1.35),('TallGrassPatch',100,2.2)]:
 m=Mesh(name)
 for i in range(count):
  x,z=R.uniform(-8,8),R.uniform(-8,8);a=R.uniform(0,math.pi*2)
  for j in range(3):blade(m,x,z,height*R.uniform(.58,1.18),a+j*2.1,R.uniform(.07,.16),tint((1,1,1),R.uniform(.83,1)))
 add(m)

fern=Mesh('FernRosette')
for i in range(12):
 a=i*math.pi*2/12;d=v(math.cos(a),0,math.sin(a));right=v(-math.sin(a),0,math.cos(a));points=[]
 for j in range(8):
  t=j/7;points.append(d*(t*2.6)+v(0,math.sin(t*math.pi*.8)*1.8+.1,0))
 fern.tube(points,[.045]*8,color(83,121,45),3)
 for j in range(1,7):
  for side in [-1,1]:fern.leaf(points[j]+right*side*.16,unit(right*side+d*.3),.9*(1-j*.09),.22,color(89+R.randrange(30),147+R.randrange(25),45),.2)
add(fern)
reeds=Mesh('ShoreReeds')
for i in range(25):blade(reeds,R.uniform(-2,2),R.uniform(-1.8,1.8),R.uniform(2.1,4.1),R.uniform(0,math.pi*2),R.uniform(.12,.24),color(118,160,57))
add(reeds)

def flowers(name,petalcolor):
 m=Mesh(name)
 for i in range(20):
  x,z=R.uniform(-7,7),R.uniform(-7,7);h=R.uniform(.65,1.6)
  m.tube([v(x,0,z),v(x+.1,h,z)],[.025,.015],color(78,123,48),3)
  for s in [-1,1]:m.leaf(v(x+s*.2,h*.4,z),v(s,.2,.3),.6,.2,color(97,147,57))
  center=v(x+.1,h,z)
  for k in range(5):
   a=k*2*math.pi/5;d=v(math.cos(a),.05,math.sin(a));p=center+d*.18
   m.leaf(p,d,.46,.24,petalcolor)
  m.blob(center+v(0,.025,0),v(.1,.07,.1),color(221,184,61),5,2)
 return add(m)
flowers('WhiteFlowerPatch',color(243,242,218))
flowers('LavenderFlowerPatch',color(195,166,207))

clover=Mesh('CloverPatch')
for i in range(33):
 x,z=R.uniform(-3,3),R.uniform(-3,3);h=R.uniform(.12,.4)
 for k in range(3):
  a=k*2*math.pi/3;d=v(math.cos(a),.1,math.sin(a));clover.leaf(v(x,h,z)+d*.2,d,.65,.5,color(119+R.randrange(40),163,49))
add(clover)
shrub=Mesh('AutumnUnderstory')
for i in range(9):
 a=i*2.399;end=v(math.cos(a)*1.7,R.uniform(1.1,2.4),math.sin(a)*1.7)
 shrub.tube([v(0,0,0),end],[.04,.01],color(112,83,47),3)
 for j in range(6):
  t=(j+1)/6;p=end*t;d=v(math.cos(a+j),.2,math.sin(a+j))
  shrub.leaf(p,d,1.1,.8,color(226+R.randrange(25),158+R.randrange(50),48))
add(shrub)

rock=Mesh('WeatheredRock')
rock.blob(v(0,2.3,0),v(3.8,3.1,3.3),color(171,171,164),8,3)
add(rock)
cliff=Mesh('LayeredSandstone')
for row in range(3):
 for col in range(4):
  center=v((col-1.5)*4.4+R.uniform(-.7,.7),3+row*4.7, R.uniform(-1.4,1.4))
  cliff.beveled_block(center,v(R.uniform(4.3,5.1),R.uniform(4.8,5.7),R.uniform(7.6,10.6)),color(180+R.randrange(20),153+R.randrange(20),111+R.randrange(20)),.22)
add(cliff)
tile=Mesh('ChippedStoneTile')
bottom=[];top=[]
for i in range(8):
 a=i*math.pi/4;rr=1 if i%2==0 else 1.15
 x,z=math.cos(a)*3.5*rr,math.sin(a)*2.3*rr
 bottom.append(v(x,0,z));top.append(v(x*.98,.2+R.uniform(-.02,.02),z*.98))
for i in range(8):
 tile.quad(bottom[i],bottom[(i+1)%8],top[(i+1)%8],top[i],color(111,116,111))
 tile.tri(v(0,.22,0),top[i],top[(i+1)%8],color(146+R.randrange(18),151+R.randrange(18),143+R.randrange(18)))
add(tile)
wood=Mesh('FallenBranch')
wood.tube([v(-5,.5,0),v(0,1,.4),v(5,.6,-.2)],[.8,.65,.44],color(101,87,67),9)
for i in range(4):
 x=-3+i*2;wood.tube([v(x,.8,0),v(x+1,1.5,2.5)],[.25,.04],color(93,81,65),5)
add(wood)

# GLB uses a single double-sided, rough material; vertex colors keep the
# original palettes without repeated 2K/4K textures across hundreds of trees.
data=bytearray();views=[];accessors=[];gmeshes=[];nodes=[]
def accessor(a,kind,component=5126):
 while len(data)%4:data.append(0)
 a=np.asarray(a,dtype='<f4' if component==5126 else '<u4')
 offset=len(data);data.extend(a.tobytes());idx=len(views)
 views.append(dict(buffer=0,byteOffset=offset,byteLength=a.nbytes))
 acc=dict(bufferView=idx,componentType=component,count=len(a),type=kind)
 if kind=='VEC3':acc.update(min=a.min(0).tolist(),max=a.max(0).tolist())
 accessors.append(acc);return len(accessors)-1
for i,m in enumerate(meshes):
 pa=accessor(m.p,'VEC3');na=accessor(m.n,'VEC3');ca=accessor(m.c,'VEC4')
 ia=accessor(np.arange(len(m.p)),'SCALAR',5125)
 gmeshes.append(dict(name=m.name,primitives=[dict(attributes={'POSITION':pa,'NORMAL':na,'COLOR_0':ca},indices=ia,material=0)]))
 nodes.append(dict(name=m.name,mesh=i,translation=[(i%6)*160,0,(i//6)*160]))
doc=dict(asset=dict(version='2.0',generator='Overyard original reference geometry v10'),scene=0,scenes=[dict(nodes=list(range(len(nodes))))],nodes=nodes,meshes=gmeshes,
 materials=[dict(name='VertexPalette',doubleSided=True,pbrMetallicRoughness=dict(baseColorFactor=[1,1,1,1],metallicFactor=0,roughnessFactor=1))],
 buffers=[dict(byteLength=len(data))],bufferViews=views,accessors=accessors)
js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*((-len(js))%4);data+=b'\x00'*((-len(data))%4)
blob=struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(data))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(data),0x004e4942)+data
(OUT/'photo-vegetation.glb').write_bytes(blob)
report=dict(models=[m.stats() for m in meshes],bytes=len(blob),sha256=hashlib.sha256(blob).hexdigest())
(OUT/'geometry-report.json').write_text(json.dumps(report,indent=2))
np.savez_compressed(OUT/'preview-geometry.npz',**{m.name+'_p':np.asarray(m.p) for m in meshes},**{m.name+'_c':np.asarray(m.c) for m in meshes})
print(json.dumps(report))
