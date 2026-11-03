local Players=game:GetService('Players');local Marketplace=game:GetService('MarketplaceService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference');local remote=package:WaitForChild('Boombox')
local Profiles=require(script.Parent.ProfileService);local last={};local valid={}
local function stop(p)local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local s=r and r:FindFirstChild('NBBoombox');if s then s:Destroy()end;p:SetAttribute('NBMusicId',0)end
remote.OnServerEvent:Connect(function(p,action,id)
 if action=='Stop'then stop(p);return end
 if action=='List'then local v=Profiles.Get(p);if v then remote:FireClient(p,'favorites',v.musicFavorites)end;return end
 if type(id)~='number'or id~=id or id%1~=0 or id<1 or id>9007199254740991 or os.clock()-(last[p]or -10)<2 then return end
 last[p]=os.clock()
 if not valid[id]then local ok,info=pcall(function()return Marketplace:GetProductInfoAsync(id,Enum.InfoType.Asset)end);if not ok or info.AssetTypeId~=3 then remote:FireClient(p,'invalid');return end;valid[id]=true end
 if action=='Favorite'then
  local _,status=Profiles.Mutate(p,function(v)
   for i,n in ipairs(v.musicFavorites)do if n==id then table.remove(v.musicFavorites,i);return true,'saved'end end
   if #v.musicFavorites>=20 then return false,'full'end
   table.insert(v.musicFavorites,id);return true,'saved'
  end)
  local v=Profiles.Get(p);if v then remote:FireClient(p,'favorites',v.musicFavorites)end;return
 end
 if action~='Play'then return end
 local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if not r or not h or h.Health<=0 then return end
 stop(p)
 local s=Instance.new('Sound');s.Name='NBBoombox';s.SoundId='rbxassetid://'..id;s.Volume=.45;s.Looped=true;s.RollOffMaxDistance=45;s.SoundGroup=game:GetService('SoundService'):FindFirstChild('NB_BoomboxVolume');s.Parent=r;s:Play();p:SetAttribute('NBMusicId',id)
 remote:FireClient(p,'playing',id)
end)
Players.PlayerRemoving:Connect(function(p)last[p]=nil end)
