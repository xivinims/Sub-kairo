assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"wrong target")
assert(game.PlaceVersion==75,"place changed since inspection")
local SS=game.ServerStorage local RS=game.ReplicatedStorage local SSS=game.ServerScriptService
local SP=game.StarterPlayer local SPS=SP.StarterPlayerScripts local IS=game.InsertService
local world=Instance.new("Folder") world.Name="HangoutWorld"
local net=Instance.new("Folder") net.Name="HangoutNet"
for _,name in ipairs({"Travel","Item"}) do local r=Instance.new("RemoteEvent") r.Name=name r.Parent=net end
local locations=Instance.new("Folder") locations.Name="Locations" locations.Parent=net
local function part(parent,name,size,cf,color,mat,class)
 local p=Instance.new(class or "Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color or Color3.fromRGB(227,220,205)
 p.Material=mat or Enum.Material.SmoothPlastic p.Anchored=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local green=Color3.fromRGB(119,157,107) local wood=Color3.fromRGB(144,107,76)
local function bench(parent,x,z,y)
 y=y or 2
 part(parent,"BenchFrame",Vector3.new(8,.5,2),CFrame.new(x,y+1,z),wood,Enum.Material.Wood)
 part(parent,"Backrest",Vector3.new(8,2,.4),CFrame.new(x,y+2,z+1),wood,Enum.Material.Wood)
 for _,dx in ipairs({-2.7,2.7}) do
  local seat=part(parent,"Seat",Vector3.new(2,.35,1.6),CFrame.new(x+dx/2,y+1.4,z),wood,Enum.Material.Wood,"Seat") seat.CanTouch=true
  part(parent,"Leg",Vector3.new(.4,1.2,1.5),CFrame.new(x+dx,y+.5,z),Color3.fromRGB(52,66,68),Enum.Material.Metal)
 end
end
local function tree(parent,x,z,y,scale)
 scale=scale or 1
 part(parent,"Trunk",Vector3.new(2,12,2)*scale,CFrame.new(x,y+6*scale,z),wood,Enum.Material.Wood)
 for i=1,3 do
  local p=part(parent,"Crown",Vector3.new(13,11,13)*scale,CFrame.new(x+(i-2)*4*scale,y+(13+(i%2)*2)*scale,z+(i==2 and 3 or 0)*scale),Color3.fromRGB(83+i*6,133+i*5,92),Enum.Material.Grass)
  p.Shape=Enum.PartType.Ball p.CanCollide=false
 end
end
local function lamp(parent,x,z,y)
 part(parent,"LampPost",Vector3.new(.5,9,.5),CFrame.new(x,y+4.5,z),Color3.fromRGB(51,62,68),Enum.Material.Metal)
 local head=part(parent,"Lamp",Vector3.new(2,1.2,2),CFrame.new(x,y+9,z),Color3.fromRGB(249,223,161),Enum.Material.Neon)
 local light=Instance.new("PointLight") light.Color=head.Color light.Brightness=1.8 light.Range=20 light.Shadows=false light.Enabled=false light.Parent=head
end
local function sign(parent,text,cf)
 local board=part(parent,"Sign",Vector3.new(15,4,.35),cf,Color3.fromRGB(36,65,61),Enum.Material.Wood)
 local ui=Instance.new("SurfaceGui") ui.Face=Enum.NormalId.Front ui.PixelsPerStud=40 ui.Parent=board
 local t=Instance.new("TextLabel") t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1 t.Font=Enum.Font.GothamMedium t.TextSize=32 t.TextColor3=Color3.fromRGB(246,241,222) t.Text=text t.TextWrapped=true t.Parent=ui
end
local function destination(id,label,order,cf)
 local v=Instance.new("Folder") v.Name=id v:SetAttribute("Label",label) v:SetAttribute("Order",order) v:SetAttribute("Spawn",cf) v.Parent=locations
 local pad=Instance.new("Model") pad.Name="Landing_"..id pad.ModelStreamingMode=Enum.ModelStreamingMode.Persistent pad.Parent=world
 local floor=part(pad,"SafeLanding",Vector3.new(8,.4,8),cf-Vector3.new(0,3.8,0),Color3.fromRGB(208,193,149),Enum.Material.Sandstone)
 floor:SetAttribute("HangoutLanding",true)
 local s=part(pad,"Marker",Vector3.new(.4,6,.4),floor.CFrame+Vector3.new(5,3,0),wood,Enum.Material.Wood)
 sign(pad,label,s.CFrame+Vector3.new(0,3,0))
end
local plaza=Instance.new("Model") plaza.Name="Praca" plaza.Parent=world
part(plaza,"Island",Vector3.new(210,14,210),CFrame.new(0,-5,0),Color3.fromRGB(104,115,102),Enum.Material.Rock)
part(plaza,"Grass",Vector3.new(208,1,208),CFrame.new(0,1.5,0),green,Enum.Material.Grass)
part(plaza,"Walkway",Vector3.new(20,.2,195),CFrame.new(0,2.1,0),Color3.fromRGB(208,193,149),Enum.Material.Sandstone)
part(plaza,"Walkway",Vector3.new(195,.2,20),CFrame.new(0,2.1,0),Color3.fromRGB(208,193,149),Enum.Material.Sandstone)
local fountain=part(plaza,"FountainBasin",Vector3.new(3,31,31),CFrame.new(0,3,28)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(174,181,166),Enum.Material.Slate) fountain.Shape=Enum.PartType.Cylinder
local water=part(plaza,"FountainWater",Vector3.new(.4,27,27),CFrame.new(0,4.4,28)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(112,172,182),Enum.Material.Glass) water.Shape=Enum.PartType.Cylinder water.Transparency=.25 water.CanCollide=false
part(plaza,"FountainColumn",Vector3.new(2,6,2),CFrame.new(0,6,28),Color3.fromRGB(195,198,183),Enum.Material.Slate)
for i=0,7 do local angle=i*math.pi/4 tree(plaza,math.cos(angle)*75,math.sin(angle)*75,2,.85) end
for _,v in ipairs({{-28,-20},{28,-20},{-32,50},{32,50}}) do bench(plaza,v[1],v[2]) end
for _,v in ipairs({{-14,-50},{14,-50},{-45,14},{45,14},{-14,63},{14,63}}) do lamp(plaza,v[1],v[2],2) end
sign(plaza,"PONTO DE ENCONTRO\nUse MAPAS para explorar",CFrame.new(0,7,-35))
-- Sheltered pavilion with open sides.
for _,x in ipairs({-48,-22}) do for _,z in ipairs({-57,-34}) do part(plaza,"PavilionPost",Vector3.new(1,12,1),CFrame.new(x,8,z),wood,Enum.Material.Wood) end end
part(plaza,"PavilionRoof",Vector3.new(31,1.2,28),CFrame.new(-35,14,-45.5),Color3.fromRGB(68,90,79),Enum.Material.WoodPlanks)
bench(plaza,-35,-48)
destination("Praca","Praça central",1,CFrame.new(0,6,-15))
local spawn=part(plaza,"HangoutSpawn",Vector3.new(8,1,8),CFrame.new(0,2.3,-15),green,Enum.Material.Grass,"SpawnLocation")
spawn.Transparency=1 spawn.CanCollide=false spawn.Neutral=true spawn.Duration=0 spawn.Enabled=true
local origins={Vector3.new(-1800,0,0),Vector3.new(1800,0,0),Vector3.new(0,0,-1800)}
local imported={}
for i,def in ipairs({{11603671645,"Praia","Praia",2},{3371706192,"Vila","Vila da ilha",3},{139782479241283,"Parque","Parque dos arcos",4}}) do
 local source=IS:LoadAsset(def[1])
 local map=Instance.new("Model") map.Name=def[2]
 for _,d in ipairs(source:GetChildren()) do d.Parent=map end source:Destroy()
 map:SetAttribute("SourceAssetId",tostring(def[1]))
 local parts,lights=0,0
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=true d.CanTouch=d:IsA("Seat") or d:IsA("VehicleSeat") parts+=1 if d:IsA("SpawnLocation") then d.Enabled=false end
  elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then d.Enabled=false
  elseif d:IsA("Sound") then d.Playing=false
  elseif d:IsA("Light") then lights+=1 d.Enabled=lights<=6 d.Shadows=false
  end
 end
 assert(parts>100,"empty imported map")
 local cf,size=map:GetBoundingBox()
 local desired=origins[i]+Vector3.new(0,size.Y/2,0)
 map:PivotTo(CFrame.new(desired-cf.Position)*map:GetPivot())
 map.Parent=workspace
 local bounds,extent=map:GetBoundingBox()
 local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={map} ray.RespectCanCollide=true
 local overlaps=OverlapParams.new() overlaps.FilterType=Enum.RaycastFilterType.Include overlaps.FilterDescendantsInstances={map} overlaps.RespectCanCollide=true
 local spawnCF
 for _,v in ipairs({Vector2.new(.15,.2),Vector2.new(-.2,.15),Vector2.new(.2,-.2),Vector2.new(-.15,-.2),Vector2.new(0,0),Vector2.new(.3,0),Vector2.new(0,.3)}) do
  local origin=Vector3.new(bounds.X+v.X*extent.X,bounds.Y+extent.Y/2+25,bounds.Z+v.Y*extent.Z)
  local hit=workspace:Raycast(origin,Vector3.new(0,-extent.Y-60,0),ray)
  if hit and hit.Normal.Y>.95 and hit.Material~=Enum.Material.Water then
   local target=hit.Position+Vector3.new(0,4.1,0)
   local blocked=false
   for _,p in ipairs(workspace:GetPartBoundsInBox(CFrame.new(target),Vector3.new(3.5,5,3.5),overlaps)) do if p.CanCollide then blocked=true break end end
   if not blocked then spawnCF=CFrame.new(target) break end
  end
 end
 assert(spawnCF,"no safe destination in "..def[2])
 destination(def[2],def[3],def[4],spawnCF)
 map.Parent=world
 table.insert(imported,{id=tostring(def[1]),name=def[2],parts=parts,spawn=tostring(spawnCF.Position)})
end
local camp=Instance.new("Model") camp.Name="Acampamento" camp.Parent=world
part(camp,"Island",Vector3.new(180,14,180),CFrame.new(0,-5,1800),Color3.fromRGB(104,115,102),Enum.Material.Rock)
part(camp,"Grass",Vector3.new(178,1,178),CFrame.new(0,1.5,1800),green,Enum.Material.Grass)
for i=0,11 do local a=i*math.pi/6 tree(camp,math.cos(a)*65,1800+math.sin(a)*65,2,.9) end
for _,z in ipairs({1770,1830}) do bench(camp,0,z) end
part(camp,"ShelterRoof",Vector3.new(30,1,25),CFrame.new(40,15,1800),Color3.fromRGB(74,97,79),Enum.Material.WoodPlanks)
for _,x in ipairs({26,54}) do for _,z in ipairs({1789,1811}) do part(camp,"ShelterPost",Vector3.new(1,13,1),CFrame.new(x,8.5,z),wood,Enum.Material.Wood) end end
bench(camp,40,1797)
local logs=part(camp,"Campfire",Vector3.new(7,.8,2),CFrame.new(0,2.8,1800),wood,Enum.Material.Wood)
local fire=Instance.new("Fire") fire.Size=5 fire.Heat=4 fire.Parent=logs
local light=Instance.new("PointLight") light.Color=Color3.fromRGB(255,176,103) light.Range=24 light.Brightness=1.8 light.Shadows=false light.Parent=logs
destination("Acampamento","Acampamento",5,CFrame.new(0,6,1784))
local items=Instance.new("Folder") items.Name="HangoutItems"
local function tool(name,color,size)
 local t=Instance.new("Tool") t.Name=name t.RequiresHandle=true t.CanBeDropped=false t.ToolTip=name
 local h=part(t,"Handle",size or Vector3.new(.45,1.4,.45),CFrame.identity,color,Enum.Material.SmoothPlastic) h.Anchored=false h.CanCollide=false h.CanTouch=false h.Massless=true
 t.Parent=items return t,h
end
local lantern,h=tool("Lanterna",Color3.fromRGB(236,189,94))
local l=Instance.new("PointLight") l.Range=22 l.Brightness=2 l.Color=Color3.fromRGB(255,232,184) l.Shadows=false l.Parent=h
local ball,b=tool("Bola",Color3.fromRGB(245,162,99),Vector3.new(1.5,1.5,1.5)) b.Shape=Enum.PartType.Ball
local umbrella,u=tool("Guarda-chuva",Color3.fromRGB(70,91,111),Vector3.new(.15,4,.15)) umbrella.Grip=CFrame.new(0,-1,0)
local canopy=part(umbrella,"Canopy",Vector3.new(7,1,7),CFrame.new(0,2.5,0),Color3.fromRGB(83,141,154),Enum.Material.SmoothPlastic)
canopy.Shape=Enum.PartType.Ball canopy.Anchored=false canopy.CanCollide=false canopy.CanTouch=false canopy.Massless=true
local weld=Instance.new("WeldConstraint") weld.Part0=u weld.Part1=canopy weld.Parent=u
local rainAsset=IS:LoadAsset(7095497839)
for _,d in ipairs(rainAsset:GetDescendants()) do if d:IsA("BaseScript") then d.Enabled=false end end
rainAsset.Name="RainCycleByNarrakin_Original"

local serverSource=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local Lighting=game:GetService("Lighting")
local Debris=game:GetService("Debris")
local net=RS:WaitForChild("HangoutNet")
local travel=net:WaitForChild("Travel")
local item=net:WaitForChild("Item")
local locations=net:WaitForChild("Locations")
local templates=SS:WaitForChild("HangoutItems")
local busy,lastItem={},{ }
Players.CharacterAutoLoads=true
Players.RespawnTime=3
local function bindTool(tool,p)
 local last=0
 tool.Activated:Connect(function()
  if os.clock()-last<.6 then return end last=os.clock()
  if tool.Parent~=p.Character then return end
  if tool.Name=="Lanterna" then
   local light=tool.Handle:FindFirstChildOfClass("PointLight")
   if light then light.Enabled=not light.Enabled end
  elseif tool.Name=="Bola" then
   local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   if not root then return end
   local ball=Instance.new("Part") ball.Name="HangoutBall" ball.Shape=Enum.PartType.Ball
   ball.Size=Vector3.new(2,2,2) ball.Color=Color3.fromRGB(245,162,99)
   ball.Material=Enum.Material.SmoothPlastic
   ball.CustomPhysicalProperties=PhysicalProperties.new(.5,.3,.8,1,1)
   ball.CFrame=root.CFrame*CFrame.new(0,0,-4) ball.Parent=workspace
   ball.AssemblyLinearVelocity=root.CFrame.LookVector*28+Vector3.new(0,14,0)
   Debris:AddItem(ball,15)
  end
 end)
end
item.OnServerEvent:Connect(function(p,name)
 if type(name)~="string" or not templates:FindFirstChild(name) then return end
 if os.clock()-(lastItem[p] or 0)<.4 then return end lastItem[p]=os.clock()
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid") local bag=p:FindFirstChildOfClass("Backpack")
 if not h or h.Health<=0 or not bag then return end
 local tool=c:FindFirstChild(name) or bag:FindFirstChild(name)
 if not tool then tool=templates[name]:Clone() bindTool(tool,p) tool.Parent=bag end
 if tool.Parent==c then h:UnequipTools() else h:EquipTool(tool) end
end)
travel.OnServerEvent:Connect(function(p,id)
 if type(id)~="string" or busy[p] then return end
 local location=locations:FindFirstChild(id)
 if not location then return end
 local c=p.Character local r=c and c:FindFirstChild("HumanoidRootPart") local h=c and c:FindFirstChildOfClass("Humanoid")
 if not r or not h or h.Health<=0 then return end
 busy[p]=true
 travel:FireClient(p,"Loading",location:GetAttribute("Label"))
 task.spawn(function()
  local target=location:GetAttribute("Spawn")
  local ok,err=pcall(function()
   -- Stream before relocating. Persistent landing pads also protect low-memory clients.
   p:RequestStreamAroundAsync(target.Position,3)
   if p.Character~=c or not r.Parent or h.Health<=0 then return end
   h.Sit=false h.PlatformStand=false
   r.Anchored=true
   c:PivotTo(target)
   r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
   task.wait(.3)
  end)
  if r.Parent then r.Anchored=false end
  if not ok then warn("Hangout travel: "..tostring(err)) end
  if p.Parent then
   if ok and p.Character==c then p:SetAttribute("HangoutLocation",id) travel:FireClient(p,"Done",location:GetAttribute("Label"))
   else travel:FireClient(p,"Error","Tente novamente") end
  end
  task.wait(1) busy[p]=nil
 end)
end)
local function setup(p)
 p:SetAttribute("HangoutLocation","Praca")
 p.CharacterAdded:Connect(function(c)
  local h=c:WaitForChild("Humanoid",10)
  if h then h.WalkSpeed=16 h.UseJumpPower=true h.JumpPower=50 h.AutoRotate=true h.PlatformStand=false end
  p:SetAttribute("HangoutLocation","Praca")
 end)
end
Players.PlayerAdded:Connect(setup) for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerRemoving:Connect(function(p)busy[p]=nil lastItem[p]=nil end)
local sky=Lighting:WaitForChild("HangoutSky")
-- Sky faces and cloudy/rain sequence from RainCycleByNarrakin (7095497839).
local skies={
 Sol={153258865,153259937,153258844,153258851,153259421,153259943},
 Nublado={4495864450,4495864887,4495865458,4495866035,4495866584,4495867486},
 Chuva={4498828382,4498828812,4498829917,4498830911,4498830417,4498831746}
}
local faces={"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}
local states={{"Sol",120},{"Nublado",18},{"Chuva",85},{"Nublado",18},{"Sol",150},{"Nublado",18},{"Chuva",95}}
local start=workspace:GetServerTimeNow()
workspace:SetAttribute("HangoutClockStart",start)
local weatherIndex=1 local nextWeather=start+120
local function applyWeather(name)
 workspace:SetAttribute("HangoutWeather",name)
 for i,face in ipairs(faces) do sky[face]="rbxassetid://"..skies[name][i] end
 sky.SunAngularSize=name=="Sol" and 10 or 0
 sky.MoonAngularSize=name=="Sol" and 11 or 0
 sky.StarCount=name=="Sol" and 2500 or 0
end
local function phase(hour)
 if hour<5 then return "Madrugada" elseif hour<6.5 then return "Amanhecer"
 elseif hour<12 then return "Manhã" elseif hour<17 then return "Tarde"
 elseif hour<18.5 then return "Pôr do sol" elseif hour<20 then return "Anoitecer" else return "Noite" end
end
applyWeather("Sol")
while true do
 local now=workspace:GetServerTimeNow()
 if now>=nextWeather then weatherIndex=weatherIndex%#states+1 applyWeather(states[weatherIndex][1]) nextWeather=now+states[weatherIndex][2] end
 local hour=(9+(now-start)*24/960)%24
 Lighting.ClockTime=hour
 workspace:SetAttribute("HangoutHour",hour) workspace:SetAttribute("HangoutPhase",phase(hour))
 local daylight=math.clamp((math.sin((hour-6)/24*math.pi*2)+.25)/1.25,0,1)
 local rainy=workspace:GetAttribute("HangoutWeather")~="Sol"
 Lighting.Brightness=.9+daylight*(rainy and 1.1 or 2)
 Lighting.Ambient=Color3.fromRGB(56,61,83):Lerp(Color3.fromRGB(115,120,125),daylight)
 Lighting.OutdoorAmbient=Color3.fromRGB(62,67,90):Lerp(Color3.fromRGB(144,150,160),daylight)
 local sunset=math.clamp(1-math.abs(hour-18)/1.5,0,1)
 Lighting.ColorShift_Top=Color3.new(0,0,0):Lerp(Color3.fromRGB(108,53,25),sunset)
 local atmosphere=Lighting.HangoutAtmosphere atmosphere.Density=rainy and .38 or .24 atmosphere.Haze=rainy and 2 or .8
 for _,d in ipairs(workspace.HangoutWorld.Praca:GetDescendants()) do if d:IsA("PointLight") then d.Enabled=daylight<.4 end end
 task.wait(1)
end
]====]

