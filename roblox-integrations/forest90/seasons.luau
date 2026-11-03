local Seasons={Names={"Primavera","Verao","Outono","Inverno"},Duration=600,Transition=35}
function Seasons.index(now,epoch)return math.floor(math.max(0,now-epoch)/Seasons.Duration)%4+1 end
function Seasons.at()
 local runtime=game.ReplicatedStorage:FindFirstChild("ForestRuntime")return runtime and(runtime:GetAttribute("SeasonName")or "Primavera")or "Primavera"
end
function Seasons.isGreen()return Seasons.at()~="Inverno"end
function Seasons.progress(now,epoch)return math.max(0,now-epoch)%Seasons.Duration/Seasons.Duration end
function Seasons.visual(_,day)
 local name=Seasons.at()local air=game.Lighting:FindFirstChild("ForestAtmosphere")local color=game.Lighting:FindFirstChild("ForestColor")
 if not air or not color then return end
 local winter=name=="Inverno"local autumn=name=="Outono"
 air.Density=winter and .31 or .265 air.Haze=winter and 1.35 or 1.05
 color.TintColor=color.TintColor:Lerp(winter and Color3.fromRGB(225,239,249)or autumn and Color3.fromRGB(255,235,204)or Color3.fromRGB(247,251,235),.25*day)
 color.Saturation+=(winter and -.05 or autumn and .025 or .015)
end
return Seasons
