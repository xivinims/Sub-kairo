-- Pure state machine: no Instances, networking or persistence. Shared by tests and server.
local Campaign = {}
local function copy(value)
 if type(value) ~= "table" then return value end
 local result = {}; for k,v in pairs(value) do result[k]=copy(v) end; return result
end
local function count(list) local n=0; for _,v in pairs(list or {}) do if v then n+=1 end end; return n end
local function toggle(matrix, index)
 for i=1,9 do if math.abs((i-1)%3-(index-1)%3)+math.abs(math.floor((i-1)/3)-math.floor((index-1)/3))<=1 then matrix[i]=not matrix[i] end end
end
function Campaign.new(sector)
 local s={sector=sector or 1,flags={},digits={0,0,0,0},valves={false,false,false,false},pressure=0,tones=0,matrix={},angles={0,0,0},finished=false,hasGrabPack=false}
 for i=1,9 do s.matrix[i]=false end
 for _,i in ipairs({1,3,5,8}) do toggle(s.matrix,i) end
 return s
end
function Campaign.restore(raw)
 if type(raw)~="table" or type(raw.sector)~="number" then return Campaign.new() end
 local sector=math.clamp(math.floor(raw.sector),1,7); local s=Campaign.new(sector)
 -- Only restore bounded primitive values. Never trust an arbitrary persisted table shape.
 if type(raw.flags)=="table" then for k,v in pairs(raw.flags) do if type(k)=="string" and #k<50 and v==true then s.flags[k]=true end end end
 for key,limit in pairs({digits=9,angles=4}) do
  if type(raw[key])=="table" then for i=1,#s[key] do s[key][i]=math.clamp(math.floor(tonumber(raw[key][i]) or 0),0,limit) end end
 end
 if type(raw.valves)=="table" then for i=1,4 do s.valves[i]=raw.valves[i]==true end end
 if type(raw.matrix)=="table" then for i=1,9 do s.matrix[i]=raw.matrix[i]==true end end
 s.pressure=math.clamp(math.floor(tonumber(raw.pressure) or 0),0,9)
 s.tones=math.clamp(math.floor(tonumber(raw.tones) or 0),0,6)
 s.finished=raw.finished==true and sector==7
  s.hasGrabPack=raw.hasGrabPack==true or s.flags.pack==true or sector>1
  if not s.hasGrabPack and type(raw.flags)=="table" then
   for _,key in ipairs({"card","fuse","power","socket1","socket2","bloom1","bloom2","bloom3","socket3","release"}) do if raw.flags[key]==true then s.hasGrabPack=true;break end end
  end
 return s
