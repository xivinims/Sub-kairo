local fs=require('@lune/fs')
local R=require('@lune/roblox')
return function()
 local roots=R.deserializeModel(fs.readFile('/tmp/lobby-health-source.rbxm'))
 local source
 for _,root in ipairs(roots) do source=root:FindFirstChild('HealthUi',true) or source;if root.Name=='HealthUi' then source=root end end
 assert(source and source:IsA('ScreenGui'),'Original health GUI missing')
 local template=source:Clone();template.Name='FalloutLobbyHealthTemplate';template.Enabled=false;template.ResetOnSpawn=false
 for _,item in ipairs(template:GetDescendants()) do if item:IsA('LuaSourceContainer') then item:Destroy() end end
 assert(template.HealthGui.HealthFrame.Size==R.UDim2.fromOffset(170,18),'Unexpected source health dimensions')
 assert(template.HealthGui.HealthFrame:FindFirstChild('HealthBar') and template.HealthGui.HealthFrame:FindFirstChild('HealthLabel'))
 template:SetAttribute('SourceAssetId','84860453909277')
 template:SetAttribute('SourceSha256','35bbef11373c32284c354fc7102af891af85fd133c2ac4be5e3df2ec7ad2deca')
 return template
end
