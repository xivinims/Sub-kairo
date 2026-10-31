local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-hotel-verified.rbxl'))
assert(dm:GetService('Workspace'):GetAttribute('DeadSignalBuildId')=='still-here-hotel-instruments-v6','Hotel build id is not v6')
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
 local rain=d:FindFirstAncestor('Rain')~=nil
 if d:IsA('BasePart') and not rain and not d:GetFullName():find('AK-47 Spawner',1,true) then originalParts[id]=d end
end
local parts=0
for _,d in ipairs(map:GetDescendants()) do
 assert(not d:IsA('ScreenGui') and not d:IsA('LuaSourceContainer') and not d:IsA('Tool') and not d:IsA('ClickDetector') and not d:IsA('ProximityPrompt'),'Map contains UI/code/weapon/legacy interaction '..d:GetFullName())
 assert(not (d:IsA('Model') and d.Name=='Rain'),'Orphaned rain model remains in map')
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
local shipped={MapInteractions='mystery-map-interactions.luau',PoolGame='pool-game.luau',PianoGame='piano-game.luau',HotelReceptionist='hotel-receptionist.luau',WorldInitializer='hotel-initialize.luau',PlayerSettings='settings-server.luau',SettingsSchema='settings-schema.luau',SessionInterface='session-interface.luau',MysteryUIClient='mystery-ui-client.luau',PoolGameClient='pool-game-client.luau',PianoGameClient='piano-game-client.luau',HotelReceptionistClient='hotel-receptionist-client.luau',SessionLoadingClient='session-loading-client.luau',PortugueseText='original-portuguese-text.luau'}
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
local receptionistRig=dm:GetService('ServerStorage'):FindFirstChild('ReceptionistRigTemplate')
if receptionistRig then
 assert(receptionistRig:FindFirstChildOfClass('Humanoid') and receptionistRig:FindFirstChild('HumanoidRootPart',true),'Optional animation sample rig is invalid')
 for _,object in ipairs(receptionistRig:GetDescendants()) do assert(not object:IsA('BaseScript'),'Unreviewed NPC-pack script was copied') end
end
local animationRigType=dm:GetService('Workspace'):GetAttribute('NPCAnimationRigType')
assert(animationRigType=='R6' or animationRigType=='R15' or animationRigType=='Unknown','NPC animation source rig type was not recorded')
local receptionistAnimations=assert(dm:GetService('ServerStorage'):FindFirstChild('ReceptionistAnimations'),'NPC animation pack was not assembled')
assert(receptionistAnimations:FindFirstChild('Idle'),'NPC animation pack has no idle')
for _,name in ipairs({'IdleToActive','ActiveIdle','ActiveToIdle'}) do
 local animation=receptionistAnimations:FindFirstChild(name)
 if animation then
  assert(animation:IsA('Animation'),'NPC animation track has the wrong type '..name)
  local idOK,animationId=pcall(function() return animation.AnimationId end)
  if idOK then assert(animationId~='','NPC animation track is empty '..name) end
 end
end
assert(dm:GetService('StarterPlayer').CameraMode==R.Enum.CameraMode.Classic,'Wrong camera mode')
assert(dm:GetService('StarterPlayer').CameraMinZoomDistance>=8,'First person enabled')
assert(dm:GetService('StarterPlayer').CharacterWalkSpeed==16,'Player walk speed was not normalized')
assert(dm:GetService('ReplicatedStorage').SessionInterface.Source:find('IgnoreGuiInset=true',1,true),'Settings do not fill the screen')
assert(dm:GetService('ReplicatedStorage').SessionInterface.Source:find('Position=UDim2.fromScale(0,0)',1,true),'Settings do not anchor to the left edge')
assert(dm:GetService('ReplicatedStorage').SessionInterface.Source:find('function M.Save()',1,true),'Settings do not autosave')
assert(not dm:GetService('ReplicatedStorage').SessionInterface.Source:find('APLICAR',1,true),'Manual apply button remains in settings')
for _,label in ipairs({'JOGO','CONTROLES','TELA','ÁUDIO','IDIOMA','RESTAURAR PADRÕES','SALVANDO AUTOMATICAMENTE'}) do assert(dm:GetService('ReplicatedStorage').SessionInterface.Source:find(label,1,true),'Settings section missing '..label) end
print('HOTEL_FILE_VERIFIED '..serde.encode('json',{parts=parts,originalGuiObjects=guiObjects,screens=#ui:GetChildren(),scripts=scripts,separateMapAndUI=true}))

