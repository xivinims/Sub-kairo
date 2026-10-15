local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local house=world.Amenities.RiversideGarden.WaterCottage
 local raw=game:GetService("AssetService"):LoadAssetAsync(15855506991)local model=assert(raw:FindFirstChild("RadioShop"))
 local radio=model:Clone()radio.Name="PersonalRadio"radio:SetAttribute("SourceAssetId",15855506991)radio.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,d in ipairs(radio:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("ProximityPrompt")or d:IsA("JointInstance")then d:Destroy()end end
 local cf,size=radio:GetBoundingBox()radio:PivotTo(radio:GetPivot()-Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z))radio.PrimaryPart=nil radio.WorldPivot=CFrame.identity
 radio:PivotTo(CFrame.new(house:GetAttribute("RadioPosition")))radio.Parent=house
 for _,p in ipairs(radio:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=true p.CanTouch=false end end
 local root=assert(radio:FindFirstChildOfClass("MeshPart"))
 local prompt=Instance.new("ProximityPrompt")prompt.Name="OpenPersonalMusic"prompt.ActionText="Ouvir música"prompt.ObjectText="Rádio"prompt.HoldDuration=0 prompt.MaxActivationDistance=7 prompt.RequiresLineOfSight=false prompt.Parent=root
 raw:Destroy()
 local old=runtime:FindFirstChild("MusicListening")if old then old:Destroy()end
 local remote=Instance.new("RemoteEvent")remote.Name="MusicListening"remote.Parent=runtime
 runtime:SetAttribute("MusicPlayback","LocalOnly")return{sourceAssetId=15855506991,radioMeshes=8,serverSounds=0}
end
return B
