local C=require(game.ReplicatedStorage.FalloutConfig)
local R=require(game.ServerScriptService.FalloutRuntime.Rules)
assert(C.RoundSeconds==600 and C.IntermissionSeconds==90 and C.MaxPlayers==10 and C.TeamSize==5)
assert(workspace.CombatMap:GetAttribute('SourceAssetId')=='8438960542','Map source mismatch')
assert(workspace.Lobby:GetAttribute('SourceAssetId')=='95512398319263','Lobby source mismatch')
assert(workspace.Lobby.Shop:GetAttribute('SourceAssetId')=='12987749061','Shop source mismatch')
assert(workspace:GetAttribute('LobbyGrassDarkened')>0,'Grass was not darkened')
assert(workspace.Shopkeeper:GetAttribute('OwnerAvatarUserId')==8344738123)
assert(workspace.Shopkeeper.Humanoid.RigType==Enum.HumanoidRigType.R6)
assert(workspace.Shopkeeper.Head:FindFirstChild('gui') and game.ReplicatedStorage:FindFirstChild('DialogModule'))
assert(#game.ReplicatedStorage.FalloutNpcClips:GetChildren()==4)
for _,name in ipairs({'Team1','Team2','Lobby'}) do
 local folder=workspace.FalloutSpawns[name];assert(#folder:GetChildren()==(name=='Lobby' and 10 or 5))
 for _,point in ipairs(folder:GetChildren()) do
  local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Include;p.FilterDescendantsInstances={name=='Lobby' and workspace.Lobby or workspace.CombatMap};p.RespectCanCollide=true
  assert(workspace:Raycast(point.Position,Vector3.new(0,-10,0),p),'Spawn has no floor: '..name)
 end
end
assert(#game.ServerStorage.FalloutWeaponTemplates:GetChildren()==#C.Catalog)
for _,item in ipairs(C.Catalog) do local tool=game.ServerStorage.FalloutWeaponTemplates[item.id];assert(tool.Handle:IsA('MeshPart') and tool.Handle.MeshId~='');assert(game.ReplicatedStorage.FalloutItemVisuals:FindFirstChild(item.id)) end
assert(not workspace:FindFirstChild('HotelMap') and not game.ServerStorage:FindFirstChild('HotelMap'))
assert(not game.ServerScriptService:FindFirstChild('StillHereRuntime'))
local startup=game.ServerScriptService.FalloutRuntime:FindFirstChild('StartupSmoke')
if startup then
 assert(#game.Players:GetPlayers()==0,'Startup check must be isolated')
 assert(require(startup)==true,'Server startup failed')
 task.wait(.1)
 assert(workspace:GetAttribute('FalloutServerInitialized'),'Server endpoints were not registered')
 startup:Destroy()
 workspace:SetAttribute('FalloutServerInitialized',nil)
end
local counts={0,0};for i=1,10 do local team=R.team(counts,5,i);assert(team);counts[team]+=1 end;assert(counts[1]==5 and counts[2]==5 and not R.team(counts,5,11))
local dummy=Instance.new('Model');dummy.Name='DamageVerification';local h=Instance.new('Humanoid');h.RequiresNeck=false;h.Parent=dummy;dummy.Parent=workspace;h:TakeDamage(24);assert(h.Health==76,'Native damage did not reduce health');dummy:Destroy()
local summary={ok=true,build=C.Build,version=game.PlaceVersion,mapParts=0,lobbyParts=0,shopParts=0,items=#C.Catalog,grass=workspace:GetAttribute('LobbyGrassDarkened'),npcRig=workspace.Shopkeeper.Humanoid.RigType.Name,owner=workspace.Shopkeeper:GetAttribute('OwnerAvatarUserId'),clips={},spawns={}}
for key,model in pairs({mapParts=workspace.CombatMap,lobbyParts=workspace.Lobby,shopParts=workspace.Lobby.Shop}) do for _,v in ipairs(model:GetDescendants()) do if v:IsA('BasePart') then summary[key]+=1 end end end
for _,clip in ipairs(game.ReplicatedStorage.FalloutNpcClips:GetChildren()) do table.insert(summary.clips,{name=clip.Name,frames=#clip:GetKeyframes()}) end
for _,folder in ipairs(workspace.FalloutSpawns:GetChildren()) do summary.spawns[folder.Name]=tostring(folder:GetChildren()[1].Position) end
assert(summary.mapParts>=680 and summary.shopParts>=30)
return game:GetService('HttpService'):JSONEncode(summary)
