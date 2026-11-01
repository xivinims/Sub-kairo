local Players=game:GetService('Players')
local Shopkeeper={}
function Shopkeeper.refresh()
 local shop=workspace.Lobby.Shop
 local floor=assert(shop:FindFirstChild('Floor',true),'Shop floor missing')
 local window=assert(shop:FindFirstChild('WindowFrame',true),'Serving window missing')
 local counter=assert(shop:FindFirstChild('Yeah',true),'Counter missing')
 local old=workspace:FindFirstChild('Shopkeeper')
 local C=require(game.ReplicatedStorage.FalloutConfig)
 local description=Players:GetHumanoidDescriptionFromUserIdAsync(C.OwnerUserId)
 local npc=Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
 description:Destroy();npc.Name='Shopkeeper'
 local humanoid=assert(npc:FindFirstChildOfClass('Humanoid'))
 assert(humanoid.RigType==Enum.HumanoidRigType.R6,'Shopkeeper must be R6')
 humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 humanoid.AutoRotate=false;humanoid.EvaluateStateMachine=false
 for _,item in ipairs(npc:GetDescendants()) do
  if item:IsA('LuaSourceContainer') then item:Destroy()
  elseif item:IsA('BasePart') then item.Anchored=false;item.CanCollide=false;item.CanTouch=false;item.AssemblyLinearVelocity=Vector3.zero end
 end
 local root=assert(npc:FindFirstChild('HumanoidRootPart'));npc.PrimaryPart=root;root.Anchored=true;root.PivotOffset=CFrame.identity
 local front=Vector3.new(window.CFrame.LookVector.X,0,window.CFrame.LookVector.Z).Unit
 local spawn=workspace.FalloutSpawns.Lobby:GetChildren()[1]
 if (spawn.Position-window.Position):Dot(front)<0 then front=-front end
 local halfDepth=(math.abs(front:Dot(counter.CFrame.RightVector))*counter.Size.X+math.abs(front:Dot(counter.CFrame.LookVector))*counter.Size.Z)/2
 local behind=(counter.Position-window.Position):Dot(front)-halfDepth-.9
 local position=window.Position+front*math.min(behind,-1.05)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={floor}
 local ground=workspace:Raycast(Vector3.new(position.X,floor.Position.Y+3,position.Z),Vector3.new(0,-8,0),params)
 assert(ground and ground.Normal.Y>.9,'Shopkeeper has no flat floor')
 local feet=math.min(npc['Left Leg'].Position.Y-npc['Left Leg'].Size.Y/2,npc['Right Leg'].Position.Y-npc['Right Leg'].Size.Y/2)
 local rootHeight=root.Position.Y-feet
 position=Vector3.new(position.X,ground.Position.Y+rootHeight+.025,position.Z)
 npc:PivotTo(CFrame.lookAt(position,position+front))
 npc:SetAttribute('OwnerAvatarUserId',C.OwnerUserId)
 npc:SetAttribute('AnimationPackAssetId','86582491164528')
 npc:SetAttribute('PlacementVersion','serving-window-v2')
 npc:SetAttribute('FloorHeight',ground.Position.Y)
 npc:SetAttribute('ServingWindowX',window.Position.X)
 npc:SetAttribute('DialogueName',old and old:GetAttribute('DialogueName') or 'ch_ckz2n')
 npc.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local oldGui=old and old:FindFirstChild('Head') and old.Head:FindFirstChild('gui')
 local source=oldGui or game.ServerStorage:FindFirstChild('NpcDialogueGui')
 local gui=assert(source,'NPC dialogue template missing'):Clone();gui.Name='gui';gui.Adornee=npc.Head;gui.Parent=npc.Head
 local nameLabel=gui:FindFirstChild('name');if nameLabel then nameLabel.Text=npc:GetAttribute('DialogueName') end
 local prompt=Instance.new('ProximityPrompt');prompt.Name='ProximityPrompt';prompt.ActionText='Conversar';prompt.ObjectText='Armeiro';prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=npc
 game:GetService('CollectionService'):AddTag(prompt,'NPCprompt')
 if old then old:Destroy() end
 npc.Parent=workspace
 return npc
end
return Shopkeeper
