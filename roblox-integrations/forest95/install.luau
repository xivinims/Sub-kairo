assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==94,"Published base changed")
game:GetService("ServerStorage")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
source(runtime,"ModuleScript","Visuals",[============[local Lighting = game:GetService("Lighting")
local Visuals = {}
local Cycle=require(script.Parent:WaitForChild("Cycle"))
function Visuals.apply()
	-- Some Roblox runtime versions restrict renderer selection to Studio. The rest of the world must still initialise.
	pcall(function()Lighting.LightingStyle=Enum.LightingStyle.Realistic end)
	pcall(function()Lighting.PrioritizeLightingQuality=true end)
	Lighting.GlobalShadows = true Lighting.ShadowSoftness = 0.4
	Lighting.EnvironmentDiffuseScale = 1 Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.7 Lighting.ClockTime = Cycle.StartClock Lighting.GeographicLatitude = 28
	Lighting.ExposureCompensation = -0.10
	Lighting.Ambient = Color3.fromRGB(47, 56, 57) Lighting.OutdoorAmbient = Color3.fromRGB(99, 119, 121)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 9, 3) Lighting.ColorShift_Bottom = Color3.new()
	Lighting.FogColor = Color3.fromRGB(178, 199, 203) Lighting.FogStart = 200 Lighting.FogEnd = 1800
	local color = Lighting:FindFirstChild("ForestColor")
	if color then color.Enabled = true color.Brightness = 0.01 color.Contrast = 0.18 color.Saturation = 0.12 color.TintColor = Color3.fromRGB(249, 255, 241) end
	local rays = Lighting:FindFirstChild("ForestSunRays")
	if rays then rays.Enabled = true rays.Intensity = 0.075 rays.Spread = 0.727 end
	local bloom = Lighting:FindFirstChild("ForestBloom")
	if bloom then bloom.Enabled = false bloom.Intensity = 0.08 bloom.Size = 10 bloom.Threshold = 1.35 end
	local air = Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Density = 0.24 air.Offset = 0.16 air.Color = Color3.fromRGB(196, 215, 221) air.Decay = Color3.fromRGB(105, 137, 134) air.Haze = .65 air.Glare = 0.20 end
end
function Visuals.clock(clock)
	local day=Cycle.daylight(clock)local night=1-day
	local warm=math.max(0,1-math.min(math.abs(clock-6.8),math.abs(clock-17.4))/2.4)*day
	Lighting.ClockTime=clock Lighting.Brightness=1.4+1.3*day
	Lighting.ExposureCompensation=-.08-.08*night
	Lighting.Ambient=Color3.fromRGB(24,32,48):Lerp(Color3.fromRGB(49,57,58),day)
	Lighting.OutdoorAmbient=Color3.fromRGB(48,63,88):Lerp(Color3.fromRGB(100,120,123),day)
	local color=Lighting:FindFirstChild("ForestColor")
	if color then color.Contrast=.08+.03*day color.Saturation=.04+.08*day color.TintColor=Color3.fromRGB(201,219,255):Lerp(Color3.fromRGB(249,255,241),day):Lerp(Color3.fromRGB(255,222,181),warm*.38)end
	local rays=Lighting:FindFirstChild("ForestSunRays")if rays then rays.Intensity=(.055+.035*warm)*day end
	local air=Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Color=Color3.fromRGB(100,133,174):Lerp(Color3.fromRGB(196,215,221),day):Lerp(Color3.fromRGB(224,185,149),warm*.4)air.Glare=.20*day end
end
return Visuals
]============])
source(runtime,"ModuleScript","SeasonController",[============[local Controller={}
function Controller.start(runtime,world)
 local Seasons=require(runtime.Seasons)local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local previousIndex=1 local busy=false local parts={}local lights={}
 local function record(model,kind)
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
   local n=p.Name:lower()local vegetation=n:find("leaf",1,true)or n:find("leaves",1,true)or n:find("fern",1,true)or n:find("flower",1,true)or n:find("clover",1,true)
   if vegetation or kind=="plants"then
    local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
    parts[#parts+1]={part=p,appearance=appearance,base=p:GetAttribute("SeasonBaseColor")or p.Color,transparency=p:GetAttribute("SeasonBaseTransparency")or p.Transparency,kind=kind,flower=model.Name:lower():find("flower",1,true)~=nil,accent=model:GetAttribute("SpringBlossom")==true}
   end
  end end
 end
 for _,m in ipairs(world.Decor.Trees:GetChildren())do record(m,"trees")end
 for _,m in ipairs(world.Decor.Plants:GetChildren())do record(m,"plants")end
 local function surface(index)
  Terrain:SetMaterialColor(Enum.Material.Grass,index==3 and Color3.fromRGB(153,134,78)or index==2 and Color3.fromRGB(111,160,65)or Color3.fromRGB(107,153,64))
  if index~=4 and previousIndex~=4 then return end
  for bx=-512,384,128 do for bz=-512,384,128 do
   local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))
   local channels=Terrain:ReadVoxelChannels(region,4,{"SolidMaterial"})local grid=channels.SolidMaterial
   for ix=1,32 do for iz=1,32 do
    for iy=1,54 do local old=grid[ix][iy][iz]
     if old==Enum.Material.Grass or old==Enum.Material.LeafyGrass or old==Enum.Material.Snow then grid[ix][iy][iz]=index==4 and Enum.Material.Snow or Enum.Material.Grass end
    end
   end end
   Terrain:WriteVoxelChannels(region,4,{SolidMaterial=grid})task.wait()
  end end
 end
 local function apply(index,instant)
  if busy then return false end busy=true local name=Seasons.Names[index]
  runtime:SetAttribute("SeasonName",name)runtime:SetAttribute("SeasonIndex",index)runtime:SetAttribute("SeasonChanging",true)
  local changes={}
  for _,entry in ipairs(parts)do
   local p=entry.part
   if p.Parent then
    local base=entry.base local color=base
    if index==1 and entry.accent then color=Color3.fromRGB(215,170,186)
    elseif index==2 then color=base:Lerp(Color3.fromRGB(64,122,53),.12)
    elseif index==3 then color=base:Lerp(Color3.fromRGB(191,134,63),entry.flower and .22 or .72)
    elseif index==4 then color=base:Lerp(Color3.fromRGB(144,165,153),.50)end
    local hidden=index==4 and entry.kind=="plants"or index==3 and entry.flower
    changes[#changes+1]={entry=entry,from=p.Color,to=color,fromTransparency=p.Transparency,toTransparency=hidden and 1 or entry.transparency}
   end
  end
  -- Eighteen bounded updates avoid thousands of per-frame replicated server tweens on mobile.
  local frames=instant and 1 or 18
  for frame=1,frames do
   local t=instant and 1 or(frame-1)/(frames-1)local alpha=t*t*(3-2*t)
   for i,c in ipairs(changes)do local e=c.entry
    if e.part.Parent then local color=c.from:Lerp(c.to,alpha)e.part.Color=color e.part.Transparency=c.fromTransparency+(c.toTransparency-c.fromTransparency)*alpha
     if e.appearance and e.appearance.Parent then e.appearance.Color=color end
    end
    if i%250==0 then task.wait()end
   end
   if frame<frames then task.wait(Seasons.Transition/(frames-1))end
  end
  surface(index)
  runtime:SetAttribute("SeasonChanging",false)runtime:SetAttribute("SeasonRevision",(runtime:GetAttribute("SeasonRevision")or 0)+1)previousIndex=index busy=false return true
 end
 runtime:SetAttribute("SeasonEpoch",workspace:GetServerTimeNow())runtime:SetAttribute("SeasonSeconds",Seasons.Duration)
 -- Saved terrain is already spring; boot does not need to rewrite its geometry.
 runtime:SetAttribute("SeasonName","Primavera")runtime:SetAttribute("SeasonIndex",1)runtime:SetAttribute("SeasonRevision",0)runtime:SetAttribute("SeasonChanging",false)
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  if runtime:GetAttribute("SeasonTestMode")then return end
  elapsed+=dt if elapsed<2 then return end elapsed=0
  local index=Seasons.index(workspace:GetServerTimeNow(),runtime:GetAttribute("SeasonEpoch"))
  if not busy and index~=runtime:GetAttribute("SeasonIndex")then task.spawn(apply,index,false)end
 end)
 return{apply=apply,surface=surface,parts=#parts}
end
return Controller
]============])
source(runtime,"ModuleScript","MusicConfig",[============[local M={}
M.Tracks={
 {id=96332574400847,title="When You Said Goodbye",category="Em inglês"},
 {id=140033922950767,title="Why Do You Leave Me to Suffer Alone",category="Em inglês"},
 {id=1836416985,title="Gone Fishing · instrumental",category="Natureza"},
 {id=109647250911986,title="Nature Chill · reggae",category="Natureza"},
 {id=105504604402949,title="Sumidero Echo · instrumental",category="Natureza"},
 {id=9116971475,title="Floresta e pássaros",category="Natureza"},
 {id=9120552550,title="Riacho",category="Natureza"},
}
function M.parse(text)
 if type(text)~="string"or #text>32 then return nil end
 local digits=text:match("^%s*(%d+)%s*$")or text:match("^rbxassetid://(%d+)$")
 if not digits or #digits>16 then return nil end
 local id=tonumber(digits)if not id or id<1 or id>=9007199254740992 or id%1~=0 then return nil end return id
end
return M
]============])
source(runtime,"ModuleScript","MusicPlayer",[============[local M={}
function M.new(parent,activity,status)
 local self={sound=nil,generation=0,volume=.25,paused=false}
 local function state(active)activity(active==true)end
 function self.stop()
  self.generation+=1 if self.sound then self.sound:Destroy()self.sound=nil end self.paused=false state(false)
 end
 function self.play(id,title)
  self.stop()local generation=self.generation
  local s=Instance.new("Sound")s.Name="TreeWorldPersonalMusic"s.SoundId="rbxassetid://"..id s.Volume=self.volume s.Looped=true s.Parent=parent self.sound=s status("Carregando…")
  local failed=false task.spawn(function()local ok=pcall(function()game:GetService("ContentProvider"):PreloadAsync({s})end)failed=not ok end)
  local deadline=os.clock()+12
  repeat task.wait(.1)until s.IsLoaded or failed or os.clock()>deadline or generation~=self.generation
  if generation~=self.generation then return false end
  if not s.IsLoaded or s.TimeLength<=0 then self.stop()status("Esse áudio não está disponível neste jogo.")return false end
  s:Play()state(true)status(title or"Sua música")return true
 end
 function self.pause()
  if not self.sound or not self.sound.IsLoaded then return end
  self.paused=not self.paused
  if self.paused then self.sound:Pause()state(false)status("Pausado")else self.sound:Resume()state(true)status("Ouvindo música")end
 end
 function self.setVolume(v)self.volume=math.clamp(v,0,.6)if self.sound then self.sound.Volume=self.volume end end
 return self
end
return M
]============])
source(runtime,"ModuleScript","MusicController",[============[local M={}
function M.start(runtime,world)
 local Players=game:GetService("Players")local remote=runtime:WaitForChild("MusicListening")
 local function label(player,character)
  local head=character:WaitForChild("Head",10)if not head or player.Character~=character then return end
  local old=head:FindFirstChild("TreeWorldMusicTag")if old then old:Destroy()end
  local tag=Instance.new("BillboardGui")tag.Name="TreeWorldMusicTag"tag.Size=UDim2.fromOffset(170,22)tag.StudsOffsetWorldSpace=Vector3.new(0,3.2,0)tag.MaxDistance=65 tag.AlwaysOnTop=false tag.Enabled=player:GetAttribute("ListeningToMusic")==true tag.Parent=head
  local text=Instance.new("TextLabel")text.Name="Status"text.Size=UDim2.fromScale(1,1)text.BackgroundTransparency=1 text.Text="♫ música ouvindo"text.Font=Enum.Font.GothamMedium text.TextSize=12 text.TextColor3=Color3.fromRGB(219,238,204)text.TextStrokeTransparency=.65 text.Parent=tag
 end
 local function apply(player,active)
  if type(active)~="boolean"then return false end
  player:SetAttribute("ListeningToMusic",active)
  local character=player.Character local head=character and character:FindFirstChild("Head")local tag=head and head:FindFirstChild("TreeWorldMusicTag")if tag then tag.Enabled=active end return true
 end
 local function added(player)
  player:SetAttribute("ListeningToMusic",false)
  player.CharacterAdded:Connect(function(character)task.spawn(label,player,character)end)
  if player.Character then task.spawn(label,player,player.Character)end
 end
 local rate={}
 remote.OnServerEvent:Connect(function(player,active)
  if type(active)~="boolean"then return end
  local now=os.clock()local record=rate[player]or{time=now,count=0}
  if now-record.time>1 then record.time=now record.count=0 end
  record.count+=1 rate[player]=record if active==false or record.count<=6 then apply(player,active)end
 end)
 Players.PlayerAdded:Connect(added)Players.PlayerRemoving:Connect(function(player)rate[player]=nil end)
 for _,player in ipairs(Players:GetPlayers())do added(player)end
 return{apply=apply,label=label}
end
return M
]============])
source(runtime,"ModuleScript","MusicUI",[============[local M={}
local function create(class,parent,name)local obj=Instance.new(class)obj.Name=name obj.Parent=parent return obj end
local function round(obj)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,10)c.Parent=obj end
local function label(parent,name,text,height)
 local l=create("TextLabel",parent,name)l.Text=text l.Size=UDim2.new(1,0,0,height or 22)l.Font=Enum.Font.Gotham l.TextSize=13 l.TextColor3=Color3.fromRGB(49,69,48)l.BackgroundTransparency=1 l.TextWrapped=true l.TextXAlignment=Enum.TextXAlignment.Left return l
end
local function button(parent,name,text)
 local b=create("TextButton",parent,name)b.Size=UDim2.new(1,0,0,42)b.Text=text b.Font=Enum.Font.GothamMedium b.TextSize=13 b.BackgroundColor3=Color3.fromRGB(225,234,212)b.TextColor3=Color3.fromRGB(46,65,46)b.BorderSizePixel=0 round(b)return b
end
function M.build(parent,tracks)
 local gui=create("ScreenGui",parent,"TreeWorldPersonalMusic")gui.ResetOnSpawn=false gui.DisplayOrder=25 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local open=button(gui,"Open","♫ Música")open.AnchorPoint=Vector2.new(1,0)open.Position=UDim2.new(1,-12,0,12)open.Size=UDim2.fromOffset(100,38)
 local panel=create("Frame",gui,"Panel")panel.AnchorPoint=Vector2.new(1,0)panel.Position=UDim2.new(1,-12,0,60)panel.Size=UDim2.new(.9,0,.72,0)panel.BackgroundColor3=Color3.fromRGB(245,247,232)panel.BorderSizePixel=0 panel.Visible=false round(panel)
 local limit=create("UISizeConstraint",panel,"SizeLimit")limit.MaxSize=Vector2.new(340,490)limit.MinSize=Vector2.new(210,150)
 local scroll=create("ScrollingFrame",panel,"Scroll")scroll.Size=UDim2.fromScale(1,1)scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=Color3.fromRGB(92,124,75)scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new()scroll.ScrollingDirection=Enum.ScrollingDirection.Y
 local pad=create("UIPadding",scroll,"Padding")pad.PaddingTop=UDim.new(0,14)pad.PaddingBottom=UDim.new(0,14)pad.PaddingLeft=UDim.new(0,14)pad.PaddingRight=UDim.new(0,14)
 local layout=create("UIListLayout",scroll,"Layout")layout.Padding=UDim.new(0,8)layout.SortOrder=Enum.SortOrder.LayoutOrder
 local refs={gui=gui,open=open,panel=panel,tracks={}}local order=0
 local function add(obj)order+=1 obj.LayoutOrder=order return obj end
 add(label(scroll,"Title","Seu rádio",24)).Font=Enum.Font.GothamBold
 add(label(scroll,"Privacy","Só você ouve. A nametag mostra quando está ouvindo.",36))
 refs.status=add(label(scroll,"Status","Escolha uma música",36))
 for _,category in ipairs({"Em inglês","Natureza"})do add(label(scroll,"Category",category,24)).Font=Enum.Font.GothamBold
  for _,track in ipairs(tracks)do if track.category==category then local b=add(button(scroll,"Track",track.title))b:SetAttribute("AssetId",track.id)refs.tracks[#refs.tracks+1]={button=b,track=track}end end
 end
 add(label(scroll,"CustomTitle","Sua música · ID do Roblox",24))
 refs.input=add(create("TextBox",scroll,"AudioId"))refs.input.Size=UDim2.new(1,0,0,42)refs.input.PlaceholderText="Cole o ID de áudio"refs.input.Text=""refs.input.ClearTextOnFocus=false refs.input.Font=Enum.Font.Gotham refs.input.TextSize=14 refs.input.BackgroundColor3=Color3.fromRGB(231,237,221)refs.input.TextColor3=Color3.fromRGB(44,65,44)refs.input.BorderSizePixel=0 round(refs.input)
 refs.play=add(button(scroll,"PlayId","Ouvir meu ID"))refs.pause=add(button(scroll,"Pause","Pausar / continuar"))refs.stop=add(button(scroll,"Stop","Parar"))
 add(label(scroll,"VolumeTitle","Volume",22))refs.lower=add(button(scroll,"Quieter","Diminuir volume"))refs.louder=add(button(scroll,"Louder","Aumentar volume"))
 return refs
end
return M
]============])
local reports={}
reports.terrain=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Terrain=workspace.Terrain local Scene=require(runtime.Scene)
 local protected={}
 for _,m in ipairs({world.Amenities.ForestRuins,world.Amenities.WeatheredHillStair})do local cf,size=m:GetBoundingBox()protected[#protected+1]={x=cf.X,z=cf.Z,rx=size.X*.5+8,rz=size.Z*.5+8}end
 for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do local cf,size=m:GetBoundingBox()protected[#protected+1]={x=cf.X,z=cf.Z,rx=size.X*.5+8,rz=size.Z*.5+8}end
 for _,m in ipairs(world.Amenities.SeasonalDetails.Camps:GetChildren())do local p=m:GetAttribute("Centre")protected[#protected+1]={x=p.X,z=p.Z,rx=14,rz=14}end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)protected[#protected+1]={x=p.X,z=p.Z,rx=15,rz=15}end end
 local function preservation(x,z)
  local weight=0
  for _,s in ipairs(protected)do local d=math.max(math.abs(x-s.x)-s.rx,math.abs(z-s.z)-s.rz)weight=math.max(weight,1-math.clamp(d/16,0,1))end
  return weight
 end
 local heights={}local MIN,MAX=-512,512 local N=256 local report={smoothedColumns=0,palePathColumns=0,removedRocks=0,keptRocks=0,trimmedTrees=0}
 for bx=MIN,MAX-1,128 do for bz=MIN,MAX-1,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))local data=Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy"})
  for ix=1,32 do local gx=(bx-MIN)/4+ix heights[gx]=heights[gx]or{}
   for iz=1,32 do local gz=(bz-MIN)/4+iz local h=-64
    for iy=54,1,-1 do local fill=data.SolidOccupancy[ix][iy][iz]if fill>0 then h=-64+(iy-1)*4+fill*4 break end end heights[gx][gz]=h
   end
  end task.wait()
 end end
 for bx=MIN,MAX-1,128 do for bz=MIN,MAX-1,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))local data=Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","SolidMaterial","LiquidOccupancy"})
  for ix=1,32 do for iz=1,32 do
   local gx,gz=(bx-MIN)/4+ix,(bz-MIN)/4+iz local x,z=bx+(ix-.5)*4,bz+(iz-.5)*4 local h=heights[gx][gz]
   if h>7.6 and gx>4 and gx<N-4 and gz>4 and gz<N-4 then
    local sum,weight=0,0
    for dx=-3,3 do for dz=-3,3 do local sample=heights[gx+dx][gz+dz]if sample>7.4 then local w=1/(1+dx*dx+dz*dz)sum+=sample*w weight+=w end end end
    local smoothHeight=sum/weight local keep=preservation(x,z)local blend=.78*(1-keep)
    local path=Scene.pathDistance(x,z)local target=math.max(7.65,h+(smoothHeight-h)*blend)
    for iy=1,54 do local low=-64+(iy-1)*4 local fill=math.clamp((target-low)/4,0,1)
     data.SolidOccupancy[ix][iy][iz]=fill
     if fill>0 then
      if target-low<7 and keep<.9 then data.SolidMaterial[ix][iy][iz]=path<4.3 and Enum.Material.Sand or Enum.Material.Grass
      elseif data.SolidMaterial[ix][iy][iz]==Enum.Material.Air then data.SolidMaterial[ix][iy][iz]=Enum.Material.Ground end
     else data.SolidMaterial[ix][iy][iz]=Enum.Material.Air end
    end
    if blend>0 and math.abs(target-h)>.015 then report.smoothedColumns+=1 end
    if path<4.3 and keep<.9 then report.palePathColumns+=1 end
   end
  end end
  Terrain:WriteVoxelChannels(region,4,{SolidOccupancy=data.SolidOccupancy,SolidMaterial=data.SolidMaterial,LiquidOccupancy=data.LiquidOccupancy})task.wait()
 end end
 Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(107,153,64))Terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(208,195,157))
 local lake=world:GetAttribute("CentralLake")local index=0
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do local name=m.Name:lower()local rock=name:find("rock",1,true)or name:find("boulder",1,true)
  if rock then
   index+=1 local p=m:GetPivot().Position local near=Scene.pathDistance(p.X,p.Z)<12
   if near or index%3~=1 or report.keptRocks>=48 then m:Destroy()report.removedRocks+=1
   else report.keptRocks+=1 local _,size=m:GetBoundingBox()if math.max(size.X,size.Y,size.Z)>11 then m:ScaleTo(m:GetScale()*11/math.max(size.X,size.Y,size.Z))end end
  end
 end
 for _,m in ipairs(world.Decor.Trees:GetChildren())do
  local _,size=m:GetBoundingBox()if size.Y>68 then m:ScaleTo(m:GetScale()*68/size.Y)report.trimmedTrees+=1 end
  for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")and(p.Name:lower():find("leaf",1,true)or p.Name:lower():find("leaves",1,true))then
   local col=p.Color:Lerp(Color3.fromRGB(103,157,74),.28)p.Color=col p:SetAttribute("SeasonBaseColor",col)local a=p:FindFirstChildOfClass("SurfaceAppearance")if a then a.Color=col end
  end end
 end
 for _,m in ipairs(world.Decor.Plants:GetChildren())do if m.Name:find("FernTall",1,true)then local _,size=m:GetBoundingBox()if size.Y>2.2 then m:ScaleTo(m:GetScale()*2.2/size.Y)end end end
 world:SetAttribute("TerrainOrganized",true)world:SetAttribute("AccentRockCount",report.keptRocks)
 return report
