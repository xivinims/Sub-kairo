local M={};local Pose=require(script.Parent.PosePlayer)
function M.Create(parent,item,char)
 local viewport=Instance.new('ViewportFrame');viewport.Size=UDim2.fromScale(1,1);viewport.BackgroundTransparency=1;viewport.Ambient=Color3.fromRGB(170,179,195);viewport.LightColor=Color3.new(1,1,1);viewport.Parent=parent
 local world=Instance.new('WorldModel');world.Parent=viewport;local camera=Instance.new('Camera');camera.Parent=viewport;viewport.CurrentCamera=camera
 local function part(size,cf,color,shape)
  local p=Instance.new('Part');p.Size=size;p.CFrame=cf;p.Color=color;p.Anchored=true;p.CanCollide=false;p.Material=Enum.Material.SmoothPlastic;if shape then p.Shape=shape end;p.Parent=world;return p
 end
 if (item.category=='Animações'or item.category=='Personagem')and char then
  local arch=char.Archivable;char.Archivable=true;local copy=char:Clone();char.Archivable=arch
  for _,v in ipairs(copy:GetDescendants())do if v:IsA('LuaSourceContainer')or v:IsA('Tool')or v:IsA('Sound')or v:IsA('BillboardGui')or v:IsA('ProximityPrompt')then v:Destroy()elseif v:IsA('BasePart')then v.Anchored=v.Name=='HumanoidRootPart';v.CanCollide=false end end
  copy:PivotTo(CFrame.new());copy.Parent=world
  local sequence=item.source and script.Parent.EmoteClips:FindFirstChild(item.id)
  if sequence then local data=Pose.Decode(sequence);Pose.Apply(data,Pose.Motors(copy),math.min(data.duration*.3,1.5),1)end
  camera.CFrame=CFrame.lookAt(Vector3.new(0,1,-9),Vector3.new(0,.3,0));camera.FieldOfView=42
 else
  local dark=Color3.fromRGB(35,41,52);local blue=Color3.fromRGB(80,160,235);local green=Color3.fromRGB(73,154,97)
  if item.id=='compass'then
   part(Vector3.new(.4,2.8,2.8),CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(189,158,91),Enum.PartType.Cylinder)
   part(Vector3.new(.18,2.4,2.4),CFrame.new(0,.25,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(224,223,205),Enum.PartType.Cylinder)
   part(Vector3.new(.16,.12,1.6),CFrame.new(0,.4,0)*CFrame.Angles(0,.5,0),Color3.fromRGB(205,69,74))
  elseif item.id=='flashlight'or item.id=='headlamp'or item.id=='baton'then
   part(Vector3.new(.6,.6,3),CFrame.new(),dark)
   part(Vector3.new(.9,.9,.3),CFrame.new(0,0,-1.5),item.id=='baton'and blue or Color3.new(1,1,1))
   for i=1,3 do part(Vector3.new(.65,.65,.15),CFrame.new(0,0,-.7+i*.35),item.id=='baton'and blue or dark)end
  elseif item.id=='nvg'then
   for _,x in ipairs({-.65,.65})do part(Vector3.new(1,1,1.8),CFrame.new(x,0,0),dark);part(Vector3.new(.8,.8,.1),CFrame.new(x,0,-.95),Color3.fromRGB(105,255,60))end
  elseif item.id=='barrier'then
   part(Vector3.new(3,2.8,.25),CFrame.new(),Color3.fromRGB(145,183,225));for _,x in ipairs({-1.4,1.4})do part(Vector3.new(.15,3,.4),CFrame.new(x,0,0),dark)end
  elseif item.id=='cola'then
   part(Vector3.new(2,1.1,1.1),CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(200,54,63),Enum.PartType.Cylinder)
  else
   part(Vector3.new(1.7,2.8,.6),CFrame.new(),item.id=='timer'and dark or green)
   local screen=part(Vector3.new(1.25,1.1,.1),CFrame.new(0,.2,-.36),item.id=='timer'and blue or Color3.fromRGB(105,235,111))
   if item.id=='radio'or item.id=='radar'then part(Vector3.new(.13,1.3,.13),CFrame.new(.55,1.9,0),dark)end
   if item.id=='timer'then local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(240,120);g.Parent=screen;local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text='3:00';t.TextColor3=Color3.new(1,1,1);t.TextScaled=true;t.Font=Enum.Font.GothamBold;t.Parent=g end
  end
  camera.CFrame=CFrame.lookAt(Vector3.new(3.6,3,-5.5),Vector3.zero);camera.FieldOfView=35
 end
 return viewport
end
return M