end
function Campaign.count(s,prefix)
 local n=0; for k,v in pairs(s.flags) do if v and string.sub(k,1,#prefix)==prefix then n+=1 end end; return n
end
function Campaign.complete(s)
 local f=s.flags
 if s.sector==1 then return f.release==true end
 if s.sector==2 then return f.safe==true end
 if s.sector==3 then return f.started==true end
 if s.sector==4 then return Campaign.count(s,"seed")==6 end
 if s.sector==5 then
  if s.tones~=6 then return false end
  for _,on in ipairs(s.matrix) do if on then return false end end; return true
 end
 if s.sector==6 then return Campaign.count(s,"cut")==4 end
 return f.silent==true
end
function Campaign.danger(s)
 return (s.sector==1 and s.flags.socket3 and not s.flags.release) or (s.sector==4 and Campaign.count(s,"seed")>=4) or (s.sector==6 and Campaign.count(s,"cut")>0 and Campaign.count(s,"cut")<4)
end
function Campaign.act(original,id,right)
 local s=copy(original); local f=s.flags; local message="Circuito atualizado."
 if s.finished then return s,"Capítulo concluído.",false end
 if id=="exit" then
  if not Campaign.complete(s) then return s,"Conclua os objetivos deste setor.",false end
  if s.sector==7 then s.finished=true; return s,"O sinal foi interrompido.",true end
  local nextState=Campaign.new(s.sector+1);nextState.hasGrabPack=s.hasGrabPack;return nextState,"Passagem liberada.",true
 end
 if s.sector==1 and id=="pack" then
   if s.hasGrabPack then return original,"O GrabPack já está equipado.",false end
   s.hasGrabPack=true;f.pack=true;return s,"GrabPack recolhido. Mãos azul e vermelha liberadas.",true
  end
  local function reject(text) return original,text,false end
 local function take(key) if f[key] then return false end; f[key]=true; return true end
 if s.sector==1 then
  if id=="card" or id=="fuse" then if not take(id) then return reject("Você já recolheu este item.") end
  elseif id=="power" then if not f.fuse then return reject("Falta o fusível.") end; f.power=true
  elseif id=="socket1" then if right or not f.power then return reject("Ligue o quadro e use a mão azul.") end; f.socket1=true
  elseif id=="socket2" then if not right or not f.socket1 then return reject("Ative 1 primeiro; use a vermelha em 2.") end; f.socket2=true
  elseif string.match(id,"^bloom[123]$") then if not f.socket2 then return reject("Ative os dois primeiros terminais.") end; if not take(id) then return reject("Esta flor já foi podada.") end
  elseif id=="socket3" then if right or Campaign.count(s,"bloom")~=3 then return reject("Pode três flores e use a azul.") end; f.socket3=true
  elseif id=="release" then if not right or not f.socket3 or not f.card then return reject("Precisa de crachá, circuito completo e mão vermelha.") end; f.release=true
  else return reject("Alvo inválido.") end
 elseif s.sector==2 then
  if string.match(id,"^page[123]$") then if not take(id) then return reject("Página já recuperada.") end
  elseif string.match(id,"^digit[1234]$") then local i=tonumber(string.sub(id,-1)); s.digits[i]=(s.digits[i]+1)%10
  elseif id=="safe" then if Campaign.count(s,"page")~=3 or table.concat(s.digits)~="1784" then return reject("Três páginas e o ano do primeiro viveiro.") end; f.safe=true
  else return reject("Alvo inválido.") end
 elseif s.sector==3 then
  if string.match(id,"^cell[123]$") then if not take(id) then return reject("Célula já recolhida.") end
  elseif string.match(id,"^valve[1234]$") then local i=tonumber(string.sub(id,-1));s.valves[i]=not s.valves[i]
  elseif id=="pressure" then s.pressure=(s.pressure+1)%10
  elseif id=="start" then
   if not right or Campaign.count(s,"cell")~=3 or s.pressure~=6 or not s.valves[1] or s.valves[2] or not s.valves[3] or not s.valves[4] then return reject("Confira três células, pressão 6, válvulas e mão vermelha.") end; f.started=true
  else return reject("Alvo inválido.") end
 elseif s.sector==4 then
  if not string.match(id,"^seed[123456]$") then return reject("Alvo inválido.") end
  if not take(id) then return reject("Semente já recolhida.") end
 elseif s.sector==5 then
  if string.match(id,"^tone[1234]$") then
   local pattern={2,4,1,3,2,1};local n=tonumber(string.sub(id,-1))
   if s.tones<6 then s.tones=if pattern[s.tones+1]==n then s.tones+1 else (if n==2 then 1 else 0) end
  elseif string.match(id,"^lamp[123456789]$") then toggle(s.matrix,tonumber(string.sub(id,-1)))
  else return reject("Alvo inválido.") end
 elseif s.sector==6 then
  local n=string.sub(id,-1)
  if string.match(id,"^isolate[1234]$") then if right then return reject("Isolador exige azul.") end;f["isolate"..n]=true
  elseif string.match(id,"^cut[1234]$") then if not right or not f["isolate"..n] then return reject("Isole com azul antes do corte vermelho.") end; if not take(id) then return reject("Raiz já cortada.") end
  else return reject("Alvo inválido.") end
 else
  if string.match(id,"^fuse[1234]$") then if not take(id) then return reject("Fusível já recolhido.") end
  elseif string.match(id,"^angle[123]$") then local i=tonumber(string.sub(id,-1));s.angles[i]=(s.angles[i]+1)%5
  elseif id=="master" then if not right or Campaign.count(s,"fuse")~=4 or table.concat(s.angles)~="314" then return reject("Quatro fusíveis, antenas 3 / 1 / 4 e mão vermelha.") end;f.silent=true
  else return reject("Alvo inválido.") end
 end
 return s,message,true
end
function Campaign.progress(s)
 if s.finished then return "FIM DO CAPÍTULO 1" end
 if s.sector==1 then return "Flores: "..Campaign.count(s,"bloom").."/3" end
 if s.sector==2 then return "Páginas: "..Campaign.count(s,"page").."/3  •  Cofre: "..table.concat(s.digits) end
 if s.sector==3 then return "Células: "..Campaign.count(s,"cell").."/3  •  Pressão: "..s.pressure end
 if s.sector==4 then return "Sementes: "..Campaign.count(s,"seed").."/6" end
 if s.sector==5 then local n=0;for _,v in ipairs(s.matrix) do if v then n+=1 end end;return "Sinal: "..s.tones.."/6  •  Luzes: "..n end
 if s.sector==6 then return "Raízes: "..Campaign.count(s,"cut").."/4" end
 return "Fusíveis: "..Campaign.count(s,"fuse").."/4  •  Antenas: "..table.concat(s.angles," / ")
end
return Campaign
