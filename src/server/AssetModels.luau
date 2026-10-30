local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local AssetModels={}
function AssetModels.load()
 local folder=RS:FindFirstChild("BrambleAssets")
 if folder and folder:GetAttribute("Ready") then return folder end
 if not folder then folder=Instance.new("Folder");folder.Name="BrambleAssets";folder.Parent=RS end
 local remaining=0
 for name,id in pairs(Config.Models or {}) do
  if id>0 and not folder:FindFirstChild(name) then
   remaining+=1
   task.spawn(function()
    local ok,container=pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
    if ok then
     -- Nothing from a catalog model is parented to the DataModel until all executable code is removed.
     for _,item in ipairs(container:GetDescendants()) do if item:IsA("LuaSourceContainer") then item:Destroy() end end
     local model=Instance.new("Model");model.Name=name
     for _,child in ipairs(container:GetChildren()) do if not child:IsA("PackageLink") then child.Parent=model end end
     container:Destroy()
     local part=model:FindFirstChildWhichIsA("BasePart",true)
     if part then
      for _,p in ipairs(model:GetDescendants()) do
       if p:IsA("BasePart") then
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false
        if name=="BlueHand" or name=="RedHand" then
         p.Color=Color3.new(1,1,1)
         local texture=Config.Assets[name.."Texture"]
         if p:IsA("MeshPart") and texture and texture>0 then
          for _,a in ipairs(p:GetChildren()) do if a:IsA("SurfaceAppearance") then a:Destroy() end end
          p.TextureID="rbxassetid://"..texture
         end
        end
       end
      end
      model.WorldPivot=model:GetBoundingBox();model.Parent=folder
     else model:Destroy();warn("Empty imported model: "..name) end
    else warn("Import unavailable: "..name.." / "..tostring(container)) end
    remaining-=1
   end)
  end
 end
 local deadline=os.clock()+28
 while remaining>0 and os.clock()<deadline do task.wait(.1) end
 folder:SetAttribute("Ready",true)
 return folder
end
function AssetModels.place(template,parent,cf,height,name)
 local m=template:Clone();m.Name=name or template.Name
 local size=m:GetExtentsSize()
 m:ScaleTo(m:GetScale()*height/math.max(size.Y,.01));m.WorldPivot=m:GetBoundingBox();m:PivotTo(cf);m.Parent=parent
 return m
end
function AssetModels.equipGrabPack(character)
 if not character then return nil end
 local existing=character:FindFirstChild("GrabPackEquipped")
 if existing then return existing end
 local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
 if not torso or not torso:IsA("BasePart") then return nil end
 local templates=RS:FindFirstChild("BrambleAssets")
 local template=templates and templates:FindFirstChild("GrabPack")
 local model
 if template and template:IsA("Model") then
  model=AssetModels.place(template,character,torso.CFrame*CFrame.new(0,0,.58),1.55,"GrabPackEquipped")
 else
  model=Instance.new("Model");model.Name="GrabPackEquipped";model.Parent=character
  local function piece(name,size,offset,color,material)
   local part=Instance.new("Part");part.Name=name;part.Size=size;part.CFrame=torso.CFrame*CFrame.new(offset);part.Color=color;part.Material=material;part.Parent=model;return part
  end
  piece("PackShell",Vector3.new(1.3,1.2,.45),Vector3.new(0,0,.58),Color3.fromRGB(42,62,49),Enum.Material.Metal)
  piece("BlueCanister",Vector3.new(.35,.9,.35),Vector3.new(-.62,0,.58),Color3.fromRGB(37,105,211),Enum.Material.Metal)
  piece("RedCanister",Vector3.new(.35,.9,.35),Vector3.new(.62,0,.58),Color3.fromRGB(197,58,41),Enum.Material.Metal)
 end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
   local weld=Instance.new("WeldConstraint");weld.Part0=torso;weld.Part1=part;weld.Parent=part
  end
 end
 model:SetAttribute("Equipped",true)
 return model
