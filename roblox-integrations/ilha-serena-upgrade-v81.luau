assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==80,"Published version changed")
local world=workspace.IlhaSerena assert(world:GetAttribute("UpgradeVersion")==80,"Wrong island baseline")
local runtime=game.ReplicatedStorage.SerenaRuntime local SSS=game.ServerScriptService local SPS=game.StarterPlayer.StarterPlayerScripts
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)if old then old:Destroy()end
 local s=Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
local function folder(parent,name)
 local old=parent:FindFirstChild(name)if old then old:Destroy()end
 local f=Instance.new("Folder")f.Name=name f.Parent=parent return f
end
local function run(code)
 local m=source(game.ServerStorage,"ModuleScript","Stage81","return function()\n"..code.."\nend")local result=require(m)()m:Destroy()return result
end
local function module(code)
 local m=source(game.ServerStorage,"ModuleScript","Factory81",code)local result=require(m)m:Destroy()return result
end

source(runtime,"ModuleScript","BridgeLifecycle",[========[local Bridge={GraceSeconds=60,AppearRadius=130,LeaveRadius=150}
function Bridge.new()
 return {visible=false,generation=0,emptySince=nil,shownAt=0}
end
function Bridge.step(state,occupied,now)
 if occupied then
  state.emptySince=nil
  if not state.visible then state.visible=true state.generation+=1 state.shownAt=now return "Show" end
 elseif state.visible then
  state.emptySince=state.emptySince or now
  if now-state.emptySince>=Bridge.GraceSeconds then state.visible=false state.emptySince=nil return "Hide" end
 end
 return nil
end
function Bridge.near(model,positions,visible)
 local center=model:GetAttribute("BridgeCenter")
 local radius=visible and Bridge.LeaveRadius or Bridge.AppearRadius
 for _,position in ipairs(positions)do
  local offset=position-center
  if offset.X*offset.X+offset.Z*offset.Z<=radius*radius and math.abs(offset.Y)<65 then return true end
 end
 return false
end
function Bridge.prepare(model)
 model:SetAttribute("EmptyGraceSeconds",Bridge.GraceSeconds)
 model:SetAttribute("AppearRadius",Bridge.AppearRadius)
 model:SetAttribute("LeaveRadius",Bridge.LeaveRadius)
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("BasePart")then
   if p:GetAttribute("BridgeRestCF")then p:SetAttribute("BridgeRestSize",p.Size)
   elseif p.CanCollide or p:GetAttribute("BridgeCollider")then p:SetAttribute("BridgeCollider",true)end
  end
 end
end
function Bridge.apply(model,state)
 -- Stable collision appears immediately. Only decorative pieces are animated on clients.
 if not state.visible then model:SetAttribute("BridgeVisible",false)end
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("BasePart")then
   if p:GetAttribute("BridgeRestCF")then
    p.CFrame=p:GetAttribute("BridgeRestCF")
    p.Size=p:GetAttribute("BridgeRestSize")or p.Size
    p.Transparency=state.visible and (p:GetAttribute("BridgeAlpha")or 0)or 1
    p.CanCollide=false p.CanTouch=false p.CanQuery=false
   elseif p:GetAttribute("BridgeCollider")then
    p.Transparency=1 p.CanCollide=state.visible p.CanQuery=state.visible p.CanTouch=false
   end
  elseif p:IsA("Light")then p.Enabled=state.visible end
 end
 model:SetAttribute("BridgeGeneration",state.generation)
 model:SetAttribute("BridgeShownAt",state.shownAt)
 model:SetAttribute("BridgeEmptySince",state.emptySince)
 model:SetAttribute("BridgeVisible",state.visible)
end
return Bridge
]========])

source(runtime,"ModuleScript","FishingCore",[========[-- Authoritative fishing state. Native services and geometry are supplied by the server adapter.
local Fishing={MaxFish=12,MaxCast=42,MoveLimit=22,BiteWindow=3}
local function vector(value)
 return typeof(value)=="Vector3"and value.X==value.X and value.Y==value.Y and value.Z==value.Z and value.Magnitude<100000
end
function Fishing.new(deps)
 local self={sessions={},deps=deps}
 local function session(p)
  local s=self.sessions[p]
  if not s then s={rod=false,fish={},phase="Idle",readyAt=0}self.sessions[p]=s end
  return s
 end
 local function message(p,text,ok)deps.send(p,"Message",{text=text,ok=ok==true})end
 local function sync(p,s)
  local value=0 for _,f in ipairs(s.fish)do value+=f.value end
  deps.send(p,"State",{phase=s.phase,deadline=s.deadline or 0,count=#s.fish,value=value,rod=s.rod,maxFish=Fishing.MaxFish})
 end
 local function cancel(p,s,text)
  if s.visual then deps.removeVisual(s.visual)s.visual=nil end
  s.phase="Idle"s.deadline=nil s.biteAt=nil s.origin=nil s.character=nil
  s.readyAt=deps.clock()+1 sync(p,s)if text then message(p,text,false)end
 end
 function self:add(p)local s=session(p)sync(p,s)return s end
 function self:remove(p)
  local s=self.sessions[p]if s and s.visual then deps.removeVisual(s.visual)end
  self.sessions[p]=nil
 end
 function self:respawn(p)
  local s=session(p)cancel(p,s)
  if s.rod then deps.giveRod(p,false)end
  for _,f in ipairs(s.fish)do deps.giveFish(p,f)end
 end
 function self:getRod(p)
  local s=session(p)local c=deps.character(p)
  if not c or not deps.nearRod(c.root.Position)then message(p,"Pegue sua vara no píer de madeira.",false)return false end
  if not deps.giveRod(p,true)then message(p,"Espere o personagem aparecer.",false)return false end
  s.rod=true sync(p,s)message(p,"Vara equipada. Mire na água e lance a linha.",true)return true
 end
 function self:cast(p,target)
  local s=session(p)local now=deps.clock()local c=deps.character(p)
  if not c or not c.rod then message(p,"Equipe a vara de pesca na mochila.",false)return false end
  if s.phase~="Idle"or s.selling or now<s.readyAt then return false end
  if s.pendingSale then message(p,"Finalize a venda no píer antes de pescar de novo.",false)return false end
  if #s.fish>=Fishing.MaxFish then message(p,"Cesto cheio! Venda os peixes no píer.",false)return false end
  if not vector(target)or (target-c.root.Position).Magnitude>Fishing.MaxCast then message(p,"Mire na água perto de você.",false)return false end
  local water=deps.water(target)
  if not water or (water-c.root.Position).Magnitude>Fishing.MaxCast or (water-c.root.Position).Magnitude<5 then
   message(p,"Lance a linha na água, longe da madeira.",false)return false
  end
  s.phase="Waiting"s.origin=c.root.Position s.character=c.character s.biteAt=now+deps.random(5,11)
  s.deadline=s.biteAt s.visual=deps.makeVisual(p,c.rod,water)
  sync(p,s)message(p,"Linha na água. Aguarde a boia afundar.",true)return true
 end
 function self:reel(p)
  local s=session(p)local c=deps.character(p)local now=deps.clock()
  if s.phase=="Idle"then return false end
  if not c or not c.rod or c.character~=s.character or (c.root.Position-s.origin).Magnitude>Fishing.MoveLimit then cancel(p,s,"A linha foi recolhida.")return false end
  if s.phase~="Bite"or now>s.deadline then cancel(p,s,"O peixe escapou. Espere a boia afundar para puxar.")return false end
  local weight=math.floor(deps.random(.35,3.2)*100+.5)/100
  local f={id=deps.guid(),species="Carpa",weight=weight,value=8+math.floor(weight*14)}
  -- A server-created fish is added only once, after a valid bite.
  table.insert(s.fish,f)deps.giveFish(p,f)cancel(p,s)
  message(p,string.format("Carpa de %.2f kg! Vale %d moedas no píer.",weight,f.value),true)
  deps.send(p,"Caught",f)return true
 end
 function self:sell(p)
  local s=session(p)local c=deps.character(p)
  if not c or not deps.nearMarket(c.root.Position)then message(p,"Venda os peixes no balcão do píer.",false)return false end
  if s.selling then return false end
  if #s.fish==0 then message(p,"Seu cesto está vazio. Pegue uma vara e pesque.",false)return false end
  cancel(p,s)s.selling=true
  if not s.pendingSale then
   local amount=0 for _,f in ipairs(s.fish)do amount+=f.value end
   s.pendingSale={id=deps.guid(),amount=amount}
  end
  local sale=s.pendingSale
  local ok,accepted,feedback=pcall(deps.credit,p,sale.amount,sale.id)
  s.selling=false
  if not ok or not accepted then message(p,ok and feedback or "Não foi possível salvar a venda. Seus peixes continuam no cesto.",false)return false end
  for _,f in ipairs(s.fish)do deps.takeFish(p,f.id)end
  table.clear(s.fish)s.pendingSale=nil sync(p,s)
  message(p,"Venda concluída: +"..sale.amount.." moedas!",true)return true
 end
 function self:dispatch(p,action,target)
  if action=="GetRod"then return self:getRod(p)
  elseif action=="Cast"then return self:cast(p,target)
  elseif action=="Reel"then return self:reel(p)
  elseif action=="Cancel"then local s=session(p)cancel(p,s)return true
  elseif action=="Sell"then return self:sell(p)
  elseif action=="Sync"then sync(p,session(p))return true end
  return false
 end
 function self:tick()
  local now=deps.clock()
  for p,s in pairs(self.sessions)do
   if s.phase~="Idle"then
    local c=deps.character(p)
    if not c or not c.rod or c.character~=s.character or (c.root.Position-s.origin).Magnitude>Fishing.MoveLimit then cancel(p,s,"A linha foi recolhida.")
    elseif s.phase=="Waiting"and now>=s.biteAt then
     s.phase="Bite"s.deadline=now+Fishing.BiteWindow
     if s.visual then deps.biteVisual(s.visual)end
     sync(p,s)message(p,"FISGOU! Puxe agora!",true)
    elseif s.phase=="Bite"and now>s.deadline then cancel(p,s,"O peixe escapou. Lance novamente.")end
   end
  end
 end
 return self
end
return Fishing
]========])

source(runtime,"ModuleScript","BoatController",[========[local Boat={MaxSpeed=22,ReverseSpeed=8,InputTimeout=.6,ReturnSeconds=60,MaxRange=430}
local function number(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
function Boat.new(deps,home)
 local _,yaw=home:ToOrientation()
 local self={cf=home,home=home,yaw=yaw,speed=0,throttle=0,steer=0,lastInput=-math.huge,emptySince=nil,driver=nil}
 function self:drive(p,throttle,steer)
  if deps.driver()~=p or not number(throttle)or not number(steer)then return false end
  self.driver=p self.throttle=math.clamp(throttle,-1,1)self.steer=math.clamp(steer,-1,1)self.lastInput=deps.clock()return true
 end
 function self:tick(dt)
  dt=math.clamp(dt,0,.1)local now=deps.clock()local driver=deps.driver()
  if driver~=self.driver then self.driver=driver self.throttle=0 self.steer=0 self.lastInput=-math.huge end
  local input=driver and now-self.lastInput<=Boat.InputTimeout
  local throttle=input and self.throttle or 0 local steer=input and self.steer or 0
  local target=throttle>=0 and throttle*Boat.MaxSpeed or throttle*Boat.ReverseSpeed
  self.speed+=(target-self.speed)*(1-math.exp(-dt*(input and 2.5 or 2)))
  if math.abs(self.speed)<.02 then self.speed=0 end
  local turn=steer*dt*1.1*math.clamp(math.abs(self.speed)/9,.15,1)*(self.speed<0 and -1 or 1)
  local yaw=self.yaw-turn
  local heading=CFrame.Angles(0,yaw,0)
  local position=self.cf.Position+heading.LookVector*self.speed*dt
  position=Vector3.new(position.X,home.Y,position.Z)
  local candidate=CFrame.new(position)*heading
  local offset=position-home.Position
  if offset.Magnitude<=Boat.MaxRange and deps.water(candidate)and deps.sweep(self.cf,candidate)then
   self.cf=candidate self.yaw=yaw
  else self.speed=0 self.throttle=0 end
  if not driver and not deps.passenger()then
   self.emptySince=self.emptySince or now
   if now-self.emptySince>=Boat.ReturnSeconds and (self.cf.Position-home.Position).Magnitude>1 then
    self.cf=home local _,angle=home:ToOrientation()self.yaw=angle self.speed=0 self.emptySince=now
   end
  else self.emptySince=nil end
  deps.move(self.cf,self.speed)
 end
 return self
end
return Boat
]========])

source(runtime,"ModuleScript","ItemRules",[========[local Rules={Price=30,StartingCoins=50,Award=10,AwardInterval=60,Duration=3,Cooldown=60}
local function finite(value,default)
 return type(value)=="number"and value==value and math.abs(value)<math.huge and value or default
end
function Rules.profile(data)
 data=type(data)=="table"and data or {}
 local credits={}
 if type(data.credits)=="table"then
  for _,id in ipairs(data.credits)do if type(id)=="string"and #id<=64 then table.insert(credits,id)end end
  while #credits>16 do table.remove(credits,1)end
 end
 return {version=2,coins=math.clamp(math.floor(finite(data.coins,Rules.StartingCoins)),0,1000000),
  apple=data.apple==true,nextAppleAt=math.max(0,finite(data.nextAppleAt,0)),credits=credits}
end
function Rules.apply(data,action,now,payload)
 local p=Rules.profile(data)
 if action=="BuyApple"then
  if p.apple then return p,false,"Você já tem esta maçã."end
  if p.coins<Rules.Price then return p,false,"Você precisa de 30 moedas."end
  p.coins-=Rules.Price p.apple=true return p,true,"Maçã comprada! Equipe na mochila e use."
 elseif action=="UseApple"then
  if not p.apple then return p,false,"Compre a maçã primeiro."end
  if now<p.nextAppleAt then return p,false,"Aguarde "..math.ceil(p.nextAppleAt-now).." s para usar novamente."end
  p.nextAppleAt=now+Rules.Cooldown return p,true,"Invisível por 3 segundos."
 elseif action=="Award"then
  p.coins=math.min(1000000,p.coins+Rules.Award)return p,true,"+10 moedas por jogar na ilha."
 elseif action=="Credit"then
  if type(payload)~="table"or type(payload.id)~="string"or #payload.id<16 or #payload.id>64 then return p,false,"Crédito inválido."end
  local amount=finite(payload.amount,0)
  if amount<1 or amount>10000 or amount%1~=0 then return p,false,"Valor inválido."end
  for _,id in ipairs(p.credits)do if id==payload.id then return p,true,"Venda já registrada."end end
  p.coins=math.min(1000000,p.coins+amount)table.insert(p.credits,payload.id)
  while #p.credits>16 do table.remove(p.credits,1)end
  return p,true,"Venda registrada."
 end
 return p,false,"Ação inválida."
end
return Rules
]========])

source(runtime,"ModuleScript","Climate",[========[-- Shared climate profile: the same native effects run on server and client.
local Climate={DayLength=600,InitialHour=9.25,TransitionSeconds=8}
function Climate.hour(now,start)
 return (Climate.InitialHour+(now-start)*24/Climate.DayLength)%24
end
function Climate.phase(hour)
 if hour<5 then return "Madrugada" elseif hour<6.5 then return "Amanhecer" elseif hour<12 then return "Manhã"
 elseif hour<17 then return "Tarde" elseif hour<18.5 then return "Pôr do sol" elseif hour<20 then return "Anoitecer" else return "Noite" end
end
function Climate.weights(now,changed,from,to)
 local t=math.clamp((now-changed)/Climate.TransitionSeconds,0,1) t=t*t*(3-2*t)
 local function amount(state,key) return state==key and 1 or 0 end
 return amount(from,"Chuva")*(1-t)+amount(to,"Chuva")*t,
  amount(from,"Sol")*(1-t)+amount(to,"Sol")*t
end
function Climate.profile(hour,rain,clear,now)
 local sun=math.clamp((math.sin((hour-6)/24*math.pi*2)+.13)/1.13,0,1)
 local sunset=math.clamp(1-math.abs(hour-17.65)/1.8,0,1)
 local dawn=math.clamp(1-math.abs(hour-6.2)/1.5,0,1)
 local warm=math.max(sunset,dawn*.65)
 local gust=1+.17*math.sin(now*.39)+.09*math.sin(now*.91)
 local wind=Vector3.new(5+rain*10,0,2+rain*5)*gust
 local p={sun=sun,rain=rain,clear=clear,warm=warm,wind=wind}
 p.brightness=.85+sun*(1.7+clear*.75-rain*.25)
 p.ambient=Color3.fromRGB(52,63,83):Lerp(Color3.fromRGB(102,114,120),sun)
 p.outdoor=Color3.fromRGB(70,83,107):Lerp(Color3.fromRGB(148,162,166),sun)
 p.atmosphere=Color3.fromRGB(189,215,233):Lerp(Color3.fromRGB(245,186,134),warm*.75)
 p.decay=Color3.fromRGB(104,139,162):Lerp(Color3.fromRGB(163,100,73),warm*.7)
 p.density=.23+(1-clear)*.045+rain*.055
 p.haze=.9+(1-clear)*.45+rain*.9
 p.cover=.2+(1-clear)*.37+rain*.21
 p.cloudDensity=.32+rain*.28
 p.cloudColor=Color3.fromRGB(246,248,244):Lerp(Color3.fromRGB(145,161,176),rain):Lerp(Color3.fromRGB(255,208,169),warm*.25)
 p.rays=(.026+.065*clear)*math.max(sun,dawn*.9,sunset*.8)*(1-rain*.85)
 p.waterColor=Color3.fromRGB(36,138,153):Lerp(Color3.fromRGB(61,111,132),rain*.7)
 p.waveSize=.32+rain*.28 p.waveSpeed=12+rain*9
 return p
end
function Climate.apply(lighting,terrain,profile)
 local p=profile
 lighting.ClockTime=p.hour or lighting.ClockTime
 lighting.GlobalShadows=true lighting.Brightness=p.brightness lighting.ExposureCompensation=.08
 lighting.EnvironmentDiffuseScale=.75 lighting.EnvironmentSpecularScale=1 lighting.ShadowSoftness=.25
 lighting.Ambient=p.ambient lighting.OutdoorAmbient=p.outdoor
 lighting.ColorShift_Top=Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(98,44,19),p.warm)
 local atmosphere=lighting:FindFirstChild("SerenaAtmosphere")
 if atmosphere then atmosphere.Color=p.atmosphere atmosphere.Decay=p.decay atmosphere.Density=p.density atmosphere.Haze=p.haze atmosphere.Glare=p.clear*.22*p.sun end
 local grade=lighting:FindFirstChild("SerenaColor")
 if grade then grade.Contrast=.105 grade.Saturation=.16-p.rain*.12 grade.Brightness=.012 grade.TintColor=Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(255,224,200),p.warm*.25) end
 local bloom=lighting:FindFirstChild("SerenaBloom")
 if bloom then bloom.Enabled=true bloom.Intensity=.19 bloom.Threshold=1.05 bloom.Size=28 end
 local rays=lighting:FindFirstChild("SerenaSunRays")
 if rays then rays.Enabled=true rays.Intensity=p.rays rays.Spread=.78 end
 local clouds=terrain:FindFirstChild("SerenaClouds")
 if clouds then clouds.Cover=p.cover clouds.Density=p.cloudDensity clouds.Color=p.cloudColor end
 terrain.WaterColor=p.waterColor terrain.WaterTransparency=.44 terrain.WaterReflectance=.38
 terrain.WaterWaveSize=p.waveSize terrain.WaterWaveSpeed=p.waveSpeed
 workspace.GlobalWind=p.wind
end
function Climate.rendering(lighting)
 -- A renderer capability failure must not stop rain, grass, time or controls.
 local style=pcall(function()lighting.LightingStyle=Enum.LightingStyle.Realistic end)
 local quality=pcall(function()lighting.PrioritizeLightingQuality=true end)
 return style and quality
end
return Climate
]========])

local assets=module([========[local Assets={}
local ASSETS={
 {key="Apple",id=2759295720,author="kinglalu",title="Apple"},
 {key="Lamp",id=14845961545,author="AmirkhanMul",title="Streetlamp"},
 {key="Rod",id=75167845877982,author="BambooPandaTime",title="Fishing Rod"},
 {key="Boat",id=9617142471,author="notorofkil",title="Boat"},
 {key="Dock",id=17010090897,author="sSkyI4r",title="Boat Dock"},
 {key="House",id=12346232595,author="paraghoul",title="Cottage House"},
 {key="Oak",id=128707014921507,author="Letaij",title="Realistic Oak Tree"},
 {key="Fish",id=9223655599,author="Biryuvignette",title="Fish"},
}
local function bounds(model)
 local lo=Vector3.new(math.huge,math.huge,math.huge)local hi=-lo
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)
   lo=Vector3.new(math.min(lo.X,q.X),math.min(lo.Y,q.Y),math.min(lo.Z,q.Z))
   hi=Vector3.new(math.max(hi.X,q.X),math.max(hi.Y,q.Y),math.max(hi.Z,q.Z))
  end end end
 end end
 assert(lo.X<math.huge,"Empty imported geometry")return lo,hi
end
local function normalize(model,origin)
 model.PrimaryPart=nil
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then p.CFrame=CFrame.new(-origin)*p.CFrame end end
 model.WorldPivot=CFrame.identity
end
local function sanitize(model)
 local removed=0
 for _,d in ipairs(model:GetDescendants())do
  for _,tag in ipairs(game:GetService("CollectionService"):GetTags(d))do game:GetService("CollectionService"):RemoveTag(d,tag)end
  if not(d:IsA("Model")or d:IsA("Folder")or d:IsA("BasePart")or d:IsA("DataModelMesh")or d:IsA("SurfaceAppearance")or d:IsA("Decal")or d:IsA("Texture"))then
   removed+=1 d:Destroy()
  elseif d:IsA("BasePart")then
   d.Anchored=true d.CanTouch=false d.AssemblyLinearVelocity=Vector3.zero d.AssemblyAngularVelocity=Vector3.zero
  end
 end return removed
end
local function credit(model,spec)
 model:SetAttribute("SourceAssetId",spec.id)model:SetAttribute("SourceCreator",spec.author)
 model:SetAttribute("CreatorStoreURL","https://create.roblox.com/store/asset/"..spec.id)
end
local function load(spec)
 local ok,asset,done
 local thread=task.spawn(function()ok,asset=pcall(function()return game:GetService("AssetService"):LoadAssetAsync(spec.id)end)done=true end)
 local deadline=os.clock()+12 while not done and os.clock()<deadline do task.wait(.1)end
 if not done then task.cancel(thread)error("Creator Store load timed out: "..spec.id)end
 assert(ok,"Creator Store asset unavailable: "..spec.id..":"..tostring(asset))
 local model=Instance.new("Model")model.Name=spec.key
 local children=asset:GetChildren()
 -- Preserve the actual meshes, unions and textures; never run imported scripts.
 for _,d in ipairs(children)do
  if d:IsA("Tool")then for _,p in ipairs(d:GetChildren())do p.Parent=model end d:Destroy()
  else d.Parent=model end
 end
 asset:Destroy()local removed=sanitize(model)credit(model,spec)
 return model,removed
end
local function part(parent,name,size,cf,color,material,collide,alpha)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.WoodPlanks
 p.Anchored=true p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.Transparency=alpha or 0 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function prompt(parent,name,action,object,distance)
 local p=Instance.new("ProximityPrompt")p.Name=name p.ActionText=action p.ObjectText=object p.MaxActivationDistance=distance or 12
 p.RequiresLineOfSight=false p.HoldDuration=.2 p.KeyboardKeyCode=Enum.KeyCode.E p.Parent=parent return p
end
local function toolFrom(model,name,handleName,item)
 local t=Instance.new("Tool")t.Name=name t.CanBeDropped=false t.RequiresHandle=true t:SetAttribute("SerenaItem",item)
 t:SetAttribute("SourceAssetId",model:GetAttribute("SourceAssetId"))t:SetAttribute("SourceCreator",model:GetAttribute("SourceCreator"))
 local pieces={}for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then table.insert(pieces,p)end end
 local handle
 for _,p in ipairs(pieces)do if p.Name==handleName then handle=p break end end
 handle=handle or pieces[1]assert(handle,"Tool has no imported handle")
 local rest=handle.CFrame
 for _,p in ipairs(pieces)do
  p.CFrame=rest:ToObjectSpace(p.CFrame)p.Anchored=false p.Massless=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
  if p~=handle and p.Name=="Handle"then p.Name="DetalheDoItem"end
  p.Parent=t
 end
 handle.Name="Handle"
 for _,p in ipairs(pieces)do if p~=handle then
  local weld=Instance.new("WeldConstraint")weld.Part0=handle weld.Part1=p weld.Parent=handle
 end end
 model:Destroy()return t
end
function Assets.install(world)
 local imported={}local audit={assets={},removedRuntimeObjects=0}
 -- Import everything successfully before replacing any live scenery.
 for _,spec in ipairs(ASSETS)do
  local m,removed=load(spec)imported[spec.key]=m audit.removedRuntimeObjects+=removed
  table.insert(audit.assets,{id=spec.id,creator=spec.author,title=spec.title})
 end
 local Storage=game.ServerStorage local items=Storage:FindFirstChild("SerenaItems")
 local runtime=game.ReplicatedStorage.SerenaRuntime
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)
  local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-300,0),ray)assert(hit,"Missing terrain footing")return hit.Position.Y
 end
 -- The apple is a real Creator Store mesh in the shop, backpack and display basket.
 do
  local m=imported.Apple local lo,hi=bounds(m)normalize(m,(lo+hi)/2)m:ScaleTo(1.15/(hi-lo).Y)
  local preview=m:Clone()preview.Name="ApplePreview"
  for _,p in ipairs(preview:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false p.CanTouch=false p.CanQuery=false end end
  local old=runtime:FindFirstChild("ApplePreview")if old then old:Destroy()end preview.Parent=runtime
  local t=toolFrom(m,"Maçã da Névoa",nil,"Apple")t.Grip=CFrame.new(0,-.1,0)
  local oldTool=items:FindFirstChild(t.Name)if oldTool then oldTool:Destroy()end t.Parent=items
  local displays={}
  for _,p in ipairs(world.VilaCosteira.FeiraDeFrutas:GetDescendants())do if p:IsA("Model")and p.Name=="MaçãNaFeira"then table.insert(displays,p)end end
  for _,oldApple in ipairs(displays)do
   local cf=oldApple:GetPivot()local clone=preview:Clone()clone.Name="MaçãNaFeira"clone:ScaleTo(preview:GetScale()*.48)clone:PivotTo(cf)
   oldApple:Destroy()clone.Parent=world.VilaCosteira.FeiraDeFrutas
  end
 end
 -- Imported cottage architecture replaces all seven house shells; retain their useful furnishings.
 do
  local m=imported.House local core=m:FindFirstChildOfClass("Model")assert(core,"Cottage structure missing")
  local exterior=core:FindFirstChild("Outdoors")if exterior then exterior:Destroy()end
  local sourceOrigin=Vector3.new(166.235,8.36,87.88)
  local door=core:FindFirstChild("Door")assert(door,"Cottage door missing")
  local moving=Instance.new("Model")moving.Name="PortaMovel"moving.Parent=core
  local hinge=Vector3.new(172.35,8.36,78.88)
  for _,p in ipairs(door:GetDescendants())do if p:IsA("BasePart")then
   if not(p.Size.Y>7.5 or p.Position.Y>16.3)then p.Parent=moving p.CanCollide=false p.CanQuery=false end
  end end
  normalize(m,sourceOrigin)
  moving.WorldPivot=CFrame.new(hinge-sourceOrigin)
  local scale=.85 m:ScaleTo(scale)
  local doorLocal=(Vector3.new(173.85,8.36,78.7425)-sourceOrigin)*scale
  local locations={{"CasaDaPraça",66,60,0},{"Ateliê",107,51,0},{"CasaAzul",149,61,0},{"CaféDoMar",161,111,270},{"CasaDoJardim",149,151,180},{"CasaDaVaranda",64,149,180},{"Biblioteca",47,110,90}}
  local palettes={Color3.fromRGB(223,214,191),Color3.fromRGB(197,213,201),Color3.fromRGB(186,211,225),Color3.fromRGB(224,197,176),Color3.fromRGB(209,202,219),Color3.fromRGB(214,218,192),Color3.fromRGB(230,219,191)}
  for i,row in ipairs(locations)do
   local name,x,z,yaw=table.unpack(row)local old=world.VilaCosteira:FindFirstChild(name)assert(old,"Original house missing")
   local floor=ground(x,z)+.35 local oldCF=CFrame.new(x,floor,z)*CFrame.Angles(0,math.rad(yaw),0)
   local entrance=oldCF:PointToWorldSpace(Vector3.new(0,0,12))
   local rotation=CFrame.Angles(0,math.rad(yaw+180),0)
   local cf=CFrame.new(entrance-rotation:VectorToWorldSpace(doorLocal))*rotation
   local clone=m:Clone()clone.Name=name clone.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   clone:PivotTo(cf)clone:SetAttribute("EntranceCF",CFrame.new(entrance)*CFrame.Angles(0,math.rad(yaw),0))clone:SetAttribute("SerenaHouse",true)
   local inside=Instance.new("Folder")inside.Name="Mobiliario"inside.Parent=clone
   for _,p in ipairs(old:GetChildren())do
    if p:IsA("BasePart")and(p.Name=="Mesa"or p.Name=="Banco"or p.Name=="Encosto"or p.Name=="Pé"or p.Name=="Livro"or p.Name=="Prateleira")then p.Parent=inside end
   end
   for _,p in ipairs(clone:GetDescendants())do if p:IsA("BasePart")then
    p.Anchored=true p.CanTouch=false
    if p:IsDescendantOf(clone:FindFirstChild("PortaMovel",true))then p.CanCollide=false p.CanQuery=false
    elseif p.Size.Y<.16 or p.Transparency>.3 then p.CanCollide=false p.CanQuery=false
    else p.CanQuery=p.CanCollide end
    -- Tint the plaster; preserve the original roof, woodwork, texture and brick details.
    if p.Material==Enum.Material.SmoothPlastic and p.Color.R>.7 and p.Color.G>.65 and p.Color.B>.55 and p.Transparency==0 then p.Color=palettes[i]end
   end end
   local movable=clone:FindFirstChild("PortaMovel",true)
   game:GetService("CollectionService"):AddTag(movable,"SerenaAutomaticDoor")
   movable:SetAttribute("DoorHingeCF",movable:GetPivot())
   for _,p in ipairs(movable:GetDescendants())do if p:IsA("BasePart")then p:SetAttribute("DoorRestCF",p.CFrame)end end
   old:Destroy()clone.Parent=world.VilaCosteira
  end m:Destroy()audit.houses=#locations
 end
 -- Real oak meshes replace spherical crowns. Every trunk uses the measured terrain surface.
 do
  local m=imported.Oak local lo,hi=bounds(m)
  local trunk=m:FindFirstChild("Trunk",true)assert(trunk,"Oak trunk missing")
  local origin=Vector3.new(trunk.Position.X,lo.Y,trunk.Position.Z)normalize(m,origin)
  local sourceHeight=(hi-lo).Y local originals={}
  for _,old in ipairs(world.Bosque:GetChildren())do if old:IsA("Model")and old.Name=="Árvore"then table.insert(originals,old)end end
  local rng=Random.new(9421311218)
  for _,old in ipairs(originals)do
   local root=old:GetAttribute("SerenaRootCF")assert(root,"Original tree root missing")local x,z=root.X,root.Z
   local y=ground(x,z)local baseY=y
   for _,offset in ipairs({Vector2.new(-2,0),Vector2.new(2,0),Vector2.new(0,-2),Vector2.new(0,2)})do baseY=math.min(baseY,ground(x+offset.X,z+offset.Y))end
   local _,size=old:GetBoundingBox()local height=math.clamp(size.Y*1.05,17,25)
   local clone=m:Clone()clone.Name="Árvore"clone:ScaleTo(height/sourceHeight)
   clone:PivotTo(CFrame.new(x,baseY-.35,z)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0))clone.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   clone:SetAttribute("SerenaRootCF",CFrame.new(x,y,z))clone:SetAttribute("SerenaRootDepth",y-baseY+.35)
   for _,p in ipairs(clone:GetDescendants())do if p:IsA("BasePart")then
    p.CanCollide=false p.CanTouch=false p.CanQuery=false
    if p.Name=="Leaves"then p:SetAttribute("SerenaRestCF",p.CFrame)p:SetAttribute("WindStrength",.45)game:GetService("CollectionService"):AddTag(p,"SerenaWindFoliage")end
   end end
   part(clone,"ColisaoDoTronco",Vector3.new(1.2,height*.44,1.2),CFrame.new(x,y+height*.22-.25,z),Color3.fromRGB(88,67,45),Enum.Material.Wood,true,1)
   old:Destroy()clone.Parent=world.Bosque
  end m:Destroy()audit.oaks=#originals
 end
 -- Real streetlights retain the island's lamp locations and personal night/day behavior.
 do
  local m=imported.Lamp local lo,hi=bounds(m)normalize(m,Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2))m:ScaleTo(10.5/(hi.Y-lo.Y))
  local poles={}for _,d in ipairs(world:GetDescendants())do if d:IsA("BasePart")and d.Name=="Poste"then table.insert(poles,d)end end
  for _,pole in ipairs(poles)do
   local parent=pole.Parent local base=pole.Position-Vector3.new(0,pole.Size.Y/2,0)
   local targetBase=parent==world.PraiaEPier and Vector3.new(96.5,6.845,346)or base
   for _,p in ipairs(parent:GetChildren())do if p:IsA("BasePart")and(p.Name=="Lanterna"or p.Name=="Cobertura")and(p.Position-Vector3.new(base.X,p.Position.Y,base.Z)).Magnitude<.1 then p:Destroy()end end
   local clone=m:Clone()clone.Name="PosteImportado"clone:PivotTo(CFrame.new(targetBase-Vector3.new(0,.12,0)))clone.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for _,p in ipairs(clone:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false p.CanQuery=false p.CanTouch=false end end
   local bulb=clone:FindFirstChild("bulb",true)assert(bulb,"Imported bulb missing")
   local light=Instance.new("PointLight")light.Name="LuzDaIlha"light.Range=21 light.Brightness=1.3 light.Color=Color3.fromRGB(255,219,170)light.Enabled=false light.Shadows=false light.Parent=bulb
   pole:Destroy()clone.Parent=parent
  end m:Destroy()audit.lamps=#poles
 end
 -- Three copies of the creator's timber dock form the continuous promenade.
 local coast=world.PraiaEPier
 local remove={PranchaDoPier=true,EstacaDoPier=true,["Corrimão"]=true,DeckDoPier=true,RampaDoPier=true,VigaDoPier=true,EstacaDeck=true,PosteDeck=true,["CorrimãoDeck"]=true,PosteFundoDeck=true,["CorrimãoFundoDeck"]=true,DegrauDoPier=true,FundoDoBarco=true,LateralDoBarco=true,BancoDoBarco=true,["CordaDeAmarração"]=true}
 for _,d in ipairs(coast:GetChildren())do if d:IsA("BasePart")and remove[d.Name]then d:Destroy()end end
 for _,d in ipairs(coast:GetChildren())do if d:IsA("BasePart")and(d.Name=="Banco"or d.Name=="Encosto"or d.Name=="Pé")and d.Position.Z>325 then d:Destroy()end end
 local pier=Instance.new("Model")pier.Name="PierDeMadeira"pier:SetAttribute("SourceAssetId",17010090897)pier:SetAttribute("SourceCreator","sSkyI4r")pier.Parent=coast
 do
  local pack=imported.Dock local dock=pack:FindFirstChild("Dock1",true)assert(dock and dock:IsA("Model"),"Real dock variant missing")
  dock.Parent=nil pack:Destroy()credit(dock,ASSETS[5])
  local lo,hi=bounds(dock)local origin=Vector3.new((lo.X+hi.X)/2,22.35,(lo.Z+hi.Z)/2)
  normalize(dock,origin)dock:ScaleTo(.72)
  local length=(hi.X-lo.X)*.72
  for i=1,3 do
   local clone=dock:Clone()clone.Name="TrechoDeMadeira"clone:PivotTo(CFrame.new(100,6.4,286+length*(i-.5))*CFrame.Angles(0,math.pi/2,0))
   for _,p in ipairs(clone:GetDescendants())do if p:IsA("BasePart")then
    p.CanCollide=false p.CanQuery=false p.CanTouch=false
    if p:IsA("MeshPart")and p.Name=="RoundedCube"then
     local _,yaw=p.CFrame:ToOrientation()p.CFrame=CFrame.new(p.Position.X,6.875-p.Size.Y/2,p.Position.Z)*CFrame.Angles(0,yaw,0)
    end
    if p.ClassName=="Part"and p.Size.Y>10 then
     local top=p.Position.Y+p.Size.Y/2 local bottom=ground(p.Position.X,p.Position.Z)-.6
     p.Size=Vector3.new(p.Size.X,math.max(1,top-bottom),p.Size.Z)p.Position=Vector3.new(p.Position.X,(top+bottom)/2,p.Position.Z)
    end
   end end
   clone.Parent=pier
  end dock:Destroy()
  local endZ=286+length*3 pier:SetAttribute("PierEndZ",endZ)
  part(pier,"PisoContinuo",Vector3.new(9.4,.35,endZ-285.2),CFrame.new(100,6.67,(endZ+285.2)/2),Color3.fromRGB(114,81,58),Enum.Material.WoodPlanks,true,1)
  local startZ,finishZ=255,286.1 local startY=ground(100,startZ)+.04
  local function approachY(z)
   local t=(z-startZ)/(finishZ-startZ)
   return math.max(ground(100,z)+.04,startY+(6.845-startY)*t)
  end
  for z=startZ,finishZ-1.4,1.4 do
   local nextZ=math.min(finishZ,z+1.4)
   local a=Vector3.new(100,approachY(z),z)local b=Vector3.new(100,approachY(nextZ),nextZ)
   local cf=CFrame.lookAt((a+b)/2,b)
   part(pier,"AcessoDaPraia",Vector3.new(9.4,.4,(b-a).Magnitude+.04),cf-cf.UpVector*.2,Color3.fromRGB(124,90,66),Enum.Material.WoodPlanks,true)
  end
  local rack=part(pier,"SuporteDasVaras",Vector3.new(1.1,3.8,1.1),CFrame.new(96.2,8.5,316),Color3.fromRGB(101,76,54),Enum.Material.Wood,false)
  prompt(rack,"RodPrompt","Pegar vara","Pescaria • vara grátis",12)
  local market=part(pier,"BalcaoDaPesca",Vector3.new(2.2,2.6,2.4),CFrame.new(103.1,8.16,316),Color3.fromRGB(140,104,74),Enum.Material.WoodPlanks,true)
  prompt(market,"SellPrompt","Vender peixes","Peixaria • moedas da ilha",12)
  local landing=part(pier,"Embarque",Vector3.new(.6,2.1,.6),CFrame.new(104.1,7.7,347),Color3.fromRGB(204,172,112),Enum.Material.Metal,false)
  prompt(landing,"BoardPrompt","Embarcar","Barco de madeira",12)
  audit.pierEndZ=endZ
 end
 -- Actual rowing boat geometry, with reliable fixed seats and controlled water navigation.
 do
  local m=imported.Boat local lo,hi=bounds(m)normalize(m,(lo+hi)/2)m:ScaleTo(1.45)m.Name="BarcoDePesca"
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false p.CanQuery=false p.CanTouch=false end end
  part(m,"PisoDoBarco",Vector3.new(3.8,.3,9.4),CFrame.new(0,-.45,.1),Color3.fromRGB(103,76,55),Enum.Material.Wood,true,1)
  local driver=Instance.new("VehicleSeat")driver.Name="DriverSeat"driver.Size=Vector3.new(1.7,.28,1.25)driver.CFrame=CFrame.new(0,.27,4.8)
  driver.Anchored=true driver.CanCollide=false driver.CanTouch=true driver.CanQuery=false driver.Transparency=1 driver.HeadsUpDisplay=false driver.Parent=m
  driver:SetAttribute("SerenaBoatSeat",true)prompt(driver,"BoardPrompt","Conduzir","Barco • teclado ou controles na tela",12)
  local passenger=Instance.new("Seat")passenger.Name="PassengerSeat"passenger.Size=Vector3.new(1.6,.28,1.15)passenger.CFrame=CFrame.new(0,.23,-3.25)
  passenger.Anchored=true passenger.CanCollide=false passenger.CanTouch=true passenger.CanQuery=false passenger.Transparency=1 passenger.Parent=m
  passenger:SetAttribute("SerenaBoatSeat",true)prompt(passenger,"PassengerPrompt","Sentar","Passageiro • pesca no barco",12)
  local home=CFrame.new(113.5,.9,348)*CFrame.Angles(0,math.pi,0)m:PivotTo(home)m:SetAttribute("BoatHome",home)m:SetAttribute("BoatSpeed",0)
  m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=coast
 end
 -- Functional fishing tools retain the creator's meshes and are never anchored to the avatar.
 do
  local m=imported.Rod local grip=m:FindFirstChild("Grip",true)assert(grip and grip:IsA("BasePart"),"Fishing grip missing")
  local lo,hi=bounds(m)normalize(m,Vector3.new(grip.Position.X,lo.Y,grip.Position.Z))m:ScaleTo(.85)
  for _,name in ipairs({"Hook","Line"})do local deadLine=m:FindFirstChild(name,true)if deadLine then deadLine:Destroy()end end
  local t=toolFrom(m,"Vara de Pesca","Grip","FishingRod")t.Grip=CFrame.new(0,-.3,-.1)*CFrame.Angles(math.rad(-20),0,0)
  local tip=Instance.new("Attachment")tip.Name="LineTip"tip.Position=Vector3.new(0,7.42,.05)tip.Parent=t.Handle
  local old=items:FindFirstChild(t.Name)if old then old:Destroy()end t.Parent=items
  local display=t:Clone()display.Name="VaraNoPier"
  local showcase=Instance.new("Model")showcase.Name="VarasDePesca"showcase.Parent=pier
  for _,p in ipairs(display:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.Parent=showcase end end
  display:Destroy()showcase.WorldPivot=CFrame.identity showcase:PivotTo(CFrame.new(96.2,8.2,316)*CFrame.Angles(0,0,math.rad(-12)))
 end
 do
  local m=imported.Fish local lo,hi=bounds(m)normalize(m,(lo+hi)/2)m:ScaleTo(2.4/(hi.X-lo.X))
  local t=toolFrom(m,"Carpa",nil,"Fish")t.Grip=CFrame.new(0,-.1,0)*CFrame.Angles(0,0,math.rad(90))
  local old=items:FindFirstChild(t.Name)if old then old:Destroy()end t.Parent=items
 end
 world:SetAttribute("RealCreatorStoreAssets",true)world:SetAttribute("FishingEnabled",true)
 return audit
end
return Assets
]========]).install(world)

