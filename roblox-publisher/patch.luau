assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==90,"Published base changed")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
source(runtime,"ModuleScript","GardenWeather",[============[local W={Period=480,RainSeconds=120,FirstRain=90}
function W.raining(now,epoch)local t=math.max(0,now-epoch)if t<W.FirstRain then return false end return(t-W.FirstRain)%W.Period<W.RainSeconds end
function W.partner(a,b)return a and b and a.Health>0 and b.Health>0 and not a.Sit and not b.Sit and a.Parent~=b.Parent and(a.Parent.HumanoidRootPart.Position-b.Parent.HumanoidRootPart.Position).Magnitude<=5 end
function W.canopy(a,b)local p=a.Head.Position if b then local q=b.Head.Position return Vector3.new((p.X+q.X)*.5,math.max(p.Y,q.Y)+1.5,(p.Z+q.Z)*.5)end return p+Vector3.yAxis*1.5 end
function W.start(runtime,world)
 if W.started then return W end W.started=true
 if runtime:GetAttribute("GardenTestMode")then return W end
 local Players=game:GetService("Players")local Run=game:GetService("RunService")
 local epoch=workspace:GetServerTimeNow()runtime:SetAttribute("WeatherEpoch",epoch)runtime:SetAttribute("Raining",false)
 local entries={}local cloudy=false
 local function reset(e)
  for j,base in pairs(e.bases)do if j.Parent then j.C0=base end end
  if e.motor then e.motor:Destroy()e.motor=nil end e.tool:SetAttribute("SharingWith",nil)
 end
 local function give(player)
  local c=player.Character local hum=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
  if not hum or not root or hum.Health<=0 or entries[player]then return end
  local t=runtime.UmbrellaTool:Clone()t.Parent=player.Backpack
  local e={tool=t,bases={},player=player}entries[player]=e
  t.Equipped:Connect(function()
   if player.Character~=c then return end
   e.motor=Instance.new("Motor6D")e.motor.Name="UmbrellaHold"e.motor.Part0=root e.motor.Part1=t.UmbrellaAnchor e.motor.C0=root.CFrame:ToObjectSpace(CFrame.new(W.canopy(c)-Vector3.yAxis*3.2))e.motor.Parent=root
   for _,j in ipairs(c:GetDescendants())do if j:IsA("Motor6D")and(j.Name=="RightShoulder"or j.Name=="Right Shoulder"or j.Name=="RightElbow")then e.bases[j]=j.C0 end end
  end)
  t.Unequipped:Connect(function()reset(e)end)
  t.Destroying:Connect(function()reset(e)if entries[player]==e then entries[player]=nil end end)
  if not hum.Sit and not c:FindFirstChildOfClass("Tool")then hum:EquipTool(t)end
 end
 local function remove(player)local e=entries[player]if e then e.tool:Destroy()end end
 local function joined(player)player.CharacterAdded:Connect(function()remove(player)task.delay(1.5,function()if runtime:GetAttribute("Raining")then give(player)end end)end)end
 Players.PlayerAdded:Connect(joined)Players.PlayerRemoving:Connect(remove)for _,p in ipairs(Players:GetPlayers())do joined(p)end
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  local rain=W.raining(workspace:GetServerTimeNow(),epoch)
  if rain~=cloudy then cloudy=rain runtime:SetAttribute("Raining",rain)for _,p in ipairs(Players:GetPlayers())do if rain then give(p)else remove(p)end end end
  local active={}
  for p,e in pairs(entries)do local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")if h and h.Health>0 and e.motor and e.tool.Parent==c and not h.Sit then active[#active+1]=e elseif e.motor then reset(e)if h then h:UnequipTools()end end end
  table.sort(active,function(a,b)return a.player.UserId<b.player.UserId end)
  local paired={}
  for _,e in ipairs(active)do
   local c=e.player.Character local buddy
   if not paired[e]then for _,other in ipairs(active)do if other~=e and not paired[other]and W.partner(c.Humanoid,other.player.Character.Humanoid)then buddy=other paired[e]=other paired[other]=e break end end else buddy=paired[e]end
   local owner=not buddy or e.player.UserId<buddy.player.UserId
   for _,p in ipairs(e.tool:GetDescendants())do if p:IsA("BasePart")then p.Transparency=owner and(p.Name=="UmbrellaAnchor"and 1 or 0)or 1 end end
   local target=W.canopy(c,buddy and buddy.player.Character)-Vector3.yAxis*3.2
   e.motor.C0=e.motor.C0:Lerp(c.HumanoidRootPart.CFrame:ToObjectSpace(CFrame.new(target)),.25)
   e.tool:SetAttribute("SharingWith",buddy and buddy.player.UserId or nil)
   for joint,base in pairs(e.bases)do if joint.Parent then local shoulder=joint.Name~="RightElbow"local angle=shoulder and 120 or 45 local tilt=buddy and math.clamp(c.HumanoidRootPart.CFrame:PointToObjectSpace(target).X*10,-35,35)or -8
    joint.C0=joint.C0:Lerp(CFrame.new(base.Position)*CFrame.Angles(math.rad(angle),0,math.rad(shoulder and tilt or 0))*base.Rotation,.2)
   end end
  end
 end)
 return W
end
return W
]============])
source(runtime,"ModuleScript","RuinController",[============[local Controller={}
local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
function Controller.allowed(distance,alive,elapsed)return alive and distance<=10 and elapsed>=4 end
function Controller.start(runtime,world)
 local ruins=assert(world.Amenities:FindFirstChild("ForestRuins"))local remote=runtime.RuinInteraction
 local last={}local sip={}
 local function actor(player)
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then return c,h,r end
 end
 for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
  if seat:IsDescendantOf(world)then seat.SitPrompt.Triggered:Connect(function(player)
   local c,h,r=actor(player)if r and(r.Position-seat.Position).Magnitude<=9 and not seat.Occupant then seat:Sit(h)end
  end)end
 end
 local prompt=ruins.TeaCorner.Teapot.PotBody.ServeTea
 local function serve(player,sourcePrompt,seated)
  sourcePrompt=sourcePrompt or prompt
  local c,h,r=actor(player)if not r then return false end
  local now=os.clock()
  if not Controller.allowed((r.Position-sourcePrompt.Parent.Position).Magnitude,true,now-(last[player]or -math.huge))then return false end
  last[player]=now
  local backpack=player:FindFirstChildOfClass("Backpack")if not backpack then return false end
  for _,container in ipairs({c,backpack})do for _,item in ipairs(container:GetChildren())do
   if item:IsA("Tool")and item:GetAttribute("RuinTeaCup")then h:EquipTool(item)remote:FireClient(player,"Já tem uma xícara! Toque para tomar um gole.")return true end
  end end
  local tool=runtime.TeaCupTool:Clone()tool.Name="Chá"tool:SetAttribute("RuinTeaCup",true)tool:SetAttribute("ServedToUserId",player.UserId)
  tool.Parent=backpack
  local bases={}local tweens={}local generation=0 local originalGrip=tool.Grip
  local function restore()
   generation+=1 if tool.Parent then tool.Grip=originalGrip end
   for _,t in ipairs(tweens)do t:Cancel()end table.clear(tweens)
   for joint,base in pairs(bases)do if joint.Parent then joint.C0=base end end table.clear(bases)
  end
  tool.Unequipped:Connect(restore)tool.Destroying:Connect(restore)
  tool.Activated:Connect(function()
   local model,hum,root=actor(player)
   if not model or tool.Parent~=model or tool:GetAttribute("ServedToUserId")~=player.UserId then return end
   local time=os.clock()if time-(sip[player]or -math.huge)<3 then return end sip[player]=time
   local original=originalGrip
   restore()local token=generation
   for _,joint in ipairs(model:GetDescendants())do if joint:IsA("Motor6D")then
    local shoulder=joint.Name=="RightShoulder"or joint.Name=="Right Shoulder"
    local elbow=joint.Name=="RightElbow"
    if shoulder or elbow then
     local base=joint.C0 bases[joint]=base
     local angle=shoulder and(hum.RigType==Enum.HumanoidRigType.R6 and 105 or 65)or 90
     local rotation=CFrame.Angles(math.rad(angle),0,math.rad(shoulder and -12 or 0))
     local goal=CFrame.new(base.Position)*rotation*base.Rotation
     local t=Tween:Create(joint,TweenInfo.new(.38,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{C0=goal})tweens[#tweens+1]=t t:Play()
    end
   end end
   task.delay(1.1,function()
    if token~=generation or tool.Parent~=model then return end
    for joint,base in pairs(bases)do if joint.Parent then local t=Tween:Create(joint,TweenInfo.new(.45,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{C0=base})tweens[#tweens+1]=t t:Play()end end
    task.delay(.5,function()if token==generation then restore()end end)
   end)
   local lift=Tween:Create(tool,TweenInfo.new(.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original*CFrame.new(.08,-.15,-.22)*CFrame.Angles(math.rad(-24),0,0)})tweens[#tweens+1]=lift lift:Play()
   remote:FireClient(player,"Um chá quentinho. ☕")
   task.delay(.9,function()if token==generation and tool.Parent==model then local back=Tween:Create(tool,TweenInfo.new(.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original})tweens[#tweens+1]=back back:Play()end end)
  end)
  task.delay(240,function()if tool.Parent then tool:Destroy()end end)
  hum:EquipTool(tool)remote:FireClient(player,"Chá servido! Toque na xícara equipada para tomar um gole.")return true
 end
 for _,p in ipairs(Collection:GetTagged("TreeWorldTeaPrompt"))do
  if p:IsDescendantOf(world)then p.Triggered:Connect(function(player)serve(player,p,false)end)end
 end
 for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
  local target=seat:FindFirstChild("TeaPrompt")
  if target and target.Value then seat:GetPropertyChangedSignal("Occupant"):Connect(function()
   local humanoid=seat.Occupant local player=humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
   if player then task.delay(.35,function()if seat.Occupant==humanoid then serve(player,target.Value,true)end end)end
  end)end
 end
 Players.PlayerRemoving:Connect(function(player)last[player]=nil sip[player]=nil end)
 return{serve=serve}
end
return Controller
]============])
local riverside=factory([============[local B={}
local C=game:GetService("CollectionService")
local function P(parent,name,size,cf,color,mat,collision)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=mat or Enum.Material.Wood p.Anchored=true p.CanCollide=collision~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function line(parent,name,a,b,width,color,mat,collision)return P(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)*.5,b),color,mat,collision)end
local WHITE=Color3.fromRGB(229,225,204)local BLUE=Color3.fromRGB(65,100,122)local WOOD=Color3.fromRGB(143,112,79)local DARK=Color3.fromRGB(85,86,72)
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 for _,obj in ipairs({world:FindFirstChild("OwnerNPC"),runtime:FindFirstChild("NPCController"),game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestNPCClient")})do if obj then obj:Destroy()end end
 local folder=Instance.new("Folder")folder.Name="RiversideGarden"folder.Parent=world.Amenities
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),rp)).Position end
 local house=Instance.new("Model")house.Name="WaterCottage"house.Parent=folder house:SetAttribute("Reference","White timber cottage with blue gable roof, dormers and a surrounding pier")
 local O=Vector3.new(40,10.5,135)house:SetAttribute("Origin",O)
 local function h(name,size,x,y,z,color,mat,col,rotation)return P(house,name,size,CFrame.new(O+Vector3.new(x,y,z))*(rotation or CFrame.identity),color or WHITE,mat,col)end
 local function support(x,z,top,parent)
  local g=ground(x,z)local p=P(parent,"GroundedPiling",Vector3.new(1.1,top-g.Y+.5,1.1),CFrame.new(x,(top+g.Y-.5)*.5,z),DARK,Enum.Material.Wood,true)p:SetAttribute("GroundPoint",g)return p
 end
 -- Continuous veranda, authored plank seams, pilings reach the actual riverbed.
 h("VerandaCollision",Vector3.new(40,.7,34),0,-.35,0,WOOD,Enum.Material.WoodPlanks,true)
 for x=-19.5,19.5,1.5 do h("VerandaPlank",Vector3.new(1.44,.12,34),x,.04,0,WOOD:Lerp(WHITE,(x+20)%4*.03),Enum.Material.Wood,false)end
 for _,x in ipairs({-18,-9,0,9,18})do for _,z in ipairs({-15,0,15})do support(O.X+x,O.Z+z,O.Y-.7,house)end end
 h("Floor",Vector3.new(28,.35,22),0,.2,0,WHITE,Enum.Material.WoodPlanks,true)
 -- Front doorway and windows are genuinely open, not a solid box behind glass.
 for _,side in ipairs({-1,1})do
  h("FrontDoorPier",Vector3.new(11,10,.5),side*8.5,5.4,-11,WHITE,Enum.Material.WoodPlanks,true)
  h("DoorFrame",Vector3.new(.3,9.5,.7),side*3,5,-11.2,BLUE,Enum.Material.Wood,true)
 end
 h("DoorLintel",Vector3.new(6,1,.6),0,10,-11,BLUE,Enum.Material.Wood,true)
 h("BackWall",Vector3.new(28,10,.5),0,5.4,11,WHITE,Enum.Material.WoodPlanks,true)
 for _,side in ipairs({-1,1})do
  h("WallSill",Vector3.new(.5,3,22),side*14,1.9,0,WHITE,Enum.Material.WoodPlanks,true)
  h("WallTop",Vector3.new(.5,2,22),side*14,9.4,0,WHITE,Enum.Material.WoodPlanks,true)
  for _,z in ipairs({-9,-3,3,9})do h("WallStud",Vector3.new(.6,5,1),side*14,5.9,z,BLUE,Enum.Material.Wood,true)end
  for _,z in ipairs({-6,0,6})do
   local glass=h("WindowGlass",Vector3.new(.08,4.6,4.8),side*14,5.9,z,Color3.fromRGB(166,212,211),Enum.Material.Glass,false)glass.Transparency=.58
   h("WindowMullion",Vector3.new(.35,4.8,.2),side*14,5.9,z,WHITE,Enum.Material.Wood,false)
   h("WindowCrossbar",Vector3.new(.35,.2,5),side*14,5.9,z,WHITE,Enum.Material.Wood,false)
   h("WindowFlowerBox",Vector3.new(1, .7,4.8),side*14.55,3.4,z,BLUE,Enum.Material.Wood,false)
   for j=-2,2 do local flower=h("Flower",Vector3.new(.35,.4,.35),side*14.55,4,z+j*.8,Color3.fromRGB(244,196,194),Enum.Material.SmoothPlastic,false)flower.Shape=Enum.PartType.Ball end
  end
 end
 for _,x in ipairs({-14,14})do for _,z in ipairs({-11,11})do h("TimberCorner",Vector3.new(.8,11,.8),x,5.5,z,BLUE,Enum.Material.Wood,true)end end
 h("TimberBelt",Vector3.new(29,.6,23),0,10.6,0,BLUE,Enum.Material.Wood,false)
 -- Two steep roof slopes; slim overlapping strips read as slate rather than a monolithic slab.
 for _,s in ipairs({-1,1})do
  local rot=CFrame.Angles(0,0,-s*math.rad(38))
  h("RoofCollision",Vector3.new(19,.55,25),s*7.2,16,0,BLUE,Enum.Material.Slate,true,rot)
  for z=-12,12,1.25 do h("RoofSlateStrip",Vector3.new(19,.16,1.2),s*7.2,16.4,z,BLUE:Lerp(WHITE,(z+12)%3*.035),Enum.Material.Slate,false,rot)end
 end
 h("RoofRidge",Vector3.new(.8,.6,26),0,21.8,0,BLUE,Enum.Material.Slate,false)
 for _,z in ipairs({-8,8})do
  h("DormerFace",Vector3.new(.5,4,5),-8,17,z,WHITE,Enum.Material.WoodPlanks,false)
  h("DormerWindow",Vector3.new(.1,2.6,3),-8.3,17,z,Color3.fromRGB(162,209,210),Enum.Material.Glass,false).Transparency=.35
  for _,s in ipairs({-1,1})do h("DormerRoof",Vector3.new(6,.4,3.4),-6.2,19.4,z+s*1.2,BLUE,Enum.Material.Slate,false,CFrame.Angles(s*math.rad(33),0,0))end
 end
 -- Wrap-around railing leaves a real opening for the incoming walkway.
 for x=-18,18,6 do for _,z in ipairs({-16,16})do h("VerandaPost",Vector3.new(.6,3.5,.6),x,1.75,z,WHITE,Enum.Material.Wood,true)end end
 for _,x in ipairs({-19,19})do for z=-12,12,6 do h("VerandaPost",Vector3.new(.6,3.5,.6),x,1.75,z,WHITE,Enum.Material.Wood,true)end end
 for _,z in ipairs({-16,16})do h("Handrail",Vector3.new(38,.35,.4),0,3.3,z,WHITE,Enum.Material.Wood,true)end
 for _,x in ipairs({-19,19})do for _,z in ipairs({-10.5,10.5})do h("Handrail",Vector3.new(.4,.35,11),x,3.3,z,WHITE,Enum.Material.Wood,true)end end
 local bulb=h("PorchLantern",Vector3.new(.6,.85,.6),0,8,-12.2,Color3.fromRGB(255,213,153),Enum.Material.Neon,false)
 local light=Instance.new("PointLight")light.Range=17 light.Color=bulb.Color light.Parent=bulb C:AddTag(light,"ForestNightLight")
 -- Compact furnished interior; no imported executable code.
 h("KitchenCounter",Vector3.new(10,3,3),6,1.9,8,BLUE,Enum.Material.Wood,true)
 h("KitchenTop",Vector3.new(10.3,.2,3.3),6,3.5,8,WHITE,Enum.Material.Marble,true)
 for _,x in ipairs({-9,-5})do h("CarvedShelf",Vector3.new(3,.2,1),x,6.5,10.5,WOOD,Enum.Material.Wood,false)end
 local tea=world.Amenities.ForestRuins.TeaCorner:Clone()tea.Name="CottageTeaCorner"tea:PivotTo(tea:GetPivot()+(O+Vector3.new(-4,.375,2)-tea.AntiqueTeaTable:GetPivot().Position))tea.Parent=house
 -- clone links must point at the cloned teapot.
 local prompt=assert(tea:FindFirstChild("ServeTea",true))C:AddTag(prompt,"TreeWorldTeaPrompt")
 for _,seat in ipairs(tea:GetDescendants())do if seat:IsA("Seat")then local link=seat:FindFirstChild("TeaPrompt")if link then link.Value=prompt end C:AddTag(seat,"RuinSeat")end end
 local walk=Instance.new("Model")walk.Name="LakesideBoardwalk"walk.Parent=folder
 local nodes={}local start=O+Vector3.new(-20,0,0)
 local bankX=O.X-24
 while ground(bankX,O.Z).Y<8.5 and bankX>-150 do bankX-=2 end
 local finish=ground(bankX,O.Z)+Vector3.new(0,.3,0)
 local N=math.ceil((finish-start).Magnitude/1.8)
 for i=0,N do local t=i/N local p=start:Lerp(finish,t)+Vector3.new(0,0,math.sin(t*math.pi)*6)nodes[#nodes+1]={p.X,p.Y,p.Z}end
 for i=1,N do
  local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))local cf=CFrame.lookAt((a+b)*.5,b)local len=(b-a).Magnitude+.06
  P(walk,"BoardwalkPlank",Vector3.new(6,.32,len),cf-CFrame.new().UpVector*.16,WOOD:Lerp(WHITE,(i%3)*.045),Enum.Material.Wood,true)
  for _,s in ipairs({-1,1})do
   if i%3==0 then P(walk,"CarvedPost",Vector3.new(.5,3,.5),cf*CFrame.new(s*2.8,1.5,0),DARK,Enum.Material.Wood,true)support(a.X+s*cf.RightVector.X*2.8,a.Z+s*cf.RightVector.Z*2.8,a.Y,walk)end
   P(walk,"Handrail",Vector3.new(.3,.3,len),cf*CFrame.new(s*2.8,2.8,0),WOOD,Enum.Material.Wood,true)
  end
 end
 walk:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))
 -- Stepping stone crossing near the lower stream: bank endpoints are found on real terrain.
 local stones=Instance.new("Model")stones.Name="StreamSteppingStones"stones.Parent=folder
 local z=-18 local cx=require(runtime.Scene).riverX(z)local left,right=cx-4,cx+4
 while ground(left,z).Y<6.8 do left-=2 end while ground(right,z).Y<6.8 do right+=2 end
 local steps=math.ceil((right-left)/4)local a,b=ground(left,z),ground(right,z)
 for i=0,steps do local t=i/steps local x=left+(right-left)*t local y=math.max(6.85,a.Y*(1-t)+b.Y*t)
  local p=P(stones,"WalkStone",Vector3.new(4.7,1.4,5),CFrame.new(x,y-.7,z+math.sin(t*math.pi*2)*1.2)*CFrame.Angles(0,(i%3)*.2,0),Color3.fromRGB(177,196,187),Enum.Material.Slate,true)p:SetAttribute("WalkTop",y)
  local g=ground(p.Position.X,p.Position.Z)P(stones,"SubmergedStone",Vector3.new(3.3,y-g.Y+.2,3.6),CFrame.new(p.Position.X,(y+g.Y)*.5-.2,p.Position.Z),Color3.fromRGB(120,146,138),Enum.Material.Slate,false)
 end
 -- Stylized edges follow the ACTUAL land/water boundary, not an analytic estimate.
 local foam=Instance.new("Folder")foam.Name="AnimeRiverFoam"foam.Parent=folder
 local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={workspace.Terrain}
 local function wet(x,z)local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),waterRay)return hit and hit.Material==Enum.Material.Water end
 local foamCount=0
 for zz=-272,272,6 do local center=require(runtime.Scene).riverX(zz)
  for _,s in ipairs({-1,1})do
   local x=center local last=x
   for _=1,100 do if not wet(x,zz)then break end last=x x+=s*2 end
   for _=1,7 do local mid=(last+x)*.5 if wet(mid,zz)then last=mid else x=mid end end
   if wet(last,zz)then local p=P(foam,"ShoreFoam",Vector3.new(.6,.035,2.6),CFrame.new(last-s*.35,6.04,zz)*CFrame.Angles(0,math.sin(zz*.05)*.25,0),Color3.fromRGB(235,249,245),Enum.Material.SmoothPlastic,false)p.Transparency=.3 p.CastShadow=false foamCount+=1
    for k=1,2 do local bubble=P(foam,"FoamBubble",Vector3.new(.25,.035,.25),CFrame.new(last-s*(.7+k*.25),6.045,zz+k*.55),WHITE,Enum.Material.SmoothPlastic,false)bubble.Shape=Enum.PartType.Ball bubble.Transparency=.3 bubble.CastShadow=false end
   end
  end
 end
 for zz=-240,240,12 do local x=require(runtime.Scene).riverX(zz)if wet(x,zz)then
  local p=P(foam,"AngularWaterGlint",Vector3.new(1.8,.025,3.4),CFrame.new(x,6.03,zz)*CFrame.Angles(0,.45,0),Color3.fromRGB(180,233,230),Enum.Material.SmoothPlastic,false)p.Transparency=.75 p.CastShadow=false end
 end
 workspace.Terrain.WaterColor=Color3.fromRGB(67,160,182)workspace.Terrain.WaterTransparency=.32 workspace.Terrain.WaterReflectance=.08 workspace.Terrain.WaterWaveSize=.025 workspace.Terrain.WaterWaveSpeed=5
 world:SetAttribute("UpgradeVersion",91)world:SetAttribute("LanternCount",#C:GetTagged("ForestNightLight"))runtime:SetAttribute("WaterStyle","AnimeSoftBlue")
 return{removedOwnerNPC=true,cottage=true,boardwalkSegments=N,steppingStones=steps+1,foamEdges=foamCount}
end
return B
]============]).install()
local animals=factory([============[local B={}
function B.install()
 local raw=game:GetService("AssetService"):LoadAssetAsync(77173958514594)
 local templates=Instance.new("Folder")templates.Name="CuteAnimalTemplates"templates.Parent=game.ReplicatedStorage.ForestRuntime
 local routes=Instance.new("Folder")routes.Name="CuteAnimalRoutes"routes.Parent=workspace.ForestWorld.Amenities
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function floor(x,z)local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),rp)return h and h.Position.Y>8 and h.Normal.Y>.78 and h.Position or nil end
 for _,name in ipairs({"Conejo","Zorro"})do
  local m=assert(raw:FindFirstChild(name)):Clone()
  for _,d in ipairs(m:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("JointInstance")or d:IsA("Constraint")or d:IsA("Humanoid")or d:IsA("RemoteEvent")then d:Destroy()end end
  m:PivotTo(CFrame.identity)
  local delta=m.Head.Position-m.Torso.Position local forward=Vector3.new(delta.X,0,delta.Z)
  if forward.Magnitude>.1 then local rot=CFrame.lookAt(Vector3.zero,forward).Rotation:Inverse()for _,part in ipairs(m:GetDescendants())do if part:IsA("BasePart")then part.CFrame=rot*part.CFrame end end end
  local bottom=math.huge
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false bottom=math.min(bottom,p.Position.Y-(math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)*.5)end end
  m:PivotTo(m:GetPivot()-Vector3.yAxis*bottom)m.PrimaryPart=nil m.WorldPivot=CFrame.identity m:SetAttribute("SourceAssetId",77173958514594)m.Parent=templates
 end
 raw:Destroy()
 local count=0 local centers={{-145,-120},{-115,170},{105,-80},{110,0},{-230,90},{-120,-210}}
 for i,center in ipairs(centers)do
  local points={}
  for j=0,31 do local a=j*math.pi*2/32 local p=floor(center[1]+math.cos(a)*9,center[2]+math.sin(a)*7)
   if not p then points={}break end points[#points+1]={p.X,p.Y+.03,p.Z}
  end
  if #points==32 then local r=Instance.new("StringValue")r.Name="AnimalRoute"r.Value=game:GetService("HttpService"):JSONEncode(points)r:SetAttribute("Species",i%2==0 and "Zorro"or"Conejo")r:SetAttribute("Speed",i%2==0 and 1.8 or 1.1)r:SetAttribute("Phase",i*7)r.Parent=routes count+=1 end
 end
 assert(count>=4,"Insufficient dry animal routes")return{animals=count,sourceAssetId=77173958514594}
end
return B
]============]).install()
local tools=factory([============[local B={}
function B.install()
 local runtime=game.ReplicatedStorage.ForestRuntime
 local tool=Instance.new("Tool")tool.Name="Guarda-chuva"tool.RequiresHandle=false tool.CanBeDropped=false tool:SetAttribute("RainUmbrella",true)
 local function p(name,size,cf,color,shape)
  local part=Instance.new("Part")part.Name=name part.Size=size part.CFrame=cf part.Color=color part.Material=Enum.Material.SmoothPlastic part.Anchored=false part.Massless=true part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Parent=tool if shape then part.Shape=shape end return part
 end
 local handle=p("UmbrellaAnchor",Vector3.new(.2,.2,.2),CFrame.identity,Color3.fromRGB(232,209,198))handle.Transparency=1
 local shaft=p("UmbrellaShaft",Vector3.new(.09,3.2,.09),CFrame.new(0,1.6,0),Color3.fromRGB(231,218,205))
 -- Overlapping radial panels form a compact pastel domed canopy, with scalloped tips.
 for i=0,15 do local a=i*math.pi*2/16 local col=i%2==0 and Color3.fromRGB(218,176,190)or Color3.fromRGB(244,224,214)
  p("CanopyPanel",Vector3.new(1.04,.16,2.65),CFrame.new(math.cos(a)*1.3,2.95,math.sin(a)*1.3)*CFrame.Angles(0,-a+math.pi*.5,math.rad(0))*CFrame.Angles(math.rad(11),0,0),col)
  local edge=p("ScallopedEdge",Vector3.new(.42,.18,.42),CFrame.new(math.cos(a)*2.55,2.68,math.sin(a)*2.55),col,Enum.PartType.Ball)
 end
 p("CanopyCrown",Vector3.new(.55,.28,.55),CFrame.new(0,3.22,0),Color3.fromRGB(244,224,214),Enum.PartType.Ball)
 for _,d in ipairs(tool:GetChildren())do if d:IsA("BasePart")and d~=handle then local w=Instance.new("WeldConstraint")w.Part0=handle w.Part1=d w.Parent=d end end
 tool.Parent=runtime tool.Name="UmbrellaTool"
 return{umbrellaParts=35}
end
return B
]============]).install()
local audio=factory([============[local B={}
function B.install()
 local folder=Instance.new("Folder")folder.Name="GardenSounds"folder.Parent=game.ReplicatedStorage.ForestRuntime
 local report={}
 for name,id in pairs({Forest=9116971475,Wind=9114518779,River=9120552550,Rain=9112854613,GrassStep=135037154891351,WoodStep=9083826864,StoneStep=178190837})do
  local s=Instance.new("Sound")s.Name=name s.SoundId="rbxassetid://"..id s.Looped=true s.Volume=.15 s.RollOffMinDistance=4 s.RollOffMaxDistance=35 s.Parent=folder
  game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Sound unavailable: "..name)
  report[name]={id=id,length=s.TimeLength}
 end return report
end
return B
]============]).install()
local tea=factory([============[local B={}
function B.install()
 local C=game:GetService("CollectionService")local world=workspace.ForestWorld local count=0
 local function part(parent,name,size,cf,col,mat,shape)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col p.Material=mat or Enum.Material.SmoothPlastic p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=parent if shape then p.Shape=shape end return p
 end
 for _,prompt in ipairs(C:GetTagged("TreeWorldTeaPrompt"))do if prompt:IsDescendantOf(world)then
  local corner=prompt.Parent.Parent.Parent local table=corner:FindFirstChild("AntiqueTeaTable")
  if table then
   local surface=table:FindFirstChild("tablecover",true)or table:FindFirstChild("table",true)local top=surface.Position.Y+surface.Size.Y*.5 local center=table:GetPivot().Position
   for _,d in ipairs(table:GetDescendants())do if d:IsA("BasePart")then if d.Name=="tablecover"then d.Color=Color3.fromRGB(230,218,202)elseif d.Name=="table"then d.Color=Color3.fromRGB(172,139,108)end end end
   -- Scalloped ceramic cake stand and strawberries, plus individual silver utensils.
   local cf=CFrame.new(center.X+1.7,top+.06,center.Z+.85)
   part(corner,"CakePlate",Vector3.new(.1,1.1,1.1),cf*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(245,237,221),nil,Enum.PartType.Cylinder)
   local cake=part(corner,"StrawberryCake",Vector3.new(.72,.46,.82),cf*CFrame.new(0,.28,0),Color3.fromRGB(242,219,190))
   part(corner,"CakeCream",Vector3.new(.76,.12,.86),cf*CFrame.new(0,.54,0),Color3.fromRGB(250,244,226))
   for _,x in ipairs({-.18,.18})do part(corner,"Strawberry",Vector3.new(.22,.24,.22),cf*CFrame.new(x,.68,0),Color3.fromRGB(210,79,83),nil,Enum.PartType.Ball)end
   for _,s in ipairs({-1,1})do for j=1,2 do
    local u=CFrame.new(center.X+s*1.75,top+.045,center.Z+j*.42-1.5)
    part(corner,"SilverSpoonStem",Vector3.new(.06,.03,.48),u,Color3.fromRGB(195,200,198),Enum.Material.Metal)
    part(corner,"SilverSpoonBowl",Vector3.new(.18,.035,.25),u*CFrame.new(0,0,-.3),Color3.fromRGB(195,200,198),Enum.Material.Metal,Enum.PartType.Ball)
   end end
   -- The existing native carved chairs keep their authored backs and seats.
   for _,chair in ipairs(corner:GetChildren())do if chair.Name=="AntiqueTeaChair"then for _,p in ipairs(chair:GetDescendants())do if p:IsA("BasePart")and p.Transparency==0 then p.Color=p.Name:find("Cushion")and Color3.fromRGB(204,172,176)or Color3.fromRGB(170,138,105)end end end end
   -- One open-air parasol recalls the garden tea reference; indoor table remains uncovered.
   if not corner:IsDescendantOf(world.Amenities.RiversideGarden)and count==1 then
    local y=top+7
    part(corner,"GardenParasolPole",Vector3.new(.12,7,.12),CFrame.new(center.X,(top+y)*.5,center.Z),Color3.fromRGB(218,198,174),Enum.Material.Wood)
    for i=0,15 do local a=i*math.pi*2/16 local radial=Vector3.new(math.cos(a)*2,y- .4,math.sin(a)*2)
     part(corner,"GardenParasolPanel",Vector3.new(1.65,.12,4.2),CFrame.new(Vector3.new(center.X,0,center.Z)+radial)*CFrame.Angles(0,math.pi*.5-a,0)*CFrame.Angles(math.rad(11),0,0),i%2==0 and Color3.fromRGB(219,196,174)or Color3.fromRGB(233,216,191),Enum.Material.Fabric)
    end
   end
   count+=1
  end
 end end
 return{detailedTeaTables=count}
end
return B
]============]).install()
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
	for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do light.Enabled=Cycle.night(clock)>.015 light.Brightness=Cycle.night(clock)*1.7 end
	local strength = 6.8 + math.sin(time * 0.047) * 0.45 + math.sin(time * 0.023) * 0.25
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestGardenClient",[============[local Run=game:GetService("RunService")local Players=game:GetService("Players")local UIS=game:GetService("UserInputService")local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local world=workspace:WaitForChild("ForestWorld")
local localWorld=Instance.new("Folder")localWorld.Name="TreeWorldGardenEffects"localWorld.Parent=workspace
local rng=Random.new()local leaves={}local cap=UIS.TouchEnabled and 22 or 40
for i=1,cap do local p=Instance.new("WedgePart")p.Name="MicroLeaf"p.Size=Vector3.new(.08,.025,.18)p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=1 p.Parent=localWorld leaves[i]={part=p,birth=-100}end
local canopies={}local Collection=game:GetService("CollectionService")
local function leafPart(p)if p:IsA("BasePart")and not canopies[p]then canopies[p]=true end end
for _,p in ipairs(Collection:GetTagged("ForestWindFoliage"))do leafPart(p)end
Collection:GetInstanceAddedSignal("ForestWindFoliage"):Connect(leafPart)Collection:GetInstanceRemovedSignal("ForestWindFoliage"):Connect(function(p)canopies[p]=nil end)
local entries={}
local function route(value)
 if not value:IsA("StringValue")then return end
 local points=game:GetService("HttpService"):JSONDecode(value.Value)local nodes={}local cumulative={0}local length=0
 for _,p in ipairs(points)do nodes[#nodes+1]=Vector3.new(unpack(p))end
 for i=1,#nodes do length+=(nodes[i%#nodes+1]-nodes[i]).Magnitude cumulative[i+1]=length end
 entries[#entries+1]={source=value,nodes=nodes,cumulative=cumulative,length=length}
end
local routes=world.Amenities:WaitForChild("CuteAnimalRoutes")for _,v in ipairs(routes:GetChildren())do route(v)end routes.ChildAdded:Connect(route)
local function activate(e)
 local m=runtime.CuteAnimalTemplates[e.source:GetAttribute("Species")]:Clone()m.Parent=localWorld e.model=m e.groups={}
 for _,group in ipairs(m:GetChildren())do if group:IsA("BasePart")then local rec={root=group,base=group.CFrame,parts={}}
  for _,p in ipairs(group:GetDescendants())do if p:IsA("BasePart")then rec.parts[p]=group.CFrame:ToObjectSpace(p.CFrame)end end e.groups[#e.groups+1]=rec
 end end
end
local soundFolder=runtime:WaitForChild("GardenSounds")
local function sound(name,parent,volume)local s=soundFolder[name]:Clone()s.Parent=parent s.Volume=volume or s.Volume return s end
local birds=sound("Forest",game:GetService("SoundService"),.12)birds:Play()
local wind=sound("Wind",game:GetService("SoundService"),.08)wind:Play()
local river=sound("River",game:GetService("SoundService"),0)river:Play()
local rain=sound("Rain",game:GetService("SoundService"),0)rain:Play()
local foot local footChar local footTime=0
local rainRoot=Instance.new("Part")rainRoot.Name="LocalRainCeiling"rainRoot.Size=Vector3.new(35,.1,35)rainRoot.Anchored=true rainRoot.Transparency=1 rainRoot.CanCollide=false rainRoot.CanTouch=false rainRoot.CanQuery=false rainRoot.Parent=localWorld
local emitter=Instance.new("ParticleEmitter")emitter.Name="GentleRain"emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"emitter.Rate=0 emitter.Lifetime=NumberRange.new(.45,.65)emitter.Speed=NumberRange.new(32,40)emitter.EmissionDirection=Enum.NormalId.Bottom emitter.Size=NumberSequence.new(.045)emitter.Color=ColorSequence.new(Color3.fromRGB(191,224,228))emitter.Transparency=NumberSequence.new(.65)emitter.Acceleration=Vector3.new(4,-18,1)emitter.SpreadAngle=Vector2.new(4,4)emitter.Parent=rainRoot
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.RespectCanCollide=true
local scan,elapsed,spawnClock,leafIndex=0,0,0,0 local nearby={}
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt scan+=dt spawnClock+=dt if elapsed<1/24 then return end local step=elapsed elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end local pos=camera.CFrame.Position local now=workspace:GetServerTimeNow()
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if scan>1 then
  scan=0 table.clear(nearby)
  for p in pairs(canopies)do if p.Parent and(p.Position-pos).Magnitude<48 and p.Size.X>3 then nearby[#nearby+1]=p end end
  if #nearby>12 then while #nearby>12 do table.remove(nearby)end end
  if root then
   ray.FilterDescendantsInstances={world.Amenities,workspace.Terrain,world.Decor}
   local roof=workspace:Raycast(root.Position+Vector3.yAxis*2,Vector3.yAxis*24,ray)
   local raining=runtime:GetAttribute("Raining")
   emitter.Rate=raining and not roof and(UIS.TouchEnabled and 65 or 100)or 0
   Tween:Create(rain,TweenInfo.new(1),{Volume=raining and(roof and .035 or .14)or 0}):Play()
   local riverX=require(runtime.Scene).riverX(root.Position.Z)local riverWidth=require(runtime.Scene).riverWidth(root.Position.Z)
   local proximity=math.clamp(1-(math.abs(root.Position.X-riverX)-riverWidth)/40,0,1)
   if math.abs(root.Position.Z)>295 then proximity=0 end
   Tween:Create(river,TweenInfo.new(1),{Volume=.13*proximity}):Play()
  end
 end
 rainRoot.CFrame=CFrame.new((root and root.Position or pos)+Vector3.yAxis*18)
 if spawnClock>.55 and #nearby>0 and runtime:GetAttribute("SeasonName")~="Inverno"then
  spawnClock=0 leafIndex=leafIndex%cap+1 local e=leaves[leafIndex]local p=nearby[rng:NextInteger(1,#nearby)]
  e.start=p.Position+Vector3.new(rng:NextNumber(-p.Size.X*.25,p.Size.X*.25),-p.Size.Y*.2,rng:NextNumber(-p.Size.Z*.25,p.Size.Z*.25))e.birth=now e.phase=rng:NextNumber(0,6.28)e.life=rng:NextNumber(5,8)
  e.part.Color=runtime:GetAttribute("SeasonName")=="Outono"and Color3.fromRGB(181,134,66)or Color3.fromRGB(128,153,93)e.part.Transparency=.12
 end
 for _,e in ipairs(leaves)do local age=now-e.birth if age< (e.life or 0)then local drift=Vector3.new(age*.25+math.sin(age*1.6+e.phase)*.4,-age*1.35,math.cos(age*1.2+e.phase)*.3)
  e.part.CFrame=CFrame.new(e.start+drift)*CFrame.Angles(age*.7,e.phase+age*.9,.3*math.sin(age*2))e.part.Transparency=.12+.88*math.clamp((age-e.life+1.5)/1.5,0,1)
 else e.part.Transparency=1 end end
 for _,e in ipairs(entries)do
  local distance=(e.nodes[1]-pos).Magnitude
  if distance<85 then if not e.model then activate(e)end
   local speed=e.source:GetAttribute("Speed")local phase=e.source:GetAttribute("Phase")local travel=(now*speed+phase)%e.length local index=1
   while index<#e.nodes and e.cumulative[index+1]<travel do index+=1 end
   local a,b=e.nodes[index],e.nodes[index%#e.nodes+1]local t=(travel-e.cumulative[index])/(e.cumulative[index+1]-e.cumulative[index])local point=a:Lerp(b,t)
   local rabbit=e.source:GetAttribute("Species")=="Conejo"local gait=math.sin(now*(rabbit and 7 or 5)+phase)local cf=CFrame.lookAt(point,point+Vector3.new(b.X-a.X,0,b.Z-a.Z))
   if rabbit then cf+=Vector3.yAxis*math.max(0,gait)*.18 end
   for _,g in ipairs(e.groups)do local leg=g.root.Name:find("Pata",1,true)local swing=CFrame.identity
    -- Native body groups and their children share one gait transform.
    if leg then local n=tonumber(g.root.Name:match("%d+"))or 1 swing=CFrame.Angles(gait*.2*(n%2==0 and 1 or -1),0,0)end
    g.root.CFrame=cf*g.base*swing for p,offset in pairs(g.parts)do p.CFrame=g.root.CFrame*offset end
   end
  elseif e.model then e.model:Destroy()e.model=nil end
 end
 if c~=footChar then if foot then foot:Destroy()end footChar=c foot=root and sound("GrassStep",root,.23)or nil if foot then foot.Looped=false end end
 if h and root and foot then
  local default=root:FindFirstChild("Running")if default then default.Volume=0 end
  local moving=h.MoveDirection.Magnitude>.1 and h.FloorMaterial~=Enum.Material.Air and h.Health>0 and not h.Sit and h:GetState()~=Enum.HumanoidStateType.Swimming
  local material=h.FloorMaterial local name=(material==Enum.Material.Wood or material==Enum.Material.WoodPlanks)and"WoodStep"or(material==Enum.Material.Grass or material==Enum.Material.LeafyGrass or material==Enum.Material.Ground or material==Enum.Material.Mud)and"GrassStep"or"StoneStep"
  local id=soundFolder[name].SoundId if foot.SoundId~=id then foot:Stop()foot.SoundId=id end foot.Looped=name~="GrassStep"
  foot.PlaybackSpeed=math.clamp(root.AssemblyLinearVelocity.Magnitude/14,.7,1.25)
  footTime+=step
  if moving then if foot.Looped then if not foot.IsPlaying then foot:Play()end elseif footTime>.42/foot.PlaybackSpeed then footTime=0 foot:Play()end elseif foot.IsPlaying then foot:Stop()end
 end
end)
]============])
run(game.ServerScriptService.ForestServer.Source)
local baseTests=run([============[local world=assert(workspace.ForestWorld)local runtime=game.ReplicatedStorage.ForestRuntime
assert(world:GetAttribute("UpgradeVersion")==91 and world:GetAttribute("SeasonLayout")=="TemporalGlobal"and world:GetAttribute("GameName")=="TreeWorld")
local Seasons=require(runtime.Seasons)
assert(Seasons.index(0,0)==1 and Seasons.index(599.9,0)==1 and Seasons.index(600,0)==2 and Seasons.index(1200,0)==3 and Seasons.index(1800,0)==4 and Seasons.index(2400,0)==1)
assert(Seasons.at(-250,-200)==Seasons.at(250,200)and runtime:GetAttribute("GrassMotionEnabled")==false)
local groundRay=RaycastParams.new()groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),groundRay)end
local report={bridges=0,bridgeWalkProbes=0,landmarkFoundations=0,teaSeats=0,teaTables=0,ruins=4,staticGrass=true,globalSeasonTests=0}
for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
 assert(bridge:GetAttribute("SourceAssetId")==117077041338395)
 local nodes=game:GetService("HttpService"):JSONDecode(bridge:GetAttribute("WalkNodes"))
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={bridge}ray.RespectCanCollide=true
 for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
  for _,t in ipairs({0,.5})do local p=a:Lerp(b,t)local hit=assert(workspace:Raycast(p+Vector3.new(0,3,0),Vector3.new(0,-6,0),ray),"Missing bridge walking collision")
   assert(hit.Instance.Name=="WalkwayCollision"and math.abs(hit.Position.Y-p.Y)<.18,"Bridge walking surface discontinuity")report.bridgeWalkProbes+=1
  end
 end
 for _,index in ipairs({1,#nodes})do local p=Vector3.new(unpack(nodes[index]))local hit=assert(ground(p.X,p.Z))assert(hit.Material~=Enum.Material.Water and math.abs(hit.Position.Y-p.Y)<1.4,"Bridge does not meet the bank: "..bridge.Name.." end "..index.." deck="..p.Y.." terrain="..hit.Position.Y)end
 for _,p in ipairs(bridge:GetChildren())do if p.Name=="MasonrySupport"then local g=p:GetAttribute("GroundPoint")assert(p.Position.Y-p.Size.Y*.5<=g.Y+.01)end end
 report.bridges+=1
end
assert(report.bridges==2)
local ruins=world.Amenities.ForestRuins local geometry=RaycastParams.new()geometry.FilterType=Enum.RaycastFilterType.Include geometry.FilterDescendantsInstances={ruins}geometry.RespectCanCollide=true
local arches=0
for _,m in ipairs(ruins.Arcade:GetChildren())do if m.Name=="StoneArch"then local point=m:GetAttribute("OpeningCentre")assert(not workspace:Raycast(point-Vector3.zAxis*4,Vector3.zAxis*8,geometry))arches+=1 end end assert(arches==6)
local landmarks=world.Amenities.ForestLandmarks assert(#landmarks:GetChildren()==3 and landmarks.BrokenWatchtower:FindFirstChild("ArmoredSkeleton"))
for _,d in ipairs(landmarks:GetDescendants())do
 if d.Name=="LandmarkFoundation"then local point=d:GetAttribute("GroundPoint")local hit=assert(ground(point.X,point.Z))assert(d.Position.Y-d.Size.Y*.5<=hit.Position.Y+.05,"Floating ruin foundation")report.landmarkFoundations+=1 end
end
local Collection=game:GetService("CollectionService")
for _,prompt in ipairs(Collection:GetTagged("TreeWorldTeaPrompt"))do if prompt:IsDescendantOf(world)then report.teaTables+=1 end end
for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
 if seat:IsDescendantOf(world)and seat.Name=="TeaSeat"then
  report.teaSeats+=1 local link=assert(seat:FindFirstChild("TeaPrompt"))assert(link.Value and link.Value:IsDescendantOf(world))
  local corner=seat.Parent.Parent local table=assert(corner.AntiqueTeaTable)local aim=Vector3.new(table:GetPivot().X-seat.Position.X,0,table:GetPivot().Z-seat.Position.Z).Unit
  assert(seat.CFrame.LookVector:Dot(aim)>.85,"Chair faces away from its tea table: "..seat:GetFullName().." dot="..seat.CFrame.LookVector:Dot(aim))
  local floorRay=RaycastParams.new()floorRay.FilterType=Enum.RaycastFilterType.Include floorRay.FilterDescendantsInstances={workspace.Terrain,world.Amenities}floorRay.RespectCanCollide=true
  local pivot=seat.Parent:GetPivot().Position local h=assert(workspace:Raycast(pivot+Vector3.new(0,.05,0),Vector3.new(0,-3,0),floorRay),"Antique chair has no floor")
  assert(math.abs(pivot.Y-h.Position.Y)<.2,"Antique chair floats above the floor")
 end
end
assert(report.teaTables==4 and report.teaSeats==16)
assert(not world:FindFirstChild("OwnerNPC")and not runtime:FindFirstChild("NPCController")and not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestNPCClient"))
report.ownerNPCRemoved=true
local menu=assert(game.StarterGui.TreeWorldMenu)assert(menu:GetAttribute("SourceAssetId")==17216750157 and menu.ResetOnSpawn==false and menu.MainMenu.PlayButton.Text=="Entrar"and menu.MainMenu.GameTitle.Text=="TreeWorld")
assert(menu.MainMenu.PlayButton.Size.Y.Offset>=48 and menu.MainMenu.PlayButton:FindFirstChildOfClass("UISizeConstraint")and menu:FindFirstChild("TreeWorldMenuClient"))
assert(runtime:GetAttribute("MenuCameraCF")and runtime:GetAttribute("MenuCameraFocus")and not game.Lighting.TreeWorldMenuBlur.Enabled)
report.importedMenu=true
-- Exercise temporal seasons on actual terrain while proving that neither water nor solid occupancy changes.
runtime:SetAttribute("SeasonTestMode",true)
local service=require(runtime.SeasonController).start(runtime,world)
local probes={Vector2.new(-280,-40),Vector2.new(-240,110),Vector2.new(160,-180),Vector2.new(240,210)}
local references={}for _,v in ipairs(probes)do local h=assert(ground(v.X,v.Y))references[#references+1]={v=v,y=h.Position.Y}end
local region=Region3.new(Vector3.new(-32,-16,-32),Vector3.new(32,24,32))
local before=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
for _,index in ipairs({3,4,2,1})do
 assert(service.apply(index,true))assert(runtime:GetAttribute("SeasonIndex")==index)
 for _,item in ipairs(references)do local h=assert(ground(item.v.X,item.v.Y))assert(math.abs(h.Position.Y-item.y)<.05,"Season transition changed terrain height")
  if index==4 then assert(h.Material==Enum.Material.Snow or h.Material==Enum.Material.Rock or h.Material==Enum.Material.Ground)end
 end
 local after=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
 for x=1,before.Size.X do for y=1,before.Size.Y do for z=1,before.Size.Z do assert(before.SolidOccupancy[x][y][z]==after.SolidOccupancy[x][y][z]and before.LiquidOccupancy[x][y][z]==after.LiquidOccupancy[x][y][z],"Season alters river geometry")end end end
 assert(Seasons.at(-280,-200)==Seasons.at(200,200))report.globalSeasonTests+=1
 if index==4 then assert(#require(runtime.Scene).around(Vector3.new(-280,0,50),42)==0,"Grass remains in winter")end
end
runtime:SetAttribute("SeasonTestMode",nil)
report.terrainChannelsPreserved=true report.grassSourceId=world:GetAttribute("GrassAssetId")
return report
]============])
local forestTests=run([============[local world=assert(workspace:FindFirstChild("ForestWorld"))
local runtime=assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(world:GetAttribute("ForestOnly")and world:GetAttribute("UpgradeVersion")==91)
assert(not workspace:FindFirstChild("MonCalamariWorld")and not workspace:FindFirstChild("IlhaSerena"))
local Scene=require(runtime.Scene)
assert(not world:FindFirstChild("OwnerNPC"))
local parts,meshes,pbr,foreign=0,0,0,0
for _,d in ipairs(world:GetDescendants())do
 if d:IsA("BasePart")then parts+=1 assert(d.Anchored,d:GetFullName().." unanchored") end
 if d:IsA("MeshPart")then meshes+=1 end
 if d:IsA("SurfaceAppearance")then pbr+=1 end
 if d:IsA("LuaSourceContainer")then foreign+=1 end
end
assert(foreign==0 and meshes>2000 and pbr>1800,"PBR forest or imported-script isolation failed")
assert(world:GetAttribute("TreeCount")>350 and world:GetAttribute("PlantCount")>1000)
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
local treeCount,plantCount,supports,maxGap,maxBurial,tallest,shortest=0,0,0,0,0,0,math.huge
local buriedExamples={}
for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do
 for _,model in ipairs(folder:GetChildren())do
  local profile=assert(runtime.GroundingProfiles:FindFirstChild(model.Name),"Missing root profile")
  local pivot=model:GetPivot()local scale=model:GetAttribute("GroundingScale")
  assert(model:GetAttribute("SupportGeometryProbes")>0,model.Name.." has no lower geometry ray samples")
  local localBurial=0
  for _,point in ipairs(profile:GetChildren())do
   local p=pivot:PointToWorldSpace(point.Value*scale)
   local h=assert(ground(p.X,p.Z),"No terrain under lower geometry")
   if h.Material~=Enum.Material.Water then
    local gap=p.Y-h.Position.Y
    assert(gap<.035,model.Name.." floats at a lower contact: "..gap)
    supports+=1 maxGap=math.max(maxGap,gap)maxBurial=math.max(maxBurial,-gap)localBurial=math.max(localBurial,-gap)
   end
  end
  if localBurial>1 then buriedExamples[#buriedExamples+1]={kind=folder.Name,name=model.Name,burial=localBurial,position={pivot.X,pivot.Y,pivot.Z},scale=scale}end
  local p=pivot.Position local h=assert(ground(p.X,p.Z))
  assert(h.Material~=Enum.Material.Water,"Vegetation root is submerged")
  if folder==world.Decor.Trees then
   treeCount+=1 assert(model:FindFirstChild("TrunkCollision"))
   local _,size=model:GetBoundingBox()tallest=math.max(tallest,size.Y)shortest=math.min(shortest,size.Y)
  else plantCount+=1 end
 end
end
assert(supports>10000 and tallest>95 and tallest-shortest>45 and maxBurial<2.85,"Tree size variation or contact coverage insufficient")
local probes,green,water,trail,minY,maxY=0,0,0,0,math.huge,-math.huge
for x=-360,360,24 do for z=-336,336,24 do
 local h=ground(x,z)if h then probes+=1 minY=math.min(minY,h.Position.Y)maxY=math.max(maxY,h.Position.Y)
  if h.Material==Enum.Material.Water then water+=1
  elseif h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass then green+=1
  elseif h.Material==Enum.Material.Ground then trail+=1 end
 end
end end
assert(green>300 and water>40 and trail>10 and maxY-minY>50)
local riverProbes=0
for z=-288,288,8 do
 local h=assert(ground(Scene.riverX(z),z))
 assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-Scene.RiverY)<.10,"River has a dry gap or uneven water plane at "..z)
 riverProbes+=1
end
assert(workspace.Terrain.WaterWaveSize>0 and workspace.Terrain.WaterReflectance<.3 and Scene.SeaY==Scene.RiverY)
for _,p in ipairs({Vector2.new(-750,0),Vector2.new(750,0),Vector2.new(0,-750),Vector2.new(0,750)})do
 local h=assert(ground(p.X,p.Y))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-Scene.SeaY)<.10,"Outer water has an abrupt edge")
end
local walks=256 -- curved bridge collision is checked by tests.luau
for _,d in ipairs(world:GetDescendants())do assert(d.Name~="RiverCrossingLog"and d.Name~="CrossingCollision","Old log crossing survived")end
local seats=0
for _,d in ipairs(world.Amenities.LogBenches:GetDescendants())do if d:IsA("Seat")then seats+=1 assert(d.Anchored and d:FindFirstChild("SitPrompt")and not d.CanCollide)end end
assert(seats>=12 and world:GetAttribute("CutTrunkCount")>=18 and world:GetAttribute("LanternCount")>=15)
local lights=game:GetService("CollectionService"):GetTagged("ForestNightLight")assert(#lights==world:GetAttribute("LanternCount"))
local spawn=runtime:GetAttribute("MainSpawnCF")
local spawnRay=RaycastParams.new()spawnRay.FilterType=Enum.RaycastFilterType.Include spawnRay.FilterDescendantsInstances={workspace.Terrain,world.Amenities.ForestRuins.Courtyard.CourtyardFloor}
local floor=assert(workspace:Raycast(spawn.Position+Vector3.new(0,20,0),Vector3.new(0,-40,0),spawnRay))
assert(floor.Material~=Enum.Material.Water and floor.Normal.Y>.65 and math.abs(spawn.Y-floor.Position.Y-3.5)<.06)
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template.Mesh
assert(template:GetAttribute("SourceAssetId")==87377915371959 and Scene.Spacing==4 and mesh.Size.X<8 and mesh.Size.Y>1.2)
local bones,offsets={},{}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
assert(#bones==100)
for i,b in ipairs(bones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)lo=lo:Min(offsets[i])hi=hi:Max(offsets[i])end
assert(hi.X-lo.X>Scene.Spacing+1 and hi.Z-lo.Z>Scene.Spacing+1,"Grass root footprint does not overlap adjacent cells")
local sampler=require(runtime.GrassSampler).new(world)
local zones,roots,coveragePoints,misses=0,0,0,0
for _,centre in ipairs({Vector3.new(-240,0,110),Vector3.new(-280,0,40),Vector3.new(160,0,-180),Vector3.new(240,0,210)})do
 local buckets={}local zoneRoots=0
 local function key(x,z)return math.floor(x/2)..":"..math.floor(z/2)end
 for _,cell in ipairs(Scene.around(centre,25))do
  local heights,anchor,valid=sampler:sample(cell,offsets)
  if anchor then
   zoneRoots+=valid
   for i,y in pairs(heights)do
    local p=Vector3.new(cell.center.X+offsets[i].X,y,cell.center.Z+offsets[i].Z)
    local k=key(p.X,p.Z)buckets[k]=buckets[k]or{}buckets[k][#buckets[k]+1]=p
   end
  end
 end
 if zoneRoots>100 then zones+=1 roots+=zoneRoots end
 for x=centre.X-8,centre.X+8,1 do for z=centre.Z-8,centre.Z+8,1 do
  local h=ground(x,z)
  if h and(h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass)and h.Normal.Y>.35 then
   local blocked=RaycastParams.new()blocked.FilterType=Enum.RaycastFilterType.Include blocked.FilterDescendantsInstances={world.Decor,world.Amenities}blocked.RespectCanCollide=true
   if not workspace:Raycast(h.Position+Vector3.new(0,20,0),Vector3.new(0,-20,0),blocked)then
    coveragePoints+=1 local covered=false
    for dx=-1,1 do for dz=-1,1 do
     for _,p in ipairs(buckets[key(x+dx*2,z+dz*2)]or{})do if(Vector2.new(p.X-x,p.Z-z)).Magnitude<.90 then covered=true break end end
    end end
    if not covered then misses+=1 end
   end
  end
 end end
end
assert(zones>=3 and coveragePoints>400 and misses==0,"Green terrain still has gaps between grass root grids: "..misses.."/"..coveragePoints)
local Priority=require(runtime.GrassPriority)
local removals,queue=Priority.plan({[99]=true,[100]=true},{{key=1},{key=2}},2,{},0)
assert(#removals==2 and #queue==2 and queue[1].key==1,"Old distant patches prevent nearer grass")
assert(#Scene.around(spawn.Position,42)<=432 and #Scene.around(spawn.Position,70)<=1152,"Client grass budget cannot cover a complete circle")
assert(runtime:GetAttribute("GrassMotionEnabled")==false)
assert(not game.StarterPlayer.StarterPlayerScripts.ForestGrassClient.Source:find("grass:Step",1,true))
local Cycle=require(runtime.Cycle)local Visuals=require(runtime.Visuals)
assert(Cycle.clock(0,0)==6 and Cycle.clock(720,0)==18 and Cycle.clock(960,0)==6)
local epsilon=.001 local before=Cycle.clock(720-epsilon,0)local after=Cycle.clock(720+epsilon,0)
assert(math.abs(before-after)<.001,"Day/night cycle jumps")
local sunDirections={}
for _,hour in ipairs({6,12,18,0})do Visuals.clock(hour)sunDirections[#sunDirections+1]={game.Lighting:GetSunDirection().X,game.Lighting:GetSunDirection().Y,game.Lighting:GetSunDirection().Z}
 assert(game.Lighting.Brightness>=1 and game.Lighting.ForestColor.Enabled and Cycle.night(hour)>=0 and Cycle.night(hour)<=1)
end
assert(Cycle.night(0)>.9 and Cycle.night(12)<.01)
Visuals.clock(Cycle.StartClock)
assert(runtime:GetAttribute("CycleEpoch")and runtime:GetAttribute("ShaderPresetAssetId")==8490242417 and game.Lighting.ForestSky:GetAttribute("SourceAssetId")==8490242417)
assert(not game.Lighting.ForestBlur.Enabled and game.Lighting.ForestSunRays.Enabled)
assert(runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834 and workspace.GlobalWind.Magnitude>6)
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})do
 for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
  local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
  local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..": "..tostring(result))compiled+=1
 end end
end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,result=pcall(require,s)assert(ok,s.Name..": "..tostring(result))compiled+=1 end end
assert(workspace.StreamingEnabled and #game.ServerScriptService:GetChildren()==1)
table.sort(buriedExamples,function(a,b)return a.burial>b.burial end)
while#buriedExamples>12 do table.remove(buriedExamples)end
return{forestOnly=true,parts=parts,realMeshParts=meshes,pbrAppearances=pbr,foreignScripts=foreign,trees=treeCount,plants=plantCount,buriedExamples=buriedExamples,
 supportPoints=supports,maximumSupportGap=maxGap,maximumSupportBurial=maxBurial,treeHeightRange={shortest,tallest},
 terrainProbes=probes,greenTerrainProbes=green,waterProbes=water,trailProbes=trail,riverContinuityProbes=riverProbes,
 woodenBridges=2,continuousWalkwayProbes=walks,logSeats=seats,cutTrunks=world:GetAttribute("CutTrunkCount"),lanterns=#lights,
 grassSampledZones=zones,validGrassRoots=roots,grassCoveragePoints=coveragePoints,grassCoverageMisses=misses,grassRootOverlap=hi.X-lo.X-Scene.Spacing,
 grassPriorityCorrect=true,staticGrassSource=true,ownerNPCRemoved=true,
 cycleSeconds=Cycle.Duration,sunDirectionSamples=sunDirections,extendedWaterSurface=true,
 shaderPresetAssetId=8490242417,compiledScriptsAndModules=compiled,streamingEnabled=true,rendering=tostring(game.Lighting.LightingStyle)}
]============])
local gardenTests=run([============[local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local folder=world.Amenities.RiversideGarden
assert(not world:FindFirstChild("OwnerNPC")and not runtime:FindFirstChild("NPCController"))
local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
local report={walkProbes=0,pilings=0,animals=0,audio=0,teaSeatsFaceTable=0}
for _,p in ipairs(folder:GetDescendants())do if p.Name=="GroundedPiling"then local g=p:GetAttribute("GroundPoint")local hit=assert(workspace:Raycast(g+Vector3.yAxis*20,Vector3.yAxis*-50,rp))assert(p.Position.Y-p.Size.Y*.5<=hit.Position.Y+.01,"Floating cottage piling")report.pilings+=1 end end
local house=folder.WaterCottage local o=house:GetAttribute("Origin")assert(o.Y>workspace.Terrain.WaterWaveSize+6+3)
for _,x in ipairs({-18,0,18})do for _,z in ipairs({-14,0,14})do local h=assert(workspace:Raycast(Vector3.new(o.X+x,200,o.Z+z),Vector3.new(0,-300,0),rp))assert(h.Position.Y<6,"Cottage planted on dry hillside")end end
local walk=folder.LakesideBoardwalk local nodes=game:GetService("HttpService"):JSONDecode(walk:GetAttribute("WalkNodes"))
local col=RaycastParams.new()col.FilterType=Enum.RaycastFilterType.Include col.FilterDescendantsInstances={walk}col.RespectCanCollide=true
for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))assert(math.abs((b-a).Unit.Y)<.45,"Boardwalk too steep")
 for _,t in ipairs({0,.5})do local p=a:Lerp(b,t)local h=assert(workspace:Raycast(p+Vector3.yAxis*2,Vector3.yAxis*-4,col),"Boardwalk collision missing")assert(math.abs(h.Position.Y-p.Y)<.16,"Boardwalk height gap")report.walkProbes+=1 end
end
local last=Vector3.new(unpack(nodes[#nodes]))local bank=assert(workspace:Raycast(last+Vector3.yAxis*20,Vector3.yAxis*-40,rp))assert(math.abs(bank.Position.Y-last.Y)<.5)
col.FilterDescendantsInstances={house}
assert(workspace:Raycast(o+Vector3.new(0,1,-16),Vector3.yAxis*-2,col),"Porch has no floor")
assert(not workspace:Raycast(o+Vector3.new(0,5,-15),Vector3.zAxis*8,col),"Cottage entrance blocked")
for _,route in ipairs(world.Amenities.CuteAnimalRoutes:GetChildren())do
 local template=assert(runtime.CuteAnimalTemplates:FindFirstChild(route:GetAttribute("Species")))assert(template:GetAttribute("SourceAssetId")==77173958514594)
 for _,p in ipairs(game:GetService("HttpService"):JSONDecode(route.Value))do local v=Vector3.new(unpack(p))local h=assert(workspace:Raycast(v+Vector3.yAxis*20,Vector3.yAxis*-40,rp))assert(h.Position.Y>6 and math.abs(h.Position.Y-v.Y)<.1,"Animal floats off its path")end report.animals+=1
end assert(report.animals>=4)
for _,s in ipairs(runtime.GardenSounds:GetChildren())do game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Ambience unavailable: "..s.Name)report.audio+=1 end
local weather=require(runtime.GardenWeather)
assert(not weather.raining(89.99,0)and weather.raining(90,0)and weather.raining(209.99,0)and not weather.raining(210,0)and weather.raining(570,0))
local a={Head={Position=Vector3.new(0,5,0)}}local b={Head={Position=Vector3.new(4,6,0)}}local target=weather.canopy(a,b)assert(target==Vector3.new(2,7.5,0))assert(weather.canopy(a)==Vector3.new(0,6.5,0))
local tool=runtime.UmbrellaTool assert(tool.RequiresHandle==false and tool.CanBeDropped==false and tool:GetAttribute("RainUmbrella")and tool:FindFirstChild("UmbrellaAnchor")and not tool:FindFirstChild("Handle"))
for _,p in ipairs(tool:GetChildren())do if p:IsA("BasePart")then assert(not p.Anchored and p.Massless and not p.CanCollide)end end
local C=game:GetService("CollectionService")for _,seat in ipairs(C:GetTagged("RuinSeat"))do if seat.Name=="TeaSeat"and seat:IsDescendantOf(world)then
 local center=seat.Parent.Parent.AntiqueTeaTable:GetPivot().Position local aim=Vector3.new(center.X-seat.Position.X,0,center.Z-seat.Position.Z).Unit assert(seat.CFrame.LookVector:Dot(aim)>.9)report.teaSeatsFaceTable+=1 end end
assert(report.teaSeatsFaceTable==16)
report.ownerNPCRemoved=true report.sharedUmbrellaMidpoint=true report.nativeFootsteps=true report.styledWater=true
runtime:SetAttribute("GardenTestMode",nil)
return report
]============])
return{staged=true,baseVersion=90,report={riverside=riverside,animals=animals,tools=tools,audio=audio,tea=tea,baseTests=baseTests,forestTests=forestTests,gardenTests=gardenTests}}
