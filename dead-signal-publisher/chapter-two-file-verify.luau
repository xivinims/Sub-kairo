local fs=require('@lune/fs')
local R=require('@lune/roblox')
local place=R.deserializePlace(fs.readFile('/tmp/still-here-chapter-two-verified.rbxl'))
local world=place:GetService('Workspace')
assert(world:GetAttribute('ExperienceChapter')==2,'Published greenhouse place internal marker changed')
assert(world:GetAttribute('DisplayEpisodeNumber')==1,'Promoted place is not Episode 1')
assert(world:GetAttribute('DeadSignalBuildId')=='still-here-chapter-two-greenhouse-v2','Wrong Chapter 2 build')
local sources={}
for _,name in ipairs({'ReplicatedFirst','ReplicatedStorage','ServerScriptService'}) do
 for _,item in ipairs(place:GetService(name):GetDescendants()) do
  if item:IsA('LuaSourceContainer') then sources[item.Name]=item.Source end
 end
end
assert(sources.SessionMenuClient and sources.SessionMenuClient:find("backButton.Visible=experienceChapter==2 and displayEpisodeNumber~=1",1,true),'Promoted Episode 1 still shows a return link')
assert(sources.SessionLoadingClient and sources.SessionLoadingClient:find('ChapterTwoLoadingArtwork',1,true) and sources.SessionLoadingClient:find('displayEpisodeNumber',1,true),'Promoted Episode 1 loading artwork/label missing')
print('CHAPTER TWO FILE VERIFIED')
