local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-hotel-verified.rbxl'))
local source=R.deserializePlace(fs.readFile('/tmp/asset-7902470429.rbxl'))
local expectedUI=require('./mystery-ui-extract')(source)
local ui=assert(dm:GetService('ReplicatedStorage'):FindFirstChild('MysteryInterface'))
local map=assert(dm:GetService('ServerStorage'):FindFirstChild('HotelMap'))
local function relativePath(object,root)
 local names={}
 while object and object~=root do table.insert(names,1,object.Name);object=object.Parent end
 return table.concat(names,'/')
end
local byPath={}
for _,d in ipairs(ui:GetDescendants()) do byPath[relativePath(d,ui)]=d end
local guiObjects=0
local function sameProperty(actual,expected,property,path)
 local aok,a=pcall(function() return actual[property] end)
 local eok,e=pcall(function() return expected[property] end)
 assert(aok==eok,'UI property availability changed '..path..'.'..property)
 -- The reflection database omits defaults for some deprecated Content properties.
 if aok then assert(a==e,'Original UI design changed '..path..'.'..property) end
end
for _,expected in ipairs(expectedUI:GetDescendants()) do
 local path=relativePath(expected,expectedUI)
 local actual=assert(byPath[path],'Missing original UI object '..path)
 assert(actual.ClassName==expected.ClassName,'UI type changed '..path)
 if expected:IsA('GuiObject') then
  guiObjects+=1
  for _,property in ipairs({'Size','Position','AnchorPoint','Rotation','ZIndex','Visible','BackgroundColor3','BackgroundTransparency'}) do
   sameProperty(actual,expected,property,path)
  end
 end
 if expected:IsA('ImageLabel') or expected:IsA('ImageButton') then
  for _,property in ipairs({'Image','ImageContent','ImageColor3','ImageTransparency','ScaleType','SliceCenter'}) do sameProperty(actual,expected,property,path) end
 end
 if expected:IsA('TextLabel') or expected:IsA('TextButton') then
  for _,property in ipairs({'Text','TextSize','FontFace','TextColor3','TextScaled','TextWrapped'}) do sameProperty(actual,expected,property,path) end
 end
end
assert(#expectedUI:GetDescendants()==#ui:GetDescendants(),'UI has extra map/controller objects')
local raw=R.deserializeModel(fs.readFile('assets/hotel/1940sHotelLobby.rbxm'))[1]
local world=raw:FindFirstChild('---- Ungroup In Workspace ----')
local originalParts={};local id=0
for _,d in ipairs(world:GetDescendants()) do
 id+=1
 if d:IsA('BasePart') and not d:GetFullName():find('AK-47 Spawner',1,true) then originalParts[id]=d end
end
local parts=0
for _,d in ipairs(map:GetDescendants()) do
 assert(not d:IsA('ScreenGui') and not d:IsA('LuaSourceContainer') and not d:IsA('Tool'),'Map contains UI/code/weapon '..d:GetFullName())
 if d:IsA('BasePart') then
  parts+=1
  local expected=assert(originalParts[d:GetAttribute('HotelSourceId')],'Unexpected map geometry')
  local actualCF={d.CFrame:GetComponents()};local expectedCF={expected.CFrame:GetComponents()}
  for i,value in ipairs(actualCF) do assert(math.abs(value-expectedCF[i])<.0001,'Map transform changed '..d:GetFullName()) end
  for _,property in ipairs({'Size','Color','Material','MaterialVariant','Transparency','CanCollide'}) do
   assert(d[property]==expected[property],'Map source changed '..d:GetFullName()..'.'..property)
  end
  if d:IsA('MeshPart') then
   for _,property in ipairs({'MeshId','MeshContent','TextureID','TextureContent'}) do sameProperty(d,expected,property,d:GetFullName()) end
  end
  originalParts[d:GetAttribute('HotelSourceId')]=nil
 end
end
assert(next(originalParts)==nil,'Missing geometry from supplied map')
assert(parts==map:GetAttribute('SourcePartCount'),'Map part count mismatch')
for _,d in ipairs(ui:GetDescendants()) do assert(not d:IsA('BasePart') and not d:IsA('LuaSourceContainer'),'UI package depends on map/code') end
local scripts=0
local shipped={MapInteractions='mystery-map-interactions.luau',WorldInitializer='hotel-initialize.luau',PlayerSettings='settings-server.luau',SettingsSchema='settings-schema.luau',SessionInterface='session-interface.luau',MysteryUIClient='mystery-ui-client.luau',SessionLoadingClient='session-loading-client.luau',PortugueseText='original-portuguese-text.luau'}
for _,d in ipairs(dm:GetDescendants()) do
 assert(not d:IsA('Tool'),'Weapon tool in release')
 if d:IsA('LuaSourceContainer') then
  scripts+=1;luau.load(d.Source,{debugName=d:GetFullName()})
  local file=assert(shipped[d.Name],'Unexpected controller '..d:GetFullName())
  assert(d.Source==fs.readFile(file),'Shipped controller source mismatch '..d.Name)
  shipped[d.Name]=nil
 end
end
assert(next(shipped)==nil,'Missing controller')
assert(not dm:GetService('ServerStorage'):FindFirstChild('OriginalWorld'),'Old mansion bundled into new map')
assert(dm:GetService('StarterPlayer').CameraMode==R.Enum.CameraMode.Classic,'Wrong camera mode')
assert(dm:GetService('StarterPlayer').CameraMinZoomDistance>=8,'First person enabled')
print('HOTEL_FILE_VERIFIED '..serde.encode('json',{parts=parts,originalGuiObjects=guiObjects,screens=#ui:GetChildren(),scripts=scripts,separateMapAndUI=true}))
