local fs=require('@lune/fs')
local R=require('@lune/roblox')
local source='/tmp/still-here-original.rbxl'
local output='/tmp/still-here-chapter-two.rbxl'
local place=R.deserializePlace(fs.readFile(source))
local world=place:GetService('Workspace')
assert(world:GetAttribute('DeadSignalBuildId')=='still-here-chapter-two-greenhouse-v2','Wrong source build')
world:SetAttribute('ExperienceChapter',2)
world:SetAttribute('DeadSignalBuildId','still-here-chapter-two-greenhouse-v2')
assert(world:GetAttribute('ExperienceChapter')==2,'Chapter 2 marker was not set')
fs.writeFile(output,R.serializePlace(place))
print('CHAPTER TWO PLACE READY '..output)
