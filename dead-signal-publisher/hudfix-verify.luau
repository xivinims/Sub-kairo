local runtime=game.ServerScriptService.FalloutRuntime
local C=require(game.ReplicatedStorage.FalloutConfig)
local UI=require(game.ReplicatedStorage.FalloutUI)
assert(workspace:GetAttribute('FalloutHUDRevision')=='hud-shop-npc-v2')
assert(workspace:GetAttribute('FalloutNametagBuild')=='nametags-v1')
assert(C.MaxPlayers==10 and C.TeamSize==5 and C.RoundSeconds==600 and C.IntermissionSeconds==90)
local before=protectedSnapshot()
local fixture=Instance.new('Folder')
local board=UI.scoreboard(fixture,{Color3.new(0,0,1),Color3.new(1,0,0)})
assert(board.root.Size.X.Offset==430 and board.root.Size.Y.Offset==42)
local portraits=0
for _,child in ipairs(board.root:GetDescendants()) do
 if child:IsA('ImageLabel') then portraits+=1 end
 if child:IsA('TextLabel') then assert(not child.Text:find('×',1,true) and child.Name~='DeathMark') end
end
assert(portraits==10)
UI.fitScoreboard(board,Vector2.new(896,414),Rect.new(240,0,840,58))
assert(board.screen.ScreenInsets==Enum.ScreenInsets.TopbarSafeInsets and board.scale.Scale==1)
UI.fitScoreboard(board,Vector2.new(640,360),Rect.new(220,0,610,58))
assert(board.scale.Scale<1 and board.scale.Scale>.8 and not board.fallback)
UI.fitScoreboard(board,Vector2.new(390,844),Rect.new(180,0,360,58))
assert(board.fallback and board.scale.Scale<=1 and board.root.Position.Y.Offset==58)
assert(UI.money(0)=='0' and UI.money(1234567.9)=='1.234.567' and UI.money(-30)=='0')
local wallet=UI.wallet(fixture);assert(wallet.balance.Text=='…' and wallet.root:FindFirstChild('CoinIcon'))
local icons=0
for _,item in ipairs(C.Catalog) do
 local holder=Instance.new('Frame');holder.Parent=fixture
 local icon=UI.itemIcon(holder,item);assert(#icon:GetChildren()>=2,'Missing fallback icon: '..item.id)
 local viewport=Instance.new('ViewportFrame');viewport.Size=UDim2.fromOffset(96,82);viewport.Parent=holder
 local model=UI.preview(viewport,game.ReplicatedStorage.FalloutItemVisuals[item.id],item)
 assert(viewport.CurrentCamera and model.Parent:IsA('WorldModel') and model.Transparency==0 and model.LocalTransparencyModifier==0)
 local camera=viewport.CurrentCamera;local tan=math.tan(math.rad(camera.FieldOfView/2));local aspect=96/82
 for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
  local world=model.CFrame:PointToWorldSpace(Vector3.new(x*model.Size.X/2,y*model.Size.Y/2,z*model.Size.Z/2))
  local point=camera.CFrame:PointToObjectSpace(world)
  assert(-point.Z>.05 and math.abs(point.X)<(-point.Z*tan*aspect) and math.abs(point.Y)<(-point.Z*tan),'Item icon cropped: '..item.id)
 end end end
 icons+=1
end
fixture:Destroy()
local npc=workspace.Shopkeeper
assert(npc:GetAttribute('PlacementVersion')=='serving-window-v2')
assert(npc:GetAttribute('OwnerAvatarUserId')==C.OwnerUserId and npc.Humanoid.RigType==Enum.HumanoidRigType.R6)
assert(npc.PrimaryPart.Anchored and not npc.Humanoid.EvaluateStateMachine)
assert(npc.Head:FindFirstChild('gui') and npc:FindFirstChild('ProximityPrompt'))
local window=workspace.Lobby.Shop:FindFirstChild('WindowFrame',true)
local lateral=math.abs((npc.Head.Position-window.Position):Dot(window.CFrame.RightVector))
assert(lateral<.2,'NPC not aligned with the serving window')
local feet=math.min(npc['Left Leg'].Position.Y-npc['Left Leg'].Size.Y/2,npc['Right Leg'].Position.Y-npc['Right Leg'].Size.Y/2)
assert(math.abs(feet-npc:GetAttribute('FloorHeight'))<.06,'NPC is floating or underground')
local poseJoints=0
for _,joint in ipairs(npc:GetDescendants()) do if joint:IsA('Motor6D') and joint.Part0 and joint.Part1 then poseJoints+=1 end end
assert(poseJoints==6)
local smoke=Instance.new('ModuleScript');smoke.Name='WalletStartupCheck';smoke.Source=runtime.Server.Source..'\nreturn true';smoke.Parent=runtime
local oldInitialized=workspace:GetAttribute('FalloutServerInitialized')
assert(require(smoke)==true);smoke:Destroy();workspace:SetAttribute('FalloutServerInitialized',oldInitialized)
assert(protectedSnapshot()==before,'Verification mutated protected content')
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build='hud-shop-npc-v2',preserved=before,portraits=portraits,scoreSize={430,42},icons=icons,npcRig=npc.Humanoid.RigType.Name,npcPosition={npc.PrimaryPart.Position.X,npc.PrimaryPart.Position.Y,npc.PrimaryPart.Position.Z},npcFloorGap=feet-npc:GetAttribute('FloorHeight'),npcWindowOffset=lateral,npcJoints=poseJoints,wallet='transactional-integer-coins'})
