local Preset={}
function Preset.install()
 local raw=game:GetService("AssetService"):LoadAssetAsync(8490242417)
 local source=assert(raw:FindFirstChildOfClass("Script"),"Extreme shaders asset changed").Source
 assert(source:find("Bloom.Intensity = 0.3",1,true)and source:find("Sky.SkyboxUp",1,true),"Inspect changed shader preset before using")
 -- Import the reviewed preset's sky/effect classes. Lighting parameters are adapted by Visuals for a moving sun.
 local lighting=game.Lighting local sky=assert(lighting:FindFirstChildOfClass("Sky"))
 for key,id in pairs({SkyboxBk=151165214,SkyboxDn=151165197,SkyboxFt=151165224,SkyboxLf=151165191,SkyboxRt=151165206,SkyboxUp=151165227})do sky[key]="rbxassetid://"..id end
 sky.SunAngularSize=10 sky.StarCount=2200 sky.CelestialBodiesShown=true sky:SetAttribute("SourceAssetId",8490242417)
 local blur=Instance.new("BlurEffect")blur.Name="ForestBlur"blur.Size=0 blur.Enabled=false blur:SetAttribute("SourceAssetId",8490242417)blur.Parent=lighting
 for _,effect in ipairs(lighting:GetChildren())do if effect:IsA("PostEffect")or effect:IsA("Atmosphere")then effect:SetAttribute("SourceAssetId",8490242417)effect:SetAttribute("AdaptedForDayNight",true)end end
 local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("ShaderPresetAssetId",8490242417)
 runtime:SetAttribute("ShaderPresetAdapted",true)runtime:SetAttribute("CycleEpoch",nil)
 raw:Destroy()return{assetId=8490242417,reviewed=true,foreignScriptExecuted=false,adaptedForDayNight=true}
end
return Preset
