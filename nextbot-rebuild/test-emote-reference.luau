-- Data preservation/structure test. This does not certify a rendered client UI.
local fs=require('@lune/fs');local R=require('@lune/roblox');local serde=require('@lune/serde')
local dm=R.Instance.new('DataModel');local package=R.Instance.new('Folder');package.Parent=dm:GetService('ReplicatedStorage')
local template=require('./ImportEmoteReference').Import(package)
local artwork=template.EmoteWheel:GetChildren();assert(#artwork>0,'source wheel artwork missing')
for i=1,4 do
 local slot=template.EmoteWheel['Slot'..i]
 assert(slot:IsA('TextButton')and slot.EmoteViewport:IsA('ViewportFrame')and slot.EmoteName:IsA('TextLabel'))
 assert(slot:FindFirstChild('AddEmoteButton',true),'source add button missing')
end
for _,v in ipairs(template:GetDescendants())do
 assert(not v:IsA('LuaSourceContainer')and not v:IsA('RemoteEvent')and not v:IsA('RemoteFunction'),'executable reference content imported')
end
local parts={};for i=0,6 do parts[#parts+1]=fs.readFile('assets/emotes.part'..i)end
local original=table.concat(parts);assert(#original==1210893,'source pack size changed')
local roots=R.deserializeModel(original);local sequences={};local keyframes,poses=0,0
for _,root in ipairs(roots)do for _,v in ipairs(root:GetDescendants())do
 if v:IsA('KeyframeSequence')then sequences[#sequences+1]=v end
 if v:IsA('Keyframe')then keyframes+=1 end
 if v:IsA('Pose')then poses+=1 end
end end
assert(#sequences==19 and keyframes==4453 and poses==33690,'source pack animation data changed')
local compared=0
if fs.isFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl')then
 local built=R.deserializePlace(fs.readFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl')).ReplicatedStorage.NextbotReference
 assert(#built.EmoteClips:GetChildren()==19 and built.EmoteSourceRig:FindFirstChildOfClass('Humanoid'),'built emote source payload incomplete')
 local function compare(a,b)
  assert(a.ClassName==b.ClassName and a.Name==b.Name,'pose tree changed')
  if a:IsA('Keyframe')then assert(a.Time==b.Time,'keyframe timestamp changed')end
  if a:IsA('Pose')then assert(a.CFrame==b.CFrame and a.Weight==b.Weight and a.EasingStyle==b.EasingStyle and a.EasingDirection==b.EasingDirection,'authored pose changed')end
  local ac,bc=a:GetChildren(),b:GetChildren();assert(#ac==#bc,'pose children changed')
  for i=1,#ac do compare(ac[i],bc[i])end
 end
 for _,sequence in ipairs(sequences)do
  local id='pack_'..sequence.Name:lower():gsub('[^%w]+','_');local copy=built.EmoteClips:FindFirstChild(id);assert(copy,'built clip missing '..id)
  assert(copy.Loop==sequence.Loop and copy.Priority==sequence.Priority,'sequence playback metadata changed')
  local name=copy.Name;copy.Name=sequence.Name;compare(sequence,copy);copy.Name=name;compared+=1
 end
end
print(serde.encode('json',{referenceSlots=4,executableReferenceImported=false,sequences=#sequences,keyframes=keyframes,poses=poses,comparedBuiltClips=compared,visualClientTest=false}))