end
return B
]============]).install()
reports.cottage=factory([============[local B={}
local WHITE=Color3.fromRGB(235,235,215)local BLUE=Color3.fromRGB(67,105,123)local WOOD=Color3.fromRGB(153,119,80)local DARK=Color3.fromRGB(79,86,78)
function B.install()
 local world=workspace.ForestWorld local garden=world.Amenities.RiversideGarden local C=game:GetService("CollectionService")
 local old=garden.WaterCottage local tea=old:FindFirstChild("CottageTeaCorner")assert(tea)tea.Parent=nil local teaCF,teaSize=tea.AntiqueTeaTable:GetBoundingBox() local teaCenter=Vector3.new(teaCF.X,teaCF.Y-teaSize.Y*.5,teaCF.Z)
 old:Destroy()garden.LakesideBoardwalk:Destroy()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)).Position end
 local O=Vector3.new(40,10.8,135)local house=Instance.new("Model")house.Name="WaterCottage"house.ModelStreamingMode=Enum.ModelStreamingMode.Atomic house:SetAttribute("Origin",O)house:SetAttribute("RebuiltEntrance",true)house.Parent=garden
 local report={parts=0,walkwaySegments=0}
 local function P(parent,name,size,cf,col,mat,collide)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col or WHITE p.Material=mat or Enum.Material.WoodPlanks p.Anchored=true p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent report.parts+=1 return p
 end
 local function h(name,size,x,y,z,col,mat,collide,rot)return P(house,name,size,CFrame.new(O+Vector3.new(x,y,z))*(rot or CFrame.identity),col,mat,collide)end
 -- Visible porch planks are the actual walking surface; no hidden box catches feet.
 for x=-13.5,13.5,1.5 do h("PorchPlank",Vector3.new(1.53,.4,24),x,-.2,0,WOOD)end
 for _,x in ipairs({-12,0,12})do for _,z in ipairs({-10,0,10})do local g=ground(O.X+x,O.Z+z)local top=O.Y-.4
  P(house,"GroundedPiling",Vector3.new(1.15,top-g.Y+.5,1.15),CFrame.new(O.X+x,(top+g.Y-.5)*.5,O.Z+z),DARK,Enum.Material.Wood,true)
 end end
 h("InteriorFloor",Vector3.new(21,.3,18),0,.15,0,WHITE)
 -- Main entrance faces the arriving boardwalk and opens directly to the room.
 for _,s in ipairs({-1,1})do h("WestWall",Vector3.new(.45,8.8,6.5),-10.5,4.7,s*5.75,WHITE)h("DoorFrame",Vector3.new(.8,8,.6),-10.65,4.2,s*2.3,BLUE,Enum.Material.Wood)end
 h("DoorLintel",Vector3.new(.7,1.2,5.2),-10.65,8.4,0,BLUE,Enum.Material.Wood)
 h("EastWall",Vector3.new(.45,8.8,18),10.5,4.7,0,WHITE)
 -- Front/back facades have framed real glass openings and solid low sills.
 for _,s in ipairs({-1,1})do
  h("FacadeSill",Vector3.new(21,2.4,.45),0,1.55,s*9,WHITE)
  h("FacadeLintel",Vector3.new(21,1.7,.45),0,8.35,s*9,WHITE)
  for _,x in ipairs({-9,-3,3,9})do h("WindowPier",Vector3.new(2.2,4.7,.5),x,5.1,s*9,WHITE)end
  for _,x in ipairs({-6,0,6})do local glass=h("WindowGlass",Vector3.new(3.8,4.4,.08),x,5.1,s*9,Color3.fromRGB(166,220,221),Enum.Material.Glass,false)glass.Transparency=.55
   h("WindowMullion",Vector3.new(.18,4.4,.3),x,5.1,s*9.1,BLUE,Enum.Material.Wood,false)h("WindowCrossbar",Vector3.new(3.8,.18,.3),x,5.1,s*9.1,BLUE,Enum.Material.Wood,false)
   h("FlowerBox",Vector3.new(4,.65,1),x,2.95,s*9.5,BLUE,Enum.Material.Wood)
  end
 end
 for _,x in ipairs({-10.5,10.5})do for _,z in ipairs({-9,9})do h("TimberCorner",Vector3.new(.75,9.5,.75),x,4.8,z,BLUE,Enum.Material.Wood)end end
 -- Roof slopes meet exactly at a shared ridge; end gables close the formerly exposed attic.
 local pitch=math.rad(32)local half=11.8 local ridge=9.6+half*math.tan(pitch)local slope=half/math.cos(pitch)
 for _,s in ipairs({-1,1})do h("RoofSlope",Vector3.new(slope,.4,21),s*half*.5,(ridge+9.6)*.5,0,BLUE,Enum.Material.Slate,true,CFrame.Angles(0,0,-s*pitch))end
 h("RoofRidge",Vector3.new(.5,.35,21.5),0,ridge+.15,0,BLUE,Enum.Material.Slate,true)
 for _,s in ipairs({-1,1})do for i=0,11 do local x=-10.5+(i+.5)*21/12 local height=(ridge-9.2)*(1-math.abs(x)/11.8)
  h("GableTimber",Vector3.new(21/12+.02,height,.4),x,9.2+height*.5,s*9,WHITE)
 end end
 for _,z in ipairs({-11.5,11.5})do for x=-12,12,4 do h("PorchPost",Vector3.new(.55,2.8,.55),x,1.4,z,WHITE,Enum.Material.Wood)end h("PorchHandrail",Vector3.new(27,.3,.45),0,2.7,z,WHITE,Enum.Material.Wood)end
 for _,x in ipairs({-13.7,13.7})do for _,z in ipairs({-8,8})do h("PorchHandrail",Vector3.new(.4,.3,6.5),x,2.7,z,WHITE,Enum.Material.Wood)end end
 local bulb=h("PorchLantern",Vector3.new(.5,.8,.5),-11.2,7.5,-3,Color3.fromRGB(255,209,141),Enum.Material.Neon,false)
 local light=Instance.new("PointLight")light.Color=bulb.Color light.Range=14 light.Shadows=false light.Parent=bulb C:AddTag(light,"ForestNightLight")
 h("KitchenCabinet",Vector3.new(6,2.7,2.5),7,1.65,6,BLUE)h("KitchenWorktop",Vector3.new(6.3,.25,2.8),7,3.1,6,WHITE,Enum.Material.Marble)
 h("RadioShelf",Vector3.new(3,.18,1.6),7,4.5,-6,WOOD,Enum.Material.Wood)
 tea:PivotTo(tea:GetPivot()+O+Vector3.new(2,.31,3)-teaCenter)tea.Parent=house
 local walk=Instance.new("Model")walk.Name="LakesideBoardwalk"walk.ModelStreamingMode=Enum.ModelStreamingMode.Atomic walk.Parent=garden
 local bankX=O.X-24 while ground(bankX,O.Z).Y<9 and bankX>-140 do bankX-=2 end
 local a=ground(bankX,O.Z)+Vector3.yAxis*.12 local b=O+Vector3.new(-14,0,0)local N=math.ceil((b-a).Magnitude/2)local nodes={}
 for i=0,N do local p=a:Lerp(b,i/N)nodes[#nodes+1]={p.X,p.Y,p.Z}end
 for i=1,N do local aa,bb=a:Lerp(b,(i-1)/N),a:Lerp(b,i/N)local cf=CFrame.lookAt((aa+bb)*.5,bb)local len=(bb-aa).Magnitude+.08
  P(walk,"BoardwalkPlank",Vector3.new(6,.32,len),cf*CFrame.new(0,-.16,0),WOOD,Enum.Material.Wood,true)
  for _,s in ipairs({-1,1})do P(walk,"BoardwalkRail",Vector3.new(.3,.3,len),cf*CFrame.new(s*2.85,2.4,0),WHITE,Enum.Material.Wood,true)
   if i%4==0 then local p=cf:PointToWorldSpace(Vector3.new(s*2.85,0,0))local g=ground(p.X,p.Z)local top=p.Y+2.7
    P(walk,"GroundedPost",Vector3.new(.6,top-g.Y+.3,.6),CFrame.new(p.X,(top+g.Y-.3)*.5,p.Z),DARK,Enum.Material.Wood,true)
   end
  end report.walkwaySegments+=1
 end
 P(walk,"BankApron",Vector3.new(2.5,.25,6),CFrame.new(a-Vector3.yAxis*.1),WOOD,Enum.Material.Wood,true)
 walk:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))house:SetAttribute("EntryPath",game:GetService("HttpService"):JSONEncode({{b.X,b.Y,b.Z},{O.X-10.5,O.Y+.3,O.Z},{O.X-5,O.Y+.3,O.Z}}))
 house:SetAttribute("RadioPosition",O+Vector3.new(7,4.61,-6))return report