local clientSource=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local p=Players.LocalPlayer
local net=RS:WaitForChild("HangoutNet")
local travel=net:WaitForChild("Travel") local item=net:WaitForChild("Item")
local gui=Instance.new("ScreenGui") gui.Name="HangoutUI" gui.ResetOnSpawn=false gui.IgnoreGuiInset=false gui.DisplayOrder=20 gui.Parent=p:WaitForChild("PlayerGui")
local function round(obj,r)
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 12) c.Parent=obj
end
local function label(text,size,pos,parent)
 local t=Instance.new("TextLabel") t.BackgroundTransparency=1 t.Text=text t.Size=size t.Position=pos
 t.Font=Enum.Font.GothamMedium t.TextSize=14 t.TextColor3=Color3.fromRGB(240,245,245) t.Parent=parent return t
end
local function button(text,size,pos,parent)
 local b=Instance.new("TextButton") b.Name=text b.Text=text b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(31,45,49)
 b.BackgroundTransparency=.08 b.TextColor3=Color3.fromRGB(238,247,244) b.Font=Enum.Font.GothamMedium b.TextSize=14 b.AutoButtonColor=true b.Parent=parent round(b)
 return b
end
local mapsButton=button("MAPAS",UDim2.fromOffset(94,40),UDim2.new(1,-106,0,12),gui)
local itemsButton=button("ITENS",UDim2.fromOffset(78,40),UDim2.new(1,-194,0,12),gui)
local info=label("",UDim2.new(1,-220,0,45),UDim2.fromOffset(16,10),gui)
info.TextXAlignment=Enum.TextXAlignment.Left info.TextSize=13 info.TextWrapped=true
local function panel(name,width,height)
 local f=Instance.new("Frame") f.Name=name f.AnchorPoint=Vector2.new(1,0) f.Position=UDim2.new(1,-12,0,62) f.Size=UDim2.fromOffset(width,height)
 f.BackgroundColor3=Color3.fromRGB(21,31,36) f.BackgroundTransparency=.05 f.Visible=false f.Parent=gui round(f,16)
 return f
