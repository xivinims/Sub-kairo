local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Tags=game:GetService('CollectionService')
local Input=game:GetService('UserInputService')
local player=Players.LocalPlayer
local runtime=RS:WaitForChild('LivingForest')
local C=require(RS:WaitForChild('PhotoWorldConfig'))
local Meta=require(RS:WaitForChild('LivingMeshMeta'))
local Meshes=runtime:WaitForChild('Meshes')
local mobile=Input.TouchEnabled;local rng=Random.new()
local folder=Instance.new('Folder');folder.Name='LocalForestLife';folder.Parent=workspace
local wind=require(runtime.WindEffects.WindShake)
local lines=require(runtime.WindEffects.WindLines)
wind:SetDefaultSettings({WindDirection=Vector3.new(1,0,.32).Unit,WindSpeed=9,WindPower=.075});wind:Init()
lines:Init({Direction=Vector3.new(1,0,.32).Unit,Speed=8,Lifetime=2.2,SpawnRate=mobile and .6 or 1})
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={workspace.Terrain}
local leaves={};local butterflies={};local ripples={};local dizzy={};local closeTrees={}
local function visual(name)
 local p=Meshes[name]:Clone();p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=folder;return p
end
local function dropLeaf(tree,count)
 if not tree.Parent then return end
 local root=tree:GetAttribute('RootPosition');local cone=tree:GetAttribute('Evergreen');local petal=tree:GetAttribute('Petals')
 for _=1,count do
  if #leaves>=(mobile and 60 or 96)then break end
  local radius=tree:GetAttribute('CanopyRadius')or 10;local a=rng:NextNumber(0,6.28);local r=rng:NextNumber(.2,1)*radius
  local pos=root+Vector3.new(math.cos(a)*r,(tree:GetAttribute('CanopyHeight')or 24)+rng:NextNumber(-3,4),math.sin(a)*r)
  local p=visual(cone and 'PineCone' or petal and 'FallingPetal' or 'FallingLeaf');p.Size*=rng:NextNumber(.65,1.0)
  if tree:GetAttribute('TreeKind')=='AmberMaple'then p.Color=Color3.fromRGB(255,182,76)end
  p.CFrame=CFrame.new(pos);table.insert(leaves,{p=p,pos=pos,age=0,seed=rng:NextNumber(0,20),cone=cone,velocity=Vector3.new(rng:NextNumber(-.7,.7),cone and -1 or -.5,rng:NextNumber(-.7,.7))})
 end
end
local function ripple(pos,strength)
 if #ripples>18 then return end
 local p=visual('WaterRipple');p.Color=Color3.fromRGB(182,223,229);p.Transparency=.68
 table.insert(ripples,{p=p,age=0,pos=pos,strength=strength or 1})
end
local function dizzyAvatar(who)
 local char=who.Character;local head=char and char:FindFirstChild('Head');local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
 if not head or not root or not hum or dizzy[char]then return end
 local joints={};for _,j in ipairs(char:GetDescendants())do if j:IsA('Motor6D')then joints[j]=j.C0 end end
 local stars={};for i=1,3 do stars[i]=visual('DizzyStar')end
 dizzy[char]={head=head,root=root,hum=hum,joints=joints,stars=stars,born=os.clock(),speed=hum.WalkSpeed,localPlayer=who==player}
 if who==player then hum.WalkSpeed=math.min(hum.WalkSpeed,5)end
end
runtime.NatureEvent.OnClientEvent:Connect(function(kind,tree,who,hard)
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if kind~='tree'or not tree or not tree.Parent or not root then return end
 if(tree:GetAttribute('RootPosition')-root.Position).Magnitude<95 then
  dropLeaf(tree,tree:GetAttribute('Evergreen')and 3 or 14)
  if hard and who then dizzyAvatar(who)end
 end
end)
-- Small original wing meshes contain dark borders, veins and cream spots.
local function butterfly(pos,index)
 local body=visual('ButterflyBody');local name=index%2==0 and 'ButterflyBlueWing'or'ButterflyAmberWing'
 local left=visual(name);local right=visual(name);local scale=rng:NextNumber(.35,.60)
 body.Size*=scale;left.Size*=scale;right.Size*=scale
 return{body=body,left=left,right=right,home=pos,seed=rng:NextNumber(0,20),scale=scale,wing=name}
end
local sounds={}
for name,volume in pairs({Wind=.045,Forest=.045,River=0})do
 local p=runtime.Sounds[name]:Clone();p.Volume=volume;p.Parent=game:GetService('SoundService');p:Play();sounds[name]=p
