local Builder={}
local Asset=game:GetService("AssetService")local Collection=game:GetService("CollectionService")
local function strip(root)
 for _,d in ipairs(root:GetDescendants())do
  if d:IsA("LuaSourceContainer")or d:IsA("RemoteEvent")or d:IsA("RemoteFunction")or d:IsA("Sound")then d:Destroy()end
 end
end
local function bounds(root)
 local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(v)hi=hi:Max(v)end end end
 end end return lo,hi
end
local function normalize(model)
 model:PivotTo(CFrame.identity)local lo,hi=bounds(model)local offset=Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)
 model:PivotTo(model:GetPivot()-offset)model.PrimaryPart=nil model.WorldPivot=CFrame.identity return hi-lo
end
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color or Color3.fromRGB(169,173,149)p.Material=material or Enum.Material.Limestone
 p.Anchored=true p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.Parent=parent return p
end
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local rng=Random.new(901014)
 local report={teaTables=0,chairs=0,bridges=0,menuAsset=17216750157,emoteAsset=127049078545834}
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
 -- All four old regional colors are restored to one green spring across the same heightfield.
 for bx=-512,384,128 do for bz=-512,384,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))local grid=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidMaterial"}).SolidMaterial
  for ix=1,32 do for iz=1,32 do for iy=1,54 do local material=grid[ix][iy][iz]
   if material==Enum.Material.Snow or material==Enum.Material.Grass or material==Enum.Material.LeafyGrass then grid[ix][iy][iz]=Enum.Material.Grass end
  end end end workspace.Terrain:WriteVoxelChannels(region,4,{SolidMaterial=grid})task.wait()
 end end
 workspace.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(98,139,66))workspace.Terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(169,132,64))workspace.Terrain:SetMaterialColor(Enum.Material.Snow,Color3.fromRGB(236,242,247))
 pcall(function()workspace.Terrain.Decoration=false end)
 runtime:SetAttribute("SeasonName","Primavera")runtime:SetAttribute("SeasonIndex",1)runtime:SetAttribute("GrassMotionEnabled",false)
 world:SetAttribute("SeasonLayout","TemporalGlobal")world:SetAttribute("SeasonCount",4)world:SetAttribute("GameName","TreeWorld")world:SetAttribute("UpgradeVersion",90)
 local packRaw=Asset:LoadAssetAsync(6432306802)local pack=assert(packRaw["Forest Pack"])strip(pack)
 local blossoms=0
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,m in ipairs(folder:GetChildren())do
  m:SetAttribute("Season",nil)m:SetAttribute("AutumnGrove",nil)
  local accent=folder==world.Decor.Trees and m.Name=="DogwoodTree_Var01"and rng:NextNumber()<.22
  m:SetAttribute("SpringBlossom",accent)if accent then blossoms+=1 end
  local original=pack:FindFirstChild(m.Name)
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
   local sample=original and original:FindFirstChild(p.Name,true)local color=sample and sample:IsA("BasePart")and sample.Color or Color3.fromRGB(94,135,71)
   if folder==world.Decor.Plants and m.Name:lower():find("flower",1,true)then color=sample and sample.Color or Color3.fromRGB(225,218,185)end
   p:SetAttribute("SeasonBaseColor",color)p:SetAttribute("SeasonBaseTransparency",p.Transparency)
   p.Color=accent and (p.Name:lower():find("leaf",1,true)or p.Name:lower():find("leaves",1,true))and Color3.fromRGB(213,173,187)or color local a=p:FindFirstChildOfClass("SurfaceAppearance")if a then a.Color=p.Color end
  end end
 end end packRaw:Destroy()report.springBlossoms=blossoms
 -- The exact requested loading/menu UI is retained; its script is adapted for bounded loading and mobile input.
 local raw=Asset:LoadAssetAsync(17216750157)
 local menu=assert(raw:FindFirstChild("LoadingMainMenuGUI",true)):Clone()strip(menu)menu.Name="TreeWorldMenu"menu.ResetOnSpawn=false menu.IgnoreGuiInset=true menu.DisplayOrder=100 menu.Enabled=true menu:SetAttribute("SourceAssetId",17216750157)
 for _,v in ipairs(menu:GetDescendants())do if v:IsA("TextLabel")or v:IsA("TextButton")then v.Font=Enum.Font.GothamMedium v.TextScaled=false end end
 local loading=menu.Background loading.Size=UDim2.fromScale(1,1)loading.Position=UDim2.fromScale(0,0)loading.AnchorPoint=Vector2.zero loading.BackgroundColor3=Color3.fromRGB(19,32,24)loading.BackgroundTransparency=0
 local function title(label,y)
  label.Text="TreeWorld"label.AnchorPoint=Vector2.new(.5,.5)label.Position=UDim2.fromScale(.5,y)label.Size=UDim2.new(.8,0,0,75)label.TextSize=48 label.TextColor3=Color3.fromRGB(239,235,210)label.BackgroundTransparency=1 label.Font=Enum.Font.Garamond
  local constraint=Instance.new("UITextSizeConstraint")constraint.MaxTextSize=48 constraint.MinTextSize=24 constraint.Parent=label label.TextScaled=true
 end
 title(loading.GameTitle,.43)loading.Description.Text="Um lugar para explorar e descansar."loading.Description.AnchorPoint=Vector2.new(.5,.5)loading.Description.Position=UDim2.fromScale(.5,.56)loading.Description.Size=UDim2.new(.86,0,0,45)loading.Description.TextSize=15 loading.Description.TextWrapped=true loading.Description.TextColor3=Color3.fromRGB(207,220,198)loading.Description.BackgroundTransparency=1
 local bar=loading.Bar bar.AnchorPoint=Vector2.new(.5,.5)bar.Position=UDim2.fromScale(.5,.65)bar.Size=UDim2.new(.55,0,0,5)bar.BackgroundColor3=Color3.fromRGB(57,72,57)bar.BorderSizePixel=0 bar.LoadBar.Size=UDim2.fromScale(0,1)bar.LoadBar.Position=UDim2.fromScale(0,0)bar.LoadBar.AnchorPoint=Vector2.zero bar.LoadBar.BackgroundColor3=Color3.fromRGB(189,209,157)
 local main=menu.MainMenu main.Size=UDim2.fromScale(1,1)main.Position=UDim2.fromScale(0,0)main.AnchorPoint=Vector2.zero main.BackgroundTransparency=1 title(main.GameTitle,.38)
 local play=main.PlayButton play.Text="Entrar"play.AnchorPoint=Vector2.new(.5,.5)play.Position=UDim2.fromScale(.5,.58)play.Size=UDim2.new(.38,0,0,52)play.BackgroundColor3=Color3.fromRGB(42,62,43)play.TextColor3=Color3.fromRGB(240,239,218)play.TextSize=20 play.AutoButtonColor=true
 local size=Instance.new("UISizeConstraint")size.MinSize=Vector2.new(150,52)size.MaxSize=Vector2.new(270,52)size.Parent=play
 for _,obj in ipairs({play,bar,bar.LoadBar})do local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,10)corner.Parent=obj end
 local name=menu:FindFirstChild("GameName")if name then name.Value="TreeWorld"end
 menu.Parent=game.StarterGui raw:Destroy()
 local blur=game.Lighting:FindFirstChild("TreeWorldMenuBlur")or Instance.new("BlurEffect")blur.Name="TreeWorldMenuBlur"blur.Enabled=false blur.Size=0 blur.Parent=game.Lighting
 local origin=world.Amenities.ForestRuins:GetAttribute("Origin")runtime:SetAttribute("MenuCameraFocus",origin+Vector3.new(0,6,-8))runtime:SetAttribute("MenuCameraCF",CFrame.lookAt(origin+Vector3.new(54,26,65),origin+Vector3.new(0,6,-8)))
 -- Antique native chair meshes have their own authored seat and back; no procedural stools remain.
 local chairRaw=Asset:LoadAssetAsync(8474839527)strip(chairRaw)local chairTemplate=assert(chairRaw:FindFirstChildOfClass("Model"))normalize(chairTemplate)
 local seatRotation=assert(chairTemplate:FindFirstChildOfClass("Seat")).CFrame.Rotation:Inverse()
 for _,part in ipairs(chairTemplate:GetDescendants())do if part:IsA("BasePart")then part.CFrame=seatRotation*part.CFrame end end
 chairTemplate.WorldPivot=CFrame.identity normalize(chairTemplate)
 -- Remove the outside duplicate from the source container; only the authored Chair model is used.
 local tableRaw=Asset:LoadAssetAsync(18831822897)strip(tableRaw)local tableTemplate=assert(tableRaw:FindFirstChildOfClass("Model"))
 for _,d in ipairs(tableTemplate:GetDescendants())do if d.Name=="bottle"then d:Destroy()end end
 normalize(tableTemplate)
 local function tea(corner)
  local oldCF=corner:GetPivot()local top=corner:FindFirstChild("TableTop",true)or corner:FindFirstChild("TeaTableTop",true)
  local centre=top and Vector3.new(top.Position.X,origin.Y,top.Position.Z)or origin+Vector3.new(-16,0,-9)
  local table=tableTemplate:Clone()table.Name="AntiqueTeaTable"table:SetAttribute("SourceAssetId",18831822897)table:ScaleTo(1.18)table:PivotTo(CFrame.new(centre))table.Parent=corner
  for _,p in ipairs(table:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=p.Name=="table"p.CanQuery=p.CanCollide p.CanTouch=false end end
  local reference=assert(table:FindFirstChild("table",true))local tableTop=reference.Position.Y+reference.Size.Y*.5
  local cover=table:FindFirstChild("tablecover",true)if cover then tableTop=math.max(tableTop,cover.Position.Y+cover.Size.Y*.5-.03)end
  local delta=tableTop-(origin.Y+3.21)
  -- Place the existing teapot, cups, cookies and flowers on the new table surface.
  for _,d in ipairs(corner:GetChildren())do
   if d.Name=="PinkStool"or d.Name=="TableTop"or d.Name=="TablePedestal"or d.Name=="TableFoot"then d:Destroy()
   elseif d~=table and d:IsA("Model")then d:PivotTo(d:GetPivot()+Vector3.new(0,delta+.025,0))
   elseif d~=table and d:IsA("BasePart")then d.CFrame+=Vector3.new(0,delta+.025,0)end
  end
  local prompt=assert(corner:FindFirstChild("ServeTea",true))Collection:AddTag(prompt,"TreeWorldTeaPrompt")
  for i=0,3 do
   local angle=i*math.pi*.5 local point=centre+Vector3.new(math.cos(angle)*4.2,0,math.sin(angle)*4.2)
   local chair=chairTemplate:Clone()chair.Name="AntiqueTeaChair"chair:SetAttribute("SourceAssetId",8474839527)
   chair:PivotTo(CFrame.lookAt(point,Vector3.new(centre.X,point.Y,centre.Z)))chair.Parent=corner
   for _,p in ipairs(chair:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
    if p.Name:find("Cushion")then p.Color=Color3.fromRGB(169,145,155)end
   end end
   local seat=assert(chair:FindFirstChildOfClass("Seat"))seat.Name="TeaSeat"seat.Transparency=1 seat.CanCollide=false seat.CanTouch=false
   local support=part(chair,"ChairSeatCollision",Vector3.new(2,.13,1.6),seat.CFrame,Color3.new(),Enum.Material.Wood,true)support.Transparency=1
   local sit=Instance.new("ProximityPrompt")sit.Name="SitPrompt"sit.ActionText="Sentar e tomar chá"sit.ObjectText="Chá da tarde"sit.HoldDuration=.2 sit.MaxActivationDistance=7 sit.RequiresLineOfSight=false sit.Parent=seat
   local link=Instance.new("ObjectValue")link.Name="TeaPrompt"link.Value=prompt link.Parent=seat Collection:AddTag(seat,"RuinSeat")report.chairs+=1
  end
  corner:SetAttribute("TeaTable",true)report.teaTables+=1
 end
 tea(world.Amenities.ForestRuins.TeaCorner)
 -- Refresh all clothes, body parts and layered accessories from the account right now.
 local old=world.OwnerNPC local oldRoot=old.HumanoidRootPart local heading=oldRoot.CFrame.Rotation
 local stump=world.Amenities.CutTrunks.OwnerCutTrunk local seatTop=stump:GetAttribute("SeatTop")
 local desc=game.Players:GetHumanoidDescriptionFromUserIdAsync(8344738123)
 local npc=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)npc.Name="OwnerNPC"strip(npc)
 npc:SetAttribute("AvatarUserId",8344738123)npc:SetAttribute("ShirtAssetId",desc.Shirt)npc:SetAttribute("PantsAssetId",desc.Pants)npc:SetAttribute("TorsoAssetId",desc.Torso)npc:SetAttribute("HeadAssetId",desc.Head)desc:Destroy()
 npc:SetAttribute("AvatarUpdatedUTC","2026-10-14")npc:SetAttribute("EmoteAssetId",127049078545834)npc:SetAttribute("EmoteAnimationId",92824429927180)npc:SetAttribute("Seated",true)
 local root=assert(npc.HumanoidRootPart)npc.PrimaryPart=root npc.Parent=world npc.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,p in ipairs(npc:GetDescendants())do if p:IsA("BasePart")then p.Anchored=p==root p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Massless=true end end
 local hum=npc.Humanoid hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.WalkSpeed=0 hum.JumpPower=0 hum.AutoRotate=false hum.BreakJointsOnDeath=false
 local animation=Instance.new("Animation")animation.Name="CatBath"animation.AnimationId="rbxassetid://92824429927180"animation.Parent=npc
 local animator=hum:FindFirstChildOfClass("Animator")or Instance.new("Animator",hum)local track=animator:LoadAnimation(animation)track.Looped=true track:Play(0)
 local deadline=os.clock()+8 repeat task.wait(.1)until track.Length>0 or os.clock()>deadline assert(track.Length>0,"Exact Cat Bath emote is unavailable")
 npc:PivotTo(CFrame.new(0,100,0))track.TimePosition=.8 animator:StepAnimations(0)
 local done={[root]=true}local motors={}for _,m in ipairs(npc:GetDescendants())do if m:IsA("Motor6D")then motors[#motors+1]=m end end
 for _=1,18 do for _,m in ipairs(motors)do if done[m.Part0]and not done[m.Part1]then m.Part1.CFrame=m.Part0.CFrame*m.C0*m.Transform*m.C1:Inverse()done[m.Part1]=true end end end
 local lower=npc.LowerTorso local offset=root.CFrame:PointToObjectSpace(lower.Position)
 local halfY=(math.abs(lower.CFrame.UpVector.Y)*lower.Size.Y+math.abs(lower.CFrame.RightVector.Y)*lower.Size.X+math.abs(lower.CFrame.LookVector.Y)*lower.Size.Z)*.5
 local target=seatTop+Vector3.new(0,halfY+.05,0)local placement=CFrame.new(target)*heading*CFrame.new(-offset)
 npc:PivotTo(placement)npc:SetAttribute("SeatCFrame",placement)npc:SetAttribute("SeatTop",seatTop)npc:SetAttribute("SeatedTorsoOffset",offset)npc:SetAttribute("SeatedTorsoHalfY",halfY)
 track:Stop(0)track:Destroy()animator:Destroy()
 for _,name in ipairs({"HiVoice","YayVoice"})do local sound=old.Head:FindFirstChild(name)if sound then local copy=sound:Clone()copy.Volume=name=="HiVoice"and .26 or .22 copy.RollOffMaxDistance=22 copy.Parent=npc.Head end end
 old:Destroy()Collection:AddTag(npc,"ForestOwnerNPC")
 local remote=runtime:FindFirstChild("OwnerDialogue")if remote then remote:Destroy()end local pose=runtime:FindFirstChild("NPCPose")if pose then pose:Destroy()end
 chairRaw:Destroy()tableRaw:Destroy()
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())
 return report
end
return Builder
