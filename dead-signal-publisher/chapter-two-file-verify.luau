local fs=require('@lune/fs')
local R=require('@lune/roblox')
local place=R.deserializePlace(fs.readFile('/tmp/still-here-chapter-two-verified.rbxl'))
local world=place:GetService('Workspace')
assert(world:GetAttribute('ExperienceChapter')==2,'Published place is not Chapter 2')
assert(world:GetAttribute('DeadSignalBuildId')=='still-here-chapter-two-greenhouse-v2','Wrong Chapter 2 build')
local sources={}
for _,name in ipairs({'ReplicatedFirst','ReplicatedStorage','ServerScriptService'}) do
 for _,item in ipairs(place:GetService(name):GetDescendants()) do
  if item:IsA('LuaSourceContainer') then sources[item.Name]=item.Source end
 end
end
assert(sources.SessionMenuClient and sources.SessionMenuClient:find("request('chapterOne')",1,true),'Return link to Chapter 1 is missing')
assert(sources.SessionLoadingClient and sources.SessionLoadingClient:find('ChapterTwoLoadingArtwork',1,true),'Chapter 2 loading artwork missing')
print('CHAPTER TWO FILE VERIFIED')