local interiors=module([========[local Interiors={}
local function load(id)
 local m=game:GetService("AssetService"):LoadAssetAsync(id)
 for _,d in ipairs(m:GetDescendants())do
  if not(d:IsA("Model")or d:IsA("Folder")or d:IsA("BasePart")or d:IsA("DataModelMesh")or d:IsA("Decal")or d:IsA("Texture")or d:IsA("SurfaceAppearance")or d:IsA("Fire")or d:IsA("Smoke")or d:IsA("Light"))then d:Destroy()
  elseif d:IsA("BasePart")then d.Anchored=true d.CanTouch=d:IsA("Seat")
  elseif d:IsA("Light")then d:SetAttribute("AlwaysOn",true)end
 end return m
end
local function normalize(m,origin)
 m.PrimaryPart=nil for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.CFrame=CFrame.new(-origin)*p.CFrame end end m.WorldPivot=CFrame.identity
end
local function bounds(m)
 local lo=Vector3.new(math.huge,math.huge,math.huge)local hi=-lo
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)
   lo=Vector3.new(math.min(lo.X,q.X),math.min(lo.Y,q.Y),math.min(lo.Z,q.Z))hi=Vector3.new(math.max(hi.X,q.X),math.max(hi.Y,q.Y),math.max(hi.Z,q.Z))
  end end end
 end end return lo,hi
end
function Interiors.install(world)
 local cabin=load(2109355142)local furniture=load(6319697240)
 local origin=Vector3.new(177.862457,9.725692,-27.714706)
 local panel
 for _,p in ipairs(cabin:GetDescendants())do if p:IsA("BasePart")and math.abs(p.Position.X-188.06157)<.02 and math.abs(p.Position.Z+33.6899)<.02 and p.Size.Z>7 then panel=p break end end
 assert(panel,"Furnished cabin door not identified")
 local door=panel.Parent assert(door:IsA("Model"),"Door assembly missing")door.Name="PortaMovel"
 normalize(cabin,origin)
 local hinge=(Vector3.new(188.06,9.725692,-30.29)-origin)
 door.WorldPivot=CFrame.new(hinge)
 local scale=.82 cabin:ScaleTo(scale)
 local doorLocal=(Vector3.new(188.06157,9.725692,-33.6899)-origin)*scale
 local swapped={["Ateliê"]=true,Biblioteca=true,CasaDoJardim=true,CasaDaVaranda=true}
 local count=0
 for _,old in ipairs(world.VilaCosteira:GetChildren())do if old:IsA("Model")and swapped[old.Name]then
  local entry=old:GetAttribute("EntranceCF")local _,yaw=entry:ToOrientation()
  local rotation=CFrame.Angles(0,yaw-math.pi/2,0)
  local cf=CFrame.new(entry.Position-rotation:VectorToWorldSpace(doorLocal))*rotation
  local m=cabin:Clone()m.Name=old.Name m:PivotTo(cf)m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  m:SetAttribute("SourceAssetId",2109355142)m:SetAttribute("SourceCreator","visionpsyche7")m:SetAttribute("CreatorStoreURL","https://create.roblox.com/store/asset/2109355142")
  m:SetAttribute("SerenaHouse",true)m:SetAttribute("Furnished",true)m:SetAttribute("EntranceCF",entry)
  local move=m:FindFirstChild("PortaMovel",true)assert(move)
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
   p.Anchored=true p.CanTouch=p:IsA("Seat")
   if p:IsDescendantOf(move)then p.CanCollide=false p.CanQuery=false p:SetAttribute("DoorRestCF",p.CFrame)
   elseif p.Transparency>.4 then p.CanCollide=false p.CanQuery=false end
  end end
  move:SetAttribute("DoorHingeCF",move:GetPivot())game:GetService("CollectionService"):AddTag(move,"SerenaAutomaticDoor")
  old:Destroy()m.Parent=world.VilaCosteira count+=1
 end end
 cabin:Destroy()
 -- Other cottages receive real beds, sofas and dining furniture from a ready interior model.
 local items={}
 for _,d in ipairs(furniture:GetDescendants())do if d:IsA("Model")then
  if d.Name=="Couch Loveseat Sofa"and not items.Sofa then items.Sofa=d
  elseif d.Name=="Bed"and not items.Bed then items.Bed=d
  elseif d.Name=="Dining Table"and not items.Table then items.Table=d
  elseif d.Name=="Chair"and not items.Chair then items.Chair=d end
 end end
 assert(items.Sofa and items.Bed and items.Table and items.Chair,"Ready interior props missing")
 local templates={}
 for key,model in pairs(items)do
  local clone=model:Clone()local lo,hi=bounds(clone)normalize(clone,Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2))
  clone:ScaleTo(key=="Sofa"and .8 or .65)templates[key]=clone
 end
 local furnishedCottages=0
 for _,home in ipairs(world.VilaCosteira:GetChildren())do if home:IsA("Model")and home:GetAttribute("SourceAssetId")==12346232595 then
  local old=home:FindFirstChild("Mobiliario")if old then old:Destroy()end
  local group=Instance.new("Model")group.Name="InteriorDaLoja"group:SetAttribute("SourceAssetId",6319697240)group:SetAttribute("SourceCreator","BIond_e")group.Parent=home
  local cf=home:GetPivot()
  for _,row in ipairs({{"Bed",-5,0,-4.2,0},{"Sofa",-5,0,3.6,180},{"Table",6.2,0,2.4,0},{"Chair",3.3,0,2.3,90},{"Chair",9.1,0,2.3,270}})do
   local clone=templates[row[1]]:Clone()clone.Name=row[1]clone:PivotTo(cf*CFrame.new(row[2],row[3],row[4])*CFrame.Angles(0,math.rad(row[5]),0))clone.Parent=group
   for _,p in ipairs(clone:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=p:IsA("Seat")if p.Transparency>.4 then p.CanCollide=false p.CanQuery=false end end end
  end
  home:SetAttribute("Furnished",true)home:SetAttribute("InteriorAssetId",6319697240)furnishedCottages+=1
 end end
 for _,model in pairs(templates)do model:Destroy()end furniture:Destroy()
 return {readyFurnishedCabins=count,cottagesWithStoreInterior=furnishedCottages,assets={{id=2109355142,creator="visionpsyche7"},{id=6319697240,creator="BIond_e"}}}
end
return Interiors
]========]).install(world)

local grass=module([========[local Grass={Spacing=22,Scale=.32,Color=Color3.fromRGB(104,171,65)}
function Grass.install(world,runtime)
 local asset=game:GetService("AssetService"):LoadAssetAsync(87377915371959)
 local root=asset:FindFirstChild("SkinnedGrass")assert(root,"Exact SkinnedGrass package missing")
 local studio=root:FindFirstChild("Studio"):FindFirstChild("Models"):FindFirstChildOfClass("Model")assert(studio,"Fine Studio grass missing")
 local templates=Instance.new("Folder")templates.Name="SkinnedGrassTemplates"templates:SetAttribute("SourceAssetId",87377915371959)templates.Parent=runtime
 local fine=studio:Clone()fine.Name="FineStudio"
 for _,d in ipairs(fine:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()end end
 local mesh=fine:FindFirstChildOfClass("MeshPart")assert(mesh and mesh.MeshId=="rbxassetid://80159239673273","Fine grass mesh changed")
 mesh.Anchored=true mesh.CanCollide=false mesh.CanQuery=false mesh.CanTouch=false mesh.CastShadow=false mesh.Color=Grass.Color
 mesh.CFrame=CFrame.identity fine.PrimaryPart=nil fine.WorldPivot=CFrame.identity fine:ScaleTo(Grass.Scale)
 fine:SetAttribute("SourceAssetId",87377915371959)fine:SetAttribute("SourceVariant","Studio")fine:SetAttribute("GrassFine",true)
 for _,d in ipairs(mesh:GetChildren())do if d:IsA("Decal")then d.Color3=Grass.Color end end
 fine.Parent=templates
 local card=root:FindFirstChild("GrassCard"):FindFirstChild("Models"):FindFirstChildOfClass("Model"):Clone()card.Name="AlternateGrassCard"card.Parent=templates
 for _,d in ipairs(card:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()end end
 asset:Destroy()
 local bones={}for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then table.insert(bones,b)end end
 table.sort(bones,function(a,b)return a.Name<b.Name end)assert(#bones==100,"Grass skeleton incomplete")
 local coverage=Instance.new("Folder")coverage.Name="GrassCoverage"coverage:SetAttribute("Spacing",Grass.Spacing)coverage:SetAttribute("SourceAssetId",87377915371959)coverage.Parent=runtime
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,world}ray.IgnoreWater=false
 local Http=game:GetService("HttpService")local count=0 local roots=0
 for x=-330,330,Grass.Spacing do for z=-330,330,Grass.Spacing do
  local anchor=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-280,0),ray)
  local y=anchor and anchor.Position.Y or 0 local points={}local valid=0
  for i,b in ipairs(bones)do
   local bx,bz=x+b.CFrame.X,z+b.CFrame.Z
   local hit=workspace:Raycast(Vector3.new(bx,180,bz),Vector3.new(0,-280,0),ray)
   if hit and hit.Instance==workspace.Terrain and hit.Material==Enum.Material.Grass and hit.Normal.Y>.64 then
    points[i]=math.floor(hit.Position.Y*100+.5)/100 valid+=1
   else points[i]=false end
  end
  if valid>0 then
   count+=1 roots+=valid local cell=Instance.new("Folder")cell.Name="Cell"..count cell:SetAttribute("Center",Vector3.new(x,y,z))cell:SetAttribute("Heights",Http:JSONEncode(points))cell:SetAttribute("GreenRoots",valid)cell.Parent=coverage
  end
 end end
 assert(count>100 and roots>10000,"Insufficient whole-island grass coverage")
 coverage:SetAttribute("PatchCount",count)coverage:SetAttribute("RootCount",roots)
 world:SetAttribute("SkinnedGrassAssetId",87377915371959)world:SetAttribute("GrassVariant","StudioFine")world:SetAttribute("GrassCoveragePatches",count)world:SetAttribute("GrassCoverageRoots",roots)
 world:SetAttribute("GrassColor",Grass.Color)world:SetAttribute("InteractiveGrass",true)world:SetAttribute("WholeMapGrass",true)
 workspace.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(90,142,64))
 return {assetId=87377915371959,variant="StudioFine",meshId=mesh.MeshId,patches=count,greenRoots=roots,bonesPerPatch=#bones,color={104,171,65},spacing=Grass.Spacing,wholeIsland=true}
end
return Grass
]========]).install(world,runtime)

