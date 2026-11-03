local S=game:GetService('ServerScriptService');local R=game:GetService('ReplicatedStorage');local Storage=game:GetService('ServerStorage')
local package=R:FindFirstChild('NextbotReference');assert(package,'Missing gameplay package')
local results={placeVersion=game.PlaceVersion,checks={},maps={}}
local function passed(name)table.insert(results.checks,name)end
for _,name in ipairs({'Settings','Emotes','Economy','Equipment','Movement','Rescue','MatchAction'})do assert(package:FindFirstChild(name)and package[name]:IsA('RemoteEvent'),'Missing '..name)end;passed('remotes')
assert(#package.EmoteClips:GetChildren()==19,'Emote count');assert(#package.MovementClips:GetChildren()>=10,'Movement animations');passed('animation payloads')
local Config=require(package.Config);assert(Config.Intermission==90 and Config.RoundDuration==180);passed('90/180 timing')
local policy=require(package.EmotePolicy);local v,status=policy.buy({coins=500},'test',250);assert(v.coins==250 and status=='purchased');assert(select(2,policy.buy(v,'test',250))=='owned');passed('no duplicate debit')
local settings=require(package.SettingsPolicy);local clamped=settings(Config.Settings,{FOV=1e6,GameMusic=-10});assert(clamped.FOV==100 and clamped.GameMusic==0);passed('settings validation')
local safe=true
for _,folder in ipairs({Storage.NBMaps,Storage.NextbotTemplates,package.EmoteClips,package.MovementClips})do
 for _,v in ipairs(folder:GetDescendants())do assert(not v:IsA('LuaSourceContainer'),'Imported executable '..v:GetFullName())end
end;passed('no imported scripts')
local starter=game:GetService('StarterPlayer'):FindFirstChild('StarterCharacter');assert(starter and starter:FindFirstChild('HumanoidRootPart'),'R6 starter rig')
assert(starter.Humanoid.RigType==Enum.HumanoidRigType.R6,'Wrong rig type')
local motors=0;for _,v in ipairs(starter:GetDescendants())do if v:IsA('Motor6D')then assert(v.Part0 and v.Part1,'Unbound joint');motors+=1 end end;assert(motors>=6,'Missing rig joints');passed('R6 joints')
local Maps=require(S.MapService)
for _,name in ipairs(Maps.Names())do
 assert(Maps.Load(name),'Map cannot load: '..name)
 task.wait(.5)
 local points=workspace.RoundSpawns:GetChildren();assert(#points>=2,'Insufficient spawns')
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.ActiveMap.Geometry};rp.RespectCanCollide=true
 for _,p in ipairs(points)do assert(workspace:Raycast(p.Position+Vector3.new(0,.2,0),Vector3.new(0,-1,0),rp),'Spawn has no supporting floor')end
 local paths={}
 for i=2,math.min(#points,4)do
  local path=game:GetService('PathfindingService'):CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
  local ok,err=pcall(function()path:ComputeAsync(points[1].Position+Vector3.new(0,3,0),points[i].Position+Vector3.new(0,3,0))end)
  table.insert(paths,{ok=ok,status=ok and path.Status.Name or tostring(err),waypoints=ok and #path:GetWaypoints()or 0})
 end
 table.insert(results.maps,{name=name,spawns=#points,parts=#workspace.ActiveMap.Geometry:GetDescendants(),paths=paths})
end;passed('map load and grounded spawns')
for _,bot in ipairs(Storage.NextbotTemplates:GetChildren())do
 assert(bot:FindFirstChild('HumanoidRootPart')and bot:FindFirstChildOfClass('Humanoid'),'Invalid bot rig')
 for _,v in ipairs(bot:GetDescendants())do if v:IsA('BasePart')then assert(not v.Anchored,'Anchored bot')end end
end;passed('nextbot rigs')
assert(package:GetAttribute('MenuAtlas')and package:GetAttribute('MenuAtlas')~='','Missing menu art');passed('menu artwork binding')
-- These tests use the real Roblox DataModel and raycasts; no player data is written.
results.assets={}
local content=game:GetService('ContentProvider')
for _,id in ipairs({93112717809068,1836009626,1838591268,1839246711,1847238776})do
 local item=Instance.new('Sound');item.SoundId='rbxassetid://'..id
 local ok,info=pcall(function()return game:GetService('MarketplaceService'):GetProductInfoAsync(id,Enum.InfoType.Asset)end)
 table.insert(results.assets,{id=id,metadata=ok,name=ok and info.Name or tostring(info),assetType=ok and info.AssetTypeId or 0})
 item:Destroy()
end
results.isRunning=game:GetService('RunService'):IsRunning()
return results
