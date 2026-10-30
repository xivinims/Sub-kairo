"""Embed the starter kit's own texture files into its glTF materials before import."""
import json,struct,urllib.request,pathlib
ROOT='https://raw.githubusercontent.com/DetectivePikaC2/PlaytimeStarterKit/8c453e7731866e34a0986e3f2c12e64dd9f8c703/'
OUT=pathlib.Path('dist/source-models');OUT.mkdir(parents=True,exist_ok=True)
def fetch(path):
 with urllib.request.urlopen(ROOT+path,timeout=60) as r:return r.read()
def build(path,name,material_textures):
 raw=fetch(path);assert raw[:4]==b'glTF';n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);offset=20+n;binary=bytearray()
 while offset<len(raw):
  length,kind=struct.unpack_from('<II',raw,offset);offset+=8
  if kind==0x004e4942:binary=bytearray(raw[offset:offset+length])
  offset+=length
 cache={}
 def image(path):
  if path in cache:return cache[path]
  data=fetch(path)
  while len(binary)%4:binary.append(0)
  view=len(doc.setdefault('bufferViews',[]));doc['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':len(data)});binary.extend(data)
  idx=len(doc.setdefault('images',[]));doc['images'].append({'bufferView':view,'mimeType':'image/png'})
  tex=len(doc.setdefault('textures',[]));doc['textures'].append({'source':idx});cache[path]=tex;return tex
 for material in doc.get('materials',[]):
  key=material.get('name','').split('.')[0];texture=material_textures.get(key) or material_textures.get('*')
  if texture:
   pbr=material.setdefault('pbrMetallicRoughness',{});pbr['baseColorTexture']={'index':image(texture)};pbr['baseColorFactor']=[1,1,1,1]
   material['normalTexture']={'index':image(texture.replace('_BC.png','_N.png'))}
 doc['buffers'][0]['byteLength']=len(binary)
 data=json.dumps(doc,separators=(',',':')).encode();data+=b' '*((-len(data))%4);binary+=b'\0'*((-len(binary))%4)
 result=struct.pack('<III',0x46546c67,2,12+8+len(data)+8+len(binary))+struct.pack('<II',len(data),0x4e4f534a)+data+struct.pack('<II',len(binary),0x004e4942)+binary
 assert len(result)<20*1024*1024;(OUT/(name+'.glb')).write_bytes(result);print(name,len(result),'bytes',len(cache),'source textures')
scan='Objects/Gameplay/Puzzles/Scanners/Models/'
build(scan+'scanners.glb','ScannerTextured',{'MI_HandScanner':scan+'T_HandScanner_BC.png'})
panel='Objects/Gameplay/ControlPanel/Mesh/'
build(panel+'ConsolesPack.glb','PanelsTextured',{
 'MI_ConsolsKeyPad_B_Redesign':panel+'T_ConsolsKeyPad_B_redesign_BC.png',
 'MI_T_ConsolsKeypad_C':panel+'T_ConsolsKeypad_C_BC.png',
 'MI_ConsolsBase_A':panel+'T_ConsolesBase_A_BC.png',
 'MI_ConsolsBase_B':panel+'T_ConsolesBase_B_BC.png',
 'MI_ConsolsButtonSupport_A':panel+'T_ConsolsButtonSupport_A_BC.png',
 'MI_ConsolsKeycardSwipe_A':panel+'T_ConsolesKeycardSwipe_A_BC.png',
 'MI_KeyCard':panel+'T_KeyCard_BC.png',
})
battery='Objects/Gameplay/Puzzles/Battery/Model/'
build(battery+'battery.glb','BatteryTextured',{'*':battery+'T_Battery_BC.png'})