end
local maps=panel("Destinos",244,302) local items=panel("Itens",244,212)
label("Escolha um lugar",UDim2.fromOffset(212,26),UDim2.fromOffset(16,12),maps).TextXAlignment=Enum.TextXAlignment.Left
local list=net:WaitForChild("Locations"):GetChildren() table.sort(list,function(a,b)return a:GetAttribute("Order")<b:GetAttribute("Order")end)
local toast=label("",UDim2.new(.8,0,0,48),UDim2.fromScale(.1,.17),gui) toast.TextWrapped=true
local fading
local function message(t)
 if fading then fading:Cancel() end toast.TextTransparency=0 toast.Text=t
 task.delay(3,function()if toast.Text==t then fading=TweenService:Create(toast,TweenInfo.new(.4),{TextTransparency=1}) fading:Play() end end)
end
for i,location in ipairs(list) do
 local b=button(location:GetAttribute("Label"),UDim2.fromOffset(212,42),UDim2.fromOffset(16,48+(i-1)*49),maps)
 b.Activated:Connect(function()maps.Visible=false travel:FireServer(location.Name)end)
end
label("Itens para levar com você",UDim2.fromOffset(212,26),UDim2.fromOffset(16,12),items).TextXAlignment=Enum.TextXAlignment.Left
for i,name in ipairs({"Lanterna","Guarda-chuva","Bola"}) do
 local b=button(name,UDim2.fromOffset(212,42),UDim2.fromOffset(16,48+(i-1)*49),items)
 b.Activated:Connect(function()item:FireServer(name) items.Visible=false end)
