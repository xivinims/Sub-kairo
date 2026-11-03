local fs=require('@lune/fs');local R=require('@lune/roblox');local S=require('@lune/serde')
local g=R.deserializePlace(fs.readFile('r6-test/arena.rbxl'))
assert(g.StarterPlayer.StarterPlayerScripts.DynamicMenu.Source==fs.readFile('r6-test/menu-client.luau'),'Previous menu source mismatch')
local arena=g.Workspace.TestArena
for _,n in ipairs({'Welcome','WallrunSign','BotsSign','DialogueSign'}) do local p=arena:FindFirstChild(n);if p then p:Destroy() end end
local function grid(p,face,width,height)
 local ui=R.Instance.new('SurfaceGui');ui.Name='TestGrid';ui.Face=face;ui.CanvasSize=R.Vector2.new(width*16,height*16);ui.LightInfluence=1;ui.Parent=p
 local function line(x,y,w,h)
  local f=R.Instance.new('Frame');f.BorderSizePixel=0;f.BackgroundColor3=R.Color3.fromRGB(80,87,94);f.BackgroundTransparency=.5;f.Position=R.UDim2.fromOffset(x,y);f.Size=R.UDim2.fromOffset(w,h);f.Parent=ui
 end
 for x=0,width*16,64 do line(x,0,1,height*16) end
 for y=0,height*16,64 do line(0,y,width*16,1) end
end
for _,p in ipairs(arena:GetChildren()) do if p:IsA('BasePart') and not p:IsA('SpawnLocation') then
 p.Color=R.Color3.fromRGB(166,173,181);p.Material=R.Enum.Material.SmoothPlastic
 local s=p.Size;grid(p,R.Enum.NormalId.Top,s.X,s.Z)
 if p.Name~='Floor' then grid(p,R.Enum.NormalId.Front,s.X,s.Y);grid(p,R.Enum.NormalId.Back,s.X,s.Y);grid(p,R.Enum.NormalId.Left,s.Z,s.Y);grid(p,R.Enum.NormalId.Right,s.Z,s.Y) end
end end
local roots=R.deserializeModel(fs.readFile('../upload/20+ R6 Emote Animations.rbxm'))
local rs=g:GetService('ReplicatedStorage');local old=rs:FindFirstChild('OriginalR6Emotes');if old then old:Destroy() end
local container=R.Instance.new('Folder');container.Name='OriginalR6Emotes';container.Parent=rs
local count=0
local function snapshot(root)
 local rows={}
 for _,x in ipairs(root:GetDescendants()) do
  if x:IsA('KeyframeSequence') then count+=1 end
  if x:IsA('Pose') then table.insert(rows,{path=x:GetFullName(),cf={x.CFrame:GetComponents()},weight=x.Weight,style=x.EasingStyle.Name,direction=x.EasingDirection.Name})
  elseif x:IsA('Keyframe') then table.insert(rows,{path=x:GetFullName(),time=x.Time}) end
 end
 return S.encode('json',rows)
end
for _,root in ipairs(roots) do local before=snapshot(root);local clone=root:Clone();assert(snapshot(clone)==before,'Animation changed during import');clone.Parent=container end
-- Count each sequence once, snapshot executes twice to compare original and clone.
g.Workspace:SetAttribute('OriginalR6EmoteCount',count/2);g.Workspace:SetAttribute('TestGridRevision','clean-grid-v1')
fs.writeFile('r6-test/arena.rbxl',R.serializePlace(g));print('Imported original R6 emotes: '..count/2)
