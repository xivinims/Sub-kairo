"""Small binary FBX data reader for source conversion (read-only, no plugins or source execution)."""
import struct,zlib

def read_fbx(path):
 data=path.read_bytes();version=struct.unpack_from('<I',data,23)[0];wide=version>=7500
 def prop(offset):
  kind=chr(data[offset]);offset+=1
  formats={'Y':'h','C':'?','I':'i','F':'f','D':'d','L':'q'}
  if kind in formats:
   f='<'+formats[kind];return struct.unpack_from(f,data,offset)[0],offset+struct.calcsize(f)
  if kind in 'SR':
   length=struct.unpack_from('<I',data,offset)[0];offset+=4;b=data[offset:offset+length]
   return b.decode('utf-8','replace') if kind=='S' else b,offset+length
  if kind in 'fdlibc':
   count,encoding,size=struct.unpack_from('<III',data,offset);offset+=12;b=data[offset:offset+size]
   if encoding:b=zlib.decompress(b)
   code={'f':'f','d':'d','l':'q','i':'i','b':'b','c':'?'}[kind]
   return list(struct.unpack('<'+str(count)+code,b)),offset+size
  raise ValueError(kind)
 def node(offset):
  header='<QQQB' if wide else '<IIIB';size=struct.calcsize(header)
  end,count,_,name_len=struct.unpack_from(header,data,offset)
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
 return nodes

def child(node,name):return next((n for n in node['children'] if n['name']==name),None)
def properties(node):
 p=child(node,'Properties70');return {n['props'][0]:n['props'][4:] for n in p['children']} if p else {}
