import json, math
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
root=Path(__file__).parent
j=json.loads((root/'layout-audit.json').read_text())
fig,ax=plt.subplots(figsize=(11,11),facecolor='#171e23');ax.set_facecolor('#202b30')
cells=j['cells']
ax.scatter([p[0] for p in cells],[p[2] for p in cells],s=8,c='#71816b',alpha=.6,marker='s',label='Piso livre amostrado')
parts=j.get('geometry',[])
if not parts:parts=[[p['n'],p['p'],p['s'],p['r'],p['c'],p['t'],p['collide']] for p in j.get('bays',[])]
for name,pos,size,rot,color,trans,col in parts:
 if trans>.9 or size[1]<2 or pos[1]>70:continue
 if name=='Bush' or name=='Leaves' or 'trees' in name:continue
 if size[0]*size[2]>90000:continue
 angle=-rot[1];co,si=math.cos(angle),math.sin(angle)
 pts=[]
 for a,b in [(-.5,-.5),(.5,-.5),(.5,.5),(-.5,.5)]:
  x,z=a*size[0],b*size[2];pts.append((pos[0]+x*co-z*si,pos[2]+x*si+z*co))
 ax.add_patch(Polygon(pts,facecolor=color,edgecolor='#273038',linewidth=.25,alpha=.75))
verification=root/'map-focus-verification.json'
if verification.exists():
 v=json.loads(verification.read_text())['verified']
 labels={'RECEPTION':'Recepção','WORKSHOP':'Oficina','POWER':'Subestação','STORAGE':'Depósito','OBSERVATION':'Observação'}
 for hub in v['hubs']:
  x,y,z=hub['centre'];ex,ey,ez=hub['entry']
  ax.scatter([x],[z],s=100,marker='s',c='#e1af67',edgecolors='#19212a',zorder=10)
  ax.plot([x,ex],[z,ez],color='#e1af67',linewidth=2,zorder=10)
  ax.annotate(labels[hub['id']],(x,z),xytext=(8,-16),textcoords='offset points',color='#fff2d9',fontsize=10,zorder=11,bbox=dict(facecolor='#17242a',edgecolor='none',alpha=.85,pad=3))
ax.set_xlim(-600,600);ax.set_ylim(550,-650);ax.set_aspect('equal');ax.tick_params(colors='#cdd2cd');ax.grid(alpha=.12)
ax.set_xlabel('X · studs',color='#cdd2cd');ax.set_ylabel('Z · studs',color='#cdd2cd')
ax.set_title('DEAD SIGNAL · planta técnica do asset 18509954401\nVolumes aproximados; não é uma captura do Roblox',color='white',pad=18)
fig.tight_layout();fig.savefig(root/'map-layout.png',dpi=150)
