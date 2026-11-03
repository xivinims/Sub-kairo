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
    self.quad(pts[j][i],pts[j][(i+1)%sides],pts[j+1][(i+1)%sides],pts[j+1][i],tint(col,1 if smooth else R.uniform(.82,1.13)))
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