end
return B
]============]).install()
reports.bridges=factory([============[local B={}
local WOOD=Color3.fromRGB(147,115,76)local PALE=Color3.fromRGB(182,146,101)local DARK=Color3.fromRGB(92,69,48)
function B.install()
 local world=workspace.ForestWorld local Scene=require(game.ReplicatedStorage.ForestRuntime.Scene)
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,rp)).Position end
 local folder=world.Amenities.WoodenBridges folder:ClearAllChildren()
 local report={bridges=0,parts=0}
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color or WOOD p.Material=material or Enum.Material.Wood p.Anchored=true p.CanCollide=true p.CanQuery=true p.CanTouch=false p.Transparency=0 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent report.parts+=1 return p
 end
 local function beam(parent,name,a,b,width,height,color)return part(parent,name,Vector3.new(width,height,(b-a).Magnitude+.03),CFrame.lookAt((a+b)*.5,b),color)end
 for index,z in ipairs({-108,176})do
  local cx=Scene.riverX(z)local xa,xb=cx-8,cx+8
  while ground(xa,z).Y<9 do xa-=2 end while ground(xb,z).Y<9 do xb+=2 end xa-=2 xb+=2
  local a,b=ground(xa,z),ground(xb,z)local W=11 local N=math.ceil((b-a).Magnitude/3.0)
  local m=Instance.new("Model")m.Name="WoodlandBridge"..index m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m:SetAttribute("DeckWidth",W)m:SetAttribute("ReferenceStyle","Wide carved woodland arch, longitudinal timber boards and scalloped support corbels")m.Parent=folder
  local function point(t)return a:Lerp(b,t)+Vector3.yAxis*(.08+2.4*math.sin(math.pi*t))end
  local nodes={}
  for i=0,N do local p=point(i/N)nodes[#nodes+1]={p.X,p.Y,p.Z}end
  for i=1,N do
   local aa,bb=point((i-1)/N),point(i/N)local cf=CFrame.lookAt((aa+bb)*.5,bb)local len=(bb-aa).Magnitude+.08
   for lane=0,7 do local x=-W*.5+(lane+.5)*W/8
    part(m,"SolidDeckPlank",Vector3.new(W/8+.012,.38,len),cf*CFrame.new(x,-.19,0),WOOD:Lerp(PALE,((lane+i)%5)*.09))
   end
   if i%3==1 then
    part(m,"UnderDeckCrossbeam",Vector3.new(W+1.3,.55,.7),cf*CFrame.new(0,-.66,0),DARK)
    for _,s in ipairs({-1,1})do
     local tip=cf:PointToWorldSpace(Vector3.new(s*(W/2+.45),-.65,0))
     for j=0,2 do part(m,"CarvedCorbel",Vector3.new(.64,.4,.75-j*.1),CFrame.new(tip+Vector3.new(0,-.4*j,j*.14))*cf.Rotation,WOOD:Lerp(PALE,j*.16))end
    end
   end
   for _,s in ipairs({-1,1})do
    part(m,"TimberHandrail",Vector3.new(.58,.32,len),cf*CFrame.new(s*(W/2-.25),2.65,0),PALE)
    part(m,"FramedLowerRail",Vector3.new(.28,.23,len),cf*CFrame.new(s*(W/2-.25),1.05,0),WOOD)
    beam(m,"ArchedFoundationTimber",aa+Vector3.new(0,-1.2,s*(W/2-.2)),bb+Vector3.new(0,-1.2,s*(W/2-.2)),.6,.85,DARK)
   end
  end
  local postCount=math.ceil((b-a).Magnitude/10)
  for i=0,postCount do local t=i/postCount local c=point(t)
   for _,s in ipairs({-1,1})do local pos=c+Vector3.zAxis*s*(W/2-.25)local g=ground(pos.X,pos.Z)local top=pos.Y+3.2 local base=g.Y-.45
    part(m,"GroundedCarvedPost",Vector3.new(1,top-base,1),CFrame.new(pos.X,(top+base)*.5,pos.Z),DARK)
    for _,h in ipairs({.75,2.42})do part(m,"CarvedPostCollar",Vector3.new(1.16,.16,1.16),CFrame.new(pos+Vector3.yAxis*h),WOOD)end
    part(m,"PostCapital",Vector3.new(1.34,.25,1.34),CFrame.new(pos+Vector3.yAxis*3.1),PALE)
    part(m,"PostCapFinial",Vector3.new(.68,.2,.68),CFrame.new(pos+Vector3.yAxis*3.32),WOOD)
   end
  end
  for _,endpoint in ipairs({a,b})do part(m,"BankApron",Vector3.new(2.6,.3,W),CFrame.new(endpoint-Vector3.yAxis*.08),WOOD)end
  m:SetAttribute("DeckStart",point(0))m:SetAttribute("DeckEnd",point(1))m:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))report.bridges+=1
 end
 return report
