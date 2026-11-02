local fs=require("@lune/fs")
local R=require("@lune/roblox")
local p=R.deserializePlace(fs.readFile("r6-test/naruto-archive-v6.rbxl"))
local n=p.ServerStorage.StudioPacks.WallWalkNaruto_R6
local w=n.StarterPlayer:FindFirstChild("WallWalk",true)
assert(w)
local src=w.Source
local lines={}
for line in (src.."\n"):gmatch("(.-)\n") do table.insert(lines,line) end
for i,line in ipairs(lines) do
 if line:find("ToggleChakraFeet",1,true) or line:find("BindAction",1,true)
 or line:find("Chakra",1,true) or line:find("gravity",1,true)
 or line:find("Gravity",1,true) then
  print("L"..i..": "..line:sub(1,200))
 end
end
print("CHAKRA_SOURCE_LINES",#lines)
for i,line in ipairs(lines) do
 if line:find("BindAction",1,true) then
  for j=math.max(1,i-35),math.min(#lines,i+15) do print("CONTEXT "..j..": "..lines[j]:sub(1,240)) end
 end
end