assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"wrong target")
local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer").StarterPlayerScripts
assert(game.PlaceVersion>60,"new version not published")
local rig=SS.NB_StarterCharacterBase
assert(rig.Humanoid.RigType==Enum.HumanoidRigType.R6)
for _,d in ipairs(rig:GetDescendants()) do if d:IsA("BasePart") then assert(not d.Anchored,"anchored rig") end end
assert(#RS.NB_R6Animations:GetChildren()==12)
assert(rig:GetAttribute("NBSourceAssetId")=="14026023204")
assert(SSS.NB_NametagService:GetAttribute("NBSourceAssetId")=="92018365421220")
assert(SSS.NB_NametagService.Nametag:IsA("BillboardGui"))
local map=SS.NB_Maps.Map3_Halloween
assert(map:GetAttribute("BaseAssetId")=="128071741625902" and map:GetAttribute("NBLayoutVersion")==2)
assert(map:GetAttribute("SeasonalOnly")==true)
local parts,models=0,0
for _,d in ipairs(map:GetDescendants()) do if d:IsA("BasePart") then parts+=1 end if d:GetAttribute("NBOriginalModel") then models+=1 end end
assert(parts==945,"unexpected map")
for _,name in ipairs({"RoundLoop","JoinHandler","NB_Server","NB_AIController"}) do local s=SSS:FindFirstChild(name) if s then assert(not s.Enabled,name) end end
for _,name in ipairs({"NBClient","NB_Client"}) do local s=SPS:FindFirstChild(name) if s then assert(not s.Enabled,name) end end
local compiled={}
for _,s in ipairs({SSS.NextbotsRoundServer,SSS.NB_NametagService,SSS.NB_MotionService,SSS.NBServer,SPS.NB_R6MotionController}) do
 assert(s.Enabled,s.Name.." disabled")
 local m=Instance.new("ModuleScript") m.Source="return function()\n"..s.Source.."\nend" m.Parent=SS
 local ok,fn=pcall(require,m) m:Destroy() assert(ok and type(fn)=="function",s.Name) table.insert(compiled,s.Name)
end
assert(SSS.NextbotDirector.Enabled and SPS.NB_NextbotVisibility.Enabled)
assert(SSS.NextbotDirector.Source:find("NBInMap",1,true))
assert(SPS.NB_NextbotVisibility.Source:find("NBInMap",1,true))
assert(game:GetService("StarterGui").NextbotsBrasilUI.NextbotsMenuClient.Enabled)
return {ok=true,version=game.PlaceVersion,rig="R6 unanchored",animations=12,mapParts=parts,originalModels=models,compiled=compiled,nextbotGuards=true,menuEnabled=true}
