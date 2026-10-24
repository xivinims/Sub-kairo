local Factory={}
function Factory.create(name)
 local template=assert(game.ServerStorage.SurvivalAssets.Killers:FindFirstChild(name),"Unknown pursuer")
 local rig=template:Clone()
 rig.Name=name rig:SetAttribute("ActivePursuer",true)
 return rig
end
return Factory