end
return B
]============]).install()
reports.water=factory([============[local B={}
local C=game:GetService("CollectionService")
local function P(parent,name,size,cf,color,mat,collide,class)
 local p=Instance.new(class or"Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=mat or Enum.Material.Slate p.Anchored=true p.CanCollide=collide==true p.CanQuery=collide==true p.CanTouch=false p.CastShadow=collide==true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
-- Two right triangular prisms form each authored polygon face. Their common edge is coplanar, never stacked.
local function triangle(parent,a,b,c,thickness,color,name)
 local ab,ac,bc=b-a,c-a,c-b local abd,acd,bcd=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
 if abd>acd and abd>bcd then c,a=a,c elseif acd>bcd and acd>abd then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit local back=bc.Unit local up=bc:Cross(right).Unit
 local height=math.abs(ab:Dot(up))local length1=math.abs(ab:Dot(back))local length2=math.abs(ac:Dot(back))
 if height<.001 or length1<.001 or length2<.001 then return end
 P(parent,name,Vector3.new(thickness,height,length1),CFrame.fromMatrix((a+b)*.5,right,up,back),color,Enum.Material.Slate,true,"WedgePart")
 P(parent,name,Vector3.new(thickness,height,length2),CFrame.fromMatrix((a+c)*.5,-right,up,-back),color,Enum.Material.Slate,true,"WedgePart")
end
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local garden=world.Amenities.RiversideGarden
 for _,name in ipairs({"AnimeRiverFoam","StreamSteppingStones","CartoonWater"})do local old=garden:FindFirstChild(name)if old then old:Destroy()end end
 local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={Terrain}
 local groundRay=RaycastParams.new()groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={Terrain}groundRay.IgnoreWater=true
 local function wet(x,z)local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.yAxis*-300,waterRay)return h and h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.12 end
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,200,z),Vector3.yAxis*-300,groundRay)).Position end
 local raw=game:GetService("AssetService"):LoadAssetAsync(6833503207)
 local surface=assert(raw:FindFirstChild("Water",true))assert(surface:IsA("MeshPart")and surface.MeshId=="rbxassetid://6833048037","Requested water model changed")
 local report={waterTiles=0,shoreFoam=0,stones=0,stoneFaces=0,waterAsset=6833503207}
 local water=Instance.new("Folder")water.Name="CartoonWater"water:SetAttribute("SourceAssetId",6833503207)water.Parent=garden
 Terrain.WaterColor=Color3.fromRGB(55,161,186)Terrain.WaterTransparency=.24 Terrain.WaterReflectance=.025 Terrain.WaterWaveSize=.015 Terrain.WaterWaveSpeed=3
 -- Keep native continuous swimming water. Import only one shallow visual layer from the requested model.
 for z=-294,294,12 do for x=-150,174,12 do
  local safe=true for _,dx in ipairs({-6,0,6})do for _,dz in ipairs({-6,0,6})do if not wet(x+dx,z+dz)then safe=false end end end
  if safe then
   local p=surface:Clone()p.Name="CartoonWaterSurface"p.Size=Vector3.new(12,.035,12)p.CFrame=CFrame.new(x,6.14,z)p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=.91 p.Color=Terrain.WaterColor p:SetAttribute("SourceAssetId",6833503207)p:SetAttribute("WaterCentre",Vector3.new(x,6,z))
   for _,d in ipairs(p:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()elseif d:IsA("Texture")then d.StudsPerTileU=14 d.StudsPerTileV=14 d.Transparency=.74 d.OffsetStudsU=x%14 d.OffsetStudsV=z%14 C:AddTag(d,"TreeWorldWaterTexture")end end
   p.Parent=water report.waterTiles+=1
  end
 end end
 local foam=Instance.new("Folder")foam.Name="ShoreFoam"foam.Parent=water
 for z=-274,274,8 do local center=Scene.riverX(z)
  if wet(center,z)then for _,side in ipairs({-1,1})do
   local inside,outside=center,center
   for _=1,80 do outside+=side*2 if not wet(outside,z)then break end inside=outside end
   for _=1,8 do local mid=(inside+outside)*.5 if wet(mid,z)then inside=mid else outside=mid end end
   local x=inside-side*.65
   if wet(x,z)then local strip=P(foam,"WaterlineFoam",Vector3.new(.32,.028,3.2),CFrame.new(x,6.075,z)*CFrame.Angles(0,.15*math.sin(z*.1),0),Color3.fromRGB(230,246,244),Enum.Material.SmoothPlastic,false)strip.Transparency=.38 report.shoreFoam+=1 end
  end end
 end
 raw:Destroy()runtime:SetAttribute("WaterStyle","CartoonWaterSingleLayer")runtime:SetAttribute("WaterAssetId",6833503207)
 -- Pale irregular polygon slabs, separated by reachable hops, with fully visible stone sides to the bed.
 local stones=Instance.new("Model")stones.Name="StreamSteppingStones"stones.ModelStreamingMode=Enum.ModelStreamingMode.Atomic stones.Parent=garden
 local z=90 local cx=Scene.riverX(z)local xa,xb=cx-4,cx+4
 while ground(xa,z).Y<7.3 do xa-=2 end while ground(xb,z).Y<7.3 do xb+=2 end
 local a,b=ground(xa,z),ground(xb,z)local count=math.ceil((xb-xa)/6.6)local nodes={}
 local rng=Random.new(942090)
 for i=0,count do
  local t=i/count local x=xa+(xb-xa)*t local zz=z+math.sin(t*math.pi*2)*1.6 local y=math.max(7.25,a.Y*(1-t)+b.Y*t)
  local model=Instance.new("Model")model.Name="FacetedWalkStone"model.Parent=stones local center=Vector3.new(x,y-.035,zz)local points={}
  local angle=rng:NextNumber(-.2,.2)local rx,rz=3.0,3.1
  for k=0,6 do local an=k*math.pi*2/7+angle local jitter=rng:NextNumber(.92,1.08)points[k+1]=center+Vector3.new(math.cos(an)*rx*jitter,0,math.sin(an)*rz*jitter)end
  local bottom=math.min(ground(x,zz).Y-.3,5.1)
  for k=1,#points do local p,q=points[k],points[k%#points+1]
   triangle(model,center,p,q,.07,Color3.fromRGB(190+k%3*4,204+k%3*4,211+k%3*4),"PaleStoneTop")
   local lowP,lowQ=Vector3.new(p.X,bottom,p.Z),Vector3.new(q.X,bottom,q.Z)
   local color=Color3.fromRGB(102+k%3*9,127+k%3*9,144+k%3*9)
   triangle(model,p,lowP,q,.1,color,"FacetedStoneSide")triangle(model,q,lowP,lowQ,.1,color,"FacetedStoneSide")report.stoneFaces+=3
  end
  model:SetAttribute("WalkTop",y)model:SetAttribute("Centre",Vector3.new(x,y,zz))nodes[#nodes+1]={x,y,zz}report.stones+=1
 end
 stones:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))
 -- A few large riverbank stones use the same polygon style without filling the walking route.
 world:SetAttribute("CartoonWaterTiles",report.waterTiles)world:SetAttribute("ReferenceSteppingStones",report.stones)
 return report
