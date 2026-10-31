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
for _,expected in ipairs(expectedUI:GetDescendants()) do
 local path=relativePath(expected,expectedUI)
 local actual=assert(byPath[path],'Missing original UI object '..path)
 assert(actual.ClassName==expected.ClassName,'UI type changed '..path)
 if expected:IsA('GuiObject') then
  guiObjects+=1
  for _,property in ipairs({'Size','Position','AnchorPoint','Rotation','ZIndex','Visible','BackgroundColor3','BackgroundTransparency'}) do
   assert(actual[property]==expected[property],'Original UI design changed '..path..'.'..property)
  end
 end
 if expected:IsA('ImageLabel') or expected:IsA('ImageButton') then
  assert(actual.Image==expected.Image and actual.ImageColor3==expected.ImageColor3,'Original UI image changed '..path)
 end
 if expected:IsA('TextLabel') or expected:IsA('TextButton') then
  for _,property in ipairs({'Text','TextSize','Font','TextColor3','TextScaled','TextWrapped'}) do assert(actual[property]==expected[property],'Original UI text style changed '..path) end
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
  for _,property in ipairs({'CFrame','Size','Color','Material','MaterialVariant','Transparency','CanCollide'}) do
   assert(d[property]==expected[property],'Map source changed '..d:GetFullName()..'.'..property)
  end
  if d:IsA('MeshPart') then assert(d.MeshId==expected.MeshId and d.TextureID==expected.TextureID,'Map mesh changed') end
  originalParts[d:GetAttribute('HotelSourceId')]=nil
 end
end
assert(next(originalParts)==nil,'Missing geometry from supplied map')
assert(parts==map:GetAttribute('SourcePartCount'),'Map part count mismatch')
for _,d in ipairs(ui:GetDescendants()) do assert(not d:IsA('BasePart') and not d:IsA('LuaSourceContainer'),'UI package depends on map/code') end
local scripts=0
for _,d in ipairs(dm:GetDescendants()) do
 assert(not d:IsA('Tool'),'Weapon tool in release')
 if d:IsA('LuaSourceContainer') then scripts+=1;luau.load(d.Source,{debugName=d:GetFullName()}) end
end
assert(not dm:GetService('ServerStorage'):FindFirstChild('OriginalWorld'),'Old mansion bundled into new map')
assert(dm:GetService('StarterPlayer').CameraMode==R.Enum.CameraMode.Classic,'Wrong camera mode')
assert(dm:GetService('StarterPlayer').CameraMinZoomDistance>=8,'First person enabled')
print('HOTEL_FILE_VERIFIED '..serde.encode('json',{parts=parts,originalGuiObjects=guiObjects,screens=#ui:GetChildren(),scripts=scripts,separateMapAndUI=true}))
