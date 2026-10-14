local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 local raw=game:GetService("AssetService"):LoadAssetAsync(10080695893)local set=assert(raw:FindFirstChild("Utah Teapot Set"))
 local cup=assert(set.Cup)local pot=assert(set.Teapot)local spoon=assert(set.Spoon)
 assert(cup.MeshId=="rbxassetid://10080681533"and pot.MeshId=="rbxassetid://10080686163")
 local report={tables=0,cups=0,teapots=0,sourceAssetId=10080695893}
 local corners={}
 for _,m in ipairs(world:GetDescendants())do if m:IsA("Model")and m:FindFirstChild("AntiqueTeaTable")then corners[#corners+1]=m end end
 local function put(src,parent,cf,scale,name)
  local p=src:Clone()p.Name=name or src.Name p.Size*=scale p.CFrame=cf p.Anchored=true p.CanCollide=false p.CanQuery=true p.CanTouch=false p.Color=Color3.fromRGB(238,238,231)p:SetAttribute("SourceAssetId",10080695893)p.Parent=parent return p
 end
 for _,corner in ipairs(corners)do
  for _,d in ipairs(corner:GetChildren())do if d.Name=="TeaCup"or d.Name=="Teapot"or d.Name=="SilverSpoon"or d.Name=="UtahSpoon"then d:Destroy()end end
  local top=assert(corner.AntiqueTeaTable:FindFirstChild("table",true))local y=top.Position.Y+top.Size.Y*.5+.04 local x,z=top.Position.X,top.Position.Z
  for i=0,3 do local a=i*math.pi*.5 local m=Instance.new("Model")m.Name="TeaCup"m:SetAttribute("SourceAssetId",10080695893)m.Parent=corner
   local scale=.82 local p=put(cup,m,CFrame.new(x+math.cos(a)*1.7,y+cup.Size.Y*scale*.5,z+math.sin(a)*1.7)*CFrame.Angles(0,-a,0),scale,"UtahCup")m.PrimaryPart=p
   local click=Instance.new("ClickDetector")click.Name="TakeCup"click.MaxActivationDistance=9 click.Parent=m C:AddTag(click,"TreeWorldCupClick")report.cups+=1
   put(spoon,corner,CFrame.new(x+math.cos(a)*1.7+math.sin(a)*.55,y+.055,z+math.sin(a)*1.7-math.cos(a)*.55)*CFrame.Angles(0,-a,0),.8,"UtahSpoon")
  end
  local m=Instance.new("Model")m.Name="Teapot"m:SetAttribute("SourceAssetId",10080695893)m.Parent=corner local scale=.66
  m.PrimaryPart=put(pot,m,CFrame.new(x,y+pot.Size.Y*scale*.5,z),scale,"UtahTeapot")report.teapots+=1 report.tables+=1
 end
 local old=runtime:FindFirstChild("TeaCupTool")if old then old:Destroy()end
 local tool=Instance.new("Tool")tool.Name="TeaCupTool"tool.CanBeDropped=false tool.RequiresHandle=true tool:SetAttribute("SourceAssetId",10080695893)tool.Grip=CFrame.new(0,-.08,-.08)
 local handle=put(cup,tool,CFrame.identity,.74,"Handle")handle.Anchored=false handle.CanQuery=false handle.Massless=true tool.Parent=runtime raw:Destroy()
 return report
end
return B