local wind=folder(runtime,"WindEffects")wind:SetAttribute("SourceAssetId",11946229834)

source(wind,"ModuleScript","WindLines",[========[--[=[

WindShake- High performance wind effect for leaves and foliage
by: boatbomber, CloneTrooper1019

Docs: https://devforum.roblox.com/t/wind-shake-high-performance-wind-effect-for-leaves-and-foliage/1039806/1

--]=]

local RunService = game:GetService("RunService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local EMPTY_TABLE = {}
local OFFSET = Vector3.new(0,0.1,0)

local module = {}

module.UpdateQueue = table.create(10)

function module:Init(Settings)
	-- Set defaults
	module.Lifetime = Settings.Lifetime or 3
	module.Direction = Settings.Direction or Vector3.new(1,0,0)
	module.Speed = Settings.Speed or 6
	
	-- Clear any old stuff
	if module.UpdateConnection then
		module.UpdateConnection:Disconnect()
		module.UpdateConnection = nil
	end
	
	for _, WindLine in ipairs(module.UpdateQueue) do
		WindLine.Attachment0:Destroy()
		WindLine.Attachment1:Destroy()
		WindLine.Trail:Destroy()
	end
	table.clear(module.UpdateQueue)
	
	module.LastSpawned = os.clock()
	local SpawnRate = 1/(Settings.SpawnRate or 25)
	
	-- Setup logic loop
	module.UpdateConnection = RunService.Heartbeat:Connect(function()
		local Clock = os.clock()
		
		-- Spawn handler
		if Clock-module.LastSpawned > SpawnRate then
			module:Create()
			module.LastSpawned = Clock
		end
		
		-- Update queue handler
		debug.profilebegin("Wind Lines")
		for i, WindLine in ipairs(module.UpdateQueue) do
			
			local AliveTime = Clock-WindLine.StartClock
			if AliveTime >= WindLine.Lifetime then
				-- Destroy the objects
				WindLine.Attachment0:Destroy()
				WindLine.Attachment1:Destroy()
				WindLine.Trail:Destroy()
				
				-- unordered remove at this index
				local Length = #module.UpdateQueue
				module.UpdateQueue[i] = module.UpdateQueue[Length]
				module.UpdateQueue[Length] = nil
				
				continue
			end
			
			WindLine.Trail.MaxLength = 20 - (20*(AliveTime/WindLine.Lifetime))
			
			local SeededClock = (Clock+WindLine.Seed)*(WindLine.Speed*0.2)
			local StartPos = WindLine.Position
			WindLine.Attachment0.WorldPosition = (
				CFrame.new(StartPos, StartPos+WindLine.Direction) * CFrame.new(0,0,WindLine.Speed * -AliveTime)
			).Position + Vector3.new(math.sin(SeededClock)*0.5,math.sin(SeededClock)*0.8,math.sin(SeededClock)*0.5)
			
			WindLine.Attachment1.WorldPosition = WindLine.Attachment0.WorldPosition + OFFSET
			
		end
		debug.profileend()
	end)


end

function module:Cleanup()
	
	if module.UpdateConnection then
		module.UpdateConnection:Disconnect()
		module.UpdateConnection = nil
	end

	for _, WindLine in ipairs(module.UpdateQueue) do
		WindLine.Attachment0:Destroy()
		WindLine.Attachment1:Destroy()
		WindLine.Trail:Destroy()
	end
	table.clear(module.UpdateQueue)
	
end

function module:Create(Settings)
	debug.profilebegin("Add Wind Line")
	
	Settings = Settings or EMPTY_TABLE

	local Lifetime = Settings.Lifetime or module.Lifetime
	local Position = Settings.Position or (workspace.CurrentCamera.CFrame*CFrame.Angles(math.rad(math.random(-30,70)),math.rad(math.random(-80,80)),0))*CFrame.new(0,0,math.random(200,600)*-0.1).Position
	local Direction = Settings.Direction or module.Direction
	local Speed = Settings.Speed or module.Speed
	if Speed <= 0 then return end

	local Attachment0 = Instance.new("Attachment")
	local Attachment1 = Instance.new("Attachment")
	
	local Trail = Instance.new("Trail")
	Trail.Attachment0 = Attachment0
	Trail.Attachment1 = Attachment1
	Trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0,0.3),
		NumberSequenceKeypoint.new(0.2,1),
		NumberSequenceKeypoint.new(0.8,1),
		NumberSequenceKeypoint.new(1,0.3),
	})
	Trail.Transparency = NumberSequence.new(0.7)
	Trail.FaceCamera = true
	Trail.Parent = Attachment0

	Attachment0.WorldPosition = Position
	Attachment1.WorldPosition = Position+OFFSET
	
	local WindLine = {
		Attachment0 = Attachment0;
		Attachment1 = Attachment1;
		Trail = Trail;
		Lifetime = Lifetime+(math.random(-10,10)*0.1);
		Position = Position;
		Direction = Direction;
		Speed = Speed+(math.random(-10,10)*0.1);
		StartClock = os.clock();
		Seed = math.random(1,1000)*0.1;
	}
	
	module.UpdateQueue[#module.UpdateQueue+1] = WindLine

	Attachment0.Parent = Terrain
	Attachment1.Parent = Terrain
	
	debug.profileend()
end

return module
]========])

local shake=source(wind,"ModuleScript","WindShake",[========[--[=[

WindShake- High performance wind effect for leaves and foliage
by: boatbomber, CloneTrooper1019

Docs: https://devforum.roblox.com/t/wind-shake-high-performance-wind-effect-for-leaves-and-foliage/1039806/1

--]=]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Settings = require(script.Settings)
local Octree = require(script.Octree)

local COLLECTION_TAG = "WindShake" -- The CollectionService tag to be watched and mounted automatically
local UPDATE_HZ = 1/45 -- Update the object positions at 45 Hz.
local COMPUTE_HZ = 1/30 -- Compute the object targets at 30 Hz.

-- Use the script's attributes as the default settings.
-- The table provided is a fallback if the attributes
-- are undefined or using the wrong value types.

local DEFAULT_SETTINGS = Settings.new(script, {
	WindDirection = Vector3.new(0.5, 0, 0.5);
	WindSpeed = 20;
	WindPower = 0.5;
})

-----------------------------------------------------------------------------------------------------------------

local ObjectShakeAddedEvent = Instance.new("BindableEvent")
local ObjectShakeRemovedEvent = Instance.new("BindableEvent")
local ObjectShakeUpdatedEvent = Instance.new("BindableEvent")
local PausedEvent = Instance.new("BindableEvent")
local ResumedEvent = Instance.new("BindableEvent")

local WindShake = {
	ObjectMetadata = {};
	Octree = Octree.new();

	Handled = 0;
	Active = 0;
	LastUpdate = os.clock();

	ObjectShakeAdded = ObjectShakeAddedEvent.Event;
	ObjectShakeRemoved = ObjectShakeRemovedEvent.Event;
	ObjectShakeUpdated = ObjectShakeUpdatedEvent.Event;
	Paused = PausedEvent.Event;
	Resumed = ResumedEvent.Event;

}

export type WindShakeSettings = {
	WindDirection: Vector3?,
	WindSpeed: number?,
	WindPower: number?,
}

function WindShake:Connect(funcName: string, event: RBXScriptSignal): RBXScriptConnection
	local callback = self[funcName]
	assert(typeof(callback) == "function", "Unknown function: " .. funcName)

	return event:Connect(function (...)
		return callback(self, ...)
	end)
end

function WindShake:AddObjectShake(object: BasePart, settingsTable: WindShakeSettings?)
	if typeof(object) ~= "Instance" then
		return
	end

	if not object:IsA("BasePart") then
		return
	end

	local metadata = self.ObjectMetadata

	if metadata[object] then
		return
	else
		self.Handled += 1
	end

	metadata[object] = {
		Node = self.Octree:CreateNode(object.Position, object);
		Settings = Settings.new(object, DEFAULT_SETTINGS);

		Seed = math.random(1000) * 0.1;
		Origin = object.CFrame;
	}

	self:UpdateObjectSettings(object, settingsTable)

	ObjectShakeAddedEvent:Fire(object)
end

function WindShake:RemoveObjectShake(object: BasePart)
	if typeof(object) ~= "Instance" then
		return
	end

	local metadata = self.ObjectMetadata
	local objMeta = metadata[object]

	if objMeta then
		self.Handled -= 1
		metadata[object] = nil
		objMeta.Settings:Destroy()
		objMeta.Node:Destroy()

		if object:IsA("BasePart") then
			object.CFrame = objMeta.Origin
		end
	end

	ObjectShakeRemovedEvent:Fire(object)
end

function WindShake:Update()
	local now = os.clock()
	local dt = now - self.LastUpdate

	if dt < UPDATE_HZ then
		return
	end

	self.LastUpdate = now

	debug.profilebegin("WindShake")

	local camera = workspace.CurrentCamera
	if not camera then return end
	local cameraCF = camera.CFrame

	debug.profilebegin("Octree Search")
	local updateObjects = self.Octree:RadiusSearch(cameraCF.Position + (cameraCF.LookVector * 115), 120)
	debug.profileend()

	local activeCount = #updateObjects

	self.Active = activeCount

	if activeCount < 1 then
		return
	end

	local step = math.min(1, dt * 8)
	local cfTable = table.create(activeCount)
	local objectMetadata = self.ObjectMetadata

	debug.profilebegin("Calc")
	for i, object in ipairs(updateObjects) do
		local objMeta = objectMetadata[object]
		local lastComp = objMeta.LastCompute or 0

		local origin = objMeta.Origin
		local current = objMeta.CFrame or origin

		if (now - lastComp) > COMPUTE_HZ then
			local objSettings = objMeta.Settings

			local seed = objMeta.Seed
			local amp = objSettings.WindPower * 0.1

			local freq = now * (objSettings.WindSpeed * 0.08)
			local rotX = math.noise(freq, 0, seed) * amp
			local rotY = math.noise(freq, 0, -seed) * amp
			local rotZ = math.noise(freq, 0, seed+seed) * amp
			local offset = object.PivotOffset
			local worldpivot = origin * offset

			objMeta.Target = (worldpivot * CFrame.Angles(rotX, rotY, rotZ) + objSettings.WindDirection * ((0.5 + math.noise(freq, seed, seed)) * amp)) * offset:Inverse()

			objMeta.LastCompute = now
		end

		current = current:Lerp(objMeta.Target, step)
		objMeta.CFrame = current
		cfTable[i] = current
	end
	debug.profileend()

	workspace:BulkMoveTo(updateObjects, cfTable, Enum.BulkMoveMode.FireCFrameChanged)
	debug.profileend()
end

function WindShake:Pause()
	if self.UpdateConnection then
		self.UpdateConnection:Disconnect()
		self.UpdateConnection = nil
	end

	self.Active = 0
	self.Running = false

	PausedEvent:Fire()
end

function WindShake:Resume()
	if self.Running then
		return
	else
		self.Running = true
	end

	-- Connect updater
	self.UpdateConnection = self:Connect("Update", RunService.Heartbeat)

	ResumedEvent:Fire()
end

function WindShake:Init()
	if self.Initialized then
		return
	else
		self.Initialized = true
	end

	-- Define attributes if they're undefined.
	local power = script:GetAttribute("WindPower")
	local speed = script:GetAttribute("WindSpeed")
	local direction = script:GetAttribute("WindDirection")

	if typeof(power) ~= "number" then
		script:SetAttribute("WindPower", DEFAULT_SETTINGS.WindPower)
	end

	if typeof(speed) ~= "number" then
		script:SetAttribute("WindSpeed", DEFAULT_SETTINGS.WindSpeed)
	end

	if typeof(direction) ~= "Vector3" then
		script:SetAttribute("WindDirection", DEFAULT_SETTINGS.WindDirection)
	end

	-- Clear any old stuff.
	self:Cleanup()
	self.Initialized = true

	-- Wire up tag listeners.
	local windShakeAdded = CollectionService:GetInstanceAddedSignal(COLLECTION_TAG)
	self.AddedConnection = self:Connect("AddObjectShake", windShakeAdded)

	local windShakeRemoved = CollectionService:GetInstanceRemovedSignal(COLLECTION_TAG)
	self.RemovedConnection = self:Connect("RemoveObjectShake", windShakeRemoved)

	for _,object in pairs(CollectionService:GetTagged(COLLECTION_TAG)) do
		self:AddObjectShake(object)
	end

	-- Automatically start.
	self:Resume()
end

function WindShake:Cleanup()
	if not self.Initialized then
		return
	end

	self:Pause()

	if self.AddedConnection then
		self.AddedConnection:Disconnect()
		self.AddedConnection = nil
	end

	if self.RemovedConnection then
		self.RemovedConnection:Disconnect()
		self.RemovedConnection = nil
	end

	for object in pairs(self.ObjectMetadata)do self:RemoveObjectShake(object)end
	table.clear(self.ObjectMetadata)
	self.Octree:ClearNodes()

	self.Handled = 0
	self.Active = 0
	self.Initialized = false
end

function WindShake:UpdateObjectSettings(object: Instance, settingsTable: WindShakeSettings)
	if typeof(object) ~= "Instance" then
		return
	end

	if typeof(settingsTable) ~= "table" then
		return
	end

	if (not self.ObjectMetadata[object]) and (object ~= script) then
		return
	end

	for key, value in pairs(settingsTable) do
		object:SetAttribute(key, value)
	end

	ObjectShakeUpdatedEvent:Fire(object)
end

function WindShake:UpdateAllObjectSettings(settingsTable: WindShakeSettings)
	if typeof(settingsTable) ~= "table" then
		return
	end

	for obj, objMeta in pairs(self.ObjectMetadata) do
		for key, value in pairs(settingsTable) do
			obj:SetAttribute(key, value)
		end
		ObjectShakeUpdatedEvent:Fire(obj)
	end
end

function WindShake:SetDefaultSettings(settingsTable: WindShakeSettings)
	self:UpdateObjectSettings(script, settingsTable)
end

return WindShake]========])

source(shake,"ModuleScript","Settings",[========[local Settings = {}

local SettingTypes = {
	WindPower = "number";
	WindSpeed = "number";
	WindDirection = "Vector3";
}

function Settings.new(object, base)
	local inst = table.create(3)

	-- Initial settings

	local WindPower = object:GetAttribute("WindPower")
	local WindSpeed = object:GetAttribute("WindSpeed")
	local WindDirection = object:GetAttribute("WindDirection")

	inst.WindPower = typeof(WindPower) == SettingTypes.WindPower and WindPower or base.WindPower
	inst.WindSpeed = typeof(WindSpeed) == SettingTypes.WindSpeed and WindSpeed or base.WindSpeed
	inst.WindDirection = typeof(WindDirection) == SettingTypes.WindDirection and WindDirection or base.WindDirection

	-- Update settings on event

	local PowerConnection = object:GetAttributeChangedSignal("WindPower"):Connect(function()
		WindPower = object:GetAttribute("WindPower")
		inst.WindPower = typeof(WindPower) == SettingTypes.WindPower and WindPower or base.WindPower
	end)

	local SpeedConnection = object:GetAttributeChangedSignal("WindSpeed"):Connect(function()
		WindSpeed = object:GetAttribute("WindSpeed")
		inst.WindSpeed = typeof(WindSpeed) == SettingTypes.WindSpeed and WindSpeed or base.WindSpeed
	end)

	local DirectionConnection = object:GetAttributeChangedSignal("WindDirection"):Connect(function()
		WindDirection = object:GetAttribute("WindDirection")
		inst.WindDirection = typeof(WindDirection) == SettingTypes.WindDirection and WindDirection or base.WindDirection
	end)

	-- Cleanup function for when shake is removed or object is unloaded

	function inst:Destroy()
		PowerConnection:Disconnect()
		SpeedConnection:Disconnect()
		DirectionConnection:Disconnect()
		table.clear(inst)
	end

	return inst
end

return Settings]========])

local octree=source(shake,"ModuleScript","Octree",[========[--- Octree implementation
-- @classmod Octree

-- Original by Quenty, Optimized by howmanysmall

local OctreeNode = require(script.OctreeNode)
local OctreeRegionUtils = require(script.OctreeRegionUtils)

local EPSILON = 1e-9
local SQRT_3_OVER_2 = math.sqrt(3) / 2
local SUB_REGION_POSITION_OFFSET = {
	{0.25, 0.25, -0.25};
	{-0.25, 0.25, -0.25};
	{0.25, 0.25, 0.25};
	{-0.25, 0.25, 0.25};
	{0.25, -0.25, -0.25};
	{-0.25, -0.25, -0.25};
	{0.25, -0.25, 0.25};
	{-0.25, -0.25, 0.25};
}

local Octree = {ClassName = "Octree"}
Octree.__index = Octree

local OctreeNode_new = OctreeNode.new
local OctreeRegionUtils_GetNeighborsWithinRadius = OctreeRegionUtils.GetNeighborsWithinRadius

function Octree.new()
	return setmetatable({
		MaxDepth = 4;
		MaxRegionSize = table.create(3, 512);
		RegionHashMap = {};
	}, Octree)
end

function Octree:ClearNodes()
	self.MaxDepth = 4
	self.MaxRegionSize = table.create(3, 512)
	table.clear(self.RegionHashMap)
end

function Octree:GetAllNodes()
	local Options = {}
	local Length = 0

	for _, RegionList in next, self.RegionHashMap do
		for _, Region in ipairs(RegionList) do
			for Node in next, Region.Nodes do
				Length += 1
				Options[Length] = Node
			end
		end
	end

	return Options
end

function Octree:CreateNode(Position: Vector3, Object)
	if typeof(Position) ~= "Vector3" then
		error("Bad position value")
	end

	if not Object then
		error("Bad object value.")
	end

	local Node = OctreeNode_new(self, Object)
	Node:SetPosition(Position)
	return Node
end

function Octree:RadiusSearch(Position: Vector3, Radius: number)
	if typeof(Position) ~= "Vector3" then
		error("Bad position value")
	end

	if type(Radius) ~= "number" then
		error("Bad radius value")
	end

	local PositionX, PositionY, PositionZ = Position.X, Position.Y, Position.Z
	local ObjectsFound = {}
	local NodeDistances2 = {}
	local ObjectsLength = 0
	local DistancesLength = 0

	local Diameter = self.MaxRegionSize[1]
	local SearchRadius = Radius + SQRT_3_OVER_2 * Diameter
	local SearchRadiusSquared = SearchRadius * SearchRadius + EPSILON

	for _, RegionList in next, self.RegionHashMap do
		for _, Region in ipairs(RegionList) do
			local RegionPosition = Region.Position
			local RegionPositionX = RegionPosition[1]
			local RegionPositionY = RegionPosition[2]
			local RegionPositionZ = RegionPosition[3]

			local OffsetX, OffsetY, OffsetZ = PositionX - RegionPositionX, PositionY - RegionPositionY, PositionZ - RegionPositionZ
			local Distance2 = OffsetX * OffsetX + OffsetY * OffsetY + OffsetZ * OffsetZ

			if Distance2 <= SearchRadiusSquared then
				ObjectsLength, DistancesLength = OctreeRegionUtils_GetNeighborsWithinRadius(Region, Radius, PositionX, PositionY, PositionZ, ObjectsFound, NodeDistances2, self.MaxDepth, ObjectsLength, DistancesLength)
			end
		end
	end

	return ObjectsFound, NodeDistances2
end

local function NearestNeighborSort(A, B)
	return A.Distance2 < B.Distance2
end

function Octree:KNearestNeighborsSearch(Position: Vector3, K: number, Radius: number)
	if typeof(Position) ~= "Vector3" then
		error("Bad position value")
	end

	if type(Radius) ~= "number" then
		error("Bad radius value")
	end

	local PositionX, PositionY, PositionZ = Position.X, Position.Y, Position.Z
	local Objects = {}
	local NodeDistances2 = {}
	local ObjectsLength = 0
	local DistancesLength = 0

	local Diameter = self.MaxRegionSize[1]
	local SearchRadius = Radius + SQRT_3_OVER_2 * Diameter
	local SearchRadiusSquared = SearchRadius * SearchRadius + EPSILON

	for _, RegionList in next, self.RegionHashMap do
		for _, Region in ipairs(RegionList) do
			local RegionPosition = Region.Position
			local RegionPositionX = RegionPosition[1]
			local RegionPositionY = RegionPosition[2]
			local RegionPositionZ = RegionPosition[3]

			local OffsetX, OffsetY, OffsetZ = PositionX - RegionPositionX, PositionY - RegionPositionY, PositionZ - RegionPositionZ
			local Distance2 = OffsetX * OffsetX + OffsetY * OffsetY + OffsetZ * OffsetZ

			if Distance2 <= SearchRadiusSquared then
				ObjectsLength, DistancesLength = OctreeRegionUtils_GetNeighborsWithinRadius(Region, Radius, PositionX, PositionY, PositionZ, Objects, NodeDistances2, self.MaxDepth, ObjectsLength, DistancesLength)
			end
		end
	end

	local Sortable = table.create(DistancesLength)
	for Index, Distance2 in ipairs(NodeDistances2) do
		Sortable[Index] = {
			Distance2 = Distance2;
			Index = Index;
		}
	end

	table.sort(Sortable, NearestNeighborSort)

	local ArrayLength = math.min(DistancesLength, K)
	local KNearest = table.create(ArrayLength)
	local KNearestDistance2 = table.create(ArrayLength)
	for Index = 1, ArrayLength do
		local Sorted = Sortable[Index]
		KNearestDistance2[Index] = Sorted.Distance2
		KNearest[Index] = Objects[Sorted.Index]
	end

	return KNearest, KNearestDistance2
end

local function GetOrCreateRegion(self, PositionX: number, PositionY: number, PositionZ: number)
	local RegionHashMap = self.RegionHashMap
	local MaxRegionSize = self.MaxRegionSize
	local X, Y, Z = MaxRegionSize[1], MaxRegionSize[2], MaxRegionSize[3]
	local CX, CY, CZ = math.floor(PositionX / X + 0.5), math.floor(PositionY / Y + 0.5), math.floor(PositionZ / Z + 0.5)
	local Hash = CX * 73856093 + CY * 19351301 + CZ * 83492791

	local RegionList = RegionHashMap[Hash]
	if not RegionList then
		RegionList = {}
		RegionHashMap[Hash] = RegionList
	end

	local RegionPositionX, RegionPositionY, RegionPositionZ = X * CX, Y * CY, Z * CZ
	for _, Region in ipairs(RegionList) do
		local Position = Region.Position
		if Position[1] == RegionPositionX and Position[2] == RegionPositionY and Position[3] == RegionPositionZ then
			return Region
		end
	end

	local HalfSizeX, HalfSizeY, HalfSizeZ = X / 2, Y / 2, Z / 2

	local LowerBoundsArray = {RegionPositionX - HalfSizeX, RegionPositionY - HalfSizeY, RegionPositionZ - HalfSizeZ}
	local PositionArray = {RegionPositionX, RegionPositionY, RegionPositionZ}
	local SizeArray = {X, Y, Z}
	local UpperBoundsArray = {RegionPositionX + HalfSizeX, RegionPositionY + HalfSizeY, RegionPositionZ + HalfSizeZ}

	local Region = {
		Depth = 1;
		LowerBounds = LowerBoundsArray;
		NodeCount = 0;
		Nodes = {}; -- [node] = true (contains subchild nodes too)
		Parent = nil;
		ParentIndex = nil;
		Position = PositionArray;
		Size = SizeArray; -- { sx, sy, sz }
		SubRegions = {};
		UpperBounds = UpperBoundsArray;
	}

	table.insert(RegionList, Region)
	return Region
end

function Octree:GetOrCreateLowestSubRegion(PositionX: number, PositionY: number, PositionZ: number)
	local Region = GetOrCreateRegion(self, PositionX, PositionY, PositionZ)
	local MaxDepth = self.MaxDepth
	local Current = Region
	for _ = Region.Depth, MaxDepth do
		local CurrentPosition = Current.Position
		local Index = PositionX > CurrentPosition[1] and 1 or 2
		if PositionY <= CurrentPosition[2] then
			Index += 4
		end

		if PositionZ >= CurrentPosition[3] then
			Index += 2
		end

		local SubRegions = Current.SubRegions
		local Next = SubRegions[Index]

		-- construct
		if not Next then
			local Size = Current.Size
			local Multiplier = SUB_REGION_POSITION_OFFSET[Index]

			local X, Y, Z = Size[1], Size[2], Size[3]
			local CurrentPositionX = CurrentPosition[1] + Multiplier[1] * X
			local CurrentPositionY = CurrentPosition[2] + Multiplier[2] * Y
			local CurrentPositionZ = CurrentPosition[3] + Multiplier[3] * Z
			local SizeX, SizeY, SizeZ = X / 2, Y / 2, Z / 2

			local HalfSizeX, HalfSizeY, HalfSizeZ = SizeX / 2, SizeY / 2, SizeZ / 2

			local LowerBoundsArray = {CurrentPositionX - HalfSizeX, CurrentPositionY - HalfSizeY, CurrentPositionZ - HalfSizeZ}
			local PositionArray = {CurrentPositionX, CurrentPositionY, CurrentPositionZ}
			local SizeArray = {SizeX, SizeY, SizeZ}
			local UpperBoundsArray = {CurrentPositionX + HalfSizeX, CurrentPositionY + HalfSizeY, CurrentPositionZ + HalfSizeZ}

			Next = {
				Depth = Current and (Current.Depth + 1) or 1;
				LowerBounds = LowerBoundsArray;
				NodeCount = 0;
				Nodes = {}; -- [node] = true (contains subchild nodes too)
				Parent = Current;
				ParentIndex = Index;
				Position = PositionArray;
				Size = SizeArray; -- { sx, sy, sz }
				SubRegions = {};
				UpperBounds = UpperBoundsArray;
			}

			-- Next = OctreeRegionUtils.CreateSubRegion(Current, Index)
			SubRegions[Index] = Next
		end

		-- iterate
		Current = Next
	end

	return Current
end

return Octree]========])