end
mapsButton.Activated:Connect(function()maps.Visible=not maps.Visible items.Visible=false end)
itemsButton.Activated:Connect(function()items.Visible=not items.Visible maps.Visible=false end)
travel.OnClientEvent:Connect(function(kind,text)
 if kind=="Loading" then message("Indo para "..text.."…") elseif kind=="Done" then message(text) else message(text or "Tente novamente") end
end)
local function refresh()
 local id=p:GetAttribute("HangoutLocation") or "Praca"
 local location=net.Locations:FindFirstChild(id)
 info.Text=(location and location:GetAttribute("Label") or "Praça").."\n"..tostring(workspace:GetAttribute("HangoutPhase") or "Manhã").." · "..tostring(workspace:GetAttribute("HangoutWeather") or "Sol")
end
for _,a in ipairs({"HangoutPhase","HangoutWeather"}) do workspace:GetAttributeChangedSignal(a):Connect(refresh) end
p:GetAttributeChangedSignal("HangoutLocation"):Connect(refresh) refresh()
-- RainCycle expects RainScript and __RainEmitter, which its asset does not include.
-- Supply a bounded local rain renderer; drops never collide with characters.
local rain=Instance.new("Folder") rain.Name="HangoutLocalRain" rain.Parent=workspace
local drops={} local rng=Random.new()
for i=1,56 do
 local d=Instance.new("Part") d.Name="Drop" d.Size=Vector3.new(.045,1.5,.045) d.Color=Color3.fromRGB(194,220,233)
 d.Material=Enum.Material.Glass d.Transparency=1 d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false d.CastShadow=false d.Parent=rain
 drops[i]={part=d,x=rng:NextNumber(-23,23),y=rng:NextNumber(-6,25),z=rng:NextNumber(-23,23)}
