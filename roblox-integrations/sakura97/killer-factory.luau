local Factory={}
function Factory.create(name)
 assert(name=="Jason","Only Jason is enabled")
 local rig=game.ServerStorage.SurvivalAssets.Killers.Jason:Clone()
 rig.Name="Jason" rig:SetAttribute("ActivePursuer",true)
 return rig
end
return Factory