source(octree,"ModuleScript","OctreeNode",[========[--- Basic node interacting with the octree
-- @classmod OctreeNode

local OctreeNode = {ClassName = "OctreeNode"}
OctreeNode.__index = OctreeNode

function OctreeNode.new(Octree, Object)
	return setmetatable({
		Octree = Octree or error("No octree");
		Object = Object or error("No object");

		CurrentLowestRegion = nil;
		Position = nil;
		PositionX = nil;
		PositionY = nil;
		PositionZ = nil;
	}, OctreeNode)
end

function OctreeNode:KNearestNeighborsSearch(K: number, Radius: number)
	return self.Octree:KNearestNeighborsSearch(self.Position, K, Radius)
end

function OctreeNode:GetObject()
	warn("OctreeNode:GetObject is deprecated.")
	return self.Object
end

function OctreeNode:RadiusSearch(Radius: number)
	return self.Octree:RadiusSearch(self.Position, Radius)
end

function OctreeNode:GetPosition()
	warn("OctreeNode:GetPosition is deprecated.")
	return self.Position
end

function OctreeNode:GetRawPosition(): (number, number, number)
	return self.PositionX, self.PositionY, self.PositionZ
end

function OctreeNode:SetPosition(Position: Vector3)
	if self.Position == Position then
		return
	end

	local PositionX, PositionY, PositionZ = Position.X, Position.Y, Position.Z

	self.PositionX = PositionX
	self.PositionY = PositionY
	self.PositionZ = PositionZ
	self.Position = Position

	if self.CurrentLowestRegion then
		local Region = self.CurrentLowestRegion
		local LowerBounds = Region.LowerBounds
		local UpperBounds = Region.UpperBounds
		if PositionX >= LowerBounds[1] and PositionX <= UpperBounds[1] and PositionY >= LowerBounds[2] and PositionY <= UpperBounds[2] and PositionZ >= LowerBounds[3] and PositionZ <= UpperBounds[3] then
			return
		end
	end

	local NewLowestRegion = self.Octree:GetOrCreateLowestSubRegion(PositionX, PositionY, PositionZ)
	if self.CurrentLowestRegion then
		-- OctreeRegionUtils_MoveNode(self.CurrentLowestRegion, NewLowestRegion, self)
		local FromLowest = self.CurrentLowestRegion
		if FromLowest.Depth ~= NewLowestRegion.Depth then
			error("fromLowest.Depth ~= toLowest.Depth")
		end

		if FromLowest == NewLowestRegion then
			error("fromLowest == toLowest")
		end

		local CurrentFrom = FromLowest
		local CurrentTo = NewLowestRegion

		while CurrentFrom ~= CurrentTo do
			-- remove from current
			local CurrentFromNodes = CurrentFrom.Nodes
			if not CurrentFromNodes[self] then
				error("CurrentFrom.Nodes doesn't have a node here.")
			end

			local NodeCount = CurrentFrom.NodeCount
			if NodeCount <= 0 then
				error("NodeCount is <= 0.")
			end

			NodeCount -= 1
			CurrentFromNodes[self] = nil
			CurrentFrom.NodeCount = NodeCount

			-- remove subregion!
			local ParentIndex = CurrentFrom.ParentIndex
			if NodeCount <= 0 and ParentIndex then
				local Parent = CurrentFrom.Parent
				if not Parent then
					error("CurrentFrom.Parent doesn't exist.")
				end

				local SubRegions = Parent.SubRegions
				if SubRegions[ParentIndex] ~= CurrentFrom then
					error("Failed equality check.")
				end

				SubRegions[ParentIndex] = nil
			end

			local CurrentToNodes = CurrentTo.Nodes
			if CurrentToNodes[self] then
				error("CurrentTo.Nodes already has a node here.")
			end

			CurrentToNodes[self] = self
			CurrentTo.NodeCount += 1

			CurrentFrom = CurrentFrom.Parent
			CurrentTo = CurrentTo.Parent
		end
	else
		local Current = NewLowestRegion
		while Current do
			local CurrentNodes = Current.Nodes
			if not CurrentNodes[self] then
				CurrentNodes[self] = self
				Current.NodeCount += 1
			end

			Current = Current.Parent
		end
	end

	self.CurrentLowestRegion = NewLowestRegion
end

function OctreeNode:Destroy()
	local LowestSubregion = self.CurrentLowestRegion
	if LowestSubregion then
		local Current = LowestSubregion

		while Current do
			local Nodes = Current.Nodes
			if not Nodes[self] then
				error("CurrentFrom.Nodes doesn't have a node here.")
			end

			local NodeCount = Current.NodeCount
			if NodeCount <= 0 then
				error("NodeCount is <= 0.")
			end

			NodeCount -= 1
			Nodes[self] = nil
			Current.NodeCount = NodeCount

			-- remove subregion!
			local Parent = Current.Parent
			local ParentIndex = Current.ParentIndex
			if NodeCount <= 0 and ParentIndex then
				if not Parent then
					error("Current.Parent doesn't exist.")
				end

				local SubRegions = Parent.SubRegions
				if SubRegions[ParentIndex] ~= Current then
					error("Failed equality check.")
				end

				SubRegions[ParentIndex] = nil
			end

			Current = Parent
		end
	end
end

return OctreeNode]========])

source(octree,"ModuleScript","OctreeRegionUtils",[========[--- Octree implementation
-- @module OctreeRegionUtils

local EPSILON = 1e-6
local SQRT_3_OVER_2 = math.sqrt(3) / 2
local SUB_REGION_POSITION_OFFSET = {
	{0.25, 0.25, -0.25};
	{-0.25, 0.25, -0.25};
	{0.25, 0.25, 0.25};
	{-0.25, 0.25, 0.25};
	{0.25, -0.25, -0.25};
	{-0.25, -0.25, -0.25};
	{0.25, -0.25, 0.25};
	{-0.25, -0.25, 0.25};
}

local OctreeRegionUtils = {}

-- See basic algorithm:
-- luacheck: push ignore
-- https://github.com/PointCloudLibrary/pcl/blob/29f192af57a3e7bdde6ff490669b211d8148378f/octree/include/pcl/octree/impl/octree_search.hpp#L309
-- luacheck: pop
local function GetNeighborsWithinRadius(Region, Radius, PositionX, PositionY, PositionZ, ObjectsFound, NodeDistances2, MaxDepth, ObjectsLength, DistancesLength)
	if not MaxDepth then
		error("Missing MaxDepth.")
	end

	local SearchRadius = Radius + SQRT_3_OVER_2 * (Region.Size[1] / 2)
	local SearchRadiusSquared = SearchRadius * SearchRadius + EPSILON
	local RadiusSquared = Radius * Radius

	-- for each child
	for _, ChildRegion in next, Region.SubRegions do
		local ChildPosition = ChildRegion.Position
		local ChildPositionX = ChildPosition[1]
		local ChildPositionY = ChildPosition[2]
		local ChildPositionZ = ChildPosition[3]

		local OffsetX = PositionX - ChildPositionX
		local OffsetY = PositionY - ChildPositionY
		local OffsetZ = PositionZ - ChildPositionZ
		local Distance2 = OffsetX * OffsetX + OffsetY * OffsetY + OffsetZ * OffsetZ

		-- within search radius
		if Distance2 <= SearchRadiusSquared then
			if ChildRegion.Depth == MaxDepth then
				for Node in next, ChildRegion.Nodes do
					local NodePositionX = Node.PositionX
					local NodePositionY = Node.PositionY
					local NodePositionZ = Node.PositionZ

					local NodeOffsetX = NodePositionX - PositionX
					local NodeOffsetY = NodePositionY - PositionY
					local NodeOffsetZ = NodePositionZ - PositionZ
					local NodeDistance2 = NodeOffsetX * NodeOffsetX + NodeOffsetY * NodeOffsetY + NodeOffsetZ * NodeOffsetZ

					if NodeDistance2 <= RadiusSquared then
						ObjectsLength += 1
						DistancesLength += 1
						ObjectsFound[ObjectsLength] = Node.Object
						NodeDistances2[DistancesLength] = NodeDistance2
					end
				end
			else
				ObjectsLength, DistancesLength = GetNeighborsWithinRadius(ChildRegion, Radius, PositionX, PositionY, PositionZ, ObjectsFound, NodeDistances2, MaxDepth, ObjectsLength, DistancesLength)
			end
		end
	end

	return ObjectsLength, DistancesLength
end

OctreeRegionUtils.GetNeighborsWithinRadius = GetNeighborsWithinRadius
return OctreeRegionUtils]========])

local skin=source(runtime,"ModuleScript","SkinnedGrass",[========[--[[
	An interactive grass module utilizing skinned meshes
	Made by xander22 (youtube.com/@xand3r22, x.com/x4nder22)
	
	CREDITS:
	
	Octree by Quenty
]]

-- Modules
local Octree = require(script.Octree)  
local utils = require(script.SkinnedGrassUtils)

-- Services
local TweenService = game:GetService("TweenService")

-- default settings, can be overriden at runtime with UpdateSettings()
local DEFAULT_SETTINGS = {
	RenderDistanceEnabled = true, -- If grass should be rendered in/out
	RenderDistance = 100, -- Distance at which grass is fully rendered out --150
	RenderInAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- TweenInfo to apply to bones rendering in. Set to nil for no animation (more performant)
	RenderOutAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), -- TweenInfo to apply to bones rendering out. Set to nil for no animation (more performant)
	RenderOutOffset = CFrame.new(0, -3, 0), -- Offset for bones when rendering in/out
	MeshStorage = nil, -- Folder to store meshes that are rendered out. By default creates a folder in ReplicatedStorage

	CollisionsEnabled = true, -- If grass should be simulated with collisions. To disable collisions, set this bool to false rather than setting collision distance to 0
	CollisionDistance = 100, -- Distance at which collisions are simulated
	CollisionRadiusInner = 4, -- Radius around collision where bones are fully displaced
	CollisionRadiusOuter = 6, -- Radius around collision where the displacement effect ends
	CollisionAngle = 90, -- Angle of the displacement effect
	CollisionTranslation = Vector3.new(0, 0, 0), -- Position offset of the displacement effect
	CollisionReturnDelay = 0, -- Time that the grass stays displaced before bouncing back (begins after collision stops)
	CollisionReturnInfo = TweenInfo.new(1.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), -- TweenInfo for the return animation

	WindEnabled = true, -- If grass should be simulated with wind. To disable wind, set this to false rather than setting wind distance to 0
	WindDistanceInner = 10, -- Distance at which wind is simulated with max frame rate
	WindDistanceOuter = 50, -- Distance at which wind is simulated with min frame rate
	WindFramerateInner = 1, -- Frame rate for wind in inner range (1 = 100% frames, 0.5 = 50% frames, etc)
	WindFramerateOuter = 0.25, -- Frame rate for wind in outer range
	WindNoiseSize = 16, -- Size for wind noise calculations
	WindNoiseIntensity = 2, -- Intensity for wind noise calculations
	UseGlobalWind = true, -- When set to true, overrides WindDirection, WindSpeed, WindAngle and WindTranslation settings with Roblox's wind
	WindDirection = Vector3.new(1, 0, 0), -- Direction of the wind effect
	WindSpeed = 8, -- Speed of the wind effect
	WindAngleMin = 35, -- Min angle of the wind effect
	WindAngleMax = 45, -- Max angle of the wind effect
	WindTranslationMin = Vector3.new(0, 0, 0), -- Min position offset of the wind effect
	WindTranslationMax = Vector3.new(0, 0, 0), -- Max position offset of the wind effect
}

local SkinnedGrass = {}
SkinnedGrass.__index = SkinnedGrass

-- initialize new grass object
function SkinnedGrass.new(initialSettings)
	local obj = {
		Settings = {},
		SkinnedMeshesRenderedIn = {},
		MeshParents = {},
		MeshTweenOuts = {},
		MeshOctree = {},
		BoneOctree = Octree.new(),
		DisplaceBones = {},
		ReturnBones = {},
		FrameCountInner = 1,
		FrameCountOuter = 1
	}
	setmetatable(obj, SkinnedGrass)
	
	obj.MeshOctree = Octree.new()
	
	obj.Settings = initialSettings or {}
	for i,v in DEFAULT_SETTINGS do
		if obj.Settings[i] == nil then
			obj.Settings[i] = v
		end
	end

	return obj
end

-- updates settings. 'settingsTable' argument should have the same format as DEFAULT_SETTINGS. Leave arguments empty to reset settings to default
function SkinnedGrass:UpdateSettings(settingsTable : {})
	if self.Settings == nil then
		self.Settings = {}
	end

	if settingsTable == nil then
		for i,v in DEFAULT_SETTINGS do
			self.Settings[i] = v
		end
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i,v in DEFAULT_SETTINGS do
		if settingsTable[i] ~= nil then
			self.Settings[i] = settingsTable[i]
		elseif self.Settings[i] == nil then
			self.Settings[i] = v
		end
	end
end

-- adds meshes to grass object
function SkinnedGrass:AddMeshes(skinnedMeshModels : {Model})
	if typeof(skinnedMeshModels) ~= "table" then warn("AddMeshes() parameter must be a table") return end
	
	if self.MeshFolder == nil then
		local folder = game.ReplicatedStorage:FindFirstChild("SkinnedGrass_Storage")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "SkinnedGrass_Storage"
			folder.Parent = game.ReplicatedStorage
		end
		self.MeshFolder = folder
	end
	
	for _,model in skinnedMeshModels do
		if not model:IsA("Model") then warn(model, "is not a model") continue end
		if self.MeshParents[model] then continue end -- check if model has already been added to simulation
		local meshPart = model:FindFirstChildOfClass("MeshPart")
		if not meshPart then -- yield thread if meshpart hasn't loaded
			local timeout = 0
			while not meshPart and timeout < 5 do
				meshPart = model:FindFirstChildOfClass("MeshPart")
				timeout += task.wait()
			end
			if not meshPart then
				warn(model, "does not have a loaded mesh part. Consider setting ModelStreamingMode to atomic")
				continue
			end
		end
		-- cache the bones for looping
		local bones = meshPart:GetChildren()
		-- create origin bone for transforming bones en masse
		local originBone = Instance.new("Bone")
		originBone.Parent = meshPart
		originBone.WorldCFrame = meshPart.CFrame
		originBone.Name = "SkinnedGrass_Origin"
		-- loop through each bone and reparent to origin bone
		for _,bone in bones do
			if not bone:IsA("Bone") then continue end
			self.BoneOctree:CreateNode(bone.TransformedWorldCFrame.Position, bone)
			bone.Parent = originBone
		end
		-- set origin bone to below skinned mesh for fade in
		originBone.Transform = CFrame.new(0, -3, 0)
		self.MeshOctree:CreateNode(originBone.WorldCFrame.Position, meshPart)
		-- store mesh in replicated storage until needed (bones aren't calculated when not in workspace)
		self.MeshParents[model] = model.Parent
		model.Parent = self.Settings.MeshStorage or self.MeshFolder
	end
end

-- main logic of the module, called every interval. Put in RunService.RenderStepped for smoothest simulation
-- targetPos = position the simulation is based around (ie the player's position)
-- collisions = table of information for the displacement effect
-- each index of collisions should be a Vector3 or a table with the following format: {collisionPos, customSettings}
-- customSettings is a table of custom displacement settings for that collision, follows the same format as DEFAULT_SETTINGS
function SkinnedGrass:Step(deltaTime : number, collisions : {}, targetPos : Vector3)
	if targetPos == nil then -- if no target pos center simulation around player character
		local char = game.Players.LocalPlayer.Character
		if char then
			targetPos = char.PrimaryPart.Position
		else
			return
		end
	end
	local settingsTable = self.Settings
	local meshesToRemove = table.clone(self.SkinnedMeshesRenderedIn)
	if settingsTable.RenderDistanceEnabled then
		local skinnedMeshesInRenderDistance = self.MeshOctree:RadiusSearch(targetPos, settingsTable.RenderDistance)
		for _,v in skinnedMeshesInRenderDistance do
			if table.find(self.SkinnedMeshesRenderedIn, v) == nil then
				table.insert(self.SkinnedMeshesRenderedIn, v)
                local pending=table.find(self.MeshTweenOuts,v.SkinnedGrass_Origin)
                if pending then table.remove(self.MeshTweenOuts,pending)end
				--v.Parent.Parent = workspace
				local model = v:FindFirstAncestorOfClass("Model")
				if not model then continue end
				model.Parent = self.MeshParents[model]
				--print("spawn mesh", v)
				if settingsTable.RenderInAnimation then
					TweenService:Create(v.SkinnedGrass_Origin, settingsTable.RenderInAnimation, { Transform = CFrame.new(0, 0, 0) }):Play()
				else
					v.SkinnedGrass_Origin.Transform = CFrame.new(0, 0, 0)
				end		
			end
			local removeIndex=table.find(meshesToRemove,v)
            if removeIndex then table.remove(meshesToRemove,removeIndex)end
		end
		for _,v in meshesToRemove do
			table.remove(self.SkinnedMeshesRenderedIn, table.find(self.SkinnedMeshesRenderedIn, v))
			if settingsTable.RenderOutAnimation then
				TweenService:Create(v.SkinnedGrass_Origin, settingsTable.RenderOutAnimation, { Transform = settingsTable.RenderOutOffset }):Play()
				table.insert(self.MeshTweenOuts, v.SkinnedGrass_Origin)
			else
				local model = v:FindFirstAncestorOfClass("Model")
				model.Parent = settingsTable.MeshStorage
			end
		end
		for i,v in self.MeshTweenOuts do
			if (v.Transform.Position - settingsTable.RenderOutOffset.Position).Magnitude <= 0 then
				table.remove(self.MeshTweenOuts, i)
				v:FindFirstAncestorOfClass("Model").Parent = settingsTable.MeshStorage
			end
		end
	end
	
	local transformedBones = {}
	
	local windDir = game.Workspace.GlobalWind
	if not settingsTable.UseGlobalWind then
		windDir = settingsTable.WindDirection
	end
	if windDir.Magnitude == 0 then windDir = Vector3.new(0, 0, 1) end
	local windIntensity = math.min(game.Workspace.GlobalWind.Magnitude, 20)
	self.FrameCountInner += 1
	if self.FrameCountInner >= 1 / settingsTable.WindFramerateInner then self.FrameCountInner = 1 end
	self.FrameCountOuter += 1
	if self.FrameCountOuter >= 1 / settingsTable.WindFramerateOuter then self.FrameCountOuter = 1 end
	
	if self.WindAnimation == nil or self.WindAnimation >= 1 then
		self.WindAnimation = 0
	end
	local windSpeed = 1 + windIntensity / 20
	if not settingsTable.UseGlobalWind then
		windSpeed = 1 + settingsTable.WindSpeed / 20
	end
	self.WindAnimation += deltaTime * windSpeed
	local minAngle = 0
	local maxAngle = 0
	local minTranslation = Vector3.zero
	local maxTranslation = Vector3.zero
	if self.Settings.WindEnabled then
		minAngle = math.max(windIntensity * 2, -2)
		maxAngle = math.max(windIntensity * 3, 2)
		if not settingsTable.UseGlobalWind then
			minAngle = settingsTable.WindAngleMin
			maxAngle = settingsTable.WindAngleMax
			minTranslation = settingsTable.WindTranslationMin
			maxTranslation = settingsTable.WindTranslationMax
		end
		if self.FrameCountInner == 1 then
			local bonesInWindDistance = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceInner)
			for i = 1, #bonesInWindDistance do
				local bone = bonesInWindDistance[i]
				local windCFrame = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = windCFrame
			end
		end
		if self.FrameCountOuter == 1 then
			local bonesInWindDistanceOuter = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceOuter)
			for i = 1, #bonesInWindDistanceOuter do
				local bone = bonesInWindDistanceOuter[i]
				local windCFrame = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = windCFrame
			end
		end
	end

	if settingsTable.CollisionsEnabled and collisions then
		local collisionsInRange = {}
		for _,collision in collisions do
			local pos, customSettings
			if typeof(collision) == "table" then
				pos = collision[1]
				customSettings = collision[2]
			else
				pos = collision
				customSettings = {}
			end
			if (pos - targetPos).Magnitude > settingsTable.CollisionDistance then continue end -- outside of the collision sim distance
			local collisionSettings = table.clone(settingsTable)
			for key,value in customSettings do -- custom settings
				if collisionSettings[key] then
					collisionSettings[key] = value
				end
			end

			local bonesInCollisionDistance = self.BoneOctree:RadiusSearch(pos, collisionSettings.CollisionRadiusOuter - 0.1) --slight offset to prevent return starting instantly
			local displaceFadeRange : number = collisionSettings.CollisionRadiusOuter - collisionSettings.CollisionRadiusInner 
			for _,bone in bonesInCollisionDistance do
				table.insert(transformedBones, bone)

				local displaceInfo = self.DisplaceBones[bone]
				if displaceInfo == nil then --first time calculating, set target rotation and displace percent
					displaceInfo = {}
					displaceInfo[1] = collisionSettings --settings
					displaceInfo[2] = self.ReturnBones[bone] and self.ReturnBones[bone][2] or 0 --displace percent

					local offset = bone.TransformedWorldCFrame.Position - pos
                    local directionToKnock = offset.Magnitude > .001 and offset.Unit or Vector3.new(1,0,0)
					local localKnockDirection = bone.WorldCFrame:VectorToObjectSpace(directionToKnock)

					-- Preserve the current Y rotation, only affect X and Z
					local _, currentYRotation, _ = bone.Transform:ToOrientation() -- Extract the Y rotation

					local horizontal = Vector3.new(localKnockDirection.X, 0, localKnockDirection.Z)
                    local tiltDirection = horizontal.Magnitude > .001 and horizontal.Unit or Vector3.new(1,0,0)

					-- Knock the bone over by tilting it based on the knock intensity
					local tiltAngle = math.rad(settingsTable.CollisionAngle)
					local newXRotation = tiltAngle * tiltDirection.Z -- Tilt along X based on Z direction
					local newZRotation = -tiltAngle * tiltDirection.X -- Tilt along Z based on X direction
					local newTranslation = settingsTable.CollisionTranslation
					-- Set the new orientation while preserving the Y rotation
					local targetCFrame = (bone:GetAttribute("SerenaTerrainOffset") or CFrame.identity) * CFrame.new(newTranslation) * CFrame.Angles(newXRotation, currentYRotation, newZRotation)
					displaceInfo[4] = targetCFrame
				end

				-- calculate displacement percentage by checking where the bone is at between the displacement radius inner and displacement radius outer
				local distFromOrigin : number = ((bone:GetAttribute("SerenaGroundPoint") or bone.WorldCFrame.Position) - pos).Magnitude
				local range = math.min(1 - (distFromOrigin - collisionSettings.CollisionRadiusInner) / displaceFadeRange, 1)
				if range > displaceInfo[2] then --displace amount can only go up, not down (out animation handled by return table)
					displaceInfo[2] = range --percent displaced, 0 = no displacement, 1 = full displacement
				end
				displaceInfo[3] = range
				self.DisplaceBones[bone] = displaceInfo
				self.ReturnBones[bone] = nil

			end

		end

		for bone,displaceInfo in self.DisplaceBones do
			local origRotX, origRotY, origRotZ = displaceInfo[4]:ToEulerAnglesYXZ()
			local newRot = CFrame.fromEulerAnglesXYZ(origRotX * displaceInfo[2], origRotY * displaceInfo[2], origRotZ * displaceInfo[2])
			local newPos = CFrame.new(displaceInfo[4].Position.X * displaceInfo[2], displaceInfo[4].Position.Y * displaceInfo[2], displaceInfo[4].Position.Z * displaceInfo[2])

			local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
			bone.Transform = CFrame.new(Vector3.zero) * windRot:Lerp(newRot * newPos, displaceInfo[2])

			if displaceInfo[3] <= 0 or table.find(transformedBones, bone) == nil then --out of range, do return
				local returnInfo = {}
				returnInfo[1] = displaceInfo[1] --settings
				returnInfo[2] = displaceInfo[2] --percent displaced
				returnInfo[3] = tick() --time of displacement leaving range
				returnInfo[4] = bone.Transform -- cframe to lerp from
				self.ReturnBones[bone] = returnInfo
				self.DisplaceBones[bone] = nil
				continue
			end
		end

		for bone,returnInfo in self.ReturnBones do
			local collisionSettings = returnInfo[1]
			local timeSinceCollision = tick() - returnInfo[3]
			if timeSinceCollision < collisionSettings.CollisionReturnDelay then 
				local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = returnInfo[4]
				continue
			end
			local returnTweenInfo : TweenInfo = collisionSettings.CollisionReturnInfo
			if timeSinceCollision >= collisionSettings.CollisionReturnDelay + returnTweenInfo.Time then 
				self.ReturnBones[bone] = nil
				continue
			end

			local percentReturned = (timeSinceCollision - collisionSettings.CollisionReturnDelay) / returnTweenInfo.Time
			local tweenValue = TweenService:GetValue(percentReturned, returnTweenInfo.EasingStyle, returnTweenInfo.EasingDirection)
			returnInfo[2] = 1 - tweenValue
			local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
			local newRot = returnInfo[4]:lerp(windRot, tweenValue)
			
			bone.Transform = CFrame.new(Vector3.zero) * newRot
		end
	end

end

return SkinnedGrass]========])skin:SetAttribute("SourceAssetId",87377915371959)