end
local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude
local exposed=true local checkTime=0
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera if not camera then return end
 local clockStart=workspace:GetAttribute("HangoutClockStart")
 if clockStart then game.Lighting.ClockTime=(9+(workspace:GetServerTimeNow()-clockStart)*24/960)%24 end
 local wet=workspace:GetAttribute("HangoutWeather")=="Chuva"
 if wet and os.clock()>checkTime then
  checkTime=os.clock()+.4 params.FilterDescendantsInstances={rain,p.Character}
  local origin=p.Character and p.Character:FindFirstChild("Head")
  exposed=not workspace:Raycast(origin and origin.Position or camera.CFrame.Position,Vector3.new(0,100,0),params)
  local tool=p.Character and p.Character:FindFirstChild("Guarda-chuva") if tool then exposed=false end
 end
 local center=camera.CFrame.Position
 for _,d in ipairs(drops) do
  if wet and exposed then
   d.y-=math.min(dt,.1)*54 if d.y< -8 then d.y=25 d.x=rng:NextNumber(-23,23) d.z=rng:NextNumber(-23,23) end
   d.part.Position=center+Vector3.new(d.x,d.y,d.z) d.part.Transparency=.35
  else d.part.Transparency=1 end
 end
end)
local function restoreCamera(char)
 local h=char:WaitForChild("Humanoid",10) if not h then return end
 local camera=workspace.CurrentCamera camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=h camera.FieldOfView=70
