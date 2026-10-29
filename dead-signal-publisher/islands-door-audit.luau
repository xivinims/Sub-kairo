local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
local function structure(o,depth) local r={name=o.Name,class=o.ClassName};if depth>0 then r.children={};for _,c in ipairs(o:GetChildren()) do table.insert(r.children,structure(c,depth-1)) end end;return r end
local dm=R.deserializePlace(fs.readFile('/tmp/asset-15864801103.rbxl'));local RS=dm:GetService('ReplicatedStorage')
print('FPS STRUCTURE '..J.encode('json',{weapons=structure(RS.Game.Weapons,3),viewmodels=structure(RS.Assets.Models.Viewmodels,3),animations=structure(RS.Assets.Animations.Weapons.M4A1,3)}))
local sequences={}
for _,d in ipairs(dm:GetDescendants()) do if d:IsA('KeyframeSequence') then table.insert(sequences,{path=d:GetFullName(),frames=#d:GetChildren()}) end end
print('SEQUENCES '..J.encode('json',sequences))
local h=R.deserializePlace(fs.readFile('/tmp/asset-13037825880.rbxl'));print('ENTRANCE '..J.encode('json',structure(h:GetService('StarterGui').Entrance,5)))