end
return B
]============]).install()
reports.lamps=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local C=game:GetService("CollectionService")
 local raw=game:GetService("AssetService"):LoadAssetAsync(11324928349)
 local template=assert(raw:FindFirstChildOfClass("Model"),"Requested lamp model missing")
 for _,d in ipairs(template:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Camera")then d:Destroy()end end
 local pole
 for _,d in ipairs(template:GetDescendants())do if d:IsA("MeshPart")and d.MeshId=="rbxassetid://11161434042"then pole=d end end
 assert(pole,"Requested lamp post mesh missing")
 local base=pole.Position-Vector3.yAxis*pole.Size.Y*.5
 template:PivotTo(template:GetPivot()-base)template.PrimaryPart=nil template.WorldPivot=CFrame.identity template:ScaleTo(template:GetScale()*.67)
 local folder=world.Amenities.Lanterns folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
 local report={lamps=0,sourceAssetId=11324928349}
 local points={}
 for z=-260,280,45 do points[#points+1]=Vector2.new(Scene.pathX(z)+7,z)points[#points+1]=Vector2.new(145+30*math.sin(z/100)-7,z+9)end
 local lake=world:GetAttribute("CentralLake")for i=0,5 do local a=i*math.pi/3 points[#points+1]=Vector2.new(lake.X+math.cos(a)*88,lake.Z+math.sin(a)*66)end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)points[#points+1]=Vector2.new(p.X,p.Z+8)end end
 for _,point in ipairs(points)do local hit=ground(point.X,point.Y)
  if hit and hit.Position.Y>7.4 and hit.Normal.Y>.83 then
   local m=template:Clone()m.Name="CandleLampPost"m:SetAttribute("SourceAssetId",11324928349)m:SetAttribute("GroundPoint",hit.Position)m:PivotTo(CFrame.new(hit.Position-Vector3.yAxis*.2))m.Parent=folder m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=false p.CanCollide=p:IsA("MeshPart")p.CanQuery=p.CanCollide p.CastShadow=p:IsA("MeshPart")
    elseif p:IsA("Light")then p.Enabled=false p.Shadows=false p.Range=14 p.Brightness=1.1 p.Color=Color3.fromRGB(255,210,151)C:AddTag(p,"ForestNightLight")
    elseif p:IsA("Fire")then p.Size=.25 p.Heat=0 C:AddTag(p,"RuinVFX")end
   end
   report.lamps+=1
  end
 end
 raw:Destroy()assert(report.lamps>=18,"Insufficient grounded lamp posts")world:SetAttribute("CandleLampCount",report.lamps)world:SetAttribute("LampAssetId",11324928349)
 return report
end
return B
]============]).install()
reports.roots=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 for _,name in ipairs({"ForestGrassClient"})do local old=game.StarterPlayer.StarterPlayerScripts:FindFirstChild(name)if old then old:Destroy()end end
 for _,name in ipairs({"SkinnedGrassTemplates","GrassSampler","GrassPriority"})do local old=runtime:FindFirstChild(name)if old then old:Destroy()end end
 local terrainRay=RaycastParams.new()terrainRay.FilterType=Enum.RaycastFilterType.Include terrainRay.FilterDescendantsInstances={workspace.Terrain}terrainRay.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-310,0),terrainRay)end
 local report={trees=0,plants=0,rootProbes=0,removedPlants=0,removedDecor=0}
 if runtime:FindFirstChild("ActualRootContacts")then runtime.ActualRootContacts:Destroy()end
 local probeFolder=Instance.new("Folder")probeFolder.Name="ActualRootContacts"probeFolder.Parent=runtime
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,p in ipairs(folder:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=true end end end
 task.wait(.15)
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,m in ipairs(folder:GetChildren())do
  local tree=folder==world.Decor.Trees local parts={}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p.Name~="TrunkCollision"and(tree and p.Name:lower():find("trunk",1,true)or not tree)then
   parts[#parts+1]=p p.CanQuery=true
   for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(point)hi=hi:Max(point)end end end
  end end
  local own=RaycastParams.new()own.FilterType=Enum.RaycastFilterType.Include own.FilterDescendantsInstances=parts
  local samples={}local minimum=math.huge
  -- Sample the actual placed mesh from below. Source scale attributes are not trusted.
  local n=tree and 13 or 5
  for ix=0,n-1 do for iz=0,n-1 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/n local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/n
   local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)
   if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
  end end
  if tree and minimum>lo.Y+1 then
   for ix=0,30 do for iz=0,30 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/31 local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/31
    local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
   end end
  end
  local contacts={}
  for _,v in ipairs(samples)do if v.Y<minimum+(tree and 2.2 or .3)then contacts[#contacts+1]=v end end
  if #contacts==0 and not tree then
   -- Flat alpha cards can have no underside for an upward ray; use the actual placed mesh bounds for these plants.
   contacts={Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)}m:SetAttribute("GroundingMethod","PlacedMeshBounds")
  else m:SetAttribute("GroundingMethod","PlacedMeshRaycast")end
  assert(#contacts>0,"No real base geometry: "..m.Name)
  local shift=math.huge local center=Vector3.zero local depth=tree and 1.15 or .18
  for _,point in ipairs(contacts)do local h=assert(ground(point.X,point.Z),"No ground beneath visible root")shift=math.min(shift,h.Position.Y-point.Y-depth)center+=point end
  center/= #contacts m:PivotTo(m:GetPivot()+Vector3.yAxis*shift)
  local finalCenter=center+Vector3.yAxis*shift m:SetAttribute("ActualRootPoint",finalCenter)m:SetAttribute("RootEmbedDepth",depth)
  local entry=Instance.new("ObjectValue")entry.Name="RootContact"entry.Value=m entry:SetAttribute("CoordinateSpace","World")entry.Parent=probeFolder
  local cf=m:GetPivot()
  for i,point in ipairs(contacts)do local v=Instance.new("Vector3Value")v.Name=tostring(i)v.Value=point+Vector3.yAxis*shift v.Parent=entry report.rootProbes+=1 end
  if tree then
   C:AddTag(m,"ForestTree")report.trees+=1
   local trunk=m:FindFirstChild("TrunkCollision")if trunk then local h=assert(ground(finalCenter.X,finalCenter.Z))trunk.CFrame=CFrame.new(finalCenter.X,h.Position.Y+trunk.Size.X*.5-.15,finalCenter.Z)*CFrame.Angles(0,0,math.pi*.5)end
  else report.plants+=1 end
  for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")then p.RenderFidelity=Enum.RenderFidelity.Performance p.CastShadow=tree
   if not p.CanCollide then p.CanQuery=false end
   if p:GetAttribute("ForestRestCF")then p:SetAttribute("ForestRestCF",p.CFrame)end
  end end
 end end
 -- Dense leaf carpets and oversized broad weeds are removed; native grass supplies continuous cover.
 for _,m in ipairs(world.Decor.Plants:GetChildren())do
  if m.Name=="DenseLeafPatch"or m.Name=="CloverPatch"then m:Destroy()report.removedPlants+=1 end
 end
 for _,m in ipairs(world.Amenities.CutTrunks:GetChildren())do local cf,size=m:GetBoundingBox()local h=ground(cf.X,cf.Z)if h then m:PivotTo(m:GetPivot()+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end end
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do
  local pivot=m:GetPivot()local h=ground(pivot.X,pivot.Z)
  if h and h.Position.Y>6 then local cf,size=m:GetBoundingBox()m:PivotTo(pivot+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end
 end
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())runtime:SetAttribute("GrassRenderer","NativeTerrain")runtime:SetAttribute("GrassMotionEnabled",false)
 return report
end
return B
]============]).install()
reports.radio=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local house=world.Amenities.RiversideGarden.WaterCottage
 local raw=game:GetService("AssetService"):LoadAssetAsync(15855506991)local model=assert(raw:FindFirstChild("RadioShop"))
 local radio=model:Clone()radio.Name="PersonalRadio"radio:SetAttribute("SourceAssetId",15855506991)radio.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,d in ipairs(radio:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("ProximityPrompt")or d:IsA("JointInstance")then d:Destroy()end end
 local cf,size=radio:GetBoundingBox()radio:PivotTo(radio:GetPivot()-Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z))radio.PrimaryPart=nil radio.WorldPivot=CFrame.identity
 radio:PivotTo(CFrame.new(house:GetAttribute("RadioPosition")))radio.Parent=house
 for _,p in ipairs(radio:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=true p.CanTouch=false end end
 local root=assert(radio:FindFirstChildOfClass("MeshPart"))
 local prompt=Instance.new("ProximityPrompt")prompt.Name="OpenPersonalMusic"prompt.ActionText="Ouvir música"prompt.ObjectText="Rádio"prompt.HoldDuration=0 prompt.MaxActivationDistance=7 prompt.RequiresLineOfSight=false prompt.Parent=root
 raw:Destroy()
 local old=runtime:FindFirstChild("MusicListening")if old then old:Destroy()end
 local remote=Instance.new("RemoteEvent")remote.Name="MusicListening"remote.Parent=runtime
 runtime:SetAttribute("MusicPlayback","LocalOnly")return{sourceAssetId=15855506991,radioMeshes=8,serverSounds=0}
end
return B
]============]).install()
workspace.ForestWorld:SetAttribute("UpgradeVersion",95)
source(game.ServerScriptService,"Script","ForestServer",[============[local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Visuals=require(runtime:WaitForChild("Visuals"))Visuals.apply()
local Cycle=require(runtime:WaitForChild("Cycle"))
runtime:SetAttribute("CycleEpoch",Cycle.epoch(workspace:GetServerTimeNow()))
runtime:SetAttribute("CycleSeconds",Cycle.Duration)
local world = workspace:WaitForChild("ForestWorld")
local spawn = world:WaitForChild("ForestSpawn")
local spawnCF = runtime:GetAttribute("MainSpawnCF")
require(runtime:WaitForChild("GardenWeather")).start(runtime,world)
require(runtime:WaitForChild("SeasonController")).start(runtime,world)
require(runtime:WaitForChild("RuinController")).start(runtime,world)
require(runtime:WaitForChild("MusicController")).start(runtime,world)
local Collection=game:GetService("CollectionService")
for _,seat in ipairs(world.Amenities.LogBenches:GetDescendants())do if seat:IsA("Seat")then
	local prompt=seat:FindFirstChild("SitPrompt")
	if prompt then prompt.Triggered:Connect(function(player)
		local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
		if h and h.Health>0 and r and not seat.Occupant and(r.Position-seat.Position).Magnitude<9 then seat:Sit(h)end
	end)end
end end
local function character(player, model)
	local humanoid = model:WaitForChild("Humanoid", 10) local root = model:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= model then return end
	root.Anchored = false humanoid.PlatformStand = false humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16 humanoid.UseJumpPower = true humanoid.JumpPower = 50
	if (root.Position - spawnCF.Position).Magnitude > 28 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero end
end
local function playerAdded(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(model) character(player, model) end)
	if player.Character then task.spawn(character, player, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt if elapsed < 1 then return end elapsed = 0
	local time = workspace:GetServerTimeNow()
	local clock=Cycle.clock(time,runtime:GetAttribute("CycleEpoch"))Visuals.clock(clock)
	for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do light.Enabled=Cycle.night(clock)>.015 light.Brightness=Cycle.night(clock)*1.25 end
	local strength = 2.8 + math.sin(time * 0.047) * 0.25 + math.sin(time * 0.023) * 0.15
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestMusicClient",[============[local Players=game:GetService("Players")local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local player=Players.LocalPlayer
local Config=require(runtime:WaitForChild("MusicConfig"))local UI=require(runtime:WaitForChild("MusicUI"))local Player=require(runtime:WaitForChild("MusicPlayer"))
local remote=runtime:WaitForChild("MusicListening")local ui=UI.build(player:WaitForChild("PlayerGui"),Config.Tracks)
local music=Player.new(game:GetService("SoundService"),function(active)remote:FireServer(active)end,function(text)ui.status.Text=text end)
ui.open.Activated:Connect(function()ui.panel.Visible=not ui.panel.Visible end)
for _,entry in ipairs(ui.tracks)do entry.button.Activated:Connect(function()task.spawn(music.play,entry.track.id,entry.track.title)end)end
ui.play.Activated:Connect(function()local id=Config.parse(ui.input.Text)if not id then ui.status.Text="Digite um ID de áudio válido."return end task.spawn(music.play,id,"Sua música")end)
ui.pause.Activated:Connect(music.pause)ui.stop.Activated:Connect(function()music.stop()ui.status.Text="Parado"end)
ui.lower.Activated:Connect(function()music.setVolume(music.volume-.05)end)ui.louder.Activated:Connect(function()music.setVolume(music.volume+.05)end)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt,who)if prompt.Name=="OpenPersonalMusic"and who==player then ui.panel.Visible=true end end)
script.Destroying:Connect(function()music.stop()ui.gui:Destroy()end)
]============])
run(game.ServerScriptService.ForestServer.Source)
reports.tests=run([============[local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
assert(world:GetAttribute("UpgradeVersion")==95)
local report={trees=0,plants=0,actualRootProbes=0,walkProbes=0,teaTables=0,teaCups=0,ruins=4,audio=0}
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestGrassClient")and not runtime:FindFirstChild("SkinnedGrassTemplates"),"Skeletal spike grass remains")
assert(runtime:GetAttribute("GrassRenderer")=="NativeTerrain")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray))end
for _,entry in ipairs(runtime.ActualRootContacts:GetChildren())do local m=entry.Value if m and m:IsDescendantOf(world)then local cf=m:GetPivot()
 for _,point in ipairs(entry:GetChildren())do local p=entry:GetAttribute("CoordinateSpace")=="World"and point.Value or cf:PointToWorldSpace(point.Value)local h=ground(p.X,p.Z)assert(p.Y-h.Position.Y<-.12,"Visible root remains above the soil: "..m.Name)report.actualRootProbes+=1 end
 if m.Parent==world.Decor.Trees then report.trees+=1 else report.plants+=1 end end end
assert(report.trees>300 and report.plants>700 and report.actualRootProbes>1000)
for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={bridge}rp.RespectCanCollide=true
 for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")then assert(p.Transparency==0 and p.CanCollide and p.CanQuery,"Bridge has an invisible or non-solid part")end end
 local nodes=game:GetService("HttpService"):JSONDecode(bridge:GetAttribute("WalkNodes"))
 for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
  for _,t in ipairs({0,.5,.95})do local center=a:Lerp(b,t)
   for _,offset in ipairs({-4.4,-2,0,2,4.4})do local p=center+Vector3.zAxis*offset local hit=assert(workspace:Raycast(p+Vector3.yAxis*.65,Vector3.yAxis*-1.5,rp),"Bridge has a walking gap")assert(hit.Instance.Name=="SolidDeckPlank"or hit.Instance.Name=="BankApron")assert(math.abs(hit.Position.Y-center.Y)<.18,"Bridge collision disagrees with visible deck")report.walkProbes+=1 end
  end
 end
 for _,i in ipairs({1,#nodes})do local p=Vector3.new(unpack(nodes[i]))assert(math.abs(ground(p.X,p.Z).Position.Y-p.Y)<.2,"Bridge shifted off the bank")end
end
assert(not world.Amenities.ForestRuins:FindFirstChild("EntrancePath"))
local positions={world.Amenities.ForestRuins:GetAttribute("Origin")}
for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do positions[#positions+1]=m:GetAttribute("Origin")end
for i=1,#positions do for j=i+1,#positions do assert((Vector2.new(positions[i].X,positions[i].Z)-Vector2.new(positions[j].X,positions[j].Z)).Magnitude>160,"Ruins still overlap")end end
for _,click in ipairs(C:GetTagged("TreeWorldCupClick"))do if click:IsDescendantOf(world)then assert(click:IsA("ClickDetector")and click.MaxActivationDistance==9)report.teaCups+=1 end end
for _,m in ipairs(world:GetDescendants())do if m:IsA("Model")and m.Name=="AntiqueTeaTable"then local cf,size=m:GetBoundingBox()assert(size.X<6 and size.Z<6 and size.Y<4,"Tea table still enormous")report.teaTables+=1 end
 assert(m.Name~="MoodPrompt"and m.Name~="ServeTea","Old tea interaction or mood selection remains")
end assert(report.teaTables==4 and report.teaCups==16)
for _,seat in ipairs(C:GetTagged("RuinSeat"))do if seat:IsDescendantOf(world)and seat.Name=="TeaSeat"then
 local table=seat.Parent.Parent.AntiqueTeaTable local center=table:GetPivot().Position local direction=Vector3.new(center.X-seat.Position.X,0,center.Z-seat.Position.Z).Unit
 assert(seat.CFrame.LookVector:Dot(direction)>.95,"Compact tea chair faces away from table")
end end
local desc=Instance.new("HumanoidDescription")local actor=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R6)desc:Destroy()actor.Name="TeaTest"actor.Parent=workspace
local click=C:GetTagged("TreeWorldCupClick")[1]local cupPoint=click.Parent:GetPivot().Position actor:PivotTo(CFrame.new(cupPoint+Vector3.yAxis*2))actor.HumanoidRootPart.Anchored=true
local bag=Instance.new("Backpack")bag.Parent=game.ServerStorage local mock={Character=actor,Backpack=bag,UserId=1092}
function mock:FindFirstChildOfClass(name)if name=="Backpack"then return bag end end
local service=require(runtime.RuinController).start(runtime,world)
assert(service.serve(mock,click,false),"Direct cup click failed to serve")assert(actor:FindFirstChildOfClass("Tool"),"Clicked cup did not reach the hand")
actor:Destroy()bag:Destroy()report.directCupServe=true
assert(not runtime:FindFirstChild("RuinInteraction")and not game.StarterPlayer.StarterPlayerScripts.ForestRuinClient.Source:find('TextLabel',1,true))
local Mood=require(runtime.RuinMood)local origin=positions[1]for _=1,60 do Mood.apply(origin,origin,"Neblina",1)end
assert(game.Lighting.ForestAtmosphere.Density<.35 and game.Lighting.ForestAtmosphere.Haze<1.3,"Fog accumulates")Mood.apply(origin+Vector3.xAxis*200,origin,"Neblina",1)assert(math.abs(game.Lighting.ForestAtmosphere.Density-.24)<.001)
for _,s in ipairs(runtime.GardenSounds:GetChildren())do game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Missing forest audio")report.audio+=1 end
assert(game.StarterPlayer.StarterPlayerScripts.ForestGardenClient.Source:find('root,.055',1,true))
local water=RaycastParams.new()water.FilterType=Enum.RaycastFilterType.Include water.FilterDescendantsInstances={workspace.Terrain}
local Scene=require(runtime.Scene)for z=-288,288,8 do local h=assert(workspace:Raycast(Vector3.new(Scene.riverX(z),200,z),Vector3.yAxis*-300,water))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.1,"River altered by repairs")end
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})do for _,s in ipairs(parent:GetChildren())do if s:IsA("LuaSourceContainer")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,v=pcall(require,m)m:Destroy()assert(ok,tostring(v))compiled+=1 end end end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,v=pcall(require,s)assert(ok,tostring(v))compiled+=1 end end
report.compiled=compiled report.noTeaPopups=true report.fogStable=true report.nativeGrassRequested=true report.parts=0 report.pbr=0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then report.parts+=1 end if p:IsA("SurfaceAppearance")then report.pbr+=1 end assert(not p:IsA("LuaSourceContainer"))end
assert(report.parts<12500 and report.pbr>2500,"Forest loss or mobile geometry increase")
assert(world:GetAttribute("AnimalsEnabled")==false and not runtime:FindFirstChild("CuteAnimalTemplates") and not runtime:FindFirstChild("WildlifeTemplates"))
assert(not world:FindFirstChild("Wildlife") and not world.Amenities:FindFirstChild("CuteAnimalRoutes"))
assert(not game.StarterPlayer.StarterPlayerScripts.ForestGardenClient.Source:find("CuteAnimal",1,true))
local lake=assert(world:GetAttribute("CentralLake"))
local lakePoints=0
for dx=-48,48,12 do for dz=-24,24,12 do
 local h=assert(workspace:Raycast(Vector3.new(lake.X+dx,200,lake.Z+dz),Vector3.yAxis*-300,water))
 assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.12,"Central lake contains dry holes")lakePoints+=1