end
p.CharacterAdded:Connect(restoreCamera) if p.Character then task.spawn(restoreCamera,p.Character) end
]====]

local compiled={}
for name,source in pairs({server=serverSource,client=clientSource}) do
 local m=Instance.new("ModuleScript") m.Source="return function()\n"..source.."\nend" m.Parent=SS
 local ok,fn=pcall(require,m) m:Destroy() assert(ok and type(fn)=="function",name..": "..tostring(fn)) compiled[name]=true
end
assert(#locations:GetChildren()==5)
for _,v in ipairs(locations:GetChildren()) do assert(typeof(v:GetAttribute("Spawn"))=="CFrame") end
local count=0 for _,d in ipairs(world:GetDescendants()) do if d:IsA("BasePart") then count+=1 assert(d.Anchored,"unanchored map object") end assert(not d:IsA("LuaSourceContainer"),"script remaining in imported world") end
local result={ok=true,sourceVersion=game.PlaceVersion,maps=imported,destinations=5,worldParts=count,items=#items:GetChildren(),compiled=compiled,weatherAsset="7095497839"}

local backup=Instance.new("Folder") backup.Name="BeforeHangout_"..tostring(game.PlaceVersion) backup.Parent=SS
local function folder(name)local f=Instance.new("Folder") f.Name=name f.Parent=backup return f end
local function archive(obj,parent)
 if obj:IsA("BaseScript") then obj.Enabled=false end
 for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BaseScript") then d.Enabled=false end end
 obj.Parent=parent
end
local oldWorld=folder("Workspace")
for _,d in ipairs(workspace:GetChildren()) do if not d:IsA("Terrain") and not d:IsA("Camera") then archive(d,oldWorld) end end
workspace.Terrain:Clear()
local oldScripts=folder("ServerScriptService")
for _,d in ipairs(SSS:GetChildren()) do archive(d,oldScripts) end
local oldPlayer=folder("StarterPlayer")
for _,d in ipairs(SPS:GetChildren()) do archive(d,oldPlayer) end
for _,d in ipairs(SP.StarterCharacterScripts:GetChildren()) do archive(d,oldPlayer) end
local oldCharacter=SP:FindFirstChild("StarterCharacter") if oldCharacter then archive(oldCharacter,oldPlayer) end
local oldGui=folder("StarterGui")
for _,d in ipairs(game.StarterGui:GetChildren()) do archive(d,oldGui) end
local oldTools=folder("StarterPack")
for _,d in ipairs(game.StarterPack:GetChildren()) do archive(d,oldTools) end
local oldLight=folder("Lighting")
for _,d in ipairs(game.Lighting:GetChildren()) do archive(d,oldLight) end
local oldNet=RS:FindFirstChild("HangoutNet") if oldNet then archive(oldNet,folder("ReplicatedStorage")) end
local oldItems=SS:FindFirstChild("HangoutItems") if oldItems then archive(oldItems,folder("ServerStorage")) end
world.Parent=workspace net.Parent=RS items.Parent=SS rainAsset.Parent=backup
local server=Instance.new("Script") server.Name="HangoutServer" server.Source=serverSource server.Parent=SSS
local client=Instance.new("LocalScript") client.Name="HangoutClient" client.Source=clientSource client.Parent=SPS
SP.LoadCharacterAppearance=true SP.CameraMode=Enum.CameraMode.Classic SP.CameraMinZoomDistance=.5 SP.CameraMaxZoomDistance=18
SP.CharacterWalkSpeed=16 SP.CharacterJumpPower=50
SP.DevComputerMovementMode=Enum.DevComputerMovementMode.UserChoice SP.DevTouchMovementMode=Enum.DevTouchMovementMode.UserChoice
workspace.StreamingEnabled=true workspace.StreamingMinRadius=64 workspace.StreamingTargetRadius=256
workspace.FallenPartsDestroyHeight=-100 workspace:SetAttribute("HangoutVersion",1)
workspace:SetAttribute("HangoutWeather","Sol") workspace:SetAttribute("HangoutPhase","Manhã") workspace:SetAttribute("HangoutHour",9)
workspace:SetAttribute("NBRoundActive",false)
local L=game.Lighting L.ClockTime=9 L.Brightness=2.5 L.GlobalShadows=true L.ExposureCompensation=0
L.Ambient=Color3.fromRGB(115,120,125) L.OutdoorAmbient=Color3.fromRGB(144,150,160) L.EnvironmentDiffuseScale=.6 L.EnvironmentSpecularScale=.6
local sky=Instance.new("Sky") sky.Name="HangoutSky" sky.StarCount=2500 sky.Parent=L
local faces={"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}
for i,id in ipairs({153258865,153259937,153258844,153258851,153259421,153259943}) do sky[faces[i]]="rbxassetid://"..id end
local atmosphere=Instance.new("Atmosphere") atmosphere.Name="HangoutAtmosphere" atmosphere.Density=.24 atmosphere.Haze=.8 atmosphere.Color=Color3.fromRGB(205,221,228) atmosphere.Decay=Color3.fromRGB(106,135,154) atmosphere.Parent=L
local bloom=Instance.new("BloomEffect") bloom.Name="HangoutBloom" bloom.Intensity=.08 bloom.Size=14 bloom.Threshold=1.3 bloom.Parent=L
local rays=Instance.new("SunRaysEffect") rays.Name="HangoutSunRays" rays.Intensity=.045 rays.Spread=.8 rays.Parent=L
result.backup=backup.Name
game:GetService("AssetService"):SavePlaceAsync()
result.saved=true
return result
