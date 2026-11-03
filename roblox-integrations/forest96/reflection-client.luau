local player=game.Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local Mirror=require(runtime:WaitForChild("RiverReflection"))
local reflection local character local elapsed=0 local scan=0 local point
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
game:GetService("RunService").Heartbeat:Connect(function(dt)
 elapsed+=dt scan+=dt if elapsed<.125 then return end elapsed=0 local camera=workspace.CurrentCamera local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")
 if not camera or not root then if reflection then reflection.hide()end return end
 if c~=character then if reflection then reflection.destroy()end character=c reflection=Mirror.create(c,player:WaitForChild("PlayerGui"),workspace)scan=1 end
 if player:GetAttribute("TreeWorldMenuOpen")then reflection.hide()return end
 if scan>.5 then scan=0 point=nil
  for _,r in ipairs({0,3,6,10,14})do for k=0,7 do local a=k*math.pi/4 local x,z=root.Position.X+math.cos(a)*r,root.Position.Z+math.sin(a)*r
   local h=workspace:Raycast(Vector3.new(x,150,z),Vector3.yAxis*-250,ray)
   if h and h.Material==Enum.Material.Water then local safe=true
    for _,dx in ipairs({-4,4})do for _,dz in ipairs({-6,6})do local edge=workspace:Raycast(Vector3.new(x+dx,150,z+dz),Vector3.yAxis*-250,ray)if not edge or edge.Material~=Enum.Material.Water then safe=false end end end
    if safe then point=h.Position break end
   end
  end if point then break end end
 end
 if point then reflection.update(point,camera.CFrame)else reflection.hide()end
end)
script.Destroying:Connect(function()if reflection then reflection.destroy()end end)
