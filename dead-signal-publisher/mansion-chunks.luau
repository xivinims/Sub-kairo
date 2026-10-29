local Players=game:GetService('Players');local SS=game:GetService('ServerStorage')
local M={};local active={};local started=false
function M.Inside(pos)
 return pos.X> -140 and pos.X<140 and pos.Z> -180 and pos.Z< -27 and pos.Y> -190 and pos.Y<90
end
function M.Warm(position,radius)
 local catalog=SS:WaitForChild('MansionCatalog');local world=workspace.Islands.mansion
 for _,cell in ipairs(catalog:GetChildren()) do
  local center=cell:GetAttribute('CellCenter');local kind=cell:GetAttribute('Section')
  if center and (Vector2.new(center.X-position.X,center.Z-position.Z)).Magnitude<(radius or 160)+46 then
   if not active[cell.Name] or not active[cell.Name].Parent then local clone=cell:Clone();clone.Parent=world;active[cell.Name]=clone end
  end
 end
end
function M.Start()
 if started then return end;started=true
 task.spawn(function()
  while task.wait(1) do
   local desired={};local catalog=SS.MansionCatalog
   for _,p in ipairs(Players:GetPlayers()) do
    local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
    if root then
     local inside=M.Inside(root.Position);p:SetAttribute('InsideMansion',inside)
     for _,cell in ipairs(catalog:GetChildren()) do
      local center=cell:GetAttribute('CellCenter');local exterior=cell:GetAttribute('Section')=='Forest'
      local distance=Vector2.new(center.X-root.Position.X,center.Z-root.Position.Z).Magnitude
      local radius=exterior and (inside and 85 or 190) or 150
      if distance<radius+46 then desired[cell.Name]=true end
     end
    end
   end
   local spawn=workspace.IslandDestinations.forestCurrent
   for _,cell in ipairs(catalog:GetChildren()) do
    local center=cell:GetAttribute('CellCenter')
    if (Vector2.new(center.X-spawn.Position.X,center.Z-spawn.Position.Z)).Magnitude<90 then desired[cell.Name]=true end
   end
   for name in pairs(desired) do if not active[name] or not active[name].Parent then local clone=catalog[name]:Clone();clone.Parent=workspace.Islands.mansion;active[name]=clone;task.wait() end end
   for name,cell in pairs(active) do if not desired[name] then cell:Destroy();active[name]=nil end end
  end
 end)
end
return M