source(skin,"ModuleScript","SkinnedGrassUtils",[========[local module = {}

local TweenService = game:GetService("TweenService")

-- wind
local function Noise(x, y, z, size, intensity)
	size = size or 1
	intensity = intensity or 1

	local scaledX = x / size
	local scaledY = y / size
	local scaledZ = z / size

	local noiseValue = math.noise(scaledX, scaledY, scaledZ) * intensity

	return noiseValue
end
function module.CalculateWindAtPoint(bone : Bone, animationPercent : number, windDirection : Vector3, minAngle : number, maxAngle : number, minTranslation : Vector3, maxTranslation : Vector3, windSize : number, windIntensity : number)
	local noise = Noise(bone.WorldCFrame.Position.X, 0, bone.WorldCFrame.Position.Z, windSize, windIntensity)
	local windAnimationLooped = 1 - math.abs(((animationPercent + noise) % 1) * 2 - 1)
	local windIntensity = minAngle + (maxAngle - minAngle) * TweenService:GetValue(windAnimationLooped, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local parentRotation = bone.Parent.Parent.CFrame
	local modifiedWindDirection = parentRotation:VectorToObjectSpace(windDirection) -- convert wind direction to skinned mesh local space
	local localWindDirection = bone.CFrame:VectorToObjectSpace(modifiedWindDirection)
	local horizontal = Vector3.new(localWindDirection.X, 0, localWindDirection.Z)
	local tiltDirection = horizontal.Magnitude > .001 and horizontal.Unit or Vector3.new(1,0,0)

	-- Knock the bone over by tilting it based on the knock intensity
	local tiltAngle = math.rad(windIntensity)
	local newXRotation = tiltAngle * tiltDirection.Z -- Tilt along X based on Z direction
	local newZRotation = -tiltAngle * tiltDirection.X -- Tilt along Z based on X direction

	local targetOrientation = CFrame.Angles(newXRotation, 0, newZRotation)
	local targetTranslation = CFrame.new(minTranslation + (maxTranslation - minTranslation) * TweenService:GetValue(windAnimationLooped, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
	return (bone:GetAttribute("SerenaTerrainOffset") or CFrame.identity) * targetOrientation * targetTranslation
end

return module
]========])

local octree=source(skin,"ModuleScript","Octree",[========[--[=[
	# MODIFIED BY PLASMA_NODE FOR OMEGASPACE, 2023 #

	Octree implementation. An octree is a data structure that allows for quick spatial
	data queries of static objects. For example, trees can be stored in an octree, and
	nearby trees could be found near the player.
	Octrees exists as a grid of nodes, which are subdivided in half in each axis, which
	results in 8 different regions. This recursively happens to a set depth.
	This allows for O(n) data storage and log(n) retrieval of nearby objects. With a large
	quantity of items in the octree, this can make data retrieval significantly faster.
	See also: https://en.wikipedia.org/wiki/Octree
	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.new(0, 0, 0), "A")
	octree:CreateNode(Vector3.new(0, 0, 0), "B")
	octree:CreateNode(Vector3.new(0, 0, 0), workspace)
	octree:CreateNode(Vector3.new(0, 0, 1000), "C")
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> { "A", "B", workspace }
	```
	:::tip
	Octrees are best for static objects in the world, and not objects moving around, since then
	data can be statically cached.
	Sometimes using Roblox's spatial hash using the region API is faster than using an octree. However,
	for data that is centralized, or static, an octree can be a very efficient spatial query mechanism.
	That said, it is totally fine to track the objects that DO move around using octree, as long as you 
	apply proper optimizations. The main performance cost of doing this comes down to tracking and 
	upating the position of the objects, which is fine if: 
		1) You have a way to detect the movement without having to loop through all the moving 
		objects to update the position
		2) You can tolerate some inaccuracy with positions and smear this update
		3) You have less than 1000 objects to track, in this case looping through everything 
		shouldn't be too costly. 
	:::
	@class Octree
]=]

local OctreeRegionUtils = require(script.OctreeRegionUtils)
local OctreeNode = require(script.OctreeNode)

local EPSILON = 1e-9

local Octree = {}
Octree.ClassName = "Octree"
Octree.__index = Octree

Octree.Node = script.OctreeNode;
Octree.RegionUtils = script.OctreeRegionUtils;

--[=[
	Constructs a new Octree.
	@return Octree<T>
]=]
function Octree.new(Depth, MaxSize)
	local self = setmetatable({}, Octree)

	self._maxRegionSize = if MaxSize then { MaxSize, MaxSize, MaxSize} else { 512, 512, 512 } -- these should all be the same number
	self._maxDepth = Depth or 4
	self._regionHashMap = {} -- [hash] = region

	return self
end

--[=[
	Returns all octree nodes stored in the octree!
	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.new(0, 0, 0), "Hi")
	octree:CreateNode(Vector3.new(0, 0, 0), "Bob")
	print(octree:GetAllNodes()) --> { "Hi", "Bob" }
	```
	Order is not guaranteed.
	:::warning
	If you have 100,000 nodes in your octree, this is going to be very slow.
	:::
	@return { OctreeNode<T> }
]=]
function Octree:GetAllNodes()
	local options = {}

	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			for node, _ in pairs(region.nodes) do
				options[#options+1] = node
			end
		end
	end

	return options
end

--[=[
	Creates a new OctreeNode at the given position which can be retrieved
	:::tip
	Be sure to call :Destroy() on a node if the data becomes stale. Note that
	this is not necessary if the whole octree is removed from memory.
	:::
	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.new(0, 0, 0), "A")
	octree:CreateNode(Vector3.new(0, 0, 0), "B")
	```
	@param position Vector3
	@param object T
	@return OctreeNode<T>
]=]
function Octree:CreateNode(position, object)
	assert(typeof(position) == "Vector3", "Bad position value")
	assert(object, "Bad object value")

	local node = OctreeNode.new(self, object)

	node:SetPosition(position)
	
	return node
end

--[=[
	Searches at the position and radius for any objects that may be within
	this radius.
	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.new(0, 0, 0), "A")
	octree:CreateNode(Vector3.new(0, 0, 0), "B")
	octree:CreateNode(Vector3.new(0, 0, 1000), "C")
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> { "A", "B" }
	```
	@param position Vector3
	@param radius number
	@return { T } -- Objects found
	@return { number } -- Distances squared
]=]
function Octree:RadiusSearch(position, radius)
	assert(typeof(position) == "Vector3", "Bad position")
	assert(type(radius) == "number", "Bad radius")

	local px, py, pz = position.x, position.y, position.z
	return self:_radiusSearch(px, py, pz, radius)
end

--[=[
	Searches at the position and radius for any objects that may be within
	this radius. Returns the knearest entries.
	The closest entities will be first in the list.
	@param position Vector3
	@param k number -- Number of objects to find
	@param radius number
	@return { any } -- Objects found
	@return { number } -- Distances squared
]=]
function Octree:KNearestNeighborsSearch(position, k, radius)
	assert(typeof(position) == "Vector3", "Bad position")
	assert(type(radius) == "number", "Bad radius")

	local px, py, pz = position.x, position.y, position.z
	local objects, nodeDistances2 = self:_radiusSearch(px, py, pz, radius)

	local sortable = {}
	for index, dist2 in pairs(nodeDistances2) do
		table.insert(sortable, {
			dist2 = dist2;
			index = index;
		})
	end

	table.sort(sortable, function(a, b)
		return a.dist2 < b.dist2
	end)

	local knearest = {}
	local knearestDist2 = {}
	for i = 1, math.min(#sortable, k) do
		local sorted = sortable[i]
		knearestDist2[#knearestDist2 + 1] = sorted.dist2
		knearest[#knearest + 1] = objects[sorted.index]
	end

	return knearest, knearestDist2
end

--[=[
	Internal API to create lowest subregion
	@private
	@param px number
	@param py number
	@param pz number
	@return OctreeSubregion
]=]
function Octree:GetOrCreateLowestSubRegion(px, py, pz)
	local region = self:_getOrCreateRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateSubRegionAtDepth(region, px, py, pz, self._maxDepth)
end

function Octree:_radiusSearch(px, py, pz, radius)
	local objectsFound = {}
	local nodeDistances2 = {}

	local diameter = self._maxRegionSize[1]
	local searchRadiusSquared = OctreeRegionUtils.getSearchRadiusSquared(radius, diameter, EPSILON)

	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			local rpos = region.position
			local rpx, rpy, rpz = rpos[1], rpos[2], rpos[3]
			local ox, oy, oz = px - rpx, py - rpy, pz - rpz
			local dist2 = ox*ox + oy*oy + oz*oz

			if dist2 <= searchRadiusSquared then
				OctreeRegionUtils.getNeighborsWithinRadius(
					region, radius, px, py, pz, objectsFound, nodeDistances2, self._maxDepth)
			end
		end
	end

	return objectsFound, nodeDistances2
end

function Octree:_getRegion(px, py, pz)
	return OctreeRegionUtils.findRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

function Octree:_getOrCreateRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

return Octree]========])

source(octree,"ModuleScript","OctreeNode",[========[--[=[
	Basic node interacting with the octree. See [Octree](/api/Octree) for usage.

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.new(0, 0, 0), "A")
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> { "A" }

	node:Destroy() -- Remove node from octree

	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> { }
	```
	@class OctreeNode
]=]

local OctreeRegionUtils = require(script.Parent.OctreeRegionUtils)

local OctreeNode = {}
OctreeNode.ClassName = "OctreeNode"
OctreeNode.__index = OctreeNode

--[=[
	Creates a new for the given Octree with the object.

	:::warning
	Use Octree:CreateNode() for more consistent results. To use this object directly
	you need to set the position before it's registered which may be unclean.
	:::

	@private
	@param octree Octree
	@param object T
	@return OctreeNode<T>
]=]
function OctreeNode.new(octree, object)
	local self = setmetatable({}, OctreeNode)

	self._octree = octree or error("No octree")
	self._object = object or error("No object")

	self._currentLowestRegion = nil
	self._position = nil

	return self
end

--[=[
	Finds the nearest neighbors to this node within the radius

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.new(0, 0, 0), "A")
	octree:CreateNode(Vector3.new(0, 0, 5), "B")
	print(octree:KNearestNeighborsSearch(10, 100)) --> { "A", "B" } { 0, 25 }
	```

	@param k number -- The number to retrieve
	@param radius number -- The radius to search in
	@return { T } -- Objects found, including self
	@return { number } -- Distances squared
]=]
function OctreeNode:KNearestNeighborsSearch(k, radius)
	return self._octree:KNearestNeighborsSearch(self._position, k, radius)
end

--[=[
	Returns the object stored in the octree

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.new(0, 0, 0), "A")
	print(octree:GetObject()) --> "A"
	```

	@return T
]=]
function OctreeNode:GetObject()
	return self._object
end

--[=[
	Finds the nearest neighbors to the octree node

	@param radius number -- The radius to search in
	@return { any } -- Objects found
	@return { number } -- Distances squared
]=]
function OctreeNode:RadiusSearch(radius)
	return self._octree:RadiusSearch(self._position, radius)
end

--[=[
	Retrieves the position

	@return Vector3
]=]
function OctreeNode:GetPosition()
	return self._position
end

--[=[
	Retrieves the as px, py, pz

	@return number -- px
	@return number -- py
	@return number -- pz
]=]
function OctreeNode:GetRawPosition()
	return self._px, self._py, self._pz
end

--[=[
	Sets the position of the octree nodes and updates the octree accordingly

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.new(0, 0, 0), "A")
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> { "A" }

	node:SetPosition(Vector3.new(1000, 0, 0))
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> {}
	```

	@param position Vector3
]=]
function OctreeNode:SetPosition(position)
	if self._position == position then
		return
	end

	local px, py, pz = position.x, position.y, position.z

	self._px = px
	self._py = py
	self._pz = pz
	self._position = position

	if self._currentLowestRegion then
		if OctreeRegionUtils.inRegionBounds(self._currentLowestRegion, px, py, pz) then
			return
		end
	end

	local newLowestRegion = self._octree:GetOrCreateLowestSubRegion(px, py, pz)

	-- Sanity check for debugging
	-- if not OctreeRegionUtils.inRegionBounds(newLowestRegion, px, py, pz) then
	-- 	error("[OctreeNode.SetPosition] newLowestRegion is not in region bounds!")
	-- end

	if self._currentLowestRegion then
		OctreeRegionUtils.moveNode(self._currentLowestRegion, newLowestRegion, self)
	else
		OctreeRegionUtils.addNode(newLowestRegion, self)
	end

	self._currentLowestRegion = newLowestRegion
end

--[=[
	Removes the OctreeNode from the octree
]=]
function OctreeNode:Destroy()
	if self._currentLowestRegion then
		OctreeRegionUtils.removeNode(self._currentLowestRegion, self)
	end
end

return OctreeNode]========])

source(octree,"ModuleScript","OctreeRegionUtils",[========[--[=[
	Octree implementation utilities. Primarily this utility code
	should not be used directly and should be considered private to
	the library.

	Use [Octree](/api/Octree) instead of this library directly.

	@class OctreeRegionUtils
]=]

local EPSILON = 1e-6
local SQRT_3_OVER_2 = math.sqrt(3)/2
local SUB_REGION_POSITION_OFFSET = {
	{ 0.25, 0.25, -0.25 };
	{ -0.25, 0.25, -0.25 };
	{ 0.25, 0.25, 0.25 };
	{ -0.25, 0.25, 0.25 };
	{ 0.25, -0.25, -0.25 };
	{ -0.25, -0.25, -0.25 };
	{ 0.25, -0.25, 0.25 };
	{ -0.25, -0.25, 0.25 };
}

local OctreeRegionUtils = {}

--[=[
	Visualizes the octree region.

	@param region OctreeRegion<T>
	@return MaidTask
]=]

--[=[
	A Vector3 equivalent for octrees. This type is primarily internal and
	used for faster access than a Vector3.

	@type OctreeVector3 { [1]: number, [2]: number, [3]: number }
	@within OctreeRegionUtils
]=]

--[=[
	An internal region which stores the data.

	@interface OctreeRegion<T>
	.subRegions { OctreeRegion<T> }
	.lowerBounds OctreeVector3
	.upperBounds OctreeVector3
	.position OctreeVector3
	.size OctreeVector3
	.parent OctreeRegion<T>?
	.parentIndex number
	.depth number
	.nodes { OctreeNode<T> }
	.node_count number
	@within OctreeRegionUtils
]=]

--[=[
	Creates a new OctreeRegion<T>

	@param px number
	@param py number
	@param pz number
	@param sx number
	@param sy number
	@param sz number
	@param parent OctreeRegion<T>?
	@param parentIndex number?
	@return OctreeRegion<T>
]=]
local boxes = {};
function OctreeRegionUtils.create(px, py, pz, sx, sy, sz, parent, parentIndex)
	local hsx, hsy, hsz = sx/2, sy/2, sz/2

	local region = {
		subRegions = {
			--topNorthEast
			--topNorthWest
			--topSouthEast
			--topSouthWest
			--bottomNorthEast
			--bottomNorthWest
			--bottomSouthEast
			--bottomSouthWest
		};
		lowerBounds = { px - hsx, py - hsy, pz - hsz };
		upperBounds = { px + hsx, py + hsy, pz + hsz };
		position = { px, py, pz };
		size = { sx, sy, sz }; -- { sx, sy, sz }
		parent = parent;
		depth = parent and (parent.depth + 1) or 1;
		parentIndex = parentIndex;
		nodes = {}; -- [node] = true (contains subchild nodes too)
		node_count = 0;
	}

	--[[
	local map = {Color3.new(1, 0, 0),Color3.new(0, 0, 1), Color3.new(0, 1, 0), Color3.new(0.7, 0, 0.8)}
	if (region.depth >= 1) then

		local trans = 0.92;
		if (region.depth >= 3) then
			trans = 0.98;
		end

		OctreeRegionUtils.visualize(region, trans, map[#map-region.depth], false)

	end
	--]]
	-- if region.depth >= 5 then
	-- 	OctreeRegionUtils.visualize(region)
	-- end

	return region
end


--[=[
	Adds a node to the lowest subregion
	@param lowestSubregion OctreeRegion<T>
	@param node OctreeNode
]=]
function OctreeRegionUtils.addNode(lowestSubregion, node)
	assert(node, "Bad node")

	local current = lowestSubregion
	while current do
		if not current.nodes[node] then
			current.nodes[node] = node
			current.node_count = current.node_count + 1
		end
		current = current.parent
	end
end

--[=[
	Moves a node from one region to another

	@param fromLowest OctreeRegion<T>
	@param toLowest OctreeRegion<T>
	@param node OctreeNode
]=]
function OctreeRegionUtils.moveNode(fromLowest, toLowest, node)
	assert(fromLowest.depth == toLowest.depth, "fromLowest.depth ~= toLowest.depth")
	assert(fromLowest ~= toLowest, "fromLowest == toLowest")

	local currentFrom = fromLowest
	local currentTo = toLowest
	while currentFrom ~= currentTo do
		-- remove from current
		do
			assert(currentFrom.nodes[node], "Not in currentFrom")
			assert(currentFrom.node_count > 0, "No nodes in currentFrom")

			currentFrom.nodes[node] = nil
			currentFrom.node_count = currentFrom.node_count - 1

			-- remove subregion!
			if currentFrom.node_count <= 0 and currentFrom.parentIndex then
				assert(currentFrom.parent, "Bad currentFrom.parent")
				assert(currentFrom.parent.subRegions[currentFrom.parentIndex] == currentFrom, "Not in subregion")
				currentFrom.parent.subRegions[currentFrom.parentIndex] = nil
			end
		end

		-- add to new
		do
			assert(not currentTo.nodes[node], "Failed to add")
			currentTo.nodes[node] = node
			currentTo.node_count = currentTo.node_count + 1
		end

		currentFrom = currentFrom.parent
		currentTo = currentTo.parent
	end
end

--[=[
	Removes a node from the given region

	@param lowestSubregion OctreeRegion<T>
	@param node OctreeNode
]=]
function OctreeRegionUtils.removeNode(lowestSubregion, node)
	assert(node, "Bad node")

	local current = lowestSubregion
	while current do
		assert(current.nodes[node], "Not in current")
		assert(current.node_count > 0, "Current has bad node count")

		current.nodes[node] = nil
		current.node_count = current.node_count - 1

		-- remove subregion!
		if current.node_count <= 0 and current.parentIndex then
			assert(current.parent, "No parent")
			assert(current.parent.subRegions[current.parentIndex] == current, "Not in subregion")
			current.parent.subRegions[current.parentIndex] = nil
		end

		current = current.parent
	end
end


--[=[
	Retrieves the search radius for a given radius given the region
	diameter

	@param radius number
	@param diameter number
	@param epsilon number
	@return number
]=]
function OctreeRegionUtils.getSearchRadiusSquared(radius, diameter, epsilon)
	local diagonal = SQRT_3_OVER_2*diameter
	local searchRadius = radius + diagonal
	return searchRadius*searchRadius + epsilon
end

-- luacheck: push ignore
--[=[
	Adds all octree nod values to objectsFound

	See basic algorithm:
	https://github.com/PointCloudLibrary/pcl/blob/29f192af57a3e7bdde6ff490669b211d8148378f/octree/include/pcl/octree/impl/octree_search.hpp#L309

	@param region OctreeRegion<T>
	@param radius number
	@param px number
	@param py number
	@param pz number
	@param objectsFound { T }
	@param nodeDistances2 { number }
	@param maxDepth number
]=]
function OctreeRegionUtils.getNeighborsWithinRadius(region, radius, px, py, pz, objectsFound, nodeDistances2, maxDepth)
-- luacheck: pop
	assert(maxDepth, "Bad maxDepth")

	local childDiameter = region.size[1]/2
	local searchRadiusSquared = OctreeRegionUtils.getSearchRadiusSquared(radius, childDiameter, EPSILON)

	local radiusSquared = radius*radius

	-- for each child
	for _, childRegion in pairs(region.subRegions) do
		local cposition = childRegion.position
		local cpx, cpy, cpz = cposition[1], cposition[2], cposition[3]

		local ox, oy, oz = px - cpx, py - cpy, pz - cpz
		local dist2 = ox*ox + oy*oy + oz*oz

		-- within search radius
		if dist2 <= searchRadiusSquared then
			if childRegion.depth == maxDepth then
				for node, _ in pairs(childRegion.nodes) do
					local npx, npy, npz = node:GetRawPosition()
					local nox, noy, noz = px - npx, py - npy, pz - npz
					local ndist2 = nox*nox + noy*noy + noz*noz
					if ndist2 <= radiusSquared then
						objectsFound[#objectsFound + 1] = node:GetObject()
						nodeDistances2[#nodeDistances2 + 1] = ndist2
					end
				end
			else
				OctreeRegionUtils.getNeighborsWithinRadius(
					childRegion, radius, px, py, pz, objectsFound, nodeDistances2, maxDepth)
			end
		end
	end
end

--[=[
	Recursively ensures that a subregion exists at a given depth, and returns
	that region for usage.

	@param region OctreeRegion<T> -- Top level region
	@param px number
	@param py number
	@param pz number
	@param maxDepth number
	@return OctreeRegion<T>
]=]
function OctreeRegionUtils.getOrCreateSubRegionAtDepth(region, px, py, pz, maxDepth)
	local current = region
	for _ = region.depth, maxDepth do
		local index = OctreeRegionUtils.getSubRegionIndex(current, px, py, pz)
		local _next = current.subRegions[index]

		-- construct
		if not _next then
			_next = OctreeRegionUtils.createSubRegion(current, index)
			current.subRegions[index] = _next
		end

		-- iterate
		current = _next
	end
	return current
end

--[=[
	Creates a subregion for an octree.
	@param parentRegion OctreeRegion<T>
	@param parentIndex number
	@return OctreeRegion<T>
]=]
function OctreeRegionUtils.createSubRegion(parentRegion, parentIndex)
	local size = parentRegion.size
	local position = parentRegion.position
	local multiplier = SUB_REGION_POSITION_OFFSET[parentIndex]

	local px = position[1] + multiplier[1]*size[1]
	local py = position[2] + multiplier[2]*size[2]
	local pz = position[3] + multiplier[3]*size[3]
	local sx, sy, sz = size[1]/2, size[2]/2, size[3]/2

	return OctreeRegionUtils.create(px, py, pz, sx, sy, sz, parentRegion, parentIndex)
end

--[=[
	Computes whether a region is in bounds.

	Consider regions to be range [px, y).

	@param region OctreeRegion<T>
	@param px number
	@param py number
	@param pz number
	@return boolean
]=]
function OctreeRegionUtils.inRegionBounds(region, px, py, pz)
	local lowerBounds = region.lowerBounds
	local upperBounds = region.upperBounds
	return (
		px >= lowerBounds[1] and px <= upperBounds[1] and
		py >= lowerBounds[2] and py <= upperBounds[2] and
		pz >= lowerBounds[3] and pz <= upperBounds[3]
	)
end

--[=[
	Gets a subregion's internal index.

	@param region OctreeRegion<T>
	@param px number
	@param py number
	@param pz number
	@return number
]=]
function OctreeRegionUtils.getSubRegionIndex(region, px, py, pz)
	local index = px > region.position[1] and 1 or 2
	if py <= region.position[2] then
		index = index + 4
	end

	if pz >= region.position[3] then
		index = index + 2
	end
	return index
end

--[=[
	This definitely collides fairly consistently

	See: https://stackoverflow.com/questions/5928725/hashing-2d-3d-and-nd-vectors

	@param cx number
	@param cy number
	@param cz number
	@return number
]=]
function OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)
	-- Normally you would modulus this to hash table size, but we want as flat of a structure as possible
	return cx * 73856093 + cy*19351301 + cz*83492791
end

--[=[
	Computes the index for a top level cell given a position

	@param maxRegionSize OctreeVector3
	@param px number
	@param py number
	@param pz number
	@return number -- rpx
	@return number -- rpy
	@return number -- rpz
]=]
function OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	return math.floor(px / maxRegionSize[1] + 0.5),
		math.floor(py / maxRegionSize[2] + 0.5),
		math.floor(pz / maxRegionSize[3] + 0.5)
end

--[=[
	Computes a top-level region's position

	@param maxRegionSize OctreeVector3
	@param cx number
	@param cy number
	@param cz number
	@return number
	@return number
	@return number
]=]
function OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	return maxRegionSize[1] * cx,
		maxRegionSize[2] * cy,
		maxRegionSize[3] * cz
end

--[=[
	Given a top-level region, returns if the region position are equal
	to this region

	@param region OctreeRegion<T>
	@param rpx number
	@param rpy number
	@param rpz number
	@return boolean
]=]
function OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz)
	local position = region.position
	return position[1] == rpx
		and position[2] == rpy
		and position[3] == rpz
end

--[=[
	Given a world space position, finds the current region in the hashmap

	@param regionHashMap { [number]: { OctreeRegion<T> } }
	@param maxRegionSize OctreeVector3
	@param px number
	@param py number
	@param pz number
	@return OctreeRegion3?
]=]
function OctreeRegionUtils.findRegion(regionHashMap, maxRegionSize, px, py, pz)
	local cx, cy, cz = OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	local hash = OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)

	local regionList = regionHashMap[hash]
	if not regionList then
		return nil
	end

	local rpx, rpy, rpz = OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	for _, region in pairs(regionList) do
		if OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz) then
			return region
		end
	end

	return nil
end

--[=[
	Gets the current region for a position, or creates a new one.

	@param regionHashMap { [number]: { OctreeRegion<T> } }
	@param maxRegionSize OctreeVector3
	@param px number
	@param py number
	@param pz number
	@return OctreeRegion<T>
]=]
function OctreeRegionUtils.getOrCreateRegion(regionHashMap, maxRegionSize, px, py, pz)
	local cx, cy, cz = OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	local hash = OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)

	local regionList = regionHashMap[hash]
	if not regionList then
		regionList = {}
		regionHashMap[hash] = regionList
	end

	local rpx, rpy, rpz = OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	for _, region in pairs(regionList) do
		if OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz) then
			return region
		end
	end

	local region = OctreeRegionUtils.create(
		rpx, rpy, rpz,
		maxRegionSize[1], maxRegionSize[2], maxRegionSize[3])
	table.insert(regionList, region)

	return region
end

return OctreeRegionUtils]========])

for _,name in ipairs({"SerenaFishing","SerenaBoat"})do local old=game.ReplicatedStorage:FindFirstChild(name)if old then old:Destroy()end local r=Instance.new("RemoteEvent")r.Name=name r.Parent=game.ReplicatedStorage end

local currency=SSS:FindFirstChild("SerenaCurrency")if currency then currency:Destroy()end currency=Instance.new("BindableFunction")currency.Name="SerenaCurrency"currency.Parent=SSS

source(SSS,"Script","SerenaBridgeServer",[========[local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")
local Bridge=require(game.ReplicatedStorage:WaitForChild("SerenaRuntime"):WaitForChild("BridgeLifecycle"))
local states={}
local function track(model)
 if not model:IsA("Model")or not model:IsDescendantOf(workspace)or states[model]then return end
 Bridge.prepare(model)states[model]=Bridge.new()Bridge.apply(model,states[model])
end
for _,m in ipairs(CollectionService:GetTagged("SerenaSuspensionBridge"))do track(m)end
CollectionService:GetInstanceAddedSignal("SerenaSuspensionBridge"):Connect(track)
CollectionService:GetInstanceRemovedSignal("SerenaSuspensionBridge"):Connect(function(m)states[m]=nil end)
while true do
 local positions={}
 for _,p in ipairs(Players:GetPlayers())do
  local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then table.insert(positions,r.Position)end
 end
 local now=workspace:GetServerTimeNow()
 for model,state in pairs(states)do
  if not model.Parent then states[model]=nil
  else
   local oldEmpty=state.emptySince
   local change=Bridge.step(state,Bridge.near(model,positions,state.visible),now)
   if change then Bridge.apply(model,state)
   elseif oldEmpty~=state.emptySince then model:SetAttribute("BridgeEmptySince",state.emptySince)end
  end
 end
 task.wait(.25)
end
]========])

source(SSS,"Script","SerenaFishingServer",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Storage=game:GetService("ServerStorage")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local core=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("FishingCore"))
local remote=RS:WaitForChild("SerenaFishing")local currency=script.Parent:WaitForChild("SerenaCurrency")
local items=Storage:WaitForChild("SerenaItems")local rodTemplate=items:WaitForChild("Vara de Pesca")local fishTemplate=items:WaitForChild("Carpa")
local world=workspace:WaitForChild("IlhaSerena")local pier=world:WaitForChild("PraiaEPier"):WaitForChild("PierDeMadeira")
local rodRack=pier:WaitForChild("SuporteDasVaras")local market=pier:WaitForChild("BalcaoDaPesca")
local fx=Instance.new("Folder")fx.Name="SerenaFishingFX"fx.Parent=workspace
local rng=Random.new()local requests={}
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=false
local function tool(p,attribute,value)
 local containers={p:FindFirstChildOfClass("Backpack"),p.Character}
 -- Avoid ipairs stopping at a temporarily absent backpack.
 for _,container in pairs(containers)do if container then for _,t in ipairs(container:GetChildren())do
  if t:IsA("Tool")and t:GetAttribute(attribute)==value then return t end
 end end end
end
local function character(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not r then return nil end
 local rod=tool(p,"SerenaItem","FishingRod")
 return {character=c,humanoid=h,root=r,rod=rod and rod.Parent==c and rod or nil}
end
local function giveRod(p,equip)
 local backpack=p:FindFirstChildOfClass("Backpack")local c=character(p)if not backpack or not c then return nil end
 local t=tool(p,"SerenaItem","FishingRod")
 if not t then t=rodTemplate:Clone()t.Parent=backpack end
 if equip then c.humanoid:EquipTool(t)end return t
end
local function giveFish(p,record)
 if tool(p,"SerenaFishId",record.id)then return end
 local backpack=p:FindFirstChildOfClass("Backpack")if not backpack then return end
 local t=fishTemplate:Clone()t.Name=string.format("Carpa • %.2f kg",record.weight)t.CanBeDropped=false
 t:SetAttribute("SerenaFishId",record.id)t:SetAttribute("WeightKg",record.weight)t:SetAttribute("FishValue",record.value)
 t.Parent=backpack
end
local fishing=core.new({
 clock=function()return workspace:GetServerTimeNow()end,
 character=character,random=function(a,b)return rng:NextNumber(a,b)end,guid=function()return HttpService:GenerateGUID(false)end,
 send=function(p,event,data)if p.Parent then remote:FireClient(p,event,data)end end,
 nearRod=function(point)return (point-rodRack.Position).Magnitude<=16 end,
 nearMarket=function(point)return (point-market.Position).Magnitude<=16 end,
 giveRod=giveRod,giveFish=giveFish,
 takeFish=function(p,id)local t=tool(p,"SerenaFishId",id)if t then t:Destroy()end end,
 credit=function(p,amount,id)return currency:Invoke(p,amount,id)end,
 water=function(point)
  local hit=workspace:Raycast(Vector3.new(point.X,80,point.Z),Vector3.new(0,-180,0),ray)
  return hit and hit.Material==Enum.Material.Water and hit.Position or nil
 end,
 makeVisual=function(p,rod,water)
  local m=Instance.new("Model")m.Name="Boia_"..p.UserId m:SetAttribute("OwnerUserId",p.UserId)m:SetAttribute("WaterPosition",water)
  local ball=Instance.new("Part")ball.Name="Boia"ball.Shape=Enum.PartType.Ball ball.Size=Vector3.new(.52,.62,.52)ball.Color=Color3.fromRGB(245,97,70)
  ball.Material=Enum.Material.SmoothPlastic ball.Anchored=true ball.CanCollide=false ball.CanTouch=false ball.CanQuery=false
  local tip=rod:FindFirstChild("LineTip",true)local position=water+Vector3.new(0,.2,0)
  ball.CFrame=CFrame.new(tip and tip.WorldPosition or position)ball.Parent=m
  local a=Instance.new("Attachment")a.Parent=ball
  local beam=Instance.new("Beam")beam.Name="LinhaDaVara"beam.Attachment0=tip beam.Attachment1=a beam.Width0=.025 beam.Width1=.015
  beam.Color=ColorSequence.new(Color3.fromRGB(235,242,240))beam.Transparency=NumberSequence.new(.15)beam.FaceCamera=true beam.Segments=12 beam.CurveSize0=1 beam.CurveSize1=0 beam.Parent=ball
  m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=fx
  TweenService:Create(ball,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.new(position)}):Play()
  return m
 end,
 removeVisual=function(m)if m.Parent then m:Destroy()end end,
 biteVisual=function(m)
  m:SetAttribute("FishBiting",true)local ball=m:FindFirstChild("Boia")local water=m:GetAttribute("WaterPosition")
  if ball then ball.Color=Color3.fromRGB(66,222,208)TweenService:Create(ball,TweenInfo.new(.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,6,true),{CFrame=CFrame.new(water-Vector3.new(0,.17,0))}):Play()end
 end,
})
local function added(p)
 fishing:add(p)
 p.CharacterAdded:Connect(function(c)task.spawn(function()
  c:WaitForChild("Humanoid",10)p:WaitForChild("Backpack",10)
  if p.Parent and p.Character==c then fishing:respawn(p)end
 end)end)
end
Players.PlayerAdded:Connect(added)for _,p in ipairs(Players:GetPlayers())do added(p)end
Players.PlayerRemoving:Connect(function(p)fishing:remove(p)requests[p]=nil end)
rodRack:WaitForChild("RodPrompt").Triggered:Connect(function(p)fishing:getRod(p)end)
market:WaitForChild("SellPrompt").Triggered:Connect(function(p)fishing:sell(p)end)
remote.OnServerEvent:Connect(function(p,action,target)
 if type(action)~="string"then return end
 local now=os.clock()if requests[p]and now-requests[p]<.15 then return end requests[p]=now
 fishing:dispatch(p,action,target)
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)elapsed+=dt if elapsed>=.1 then elapsed=0 fishing:tick()end end)
script.Destroying:Connect(function()fx:Destroy()end)
]========])

