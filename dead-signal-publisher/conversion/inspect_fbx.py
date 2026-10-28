"""Read-only FBX binary inventory; never executes source project code."""
import struct,zlib,json,sys
from pathlib import Path
p=Path(sys.argv[1]); data=p.read_bytes(); version=struct.unpack_from('<I',data,23)[0]; wide=version>=7500

def prop(offset):
 kind=chr(data[offset]); offset+=1
 formats={'Y':'h','C':'?','I':'i','F':'f','D':'d','L':'q'}
 if kind in formats:
  f='<'+formats[kind];return struct.unpack_from(f,data,offset)[0],offset+struct.calcsize(f)
 if kind in 'SR':
  length=struct.unpack_from('<I',data,offset)[0];offset+=4
  b=data[offset:offset+length];return (b.decode('utf-8','replace') if kind=='S' else {'binaryBytes':length}),offset+length
 if kind in 'fdlibc':
  count,encoding,size=struct.unpack_from('<III',data,offset);offset+=12
  return {'arrayType':kind,'count':count,'encoding':encoding,'compressedBytes':size},offset+size
 raise ValueError(kind)
def node(offset):
 header='<QQQB' if wide else '<IIIB';size=struct.calcsize(header)
 end,count,props_len,name_len=struct.unpack_from(header,data,offset)
 if not end:return None,offset+size
 name=data[offset+size:offset+size+name_len].decode('utf-8','replace');cursor=offset+size+name_len;props=[]
 for _ in range(count):value,cursor=prop(cursor);props.append(value)
 children=[]
 while cursor<end:
  child,nextpos=node(cursor)
  if child is None:break
  children.append(child);cursor=nextpos
 return {'name':name,'props':props,'children':children},end
nodes=[];cursor=27
while cursor<len(data)-13:
 n,cursor=node(cursor)
 if n is None:break
 nodes.append(n)
objects=next(n for n in nodes if n['name']=='Objects')['children']
report={'file':p.name,'bytes':len(data),'version':version,'objects':{}}
for obj in objects:
 report['objects'].setdefault(obj['name'],[]).append({'properties':obj['props'],'arrays':{n['name']:n['props'] for n in obj['children'] if n['name'] in ['Vertices','PolygonVertexIndex','KeyTime','KeyValueFloat','FileName','RelativeFilename']}})
print(json.dumps(report,indent=2))
