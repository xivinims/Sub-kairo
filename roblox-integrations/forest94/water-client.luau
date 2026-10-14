local Run=game:GetService("RunService")local Collection=game:GetService("CollectionService")local UIS=game:GetService("UserInputService")
local textures={}local nearby={}local scan=0 local elapsed=0 local cap=UIS.TouchEnabled and 32 or 64
local function add(texture)if texture:IsA("Texture")then textures[texture]=true end end
for _,t in ipairs(Collection:GetTagged("TreeWorldWaterTexture"))do add(t)end
Collection:GetInstanceAddedSignal("TreeWorldWaterTexture"):Connect(add)
Collection:GetInstanceRemovedSignal("TreeWorldWaterTexture"):Connect(function(t)textures[t]=nil end)
Run.Heartbeat:Connect(function(dt)
 scan+=dt elapsed+=dt if elapsed<.1 then return end elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end local pos=camera.CFrame.Position
 if scan>1 then scan=0 table.clear(nearby)
  for t in pairs(textures)do if t.Parent and t.Parent:IsA("BasePart")and(t.Parent.Position-pos).Magnitude<80 then nearby[#nearby+1]=t end end
  table.sort(nearby,function(a,b)return(a.Parent.Position-pos).Magnitude<(b.Parent.Position-pos).Magnitude end)
  while #nearby>cap do table.remove(nearby)end
 end
 local phase=(workspace:GetServerTimeNow()*.32)%14
 for _,t in ipairs(nearby)do if t.Parent then t.OffsetStudsU=(t.Parent.Position.X+phase)%14 t.OffsetStudsV=(t.Parent.Position.Z+phase*.48)%14 end end
end)