source(SSS,"Script","SerenaBoatServer",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local core=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("BoatController"))
local world=workspace:WaitForChild("IlhaSerena")
local boat=world:WaitForChild("PraiaEPier"):WaitForChild("BarcoDePesca")
local driver=boat:WaitForChild("DriverSeat")local passenger=boat:WaitForChild("PassengerSeat")
local remote=RS:WaitForChild("SerenaBoat")
local terrain=RaycastParams.new()terrain.FilterType=Enum.RaycastFilterType.Include terrain.FilterDescendantsInstances={workspace.Terrain}terrain.IgnoreWater=false
local obstacles=RaycastParams.new()obstacles.FilterType=Enum.RaycastFilterType.Exclude obstacles.RespectCanCollide=true obstacles.IgnoreWater=true
local function owner(seat)
 local h=seat.Occupant return h and h.Health>0 and Players:GetPlayerFromCharacter(h.Parent)or nil
end
local function surface(position)
 local hit=workspace:Raycast(Vector3.new(position.X,75,position.Z),Vector3.new(0,-170,0),terrain)
 return hit and hit.Material==Enum.Material.Water
end
local controller=core.new({
 clock=function()return workspace:GetServerTimeNow()end,
 driver=function()return owner(driver)end,passenger=function()return passenger.Occupant~=nil end,
 water=function(cf)
  for _,point in ipairs({Vector3.zero,Vector3.new(0,0,-5.6),Vector3.new(0,0,5.6),Vector3.new(-2.4,0,0),Vector3.new(2.4,0,0)})do
   if not surface(cf:PointToWorldSpace(point))then return false end
  end return true
 end,
 sweep=function(previous,nextCF)
  local exclude={boat}local effects=workspace:FindFirstChild("SerenaFishingFX")if effects then table.insert(exclude,effects)end
  for _,seat in ipairs({driver,passenger})do if seat.Occupant then table.insert(exclude,seat.Occupant.Parent)end end
  obstacles.FilterDescendantsInstances=exclude
  local displacement=nextCF.Position-previous.Position
  if displacement.Magnitude<.001 then return true end
  local hit=workspace:Blockcast(previous*CFrame.new(0,.2,0),Vector3.new(4.4,1.5,11),displacement,obstacles)
  return hit==nil
 end,
 move=function(cf,speed)
  local now=workspace:GetServerTimeNow()
  local bob=CFrame.new(0,math.sin(now*1.5)*.035,0)*CFrame.Angles(0,0,math.sin(now*1.1)*.008)
  boat:PivotTo(cf*bob)boat:SetAttribute("BoatSpeed",math.floor(math.abs(speed)*10+.5)/10)
 end,
},boat:GetAttribute("BoatHome"))
local requests={}
local function character(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not r then return end return c,h,r
end
local function board(p,seat)
 local c,h,r=character(p)if not c or seat.Occupant or h.SeatPart then return end
 if (r.Position-seat.Position).Magnitude>18 then return end
 h:UnequipTools()seat:Sit(h)
end
driver:WaitForChild("BoardPrompt").Triggered:Connect(function(p)board(p,driver)end)
passenger:WaitForChild("PassengerPrompt").Triggered:Connect(function(p)board(p,passenger)end)
local shorePrompt=world.PraiaEPier.PierDeMadeira:WaitForChild("Embarque"):WaitForChild("BoardPrompt")
shorePrompt.Triggered:Connect(function(p)
 if not driver.Occupant then board(p,driver)elseif not passenger.Occupant then board(p,passenger)end
end)
local function leave(p)
 local c,h=character(p)if not c or(h.SeatPart~=driver and h.SeatPart~=passenger)then return end
 local near=(boat:GetPivot().Position-Vector3.new(100,.9,347)).Magnitude<22
 h.Sit=false
 for _,seat in ipairs({driver,passenger})do
  local weld=seat:FindFirstChild("SeatWeld")if weld and weld.Part1 and weld.Part1:IsDescendantOf(c)then weld:Destroy()end
 end
 h:ChangeState(Enum.HumanoidStateType.Jumping)
 if near then task.delay(.15,function()
  if p.Character==c and h.Health>0 and not h.SeatPart then c:PivotTo(CFrame.new(100,10.5,347))end
 end)end
end
remote.OnServerEvent:Connect(function(p,action,throttle,steer)
 local now=os.clock()if requests[p]and now-requests[p]<.07 then return end requests[p]=now
 if action=="Drive"then controller:drive(p,throttle,steer)
 elseif action=="Exit"then leave(p)end
end)
Players.PlayerRemoving:Connect(function(p)requests[p]=nil end)
RunService.Heartbeat:Connect(function(dt)controller:tick(dt)end)
for _,seat in ipairs({driver,passenger})do
 seat:GetPropertyChangedSignal("Occupant"):Connect(function()
  local p=owner(seat)if p then remote:FireClient(p,"Boarded",seat==driver)end
 end)
end
]========])

source(SSS,"Script","SerenaDoorServer",[========[local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")
local TweenService=game:GetService("TweenService")
local doors={}
local function track(m)
 if m:IsA("Model")and m:IsDescendantOf(workspace)then doors[m]={open=false,tweens={},lastNear=0}end
end
for _,m in ipairs(CollectionService:GetTagged("SerenaAutomaticDoor"))do track(m)end
CollectionService:GetInstanceAddedSignal("SerenaAutomaticDoor"):Connect(track)
CollectionService:GetInstanceRemovedSignal("SerenaAutomaticDoor"):Connect(function(m)doors[m]=nil end)
while true do
 local positions={}
 for _,p in ipairs(Players:GetPlayers())do local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then table.insert(positions,r.Position)end
 end
 local now=os.clock()
 for model,state in pairs(doors)do
  if not model.Parent then doors[model]=nil
  else
   local hinge=model:GetAttribute("DoorHingeCF")local near=false
   for _,point in ipairs(positions)do if(point-(hinge.Position+Vector3.new(0,3,0))).Magnitude<10 then near=true break end end
   if near then state.lastNear=now end
   local open=near or(state.open and now-state.lastNear<3)
   if open~=state.open then
    state.open=open for _,t in ipairs(state.tweens)do t:Cancel()end table.clear(state.tweens)
    for _,part in ipairs(model:GetDescendants())do if part:IsA("BasePart")and part:GetAttribute("DoorRestCF")then
     local rest=part:GetAttribute("DoorRestCF")local target=open and hinge*CFrame.Angles(0,math.rad(-95),0)*hinge:ToObjectSpace(rest)or rest
     local t=TweenService:Create(part,TweenInfo.new(.45,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{CFrame=target})table.insert(state.tweens,t)t:Play()
    end end
   end
  end
 end
 task.wait(.2)
end
]========])

source(SSS,"Script","SerenaShopServer",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local DataStoreService=game:GetService("DataStoreService")
local Rules=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("ItemRules"))
local Effect=require(script.Parent:WaitForChild("SerenaInvisibility"))
local remote=RS:WaitForChild("SerenaShop")
local template=ServerStorage:WaitForChild("SerenaItems"):WaitForChild("Maçã da Névoa")
local prompt=workspace:WaitForChild("IlhaSerena"):WaitForChild("VilaCosteira"):WaitForChild("FeiraDeFrutas"):WaitForChild("Banca"):WaitForChild("SerenaShopPrompt")
prompt.Triggered:Connect(function(p)remote:FireClient(p,"Open")end)
local store=DataStoreService:GetDataStore("SerenaItems_v1")
local profiles={} local temporary={} local busy={} local requestTimes={} local active={}
local function attributes(p,data)
 p:SetAttribute("SerenaCoins",data.coins) p:SetAttribute("SerenaAppleOwned",data.apple)
 p:SetAttribute("SerenaAppleReadyAt",data.nextAppleAt) p:SetAttribute("SerenaDataSaved",not temporary[p])
 p:SetAttribute("SerenaShopReady",true)
end
local function message(p,text,ok)
 if p.Parent then remote:FireClient(p,"Message",text,ok==true) end
end
local function transaction(p,action,payload)
 if not profiles[p] or busy[p] then return false,"Aguarde um instante." end
 busy[p]=true
 local now=workspace:GetServerTimeNow() local accepted=false local feedback=""
 local result
 if not temporary[p] then
  local ok,data=pcall(function()
   return store:UpdateAsync("u"..p.UserId,function(old)
    local nextData,succeeded,text=Rules.apply(old,action,now,payload)
    accepted=succeeded feedback=text return nextData
   end)
  end)
  if ok then result=Rules.profile(data)
  else
   -- Do not acknowledge a permanent purchase if saving failed.
   busy[p]=nil return false,"Não foi possível salvar agora. Tente novamente."
  end
 else result,accepted,feedback=Rules.apply(profiles[p],action,now,payload) end
 profiles[p]=result if p.Parent then attributes(p,result) end
 busy[p]=nil return accepted,feedback
end
-- Private server endpoint: clients cannot invoke BindableFunctions in ServerScriptService.
local currency=script.Parent:WaitForChild("SerenaCurrency")
currency.OnInvoke=function(p,amount,id)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players then return false,"Jogador indisponível." end
 return transaction(p,"Credit",{amount=amount,id=id})
end
local useApple
local function ensureApple(p)
 if not profiles[p] or not profiles[p].apple then return nil end
 local backpack=p:FindFirstChildOfClass("Backpack") if not backpack then return nil end
 for _,container in ipairs({backpack,p.Character}) do
  if container then for _,d in ipairs(container:GetChildren()) do
   if d:IsA("Tool") and d:GetAttribute("SerenaItem")=="Apple" then return d end
  end end
 end
 local tool=template:Clone() tool.CanBeDropped=false tool.Parent=backpack
 tool.Activated:Connect(function()if p.Character and tool.Parent==p.Character then useApple(p) end end)
 return tool
end
useApple=function(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 or active[p] then return end
 local item=ensureApple(p) if not item then message(p,"Compre a maçã primeiro.",false) return end
 if item.Parent~=c then h:EquipTool(item) end
 local accepted,feedback=transaction(p,"UseApple")
 if not accepted then message(p,feedback,false) return end
 -- A respawn during DataStore I/O must never hide the replacement character.
 if not p.Parent or p.Character~=c or h.Health<=0 or not c.Parent then return end
 local restore=Effect.begin(c)
 active[p]={character=c,restore=restore}
 p:SetAttribute("SerenaInvisibleUntil",workspace:GetServerTimeNow()+Rules.Duration)
 message(p,feedback,true)
 task.delay(Rules.Duration,function()
  restore()
  if active[p] and active[p].character==c then active[p]=nil if p.Parent then p:SetAttribute("SerenaInvisibleUntil",0) end end
 end)
end
local function character(p,c)
 local effect=active[p]
 if effect then effect.restore() active[p]=nil p:SetAttribute("SerenaInvisibleUntil",0) end
 task.spawn(function()
  c:WaitForChild("Humanoid",10) p:WaitForChild("Backpack",10)
  if p.Character==c then ensureApple(p) end
 end)
end
local function added(p)
 p:SetAttribute("SerenaShopReady",false)
 p.CharacterAdded:Connect(function(c)character(p,c)end)
 local ok,data=pcall(function()
  return store:UpdateAsync("u"..p.UserId,function(old)return Rules.profile(old)end)
 end)
 if not p.Parent then return end
 profiles[p]=Rules.profile(ok and data or nil) temporary[p]=not ok
 attributes(p,profiles[p])
 if p.Character then character(p,p.Character) end
end
Players.PlayerAdded:Connect(function(p)task.spawn(added,p)end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Players.PlayerRemoving:Connect(function(p)
 if active[p] then active[p].restore() end
 profiles[p]=nil temporary[p]=nil busy[p]=nil requestTimes[p]=nil active[p]=nil
end)
remote.OnServerEvent:Connect(function(p,action)
 if action~="BuyApple" and action~="UseApple" then return end
 local now=os.clock() if requestTimes[p] and now-requestTimes[p]<.35 then return end requestTimes[p]=now
 if action=="UseApple" then useApple(p) return end
 if not p:FindFirstChildOfClass("Backpack") then message(p,"Espere o personagem aparecer.",false) return end
 local accepted,feedback=transaction(p,action)
 if accepted or (profiles[p] and profiles[p].apple) then ensureApple(p) end
 message(p,feedback,accepted)
end)
-- Rewards are generated by elapsed server time, never by a client claim.
task.spawn(function()
 local nextAward={}
 while true do
  local now=workspace:GetServerTimeNow()
  for _,p in ipairs(Players:GetPlayers()) do
   if profiles[p] then
    nextAward[p]=nextAward[p] or now+Rules.AwardInterval
    if now>=nextAward[p] and not busy[p] then
     nextAward[p]=now+Rules.AwardInterval
     task.spawn(function()local ok,text=transaction(p,"Award") if ok then message(p,text,true) end end)
    end
   end
  end
  for p in pairs(nextAward) do if not p.Parent then nextAward[p]=nil end end
  task.wait(1)
 end
end)
]========])

source(SPS,"LocalScript","SerenaBridgeAnimation",[========[local TweenService=game:GetService("TweenService")
local CollectionService=game:GetService("CollectionService")
local records={}
local function cancel(record)
 record.serial+=1
 for _,t in ipairs(record.tweens)do t:Cancel()end
 table.clear(record.tweens)
end
local function update(model,record)
 if not model.Parent then return end
 local visible=model:GetAttribute("BridgeVisible")==true
 local generation=model:GetAttribute("BridgeGeneration")or 0
 if record.visible==visible and record.generation==generation then return end
 cancel(record)record.visible=visible record.generation=generation
 local serial=record.serial
 local elapsed=math.max(0,workspace:GetServerTimeNow()-(model:GetAttribute("BridgeShownAt")or 0))
 local construct=visible and model:GetAttribute("AnimateConstruction")~=false and elapsed<(model:GetAttribute("ConstructionDuration")or 6)
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("BasePart")and p:GetAttribute("BridgeRestCF")then
   local rest=p:GetAttribute("BridgeRestCF")local size=p:GetAttribute("BridgeRestSize")or p.Size
   local alpha=p:GetAttribute("BridgeAlpha")or 0
   p.CFrame=rest p.Size=size p.Transparency=visible and alpha or 1
   if visible then
    local reveal=p:GetAttribute("BridgeRevealAt")or 0
    local delay=construct and math.max(0,reveal-elapsed)or 0
    local drop=construct and elapsed<reveal+.5
    if drop then p.CFrame=rest+Vector3.new(0,model:GetAttribute("DropHeight")or 12,0)p.Transparency=1 end
    task.delay(delay,function()
     if not p.Parent or record.serial~=serial or not model:GetAttribute("BridgeVisible")then return end
     if drop then
      local tween=TweenService:Create(p,TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=rest,Transparency=alpha})
      table.insert(record.tweens,tween)tween:Play()
     end
     if p:GetAttribute("BridgeOrb")then
      task.delay(drop and .55 or 0,function()
       if not p.Parent or record.serial~=serial or not model:GetAttribute("BridgeVisible")then return end
       local pulse=TweenService:Create(p,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Size=size*1.38})
       table.insert(record.tweens,pulse)pulse:Play()
      end)
     end
    end)
   end
  end
 end
end
local function track(model)
 if not model:IsA("Model")or not model:IsDescendantOf(workspace)or records[model]then return end
 local record={serial=0,tweens={},connections={}}records[model]=record
 for _,name in ipairs({"BridgeVisible","BridgeGeneration","BridgeShownAt"})do
  table.insert(record.connections,model:GetAttributeChangedSignal(name):Connect(function()update(model,record)end))
 end
 update(model,record)
end
local function remove(model)
 local record=records[model]if not record then return end cancel(record)
 for _,c in ipairs(record.connections)do c:Disconnect()end records[model]=nil
end
for _,m in ipairs(CollectionService:GetTagged("SerenaSuspensionBridge"))do track(m)end
CollectionService:GetInstanceAddedSignal("SerenaSuspensionBridge"):Connect(track)
CollectionService:GetInstanceRemovedSignal("SerenaSuspensionBridge"):Connect(remove)
script.Destroying:Connect(function()for m in pairs(records)do remove(m)end end)
]========])

source(SPS,"LocalScript","SerenaFishingClient",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local fishing=RS:WaitForChild("SerenaFishing")local boating=RS:WaitForChild("SerenaBoat")
local gui=Instance.new("ScreenGui")gui.Name="SerenaFishingUI"gui.ResetOnSpawn=false gui.IgnoreGuiInset=false gui.DisplayOrder=22 gui.Parent=player:WaitForChild("PlayerGui")
local function corners(o,r)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,r or 12)c.Parent=o end
local function text(parent,name,size,pos,label,bold)
 local t=Instance.new("TextLabel")t.Name=name t.Size=size t.Position=pos t.BackgroundTransparency=1 t.Text=label
 t.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham t.TextSize=bold and 13 or 12 t.TextColor3=Color3.fromRGB(224,235,230)t.TextWrapped=true t.Parent=parent return t
end
local function button(parent,name,label,size,pos)
 local b=Instance.new("TextButton")b.Name=name b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(53,104,95)b.TextColor3=Color3.fromRGB(243,255,248)
 b.Font=Enum.Font.GothamBold b.TextSize=13 b.Text=label b.AutoButtonColor=true b.Parent=parent corners(b,9)return b