end
function AssetModels.unequipGrabPack(character)
 local existing=character and character:FindFirstChild("GrabPackEquipped")
 if existing then existing:Destroy() end
end
function AssetModels.decorate(world)
 local templates=RS:FindFirstChild("BrambleAssets");if not templates then return end
 local built=workspace:FindFirstChild("BrambleWorld")
 if built then
  for _,part in ipairs(built:GetDescendants()) do
   if part:IsA("BasePart") and (part.Name=="Wall" or part.Name=="EndWall" or part.Name=="EntryWall" or part.Name=="Partition" or part.Name=="BackWall") then part.Material=Enum.Material.Concrete;part.MaterialVariant="KitConcrete";part.Color=Color3.fromRGB(190,196,186)
   elseif part:IsA("BasePart") and (part.Name=="Floor" or part.Name=="Stage") then part.Material=Enum.Material.Concrete;part.MaterialVariant="KitFactoryTiles";part.Color=Color3.fromRGB(225,225,220) end
  end
 end
 for _,target in pairs(world.Targets) do
  local id=target:GetAttribute("Action")
  local name=if id=="pack" then "GrabPack" else if string.match(id,"^fuse") or string.match(id,"^cell") then "Battery" else if string.match(id,"^socket") then "Scanner" else if id=="exit" then "Doors" else if id=="power" or id=="master" or id=="start" then "BatteryHolder" else nil
  local template=name and templates:FindFirstChild(name)
  if template and not target:FindFirstChild("ImportedVisual") then
   local m=AssetModels.place(template,target,target.CFrame*CFrame.new(0,0,.7),if name=="Battery" then 1.5 else if name=="Doors" then 9 else if name=="GrabPack" then 1.55 else 2.5,"ImportedVisual")
   target.Transparency=1
   local indicator=target:FindFirstChild("Indicator");if indicator then indicator.Transparency=1 end
   for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p:SetAttribute("TargetId",target:GetAttribute("TargetId"));p:SetAttribute("Sector",target:GetAttribute("Sector"));p:SetAttribute("Action",target:GetAttribute("Action"));p:SetAttribute("Title",target:GetAttribute("Title")) end end
  end
  local prompt=target:FindFirstChildOfClass("ProximityPrompt");if prompt then prompt.Enabled=id=="pack" end
 end
 local root=workspace:FindFirstChild("BrambleWorld");if not root or root:FindFirstChild("ImportedKitScenery") then return end
 local scenery=Instance.new("Folder");scenery.Name="ImportedKitScenery";scenery.Parent=root
 for sector=1,7 do
  local origin=world.Origins[sector]
  for _,spec in ipairs({{"Panels",Vector3.new(-40,3,-120),6},{"Storage",Vector3.new(45,4,-155),9},{"Pipes",Vector3.new(-55,10,-80),8},{"BrickWalls",Vector3.new(40,3,-60),7}}) do
   local template=templates:FindFirstChild(spec[1]);if template then AssetModels.place(template,scenery,CFrame.new(origin+spec[2]),spec[3]) end
  end
 end
 local bramble=templates:FindFirstChild("BrambleTemplate")
 if bramble then local menu=root:FindFirstChild("MenuSet");local old=menu and menu:FindFirstChild("Bramble_Placeholder");if old then old:Destroy();world.createEnemy(menu,Vector3.new(6,6,67)) end end
 local battery=templates:FindFirstChild("Battery")
 if battery then
  for sector=1,7 do
   local prop=AssetModels.place(battery,scenery,CFrame.new(world.Origins[sector]+Vector3.new(12,3,-24)),1.5,"LoosePowerCube")
   local rootPart=prop:FindFirstChildWhichIsA("BasePart",true)
   for _,part in ipairs(prop:GetDescendants()) do if part:IsA("BasePart") then part.Anchored=false;part.CanCollide=true;part.CanQuery=true;part:SetAttribute("GrabMovable",true);if part~=rootPart then local weld=Instance.new("WeldConstraint");weld.Part0=rootPart;weld.Part1=part;weld.Parent=rootPart end end end
  end
 end
 
end
return AssetModels
