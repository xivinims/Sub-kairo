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
doc=dict(asset=dict(version='2.0',generator='Overyard original reference geometry v12'),scene=0,scenes=[dict(nodes=list(range(len(nodes))))],nodes=nodes,meshes=gmeshes,
 materials=[dict(name='VertexPalette',doubleSided=True,pbrMetallicRoughness=dict(baseColorFactor=[1,1,1,1],metallicFactor=0,roughnessFactor=1))],
 buffers=[dict(byteLength=len(data))],bufferViews=views,accessors=accessors)
js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*((-len(js))%4);data+=b'\x00'*((-len(data))%4)
blob=struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(data))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(data),0x004e4942)+data
(OUT/'photo-vegetation.glb').write_bytes(blob)
report=dict(models=[m.stats() for m in meshes],bytes=len(blob),sha256=hashlib.sha256(blob).hexdigest())
(OUT/'geometry-report.json').write_text(json.dumps(report,indent=2))
np.savez_compressed(OUT/'preview-geometry.npz',**{m.name+'_p':np.asarray(m.p) for m in meshes},**{m.name+'_c':np.asarray(m.c) for m in meshes},**{m.name+'_n':np.asarray(m.n) for m in meshes})
print(json.dumps({'bytes':len(blob),'models':len(meshes),'triangles':sum(len(m.p)//3 for m in meshes)}))