end end
local tiles=0
for _,p in ipairs(world.Amenities.RiversideGarden.CartoonWater:GetChildren())do if p:IsA("MeshPart")then
 assert(p.MeshId=="rbxassetid://6833048037" and p:GetAttribute("SourceAssetId")==6833503207)
 assert(not p.CanCollide and not p.CanQuery and math.abs(p.Position.Y-6.14)<.001 and p.Size.Y<.04,"Water overlay blocks swimming or has stacked layers")
 for _,dx in ipairs({-6,0,6})do for _,dz in ipairs({-6,0,6})do local h=assert(workspace:Raycast(Vector3.new(p.Position.X+dx,200,p.Position.Z+dz),Vector3.yAxis*-300,water))assert(h.Material==Enum.Material.Water,"Water tile crosses the shore")end end
 tiles+=1
end end
assert(tiles>150 and tiles<1000,"Water geometry budget exceeded")
local lampCount=0
for _,m in ipairs(world.Amenities.Lanterns:GetChildren())do
 assert(m:GetAttribute("SourceAssetId")==11324928349,"Incorrect lamp asset")local pole
 for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")and p.MeshId=="rbxassetid://11161434042"then pole=p end end
 assert(pole)local bottom=pole.Position.Y-pole.Size.Y*.5 local g=ground(pole.Position.X,pole.Position.Z)
 assert(bottom<g.Position.Y+.1 and bottom>g.Position.Y-1.5,"Lamp floats")lampCount+=1
