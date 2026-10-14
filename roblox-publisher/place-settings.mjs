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