end
local panel=Instance.new("Frame")panel.Name="FishingPanel"panel.AnchorPoint=Vector2.new(.5,1)panel.Position=UDim2.new(.5,0,1,-128)panel.Size=UDim2.fromOffset(284,118)
panel.BackgroundColor3=Color3.fromRGB(23,42,40)panel.BackgroundTransparency=.08 panel.Visible=false panel.Parent=gui corners(panel,14)
local stroke=Instance.new("UIStroke")stroke.Color=Color3.fromRGB(109,169,147)stroke.Transparency=.5 stroke.Thickness=1 stroke.Parent=panel
local title=text(panel,"Title",UDim2.new(1,-20,0,22),UDim2.fromOffset(10,6),"PESCARIA",true)
local status=text(panel,"Status",UDim2.new(1,-22,0,29),UDim2.fromOffset(11,27),"Pegue uma vara grátis no píer.",false)
local action=button(panel,"FishingAction","LANÇAR LINHA",UDim2.fromOffset(179,39),UDim2.fromOffset(10,62))
local cancel=button(panel,"FishingCancel","RECOLHER",UDim2.fromOffset(75,39),UDim2.fromOffset(199,62))cancel.TextSize=10 cancel.BackgroundColor3=Color3.fromRGB(54,65,62)
local sell=button(panel,"SellFish","VENDER",UDim2.fromOffset(75,39),UDim2.fromOffset(199,62))sell.TextSize=11
local bar=Instance.new("Frame")bar.Name="BiteProgress"bar.Position=UDim2.fromOffset(11,108)bar.Size=UDim2.new(1,-22,0,3)bar.BackgroundColor3=Color3.fromRGB(56,79,72)bar.BorderSizePixel=0 bar.Parent=panel corners(bar,2)
local fill=Instance.new("Frame")fill.Name="Fill"fill.Size=UDim2.fromScale(0,1)fill.BackgroundColor3=Color3.fromRGB(241,188,105)fill.BorderSizePixel=0 fill.Parent=bar corners(fill,2)
local boatPanel=Instance.new("Frame")boatPanel.Name="BoatPanel"boatPanel.AnchorPoint=Vector2.new(.5,1)boatPanel.Position=UDim2.new(.5,0,1,-128)boatPanel.Size=UDim2.fromOffset(284,115)
boatPanel.BackgroundColor3=Color3.fromRGB(23,42,40)boatPanel.BackgroundTransparency=.08 boatPanel.Visible=false boatPanel.Parent=gui corners(boatPanel,14)
local boatTitle=text(boatPanel,"BoatTitle",UDim2.new(1,-20,0,24),UDim2.fromOffset(10,4),"BARCO DE PESCA",true)
local boatHint=text(boatPanel,"BoatHint",UDim2.new(1,-20,0,23),UDim2.fromOffset(10,27),"WASD ou joystick • pule para sair",false)
local exit=button(boatPanel,"ExitBoat","SAIR",UDim2.fromOffset(54,38),UDim2.fromOffset(220,62))exit.TextSize=11
local controls={}
for i,row in ipairs({{"Left","◀"},{"Forward","▲"},{"Back","▼"},{"Right","▶"}})do
 local b=button(boatPanel,row[1],row[2],UDim2.fromOffset(44,38),UDim2.fromOffset(10+(i-1)*49,62))controls[row[1]]=b
end
local toast=Instance.new("Frame")toast.Name="FishingNotice"toast.AnchorPoint=Vector2.new(.5,1)toast.Position=UDim2.new(.5,0,1,-254)toast.Size=UDim2.fromOffset(284,46)
toast.BackgroundColor3=Color3.fromRGB(27,47,41)toast.Visible=false toast.Parent=gui corners(toast,11)
local toastText=text(toast,"NoticeText",UDim2.new(1,-20,1,-10),UDim2.fromOffset(10,5),"",false)
local state={phase="Idle",count=0,value=0,rod=false,deadline=0,maxFish=12}
local currentRod local activation local gripTween local originalGrip
local noticeId=0 local held={}local heldInputs={}
local function notice(message,ok)
 noticeId+=1 local id=noticeId toast.Visible=true toastText.Text=message
 toast.BackgroundColor3=ok and Color3.fromRGB(28,73,56)or Color3.fromRGB(78,56,39)
 task.delay(3.5,function()if noticeId==id then toast.Visible=false end end)
end
local function send(actionName,target)fishing:FireServer(actionName,target)end
local function aim(useMouse)
 local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")local camera=workspace.CurrentCamera
 if not root or not camera then return Vector3.zero end
 local ray
 if useMouse and not UIS.TouchEnabled then ray=player:GetMouse().UnitRay
 else ray=camera:ViewportPointToRay(camera.ViewportSize.X*.5,camera.ViewportSize.Y*.48)end
 local parameters=RaycastParams.new()parameters.FilterType=Enum.RaycastFilterType.Include parameters.FilterDescendantsInstances={workspace.Terrain}parameters.IgnoreWater=false
 local hit=workspace:Raycast(ray.Origin,ray.Direction*250,parameters)
 if hit and(hit.Position-root.Position).Magnitude<=42 then return hit.Position end
 local forward=camera.CFrame.LookVector*Vector3.new(1,0,1)
 if forward.Magnitude<.1 then forward=root.CFrame.LookVector*Vector3.new(1,0,1)end
 return root.Position+forward.Unit*25
end
local function castAnimation()
 local rod=currentRod if not rod then return end
 if gripTween then gripTween:Cancel()end
 originalGrip=originalGrip or rod.Grip
 gripTween=TweenService:Create(rod,TweenInfo.new(.18,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Grip=originalGrip*CFrame.Angles(math.rad(25),0,0)})gripTween:Play()
 task.delay(.22,function()
  if currentRod==rod and rod.Parent==player.Character then
   gripTween=TweenService:Create(rod,TweenInfo.new(.28,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Grip=originalGrip})gripTween:Play()
  end
 end)
end
local function act(useMouse)
 if not currentRod then send("GetRod")return end
 if state.phase=="Bite"then send("Reel")castAnimation()
 elseif state.phase=="Idle"then send("Cast",aim(useMouse))castAnimation()
 else send("Cancel")end
end
local function connectButton(b,fn)b.Activated:Connect(fn)end
connectButton(action,function()act(false)end)
connectButton(cancel,function()send("Cancel")end)
connectButton(sell,function()send("Sell")end)
connectButton(exit,function()boating:FireServer("Exit")end)
for name,b in pairs(controls)do
 b.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then held[name]=true heldInputs[input]=name end
 end)
end
UIS.InputEnded:Connect(function(input)local name=heldInputs[input]if name then heldInputs[input]=nil held[name]=nil end end)
local function resetRod()
 if activation then activation:Disconnect()activation=nil end
 if gripTween then gripTween:Cancel()gripTween=nil end
 if currentRod and currentRod.Parent and originalGrip then currentRod.Grip=originalGrip end
 currentRod=nil originalGrip=nil
end
fishing.OnClientEvent:Connect(function(event,data)
 if event=="State"then state=data
 elseif event=="Message"then notice(data.text,data.ok)
 elseif event=="Caught"then notice(string.format("Carpa • %.2f kg • %d moedas",data.weight,data.value),true)end
end)
boating.OnClientEvent:Connect(function(event,isDriver)
 if event=="Boarded"then notice(isDriver and "Use WASD, joystick ou as setas para navegar."or "Você pode equipar a vara e pescar aqui.",true)end
end)
local elapsed=0 local driveElapsed=0 local seatedPreviously=false
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt driveElapsed+=dt if elapsed<.1 then return end elapsed=0
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not root then panel.Visible=false boatPanel.Visible=false resetRod()return end
 local equipped
 for _,t in ipairs(c:GetChildren())do if t:IsA("Tool")and t:GetAttribute("SerenaItem")=="FishingRod"then equipped=t break end end
 if equipped~=currentRod then
  resetRod()currentRod=equipped
  if equipped then originalGrip=equipped.Grip activation=equipped.Activated:Connect(function()act(true)end)end
 end
 local near=(root.Position-Vector3.new(100,7,316)).Magnitude<23
 local seat=h.SeatPart local inBoat=seat and seat:GetAttribute("SerenaBoatSeat")==true
 local driving=inBoat and seat:IsA("VehicleSeat")
 panel.Visible=currentRod~=nil or(near and not inBoat)
 boatPanel.Visible=inBoat and not currentRod or false
 title.Text=string.format("PESCARIA  •  %d/%d  •  %d moedas",state.count or 0,state.maxFish or 12,state.value or 0)
 cancel.Visible=currentRod~=nil and state.phase~="Idle"sell.Visible=not cancel.Visible and near
 if not currentRod then
  action.Text="PEGAR VARA"status.Text="Vara grátis • venda os peixes antes de sair."
 elseif state.phase=="Waiting"then action.Text="RECOLHER LINHA"status.Text="Aguarde a boia afundar."
 elseif state.phase=="Bite"then action.Text="PUXAR AGORA!"status.Text="Fisgou! Puxe antes de o peixe escapar."
 else action.Text="LANÇAR LINHA"status.Text="Mire na água e lance a linha."end
 local bite=state.phase=="Bite"action.BackgroundColor3=bite and Color3.fromRGB(151,103,40)or Color3.fromRGB(53,104,95)
 fill.Size=UDim2.fromScale(bite and math.clamp((state.deadline-workspace:GetServerTimeNow())/3,0,1)or 0,1)
 for _,b in pairs(controls)do b.Visible=driving end
 boatTitle.Text=driving and "BARCO DE PESCA • CONDUTOR"or "BARCO DE PESCA • PASSAGEIRO"
 boatHint.Text=driving and "WASD, joystick ou setas • pule para sair"or "Equipe sua vara para pescar no barco."
 if not inBoat and seatedPreviously then table.clear(held)table.clear(heldInputs)end seatedPreviously=inBoat==true
 if driving and driveElapsed>=.1 then
  driveElapsed=0
  local throttle=held.Forward and 1 or(held.Back and -1 or seat.ThrottleFloat)
  local steer=held.Right and 1 or(held.Left and -1 or seat.SteerFloat)
  boating:FireServer("Drive",throttle,steer)
 end
end)
player.CharacterAdded:Connect(function()resetRod()table.clear(held)table.clear(heldInputs)send("Sync")end)
task.delay(2,function()send("Sync")end)
script.Destroying:Connect(function()resetRod()gui:Destroy()end)
]========])

source(SPS,"LocalScript","SerenaGrassClient",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local UIS=game:GetService("UserInputService")
local runtime=RS:WaitForChild("SerenaRuntime")local world=workspace:WaitForChild("IlhaSerena")
local SkinnedGrass=require(runtime:WaitForChild("SkinnedGrass"))
local template=runtime:WaitForChild("SkinnedGrassTemplates"):WaitForChild("FineStudio")
local coverage=runtime:WaitForChild("GrassCoverage")local player=Players.LocalPlayer
local visible=Instance.new("Folder")visible.Name="SerenaInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="SerenaGrassLocalStorage"storage.Parent=RS
local renderDistance=UIS.TouchEnabled and 215 or 340
local grass=SkinnedGrass.new({
 RenderDistance=renderDistance,MeshStorage=storage,
 RenderInAnimation=TweenInfo.new(.35,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 RenderOutAnimation=TweenInfo.new(.2,Enum.EasingStyle.Sine,Enum.EasingDirection.In),
 RenderOutOffset=CFrame.new(0,-2,0),CollisionDistance=55,
 CollisionRadiusInner=1.2,CollisionRadiusOuter=3.2,CollisionAngle=68,
 CollisionReturnDelay=.08,CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 WindDistanceInner=UIS.TouchEnabled and 30 or 45,WindDistanceOuter=UIS.TouchEnabled and 80 or 120,
 WindFramerateInner=1,WindFramerateOuter=.25,UseGlobalWind=true,
})
local cells=coverage:GetChildren()local loaded={}local completed=false local generation=0
local function rootOf(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if h and h.Health>0 and r then return r,h end
end
local function add(cell)
 if loaded[cell]then return end loaded[cell]=true
 local model=template:Clone()model.Name=cell.Name model:PivotTo(CFrame.new(cell:GetAttribute("Center")))model.Parent=visible
 local mesh=model:FindFirstChildOfClass("MeshPart")local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then table.insert(bones,b)end end
 table.sort(bones,function(a,b)return a.Name<b.Name end)
 local heights=HttpService:JSONDecode(cell:GetAttribute("Heights"))
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=heights[i]
  local point=type(height)=="number"and Vector3.new(original.X,height-.045,original.Z)or(original-Vector3.new(0,240,0))
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)b:SetAttribute("SerenaGreenRoot",type(height)=="number")b.Transform=offset
 end
 grass:AddMeshes({model})
end
-- Coverage exists for the whole island. Load nearby volumes first, then the remaining field.
task.spawn(function()
 while not completed and script.Parent do
  local r=rootOf(player)
  if r then
   table.sort(cells,function(a,b)return(a:GetAttribute("Center")-r.Position).Magnitude<(b:GetAttribute("Center")-r.Position).Magnitude end)
   for _,cell in ipairs(cells)do if not loaded[cell]then
    add(cell)generation+=1 player:SetAttribute("SerenaGrassLoadedPatches",generation)
    if generation%3==0 then task.wait()end
   end end
   completed=true player:SetAttribute("SerenaWholeMapGrassReady",true)
  else task.wait(.15)end
 end
end)
local time=0
RunService.RenderStepped:Connect(function(dt)
 time+=dt if time<(UIS.TouchEnabled and 1/24 or 1/30)then return end local step=math.min(time,.1)time=0
 local r=rootOf(player)if not r then return end
 local actors={}
 for _,p in ipairs(Players:GetPlayers())do
  local root,humanoid=rootOf(p)
  if root and(root.Position-r.Position).Magnitude<65 then
   local feet=root.Position.Y-(humanoid.RigType==Enum.HumanoidRigType.R6 and 3 or humanoid.HipHeight+root.Size.Y/2)
   table.insert(actors,Vector3.new(root.Position.X,feet+.1,root.Position.Z))
  end
 end
 grass:Step(step,actors,r.Position)
end)
script.Destroying:Connect(function()visible:Destroy()storage:Destroy()table.clear(loaded)end)
]========])

source(SPS,"LocalScript","SerenaWindClient",[========[local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local UIS=game:GetService("UserInputService")
local effects=RS:WaitForChild("SerenaRuntime"):WaitForChild("WindEffects")
local WindLines=require(effects:WaitForChild("WindLines"))
local WindShake=require(effects:WaitForChild("WindShake"))
while not workspace.CurrentCamera do RunService.Heartbeat:Wait()end
local function tag(p)
 if p:IsA("BasePart")and p:IsDescendantOf(workspace)then
  local rest=p:GetAttribute("SerenaRestCF")or p.CFrame
  p.CFrame=rest p:SetAttribute("WindPower",p.Name=="Leaves"and .32 or .22)
  CollectionService:AddTag(p,"WindShake")
 end
end
for _,p in ipairs(CollectionService:GetTagged("SerenaWindFoliage"))do tag(p)end
CollectionService:GetInstanceAddedSignal("SerenaWindFoliage"):Connect(tag)
CollectionService:GetInstanceRemovedSignal("SerenaWindFoliage"):Connect(function(p)CollectionService:RemoveTag(p,"WindShake")end)
WindLines:Init({Direction=Vector3.new(1,0,.3).Unit,Speed=14,Lifetime=2,SpawnRate=UIS.TouchEnabled and 9 or 15})
WindShake:SetDefaultSettings({WindDirection=Vector3.new(1,0,.3).Unit,WindSpeed=14,WindPower=.35})WindShake:Init()
local floating={}
for _,p in ipairs(CollectionService:GetTagged("SerenaFloatingDetail"))do if p:IsA("BasePart")then floating[p]=p:GetAttribute("SerenaRestCF")or p.CFrame end end
CollectionService:GetInstanceAddedSignal("SerenaFloatingDetail"):Connect(function(p)if p:IsA("BasePart")then floating[p]=p:GetAttribute("SerenaRestCF")or p.CFrame end end)
CollectionService:GetInstanceRemovedSignal("SerenaFloatingDetail"):Connect(function(p)floating[p]=nil end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.35 then return end elapsed=0
 local wind=workspace.GlobalWind local speed=math.clamp(wind.Magnitude*1.5,8,32)local direction=wind.Magnitude>.01 and wind.Unit or Vector3.new(1,0,.3).Unit
 WindLines.Direction=direction WindLines.Speed=speed WindShake:SetDefaultSettings({WindDirection=direction,WindSpeed=speed,WindPower=.28+math.min(wind.Magnitude,20)*.009})
 local now=workspace:GetServerTimeNow()
 for p,rest in pairs(floating)do if p.Parent then p.CFrame=rest+Vector3.new(0,math.sin(now*1.15+rest.X*.04)*.055,0)else floating[p]=nil end end
end)
script.Destroying:Connect(function()WindLines:Cleanup()WindShake:Cleanup()end)
]========])

world:SetAttribute("WindEffectsAssetId",11946229834)world:SetAttribute("DayLength",600)world:SetAttribute("ClockStart",nil)world:SetAttribute("WeatherChanged",nil)