end
assert(lampCount>=18)
local stoneCount=0 local stoneProbes=0
for _,m in ipairs(world.Amenities.RiversideGarden.StreamSteppingStones:GetChildren())do
 local center=m:GetAttribute("Centre")local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={m}rp.RespectCanCollide=true
 for _,off in ipairs({Vector3.new(.3,0,.3),Vector3.new(-1.4,0,.4),Vector3.new(.4,0,-1.4)})do local h=assert(workspace:Raycast(center+off+Vector3.yAxis*1,Vector3.yAxis*-2,rp),"Faceted stone has missing walk surface")assert(h.Instance.Name=="PaleStoneTop"and math.abs(h.Position.Y-center.Y)<.08)stoneProbes+=1 end
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then assert(p.Transparency==0 and p.CanCollide,"Stone side invisible or not solid")end end
 stoneCount+=1
end
assert(stoneCount>5)
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then
 for _,n in ipairs({p.CFrame:GetComponents()})do assert(n==n and math.abs(n)<5000,"Invalid world frame: "..p:GetFullName())end
end end
local stair=world.Amenities.WeatheredHillStair local _,stairSize=stair:GetBoundingBox()assert(stairSize.Y<100,"Malformed hill stair survives")
local flowers=0 for _,m in ipairs(world.Decor.Plants:GetChildren())do if m:GetAttribute("LakeFlower")then flowers+=1 local _,size=m:GetBoundingBox()assert(size.Y<1.3,"Lakeside flower too tall")end end assert(flowers>=40)
local Scene=require(runtime.Scene)
for _,m in ipairs(world.Amenities.CutTrunks:GetChildren())do local cf,size=m:GetBoundingBox()assert(Scene.pathDistance(cf.X,cf.Z)>=8+math.min(11,math.max(size.X,size.Z)*.5),"Stump blocks trail")end
report.lakeWaterProbes=lakePoints report.cartoonWaterTiles=tiles report.exactLampPosts=lampCount report.facetedStones=stoneCount report.stoneWalkProbes=stoneProbes report.lowLakeFlowers=flowers report.noAnimals=true report.finiteWorldGeometry=true
assert(world:GetAttribute("TerrainOrganized")==true)
local rocks=0 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do local n=m.Name:lower()if n:find("rock",1,true)or n:find("boulder",1,true)then rocks+=1 end end assert(rocks<=48,"Excess rock clutter")
local house=world.Amenities.RiversideGarden.WaterCottage assert(house:GetAttribute("RebuiltEntrance"))
local O=house:GetAttribute("Origin")local path=game:GetService("HttpService"):JSONDecode(house:GetAttribute("EntryPath"))
local collision=RaycastParams.new()collision.FilterType=Enum.RaycastFilterType.Include collision.FilterDescendantsInstances={house}collision.RespectCanCollide=true
local entryProbes=0
for i=1,#path-1 do local a,b=Vector3.new(unpack(path[i])),Vector3.new(unpack(path[i+1]))
 for _,offset in ipairs({-1.0,0,1.0})do for _,height in ipairs({1.0,2.6,4.4})do
  local start=a+Vector3.new(0,height,offset)local hit=workspace:Raycast(start,b-a,collision)assert(not hit,"Cottage entrance blocked: "..(hit and hit.Instance.Name or ""))entryProbes+=1
 end end
