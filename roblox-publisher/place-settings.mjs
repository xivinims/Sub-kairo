// Native Roblox binary chunks. Changing editor-only scalar properties leaves voxel and model chunks intact.
import assert from 'node:assert/strict';
function lz4Block(input,expected) {
 const out=Buffer.alloc(expected);let pos=0,index=0;
 while(pos<input.length){const token=input[pos++];let literal=token>>>4;
  if(literal===15){let extra;do{extra=input[pos++];literal+=extra;}while(extra===255);}
  assert(pos+literal<=input.length&&index+literal<=out.length,'Invalid LZ4 literals');input.copy(out,index,pos,pos+literal);pos+=literal;index+=literal;
  if(pos===input.length)break;
  const offset=input.readUInt16LE(pos);pos+=2;let length=(token&15)+4;
  if((token&15)===15){let extra;do{extra=input[pos++];length+=extra;}while(extra===255);}
  assert(offset>0&&offset<=index&&index+length<=out.length,'Invalid LZ4 match');for(let n=0;n<length;n++)out[index+n]=out[index+n-offset];index+=length;
 }assert.equal(index,expected);return out;
}
export function inspectPlace(input){
 assert.equal(input.subarray(0,14).toString('latin1'),'<roblox!\x89\xff\r\n\x1a\n');const chunks=[];const classes=new Map();const properties=[];
 for(let pos=32;pos<input.length;){assert(pos+16<=input.length);const kind=input.subarray(pos,pos+4).toString('latin1');const compressed=input.readUInt32LE(pos+4),uncompressed=input.readUInt32LE(pos+8),size=compressed||uncompressed;
  assert(pos+16+size<=input.length);const raw=input.subarray(pos+16,pos+16+size);const data=kind==='PROP'||kind==='INST'?(compressed?lz4Block(raw,uncompressed):raw):null;const chunk={kind,start:pos,end:pos+16+size,data};chunks.push(chunk);
  if(kind==='INST'){const length=data.readUInt32LE(4);classes.set(data.readUInt32LE(0),{name:data.subarray(8,8+length).toString(),count:data.readUInt32LE(9+length)});}
  if(kind==='PROP'){const length=data.readUInt32LE(4);properties.push({chunk,id:data.readUInt32LE(0),name:data.subarray(8,8+length).toString(),type:data[8+length],offset:9+length});}
  pos+=16+size;
 }for(const p of properties)p.class=classes.get(p.id)?.name;
 return{chunks,properties,classes};
}
function number(data,offset,type){if(type===2)return Boolean(data[offset]);const v=data.readUInt32BE(offset);if(type===3)return(v>>>1)^-(v&1);if(type===4){const b=Buffer.alloc(4);b.writeUInt32LE(((v>>>1)|(v<<31))>>>0);return b.readFloatLE();}throw Error('Unsupported scalar type '+type);}
function zigzag(value){return((value<<1)^(value>>31))>>>0;}
function ints(values,delta=false){const out=Buffer.alloc(values.length*4);let previous=0;for(let i=0;i<values.length;i++){const n=values[i];const v=zigzag(delta?n-previous:n);previous=n;for(let byte=0;byte<4;byte++)out[byte*values.length+i]=(v>>>(24-byte*8))&255;}return out;}
function decodeInts(data,count,delta=false){const out=[];let prior=0;for(let i=0;i<count;i++){let v=0;for(let byte=0;byte<4;byte++)v=(v<<8)|data[byte*count+i];v=(v>>>1)^-(v&1);if(delta){prior+=v;v=prior;}out.push(v);}return out;}
function string(value){const b=Buffer.from(value);const n=Buffer.alloc(4);n.writeUInt32LE(b.length);return Buffer.concat([n,b]);}
function uint(n){const b=Buffer.alloc(4);b.writeUInt32LE(n);return b;}
function chunk(kind,data){const header=Buffer.alloc(16);header.write(kind,0,'latin1');header.writeUInt32LE(data.length,8);return Buffer.concat([header,data]);}
export function wrapServices(input,manifest,serviceProperties=[]){
 const parsed=inspectPlace(input);const refs=new Map();const names=new Map();let maxRef=-1,maxClass=-1;
 for(const c of parsed.chunks)if(c.kind==='INST'){const id=c.data.readUInt32LE();const length=c.data.readUInt32LE(4);const count=c.data.readUInt32LE(9+length);const ids=decodeInts(c.data.subarray(13+length),count,true);refs.set(id,ids);for(const n of ids)maxRef=Math.max(maxRef,n);maxClass=Math.max(maxClass,id);}
 for(const p of parsed.properties)if(p.name==='Name'){assert.equal(p.type,1);let pos=p.offset;const ids=refs.get(p.id);for(const id of ids){const n=p.chunk.data.readUInt32LE(pos);pos+=4;names.set(id,p.chunk.data.subarray(pos,pos+n).toString());pos+=n;}}
 const parentChunk=parsed.chunks.find(c=>c.kind==='PRNT');assert(parentChunk);const raw=input.subarray(parentChunk.start);const cLen=raw.readUInt32LE(4),size=raw.readUInt32LE(8);const bytes=input.subarray(parentChunk.start+16,parentChunk.end);const parent=cLen?lz4Block(bytes,size):bytes;const n=parent.readUInt32LE(1);const ids=decodeInts(parent.subarray(5,5+4*n),n,true),parents=decodeInts(parent.subarray(5+4*n),n,true);const byRefClass=new Map();for(const [id,list]of refs)for(const r of list)byRefClass.set(r,parsed.classes.get(id).name);
 const serviceNames=["Workspace","ReplicatedStorage","ServerScriptService","StarterPlayer","StarterGui","StarterPack","ReplicatedFirst","Lighting","SoundService","MaterialService","Teams","TextChatService"];const serviceRefs=new Map(),add=[];
 for(const name of serviceNames){const id=++maxClass,ref=++maxRef;serviceRefs.set(name,ref);const data=Buffer.concat([uint(id),string(name),Buffer.from([1]),uint(1),ints([ref],true),Buffer.from([1])]);add.push(chunk('INST',data));
  add.push(chunk('PROP',Buffer.concat([uint(id),string('Name'),Buffer.from([1]),string(name)])));
  for(const prop of serviceProperties.filter(p=>p.service===name)){
   const types={boolean:2,number:4,enum:18,vector:14,color:12};const type=types[prop.kind];let value;
   const f32=x=>{const b=Buffer.alloc(4);b.writeFloatLE(x);const bits=b.readUInt32LE();b.writeUInt32BE(((bits<<1)|(bits>>>31))>>>0);return b;};
   if(type===2)value=Buffer.from([Number(prop.value)]);else if(type===18){value=Buffer.alloc(4);value.writeUInt32BE(prop.value);}else if(type===4)value=f32(prop.value);else value=Buffer.concat(prop.value.map(f32));
   add.push(chunk('PROP',Buffer.concat([uint(id),string(prop.name),Buffer.from([type]),value])));
  }
  if(name==='Workspace'){for(const [key,value,type]of [['StreamingEnabled',true,2],['StreamingMinRadius',64,3],['StreamingTargetRadius',128,3]])add.push(chunk('PROP',Buffer.concat([uint(id),string(key),Buffer.from([type]),type===2?Buffer.from([Number(value)]):ints([value])])));}
 }
 for(let i=0;i<n;i++)if(parents[i]===-1){const matches=manifest.filter(m=>m.name===names.get(ids[i])&&m.class===byRefClass.get(ids[i]));assert.equal(matches.length,1,'Ambiguous exported root '+names.get(ids[i]));parents[i]=serviceRefs.get(matches[0].service);}
 for(const ref of serviceRefs.values()){ids.push(ref);parents.push(-1);}
 const newParent=chunk('PRNT',Buffer.concat([Buffer.from([0]),uint(ids.length),ints(ids,true),ints(parents,true)]));
 const header=Buffer.from(input.subarray(0,32));header.writeUInt32LE(maxClass+1,16);header.writeUInt32LE(header.readUInt32LE(20)+serviceRefs.size,20);
 const body=[];for(const c of parsed.chunks){if(c.kind==='PRNT')body.push(...add,newParent);else body.push(input.subarray(c.start,c.end));}
 return Buffer.concat([header,...body]);
}
export function editPlace(input){
 const parsed=inspectPlace(input);assert(parsed.classes.size>8,'Missing place services');for(const name of ['Workspace','Terrain','ReplicatedStorage','ServerScriptService','StarterGui','StarterPlayer'])assert([...parsed.classes.values()].some(x=>x.name===name),'Missing '+name);
 const desired={'Terrain.Decoration':true,'Terrain.GrassLength':.4,'Workspace.StreamingEnabled':true,'Workspace.StreamingMinRadius':64,'Workspace.StreamingTargetRadius':128};const replacement=new Map(),changes=[];
 for(const p of parsed.properties){const key=p.class+'.'+p.name;if(!Object.hasOwn(desired,key))continue;assert.equal(parsed.classes.get(p.id).count,1,'Scalar service property expected');const data=Buffer.from(p.chunk.data);const before=number(data,p.offset,p.type),after=desired[key];
  if(p.type===2)data[p.offset]=Number(after);else if(p.type===3){data.writeUInt32BE((after*2)>>>0,p.offset);}else if(p.type===4){const n=Buffer.alloc(4);n.writeFloatLE(after);const bits=n.readUInt32LE();data.writeUInt32BE(((bits<<1)|(bits>>>31))>>>0,p.offset);}else throw Error('Unsupported property '+key);
  const header=Buffer.alloc(16);header.write(p.chunk.kind,0,'latin1');header.writeUInt32LE(data.length,8);replacement.set(p.chunk,Buffer.concat([header,data]));changes.push({key,before,after});
 }assert.equal(changes.length,Object.keys(desired).length,'Missing required native grass or streaming setting');
 const output=Buffer.concat([input.subarray(0,32),...parsed.chunks.map(c=>replacement.get(c)||input.subarray(c.start,c.end))]);const verified=inspectPlace(output);
 for(const p of verified.properties){const key=p.class+'.'+p.name;if(Object.hasOwn(desired,key))assert(Math.abs(Number(number(p.chunk.data,p.offset,p.type))-Number(desired[key]))<1e-6,key+' failed');}
 return{buffer:output,changes,classes:[...parsed.classes.values()].map(x=>x.name)};
}

export function terrainSettings(input){const p=inspectPlace(input);const result={};for(const prop of p.properties)if(prop.class==='Terrain'&&['Decoration','GrassLength'].includes(prop.name))result[prop.name]=number(prop.chunk.data,prop.offset,prop.type);return result;}