local geometry=run([========[local w=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime
local Bridge=require(runtime.BridgeLifecycle)
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,w}ray.IgnoreWater=true ray.RespectCanCollide=true
local overlap=OverlapParams.new()overlap.FilterType=Enum.RaycastFilterType.Include overlap.FilterDescendantsInstances={w}overlap.RespectCanCollide=true
local samples=0 local maximum=0
local function walk(points,label,width)
 local last
 for _,point in ipairs(points)do
  local hit=workspace:Raycast(Vector3.new(point.X,100,point.Z),Vector3.new(0,-180,0),ray)assert(hit,"Missing floor: "..label)
  if last then
   local distance=(Vector3.new(point.X,0,point.Z)-Vector3.new(last.point.X,0,last.point.Z)).Magnitude
   local grade=math.abs(hit.Position.Y-last.height)/distance maximum=math.max(maximum,grade)
   assert(grade<.65,"Steep walking lip: "..label..":"..point.Z..":"..grade)
  end
  assert(hit.Normal.Y>.83,"Unsafe slope: "..label)
  local blockers=workspace:GetPartBoundsInBox(CFrame.new(point.X,hit.Position.Y+3.35,point.Z),Vector3.new(width or 2.1,5.1,1),overlap)
  assert(#blockers==0,"Blocked walking path: "..label..":"..(#blockers>0 and blockers[1]:GetFullName()or ""))
  last={point=point,height=hit.Position.Y}samples+=1
 end
end
for _,z in ipairs({70,124})do
 local bridge=w.TrilhasEMirante["Ponte"..z]Bridge.prepare(bridge)local state=Bridge.new()Bridge.step(state,true,workspace:GetServerTimeNow())Bridge.apply(bridge,state)
 local points={}
 for x=bridge:GetAttribute("SpanLeft")-6,bridge:GetAttribute("SpanRight")+6,.75 do table.insert(points,Vector3.new(x,0,z))end
 walk(points,bridge.Name,3)
end
local points={}
for z=255,w.PraiaEPier.PierDeMadeira:GetAttribute("PierEndZ")-.3,.65 do table.insert(points,Vector3.new(100,0,z))end
walk(points,"Beach to real wooden pier",2.1)
local doors=0 local realTrees=0 local grounded=0 local allTrees=0
local groundRay=RaycastParams.new()groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={workspace.Terrain}groundRay.IgnoreWater=true
for _,home in ipairs(w.VilaCosteira:GetChildren())do if home:IsA("Model")and home:GetAttribute("SerenaHouse")then
 assert((home:GetAttribute("SourceAssetId")==12346232595 or home:GetAttribute("SourceAssetId")==2109355142) and home:GetAttribute("Furnished"),"Furnished house import lost")
 local cf=home:GetAttribute("EntranceCF")
 for z=-.6,.6,.6 do
  local at=cf*CFrame.new(0,3,z)local blockers=workspace:GetPartBoundsInBox(at,Vector3.new(2.05,5, .7),overlap)
  assert(#blockers==0,"Blocked imported door: "..home.Name..":"..(#blockers>0 and blockers[1]:GetFullName()or ""))
 end
 local door=home:FindFirstChild("PortaMovel",true)assert(door and #door:GetDescendants()>=5,"Automatic door missing")
 doors+=1
end end
assert(doors==7,"Seven cottages not present")
for _,tree in ipairs(w.Bosque:GetChildren())do if tree:IsA("Model")and(tree.Name=="Árvore"or tree.Name=="Palmeira")then
 allTrees+=1 local cf=tree:GetAttribute("SerenaRootCF")assert(cf,"Root marker absent")
 local hit=workspace:Raycast(cf.Position+Vector3.new(0,100,0),Vector3.new(0,-200,0),groundRay)
 assert(hit and math.abs(hit.Position.Y-cf.Y)<.02,"Floating root marker")grounded+=1
 if tree.Name=="Árvore"then assert(tree:GetAttribute("SourceAssetId")==128707014921507,"Oak mesh missing")realTrees+=1 end
end end
assert(realTrees==100 and grounded==allTrees,"Grounded grove incomplete")
local parts=0 local meshes=0
for _,p in ipairs(w:GetDescendants())do
 assert(not p:IsA("LuaSourceContainer"),"Imported script in scenery")
 if p:IsA("BasePart")then parts+=1 assert(p.Anchored,"Unanchored scenery")if p:IsA("MeshPart")then meshes+=1 assert(p.MeshId~="","Empty mesh")end end
end
assert(parts<7500,"Scene part budget exceeded")
for _,name in ipairs({"Maçã da Névoa","Vara de Pesca","Carpa"})do
 local t=game.ServerStorage.SerenaItems[name]assert(t:IsA("Tool")and t:GetAttribute("SourceAssetId"),"Real tool template missing")
 local handles=0
 for _,p in ipairs(t:GetChildren())do if p:IsA("BasePart")and p.Name=="Handle"then handles+=1 end end
 assert(handles==1 and t.Handle:IsA("MeshPart"),"Tool handle not a real mesh")
 for _,p in ipairs(t:GetDescendants())do if p:IsA("BasePart")then assert(not p.Anchored and p.Massless and not p.CanCollide and not p.CanTouch and not p.CanQuery,"Item can freeze or collide with avatar")end end
end
local boat=w.PraiaEPier.BarcoDePesca assert(boat:GetAttribute("SourceAssetId")==9617142471 and boat.DriverSeat:IsA("VehicleSeat")and boat.PassengerSeat:IsA("Seat"),"Usable imported boat missing")
local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={workspace.Terrain}waterRay.IgnoreWater=false
for _,offset in ipairs({Vector3.zero,Vector3.new(0,0,-5.6),Vector3.new(0,0,5.6),Vector3.new(-2.4,0,0),Vector3.new(2.4,0,0)})do
 local point=boat:GetAttribute("BoatHome"):PointToWorldSpace(offset)
 local hit=workspace:Raycast(Vector3.new(point.X,75,point.Z),Vector3.new(0,-170,0),waterRay)assert(hit and hit.Material==Enum.Material.Water,"Boat starts on dry land")
end
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,result=pcall(require,m)m:Destroy()assert(ok,"Compile error: "..s.Name..":"..tostring(result))compiled+=1
end end end
local climate=require(runtime.Climate)local personal=require(runtime.PersonalClimate)
local hour,rain,clear=personal.resolve("Noite","Chuva",12,0,1)assert(hour==23 and rain==1 and clear==0,"Personal night/rain lost")
assert(climate.DayLength==600 and climate.TransitionSeconds==8,"Fast weather lost")
assert(w:GetAttribute("InteractiveGrass")and game.StarterPlayer.StarterPlayerScripts.SerenaGrassClient,"Interactive grass missing")
assert(game.Lighting.SerenaSky.SkyboxBk=="rbxassetid://1084532042","HD sky lost")
return {parts=parts,realMeshParts=meshes,walkSamples=samples,maxGrade=maximum,clearHouseDoors=doors,groundedTrees=grounded,realOaks=realTrees,usableBoatOnWater=true,unanchoredMasslessRealTools=true,compiledScripts=compiled,personalWeatherPreserved=true,interactiveGrassPreserved=true,hdSkyPreserved=true}
]========])

local behavior=run([========[local runtime=game.ReplicatedStorage.SerenaRuntime
local Bridge=require(runtime.BridgeLifecycle)local Fishing=require(runtime.FishingCore)local Boat=require(runtime.BoatController)local Rules=require(runtime.ItemRules)
local w=workspace.IlhaSerena
-- Global bridge occupancy: grace, returning players, repeat construction and stable floors.
local state=Bridge.new()
assert(Bridge.step(state,false,0)==nil and not state.visible)
assert(Bridge.step(state,true,2)=="Show"and state.generation==1)
assert(Bridge.step(state,false,3)==nil and state.emptySince==3)
assert(Bridge.step(state,false,62.99)==nil and state.visible)
assert(Bridge.step(state,true,62.99)==nil and not state.emptySince)
assert(Bridge.step(state,false,70)==nil)
assert(Bridge.step(state,false,129.99)==nil and state.visible)
assert(Bridge.step(state,false,130)=="Hide"and not state.visible)
assert(Bridge.step(state,true,131)=="Show"and state.generation==2)
local bridge=w.TrilhasEMirante.Ponte70 Bridge.prepare(bridge)
assert(Bridge.near(bridge,{bridge:GetAttribute("BridgeCenter")+Vector3.new(120,3,0)},false),"Nearby player ignored")
assert(not Bridge.near(bridge,{bridge:GetAttribute("BridgeCenter")+Vector3.new(180,3,0)},true),"Distant player counted")
local fixed={}for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")then fixed[p]=p.CFrame end end
Bridge.apply(bridge,state)
for p,cf in pairs(fixed)do assert(p.CanCollide and p.CFrame==cf)end
state.visible=false Bridge.apply(bridge,state)
for p,cf in pairs(fixed)do assert(not p.CanCollide and not p.CanQuery and p.CFrame==cf)end
state.visible=true Bridge.apply(bridge,state)
for p,cf in pairs(fixed)do assert(p.CanCollide and p.CFrame==cf)end
-- Fish sale credits survive profile updates and duplicate DataStore callbacks.
local profile=Rules.profile({coins=50,apple=true,nextAppleAt=77})
local accepted
profile,accepted=Rules.apply(profile,"Credit",100,{amount=32,id="sale-test-0000000001"})assert(accepted and profile.coins==82)
profile,accepted=Rules.apply(profile,"Credit",100,{amount=32,id="sale-test-0000000001"})assert(accepted and profile.coins==82,"Duplicate sale paid twice")
profile,accepted=Rules.apply(profile,"Award",100)assert(accepted and profile.coins==92 and profile.apple and profile.nextAppleAt==77 and #profile.credits==1)
local invalid,ok=Rules.apply(profile,"Credit",100,{amount=math.huge,id="sale-test-0000000002"})assert(not ok and invalid.coins==92)
assert(Rules.Duration==3 and Rules.Cooldown==60 and Rules.Price==30,"Apple contract changed")
-- Actual fishing state with native terrain water tests and a simulated saving failure.
local now=0 local id=0 local equipped=false local position=Vector3.new(100,9.85,316)local messages={}local inventory={}local visualCount=0 local simulateFailure=true local paid=Rules.profile(nil)
local player={}local identity={}
local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={workspace.Terrain}waterRay.IgnoreWater=false
local fishing=Fishing.new({
 clock=function()return now end,random=function(a,b)return(a+b)/2 end,guid=function()id+=1 return "fishing-test-0000000000-"..id end,
 character=function()return {character=identity,root={Position=position},rod=equipped and {}or nil}end,
 send=function(p,event,data)table.insert(messages,{event=event,data=data})end,
 nearRod=function(point)return(point-Vector3.new(96.2,8.5,316)).Magnitude<16 end,
 nearMarket=function(point)return(point-Vector3.new(103.1,8.16,316)).Magnitude<16 end,
 giveRod=function(p,equip)if equip then equipped=true end return true end,
 water=function(point)local hit=workspace:Raycast(Vector3.new(point.X,80,point.Z),Vector3.new(0,-180,0),waterRay)return hit and hit.Material==Enum.Material.Water and hit.Position or nil end,
 makeVisual=function()visualCount+=1 return {}end,removeVisual=function()visualCount-=1 end,biteVisual=function()end,
 giveFish=function(p,f)inventory[f.id]=f end,takeFish=function(p,fishId)inventory[fishId]=nil end,
 credit=function(p,amount,token)
  local success paid,success=Rules.apply(paid,"Credit",now,{amount=amount,id=token})
  if simulateFailure then simulateFailure=false return false,"Resposta interrompida depois de salvar; tente novamente."end
  return success,"OK"
 end,
})
fishing:add(player)
assert(not fishing:dispatch(player,"Credit",99999),"Client can create money")
assert(not fishing:cast(player,Vector3.new(125,0,326)),"Unequipped rod accepted")
assert(fishing:getRod(player))
assert(not fishing:cast(player,Vector3.new(100,8,260)),"Fishing on sand accepted")
assert(not fishing:cast(player,Vector3.new(9999,0,9999)),"Unbounded cast")
assert(not fishing:cast(player,Vector3.new(0/0,0,0)),"NaN cast accepted")
assert(fishing:cast(player,Vector3.new(125,0,326))and visualCount==1)
assert(not fishing:cast(player,Vector3.new(125,0,326))and visualCount==1,"Duplicate bobber")
assert(not fishing:reel(player)and visualCount==0,"Early reel caught a fish")
now=2 assert(fishing:cast(player,Vector3.new(125,0,326)))
now=10 fishing:tick()assert(fishing.sessions[player].phase=="Bite")
assert(fishing:reel(player)and #fishing.sessions[player].fish==1 and visualCount==0)
assert(not fishing:reel(player)and #fishing.sessions[player].fish==1,"Fish caught twice")
local fish=fishing.sessions[player].fish[1]local expected=Rules.StartingCoins+fish.value
assert(not fishing:sell(player)and #fishing.sessions[player].fish==1 and paid.coins==expected,"Failed response lost the fish")
local saleId=fishing.sessions[player].pendingSale.id
now=12 assert(not fishing:cast(player,Vector3.new(125,0,326)),"Pending sale changed inventory")
assert(fishing:sell(player)and #fishing.sessions[player].fish==0 and paid.coins==expected,"Retry duplicated payment")
assert(#paid.credits==1 and paid.credits[1]==saleId)
now=14 assert(fishing:cast(player,Vector3.new(125,0,326)))now=22 fishing:tick()now=26 fishing:tick()
assert(fishing.sessions[player].phase=="Idle"and visualCount==0,"Bite timeout did not clean up")
now=28 assert(fishing:cast(player,Vector3.new(125,0,326)))position=Vector3.new(150,10,316)fishing:tick()
assert(fishing.sessions[player].phase=="Idle"and visualCount==0,"Moving away kept the line alive")
position=Vector3.new(100,10,316)now=30 assert(fishing:cast(player,Vector3.new(125,0,326)))equipped=false fishing:tick()
assert(visualCount==0 and fishing.sessions[player].phase=="Idle","Unequip did not clean the bobber")
fishing:remove(player)assert(not fishing.sessions[player])
-- Boat authority, input timeout, obstacle stop and return after an empty minute.
local occupant={}local intruder={}local seated=occupant local passenger=false local blocked=false local moved=0 local clock=0
local home=w.PraiaEPier.BarcoDePesca:GetAttribute("BoatHome")
local controller=Boat.new({clock=function()return clock end,driver=function()return seated end,passenger=function()return passenger end,
 water=function()return true end,sweep=function()return not blocked end,move=function(cf,speed)moved+=1 end},home)
assert(not controller:drive(intruder,1,1),"Non-driver can steer")assert(not controller:drive(occupant,0/0,0),"NaN boat input")
assert(controller:drive(occupant,1,0))for _=1,50 do clock+=.1 controller:drive(occupant,1,0)controller:tick(.1)end
assert((controller.cf.Position-home.Position).Magnitude>60 and controller.speed>20,"Boat does not advance")
local distance=(controller.cf.Position-home.Position).Magnitude
blocked=true controller:tick(.1)assert(controller.speed==0 and math.abs((controller.cf.Position-home.Position).Magnitude-distance)<.01,"Boat passed through obstacle")
blocked=false assert(controller:drive(occupant,1,1))clock+=1 controller:tick(.1)assert(controller.speed==0,"Expired input kept accelerating")
seated=nil clock=20 controller:tick(.1)assert(controller.emptySince==20)
clock=79.9 controller:tick(.1)assert((controller.cf.Position-home.Position).Magnitude>1,"Boat returned too early")
clock=80 controller:tick(.1)assert((controller.cf.Position-home.Position).Magnitude<.01,"Empty boat did not return")
for _,m in ipairs({w.TrilhasEMirante.Ponte70,w.TrilhasEMirante.Ponte124})do Bridge.prepare(m)Bridge.apply(m,Bridge.new())end
return {bridgeGraceAndRepeat=true,stationaryCollision=true,fishingCatchAndTimeout=true,waterOnlyCasting=true,unequipCleanup=true,failedSaleRetryWithoutDuplicateCoins=true,privateCurrency=true,boatDriverOnly=true,boatMovement=true,boatObstacleStop=true,boatInputTimeout=true,boatReturnsAfter60Seconds=true}
]========])

local clients=run([========[-- Execute real client sources with simulated input and time on native Roblox objects.
local function signal()
 local callbacks={}local s={}
 function s:Connect(fn)table.insert(callbacks,fn)return {Disconnect=function()end}end
 function s:Fire(...)for _,fn in ipairs(callbacks)do fn(...)end end
 return s
end
local sandbox=Instance.new("Folder")sandbox.Name="QA81"sandbox.Parent=game.ServerStorage
local playerGui=Instance.new("Folder")playerGui.Parent=sandbox
local char=Instance.new("Model")char.Parent=sandbox
local root=Instance.new("Part")root.Name="HumanoidRootPart"root.Anchored=true root.CanCollide=false root.Parent=char
local h=Instance.new("Humanoid")h.Parent=char
local attrs={}local events={}local bindings={}local inputs={}local envWorkspace=workspace local envRuntime
local player={Character=char,CharacterAdded=signal()}
function player:WaitForChild(name)assert(name=="PlayerGui")return playerGui end
function player:GetAttribute(k)return attrs[k]end
function player:SetAttribute(k,v)attrs[k]=v if events[k]then events[k]:Fire()end end
function player:GetAttributeChangedSignal(k)events[k]=events[k]or signal()return events[k]end
local players={LocalPlayer=player}function players:GetPlayers()return {player}end
local run={RenderStepped=signal(),Heartbeat=signal()}
local now=0 local delays={}local fakeTask={}
function fakeTask.delay(time,fn)table.insert(delays,{at=now+time,fn=fn})end
function fakeTask.spawn(fn,...)fn(...)end
local function advance(seconds)
 local untilTime=now+seconds
 while true do
  local index local earliest=math.huge
  for i,t in ipairs(delays)do if t.at<earliest then earliest=t.at index=i end end
  if earliest>untilTime then break end now=earliest local callback=table.remove(delays,index)callback.fn()
 end now=untilTime
end
local tweenCount=0 local pulses=0 local fakeTweens={}
function fakeTweens:Create(part,info,goal)
 tweenCount+=1 if info.RepeatCount==-1 then pulses+=1 end
 return {Play=function()for k,v in pairs(goal)do part[k]=v end end,Cancel=function()end}
end
local services={Players=players,RunService=run,UserInputService={TouchEnabled=true}}
local fakeGame={ReplicatedStorage=game.ReplicatedStorage}
function fakeGame:GetService(name)return services[name] or game:GetService(name)end
local scriptMock={Destroying=signal()}
local function execute(name,src)
 local m=Instance.new("ModuleScript")m.Name=name m.Source="return function(env)\nlocal game=env.game local script=env.script local task=env.task local workspace=env.workspace or workspace\n"..src.."\nend"m.Parent=sandbox
 require(m)({game=fakeGame,script=scriptMock,task=fakeTask,workspace=envWorkspace,runtime=envRuntime,clock=function()return now end,bind=function(b,fn)bindings[b]=fn end,bindInput=function(b,fn)inputs[b]=fn end})
end
local SPS=game.StarterPlayer.StarterPlayerScripts
local source=SPS.SerenaWeatherMenu.Source
for _,name in ipairs({"b","open","close"})do source=source:gsub(name.."%.Activated:Connect%(","env.bind("..name..",")end
execute("Menu",source)
local gui=playerGui.SerenaWeatherUI local panel=gui.ClimatePanel local options=panel.ClimateOptions
assert(options:IsA("ScrollingFrame") and options.AutomaticCanvasSize==Enum.AutomaticSize.Y and options.ClipsDescendants,"Scrolling menu missing")
bindings[gui.OpenClimate]()assert(panel.Visible,"Menu does not open")
bindings[options.SerenaTimeChoice_Noite]()bindings[options.SerenaWeatherChoice_Chuva]()
assert(attrs.SerenaTimeChoice=="Noite"and attrs.SerenaWeatherChoice=="Chuva","Menu selections incorrect")
assert(options.SerenaTimeChoice_Noite.Text:find("✓",1,true),"Selected state missing")
bindings[panel.CloseClimate]()assert(not panel.Visible,"Menu does not close")
-- Real ambience script must use personal choices without changing shared world attributes.
run.RenderStepped=signal()scriptMock={Destroying=signal()}
local w=workspace.IlhaSerena local snapshot={clock=w:GetAttribute("ClockStart"),changed=w:GetAttribute("WeatherChanged"),weather=w:GetAttribute("Weather"),previous=w:GetAttribute("PreviousWeather")}
w:SetAttribute("ClockStart",workspace:GetServerTimeNow())w:SetAttribute("WeatherChanged",workspace:GetServerTimeNow()-8)w:SetAttribute("Weather","Sol")w:SetAttribute("PreviousWeather","Sol")
local oldCamera=workspace.CurrentCamera local testCamera=Instance.new("Camera")testCamera.CFrame=CFrame.new(104,28,87)testCamera.Parent=workspace workspace.CurrentCamera=testCamera
local lights={}
for _,d in ipairs(w:GetDescendants())do if d:IsA("PointLight")or d:IsA("ParticleEmitter")then lights[d]=d.Enabled end end
execute("ActualPersonalAmbience",SPS.SerenaAmbienceClient.Source)
for _=1,100 do run.RenderStepped:Fire(.05)end
assert(math.abs(attrs.SerenaAppliedHour-23)<.01 and attrs.SerenaAppliedRain>.99,"Night/rain not applied")
assert(w:GetAttribute("Weather")=="Sol","Personal weather changed server state")
local rain=workspace.SerenaLocalRain local visible=0
for _,p in ipairs(rain:GetChildren())do if p.Name=="Chuva"and p.Transparency<1 then visible+=1 end end assert(visible>0,"Personal rain invisible")
player:SetAttribute("SerenaTimeChoice","Dia")player:SetAttribute("SerenaWeatherChoice","Sol")
for _=1,100 do run.RenderStepped:Fire(.05)end
assert(math.abs(attrs.SerenaAppliedHour-12)<.01 and attrs.SerenaAppliedRain<.01,"Day/sun not applied")
for _,p in ipairs(rain:GetChildren())do if p.Name=="Chuva"then assert(p.Transparency==1,"Rain remains after choosing sun")end end
player:SetAttribute("SerenaTimeChoice","Amanhecer")player:SetAttribute("SerenaWeatherChoice","Nublado")
for _=1,100 do run.RenderStepped:Fire(.05)end
assert(math.abs(attrs.SerenaAppliedHour-6.2)<.01,"Dawn not applied")
scriptMock.Destroying:Fire()
for d,value in pairs(lights)do if d.Parent then d.Enabled=value end end
workspace.CurrentCamera=oldCamera testCamera:Destroy()
w:SetAttribute("ClockStart",snapshot.clock)w:SetAttribute("WeatherChanged",snapshot.changed)w:SetAttribute("Weather",snapshot.weather)w:SetAttribute("PreviousWeather",snapshot.previous)
-- The actual new bridge source must cancel hidden construction and repeat its animation.
services.TweenService=fakeTweens scriptMock={Destroying=signal()}
envWorkspace=workspace
local Bridge=require(game.ReplicatedStorage.SerenaRuntime.BridgeLifecycle)
local m=w.TrilhasEMirante.Ponte70 local state=Bridge.new()
Bridge.step(state,true,now)Bridge.apply(m,state)
local fixed={}
for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")then fixed[p]=p.CFrame end end
execute("ActualBridge81",SPS.SerenaBridgeAnimation.Source:gsub("workspace:GetServerTimeNow%(%)","env.clock()"))
local raised=0
for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeRestCF")then assert(p.Transparency==1 and p.Position.Y>p:GetAttribute("BridgeRestCF").Y+11)raised+=1 end end
assert(raised>200,"Bridge construction missing")
advance(8)
for p,cf in pairs(fixed)do assert(p.CFrame==cf and p.CanCollide,"Bridge floor moved")end
state.visible=false Bridge.apply(m,state)task.wait(.03)
for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeRestCF")then assert(p.Transparency==1,"Bridge did not hide on client")end end
assert(Bridge.step(state,true,now)=="Show")Bridge.apply(m,state)task.wait(.03)
local repeated=0
for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeRestCF")and p.Position.Y>p:GetAttribute("BridgeRestCF").Y+11 then repeated+=1 end end
assert(repeated>200,"Bridge did not reconstruct on return")advance(8)
for p,cf in pairs(fixed)do assert(p.CFrame==cf,"Repeated construction moved collision")end
scriptMock.Destroying:Fire()
for _,bridge in ipairs({w.TrilhasEMirante.Ponte70,w.TrilhasEMirante.Ponte124})do Bridge.apply(bridge,Bridge.new())end
envWorkspace=workspace
-- Actual fishing/boat client with touch actions on native GUI objects.
run.Heartbeat=signal()scriptMock={Destroying=signal()}services.UserInputService={TouchEnabled=true,InputEnded=signal()}
local sentFish={}local sentBoat={}
local fishRemote={OnClientEvent=signal()}function fishRemote:FireServer(action,target)table.insert(sentFish,{action=action,target=target})end
local boatRemote={OnClientEvent=signal()}function boatRemote:FireServer(action,throttle,steer)table.insert(sentBoat,{action=action,throttle=throttle,steer=steer})end
local fakeRS={}function fakeRS:WaitForChild(name)if name=="SerenaFishing"then return fishRemote elseif name=="SerenaBoat"then return boatRemote end error(name)end
services.ReplicatedStorage=fakeRS
local rootPart=Instance.new("Part")rootPart.Name="HumanoidRootPart"rootPart.CFrame=CFrame.new(100,9.845,316)rootPart.Parent=sandbox
local hum={Health=100,HipHeight=0,RigType=Enum.HumanoidRigType.R6}
local fakeChar={children={}}
function fakeChar:FindFirstChild(name)return name=="HumanoidRootPart"and rootPart or nil end
function fakeChar:FindFirstChildOfClass(name)return name=="Humanoid"and hum or nil end
function fakeChar:GetChildren()return self.children end
local rod={Parent=fakeChar,Grip=CFrame.identity,Activated=signal()}
function rod:IsA(name)return name=="Tool"end
function rod:GetAttribute(name)return name=="SerenaItem"and "FishingRod"or nil end
player.Character=fakeChar fakeChar.children={rod}
local src=SPS.SerenaFishingClient.Source:gsub("b%.Activated:Connect%(fn%)","env.bind(b,fn)"):gsub("b%.InputBegan:Connect%(","env.bindInput(b,")
execute("ActualFishingTouch81",src)
run.Heartbeat:Fire(.11)
local fgui=playerGui.SerenaFishingUI local fpanel=fgui.FishingPanel
assert(fpanel.Visible and bindings[fpanel.FishingAction],"Touch fishing panel unavailable")
local camera=Instance.new("Camera")camera.CFrame=CFrame.lookAt(Vector3.new(100,14,316),Vector3.new(125,0,326))camera.Parent=workspace local savedCamera=workspace.CurrentCamera workspace.CurrentCamera=camera
fishRemote.OnClientEvent:Fire("State",{phase="Idle",count=0,value=0,rod=true,deadline=0,maxFish=12})
bindings[fpanel.FishingAction]()assert(sentFish[#sentFish].action=="Cast"and typeof(sentFish[#sentFish].target)=="Vector3","Touch cast missing")
fishRemote.OnClientEvent:Fire("State",{phase="Bite",count=0,value=0,rod=true,deadline=workspace:GetServerTimeNow()+3,maxFish=12})
run.Heartbeat:Fire(.11)assert(fpanel.FishingAction.Text=="PUXAR AGORA!","Bite prompt missing")
bindings[fpanel.FishingAction]()assert(sentFish[#sentFish].action=="Reel","Touch reel missing")
bindings[fpanel.SellFish]()assert(sentFish[#sentFish].action=="Sell","Touch sale missing")
fakeChar.children={}hum.SeatPart=w.PraiaEPier.BarcoDePesca.DriverSeat
run.Heartbeat:Fire(.11)
local boatUI=fgui.BoatPanel assert(boatUI.Visible and inputs[boatUI.Forward],"Touch boat panel unavailable")
local touch={UserInputType=Enum.UserInputType.Touch}inputs[boatUI.Forward](touch)run.Heartbeat:Fire(.11)
assert(sentBoat[#sentBoat].action=="Drive"and sentBoat[#sentBoat].throttle==1,"Touch forward did not drive")
services.UserInputService.InputEnded:Fire(touch)run.Heartbeat:Fire(.11)
assert(sentBoat[#sentBoat].throttle==0,"Released touch left boat accelerating")
bindings[boatUI.ExitBoat]()assert(sentBoat[#sentBoat].action=="Exit","Boat exit missing")
scriptMock.Destroying:Fire()workspace.CurrentCamera=savedCamera camera:Destroy()
-- The exact wind package produces native wind trails and foliage settings.
local runtime=game.ReplicatedStorage.SerenaRuntime
local lines=require(runtime.WindEffects.WindLines)lines:Create({Position=Vector3.new(100,25,108),Direction=Vector3.new(1,0,.3).Unit,Speed=14,Lifetime=2})
assert(#lines.UpdateQueue==1 and lines.UpdateQueue[1].Trail:IsA("Trail"),"Exact WindLines did not create wind")lines:Cleanup()assert(#lines.UpdateQueue==0)
local shake=require(runtime.WindEffects.WindShake)local leaf
for _,d in ipairs(w.Bosque:GetDescendants())do if d:IsA("MeshPart")and d.Name=="Leaves"then leaf=d break end end
assert(leaf)local cf=leaf.CFrame shake:AddObjectShake(leaf,{WindPower=.3,WindSpeed=14,WindDirection=Vector3.new(1,0,.3).Unit})assert(shake.Handled==1)
shake:RemoveObjectShake(leaf)assert(shake.Handled==0 and leaf.CFrame==cf,"WindShake cleanup changed the tree")
-- Execute the exact skinned-grass core on real native bones, including a collision at zero distance.
local SkinnedGrass=require(runtime.SkinnedGrass)local model=runtime.SkinnedGrassTemplates.FineStudio:Clone()model.Parent=sandbox model:PivotTo(CFrame.new(104,18.3,108))
local mesh=model:FindFirstChildOfClass("MeshPart")local first
for _,bone in ipairs(mesh:GetChildren())do if bone:IsA("Bone")then
 local point=bone.WorldCFrame.Position+Vector3.new(0,.7,0)bone:SetAttribute("SerenaTerrainOffset",CFrame.new(0,.7,0))bone:SetAttribute("SerenaGroundPoint",point)bone.Transform=CFrame.new(0,.7,0)first=first or bone
end end
local simulation=SkinnedGrass.new({MeshStorage=sandbox,RenderDistance=1000,RenderInAnimation=false,RenderOutAnimation=false,WindEnabled=true,CollisionRadiusInner=1.2,CollisionRadiusOuter=3.2,CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)})
assert(simulation.Settings.RenderInAnimation==false,"False settings ignored")simulation:AddMeshes({model})
local point=first:GetAttribute("SerenaGroundPoint")simulation:Step(.04,{point},point)
local collisions=0 for _ in pairs(simulation.DisplaceBones)do collisions+=1 end assert(collisions>0,"Skinned grass does not respond to walking")
for _,bone in ipairs(mesh:GetDescendants())do if bone:IsA("Bone")then for _,v in ipairs({bone.Transform:GetComponents()})do assert(v==v and math.abs(v)<100000,"Invalid grass deformation")end end end
simulation:Step(.04,{},point)task.wait(1.1)simulation:Step(.04,{},point)
assert(next(simulation.ReturnBones)==nil,"Grass recovery never finishes")
-- Execute the actual grass loader on native, saved coverage cells.
local limitedCoverage=Instance.new("Folder")limitedCoverage.Parent=sandbox
local cells=runtime.GrassCoverage:GetChildren()table.sort(cells,function(a,b)return a:GetAttribute("GreenRoots")>b:GetAttribute("GreenRoots")end)
for i=1,2 do cells[i]:Clone().Parent=limitedCoverage end
local runtimeProxy={}
function runtimeProxy:WaitForChild(name)if name=="GrassCoverage"then return limitedCoverage end return runtime:WaitForChild(name)end
local grassRS={}
function grassRS:WaitForChild(name)assert(name=="SerenaRuntime")return runtimeProxy end
services.ReplicatedStorage=game.ReplicatedStorage envRuntime=runtimeProxy run.RenderStepped=signal()scriptMock={Destroying=signal(),Parent=sandbox}
local before=rootPart.CFrame rootPart.CFrame=CFrame.new(cells[1]:GetAttribute("Center")+Vector3.new(0,3,0))
execute("ActualGrassCoverageLoader",SPS.SerenaGrassClient.Source:gsub('local runtime=RS:WaitForChild%("SerenaRuntime"%)',"local runtime=env.runtime\n"))
assert(attrs.SerenaGrassLoadedPatches==2 and attrs.SerenaWholeMapGrassReady,"Actual grass loader did not finish")
run.RenderStepped:Fire(.06)
local field=workspace.SerenaInteractiveGrass local patchCount=0 local nativeRoots=0
for _,patch in ipairs(field:GetChildren())do
 patchCount+=1 local part=patch:FindFirstChildOfClass("MeshPart")assert(part.MeshId=="rbxassetid://80159239673273"and not part.CanCollide,"Fine grass loader changed the mesh")
 for _,bone in ipairs(part:GetDescendants())do if bone:IsA("Bone")and bone:GetAttribute("SerenaGreenRoot")then
  nativeRoots+=1 local ground=bone:GetAttribute("SerenaGroundPoint")local offset=bone:GetAttribute("SerenaTerrainOffset")
  assert(math.abs((bone.WorldCFrame*offset).Y-ground.Y)<.02,"Grass terrain placement changed")
 end end
end
assert(patchCount==2 and nativeRoots>150,"Whole-map volumes did not load and render")
scriptMock.Destroying:Fire()rootPart.CFrame=before
local climate=require(runtime.Climate)local profile=climate.profile(9.25,0,1,0)profile.hour=9.25 climate.apply(game.Lighting,workspace.Terrain,profile)
sandbox:Destroy()
return {actualClientSources=true,scrollingClimateMenu=true,personalNightRainAndDawn=true,bridgeReappearsAndAnimates=true,stationaryBridgeCollision=true,touchCastReelAndSale=true,touchBoatForwardReleaseAndExit=true,exactWindTrails=true,exactWindShake=true,nativeSkinnedGrassCollisionAndRecovery=true,actualWholeMapGrassLoader=true}
]========])

local climate=require(runtime.Climate)local morning=climate.profile(9.25,0,1,0)morning.hour=9.25 climate.apply(game.Lighting,workspace.Terrain,morning)

world:SetAttribute("UpgradeVersion",81)world:SetAttribute("DesignVersion",4)
assert(not clients.pending,"Client validation missing")
game:GetService("AssetService"):SavePlaceAsync()
return {geometry=geometry,behavior=behavior,clients=clients,assets=assets,interiors=interiors,grass=grass,sourceVersion=game.PlaceVersion,published=true}