end
local boardwalk=world.Amenities.RiversideGarden.LakesideBoardwalk local nodes=game:GetService("HttpService"):JSONDecode(boardwalk:GetAttribute("WalkNodes"))
local walkwayRay=RaycastParams.new()walkwayRay.FilterType=Enum.RaycastFilterType.Include walkwayRay.FilterDescendantsInstances={boardwalk}walkwayRay.RespectCanCollide=true
local walkwayProbes=0
for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
 for _,t in ipairs({0,.5,.95})do for _,offset in ipairs({-2.1,0,2.1})do local p=a:Lerp(b,t)+Vector3.zAxis*offset local h=assert(workspace:Raycast(p+Vector3.yAxis*.65,Vector3.yAxis*-1.5,walkwayRay),"Cottage walkway has a hole")assert(h.Instance.Name=="BoardwalkPlank"or h.Instance.Name=="BankApron")assert(math.abs(h.Position.Y-p.Y)<.18)walkwayProbes+=1 end end
end
local cf,size=house.CottageTeaCorner.AntiqueTeaTable:GetBoundingBox()assert(math.abs(cf.Y-size.Y*.5-(O.Y+.31))<.06,"Cottage tea table sank into floor")
local Player=require(runtime.MusicPlayer)local Config=require(runtime.MusicConfig)
assert(Config.parse("123456")==123456 and Config.parse("rbxassetid://123456")==123456 and not Config.parse("-1") and not Config.parse("12.5") and not Config.parse("abc") and not Config.parse(string.rep("9",20)))
for _,track in ipairs(Config.Tracks)do local s=Instance.new("Sound")s.SoundId="rbxassetid://"..track.id s.Parent=game:GetService("SoundService")game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>5,"Preset music unavailable: "..track.title)s:Destroy()end
local listeners={false,false}local a=Instance.new("Folder")a.Parent=game:GetService("SoundService")local b=Instance.new("Folder")b.Parent=game:GetService("SoundService")
local A=Player.new(a,function(state)listeners[1]=state end,function()end)local B=Player.new(b,function(state)listeners[2]=state end,function()end)
assert(A.play(Config.Tracks[1].id,"A")and B.play(Config.Tracks[4].id,"B"))assert(A.sound.Parent==a and B.sound.Parent==b and listeners[1]and listeners[2])
A.pause()assert(not listeners[1]and listeners[2]and not A.sound.IsPlaying and B.sound.IsPlaying)
A.stop()assert(B.sound.IsPlaying and listeners[2])B.stop()assert(not listeners[2])a:Destroy()b:Destroy()
local root=Instance.new("Folder")root.Parent=game.ServerStorage local UI=require(runtime.MusicUI).build(root,Config.Tracks)
assert(UI.panel.Scroll:IsA("ScrollingFrame")and UI.panel.Scroll.AutomaticCanvasSize==Enum.AutomaticSize.Y and UI.input:IsA("TextBox")and #UI.tracks==#Config.Tracks and not UI.panel.Visible)root:Destroy()
local radio=house.PersonalRadio assert(radio:GetAttribute("SourceAssetId")==15855506991)local meshes=0
for _,d in ipairs(radio:GetDescendants())do assert(not d:IsA("Sound")and not d:IsA("LuaSourceContainer"),"Shared original radio playback remains")if d:IsA("MeshPart")then meshes+=1 end end assert(meshes==8)
local service=require(runtime.MusicController).start(runtime,world)
local mock={Character=nil,attributes={}}function mock:SetAttribute(k,v)self.attributes[k]=v end
assert(not service.apply(mock,"123"))assert(service.apply(mock,true)and mock.attributes.ListeningToMusic==true)assert(service.apply(mock,false)and not mock.attributes.ListeningToMusic)
assert(runtime:GetAttribute("MusicPlayback")=="LocalOnly")assert(not game.ServerScriptService.ForestServer.Source:find("SoundId",1,true))
report.accentRocks=rocks report.cottageEntranceProbes=entryProbes report.cottageWalkwayProbes=walkwayProbes report.cottageTeaFloor=true report.radioMeshes=meshes report.musicPresets=#Config.Tracks report.personalPlaybackIsolation=true report.musicStatusValidation=true report.musicScrollUI=true
return report
]============])
runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,expectedVersion=95,reports=reports}