end
local Mirror=require(runtime.Reflection)
local mirrors={};local waterPoint=nil;local waterHeight=nil;local lastWater=false
local scan=0;local tick=0;local leafClock=0;local rippleClock=0
local function scanLife(root)
 closeTrees={}
 for _,m in ipairs(Tags:GetTagged('LivingTree'))do
  local pos=m:GetAttribute('RootPosition')
  if m.Parent and pos and(pos-root.Position).Magnitude<76 then table.insert(closeTrees,m)end
 end
 table.sort(closeTrees,function(a,b)return(a:GetAttribute('RootPosition')-root.Position).Magnitude<(b:GetAttribute('RootPosition')-root.Position).Magnitude end)
 while #closeTrees>30 do table.remove(closeTrees)end
 for i=#butterflies,1,-1 do local b=butterflies[i];if(b.home-root.Position).Magnitude>100 then b.body:Destroy();b.left:Destroy();b.right:Destroy();table.remove(butterflies,i)end end
 if #butterflies<(mobile and 5 or 9)then
  local a=rng:NextNumber(0,6.28);local r=rng:NextNumber(14,65);local x,z=root.Position.X+math.cos(a)*r,root.Position.Z+math.sin(a)*r
  local h,_,w=C.surface(x,z);if not w then table.insert(butterflies,butterfly(Vector3.new(x,h+2.6,z),#butterflies+1))end
 end
 waterPoint=nil;waterHeight=nil
 for _,radius in ipairs({0,4,8,12})do
  for i=0,7 do
   local a=i*math.pi/4;local x,z=root.Position.X+math.cos(a)*radius,root.Position.Z+math.sin(a)*radius
   local hit=workspace:Raycast(Vector3.new(x,root.Position.Y+25,z),Vector3.new(0,-70,0),ray)
   if hit and hit.Material==Enum.Material.Water then waterPoint=hit.Position;waterHeight=hit.Position.Y;break end
  end
  if waterPoint then break end
 end
 sounds.River.Volume=waterPoint and .085 or 0
end
Run.PreSimulation:Connect(function()
 local now=os.clock()
 for char,d in pairs(dizzy)do
  local t=now-d.born
  if t>2.15 or not char.Parent or not d.head.Parent or d.hum.Health<=0 then
   for j,cf in pairs(d.joints)do if j.Parent then j.C0=cf end end
   if d.localPlayer and d.hum.Parent and d.hum.WalkSpeed==5 then d.hum.WalkSpeed=d.speed end
   for _,p in ipairs(d.stars)do p:Destroy()end;dizzy[char]=nil
  else
   local strength=math.min(t*5,1)*math.clamp((2.15-t)*3,0,1)
   for j,cf in pairs(d.joints)do if j.Parent then
    if j.Name=='Neck'then j.C0=cf*CFrame.Angles(math.rad(10)*strength,0,math.sin(t*8)*.1*strength)
    elseif j.Name=='Right Shoulder'or j.Name=='RightShoulder'then j.C0=cf*CFrame.Angles(math.rad(-125)*strength,0,math.rad(-15+5*math.sin(t*14))*strength)
    elseif j.Name=='RootJoint'then j.C0=cf*CFrame.Angles(0,0,math.sin(t*7)*.05*strength)end
   end end
   if d.localPlayer and t>.45 and t<1.1 then
    local direction=-d.root.CFrame.LookVector;local hit=workspace:Raycast(d.root.Position+direction*3,Vector3.new(0,-8,0),ray)
    if hit and hit.Normal.Y>.7 and hit.Material~=Enum.Material.Water then d.hum:Move(direction,false)end
   end
   for i,p in ipairs(d.stars)do local a=t*3.1+i*math.pi*2/3;p.CFrame=CFrame.new(d.head.Position+Vector3.new(math.cos(a)*1.4,1.7+math.sin(a*2)*.12,math.sin(a)*1.4))*CFrame.Angles(0,-a,t*.8)end
  end
 end
end)
Run.Heartbeat:Connect(function(dt)
 tick+=dt;scan+=dt;leafClock+=dt;rippleClock+=dt;if tick<1/30 then return end;dt=math.min(tick,.1);tick=0
 local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local now=os.clock()
 if not root then return end
 if scan>.6 then scan=0;scanLife(root)end
 if leafClock>1.7 then leafClock=0;if #closeTrees>0 then local tree=closeTrees[rng:NextInteger(1,#closeTrees)];if not tree:GetAttribute('Evergreen')or rng:NextNumber()<.2 then dropLeaf(tree,1)end end end
 for i=#leaves,1,-1 do
  local d=leaves[i];d.age+=dt
  if d.age>24 or not d.p.Parent then d.p:Destroy();table.remove(leaves,i)
  elseif d.landed then d.p.Transparency=math.clamp((d.age-d.landed-3)/2,0,1);if d.age-d.landed>5 then d.p:Destroy();table.remove(leaves,i)end
  else
   if d.cone then d.velocity-=Vector3.yAxis*(45*dt)else d.velocity=Vector3.new(.7+math.sin(d.age*1.8+d.seed)*.6,-1.65,math.cos(d.age*1.4+d.seed)*.5)end
   local nextPos=d.pos+d.velocity*dt;local hit=workspace:Raycast(d.pos,nextPos-d.pos-Vector3.yAxis*.06,ray)
   if hit then
    d.pos=hit.Position+Vector3.yAxis*(d.cone and .22 or .03)
    if d.cone and not d.bounced and d.velocity.Y<-5 then d.velocity=Vector3.new(d.velocity.X*.4,math.abs(d.velocity.Y)*.18,d.velocity.Z*.4);d.bounced=true
    else d.landed=d.age end
   else d.pos=nextPos end
   local spin=d.cone and d.age*3.8 or math.sin(d.age*2+d.seed)*.5
   d.p.CFrame=CFrame.new(d.pos)*CFrame.Angles(spin,d.age*.8,spin*.5)
  end
 end
 for _,b in ipairs(butterflies)do
  local t=now+b.seed;local pos=b.home+Vector3.new(math.sin(t*.46)*4,math.sin(t*.85)*1.1,math.cos(t*.38)*3)
  local cf=CFrame.new(pos)*CFrame.Angles(0,-t*.38,math.sin(t*.4)*.12);local flap=math.sin(t*18)*.95
  b.body.CFrame=cf;b.left.CFrame=cf*CFrame.Angles(0,0,flap)*CFrame.new(Meta[b.wing].center*b.scale)
  b.right.CFrame=cf*CFrame.Angles(0,0,math.pi-flap)*CFrame.new(Meta[b.wing].center*b.scale)
 end
 local immersed=waterHeight and root.Position.Y<waterHeight+3.2
 if immersed and(not lastWater or rippleClock>.55 and root.AssemblyLinearVelocity.Magnitude>1.5)then
  rippleClock=0;ripple(Vector3.new(root.Position.X,waterHeight+.065,root.Position.Z),lastWater and 1 or 1.5)
 end;lastWater=immersed
 for i=#ripples,1,-1 do local d=ripples[i];d.age+=dt;if d.age>2.6 then d.p:Destroy();table.remove(ripples,i)else
  local radius=(.4+d.age*2.4)*d.strength;d.p.Size=Vector3.new(radius*2,.012,radius*2);d.p.CFrame=CFrame.new(d.pos);d.p.Transparency=.64+.36*d.age/2.6
 end end
 -- At most the local player and one nearby avatar are reflected, at 8 Hz.
 if math.floor(now*8)~=runtime:GetAttribute('LocalMirrorFrame')then
  runtime:SetAttribute('LocalMirrorFrame',math.floor(now*8));local used=0
  local ordered={player};for _,p in ipairs(Players:GetPlayers())do if p~=player then table.insert(ordered,p)end end
  for _,p in ipairs(ordered)do
   local c=p.Character;local r=c and c:FindFirstChild('HumanoidRootPart')
   if r and waterPoint and(r.Position-waterPoint).Magnitude<19 and used<2 then
    local m=mirrors[p];if not m or m.character~=c then if m then m.destroy()end;m=Mirror.create(c,player.PlayerGui,folder);m.character=c;mirrors[p]=m end
    m.view.ImageTransparency=r.Position.Y<waterHeight+3.2 and .96 or .87;m.update(waterPoint,workspace.CurrentCamera.CFrame);used+=1
   elseif mirrors[p]then mirrors[p].hide()end
  end
 end
end)
Players.PlayerRemoving:Connect(function(p)if mirrors[p]then mirrors[p].destroy();mirrors[p]=nil end end)
script.Destroying:Connect(function()wind:Cleanup();lines:Cleanup();for _,m in pairs(mirrors)do m.destroy()end;for _,s in pairs(sounds)do s:Destroy()end;folder:Destroy()end)
