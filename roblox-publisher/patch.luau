
local AS=game:GetService("AssetService")
local SG=game:GetService("StarterGui")
local SPS=game:GetService("StarterPlayer").StarterPlayerScripts
local Lighting=game:GetService("Lighting")

local asset=AS:LoadAssetAsync(12962987574)
local out={
 version=game.PlaceVersion,
 lighting={clock=Lighting.ClockTime,brightness=Lighting.Brightness},
 asset={top={},scripts={},animations={},humanoids={},values={}},
 ui={}
}
for _,c in ipairs(asset:GetChildren()) do
 table.insert(out.asset.top,{name=c.Name,class=c.ClassName})
end
for _,d in ipairs(asset:GetDescendants()) do
 if d:IsA("LuaSourceContainer") and #out.asset.scripts<25 then
  table.insert(out.asset.scripts,{path=d:GetFullName(),source=string.sub(d.Source,1,7000)})
 elseif d:IsA("Animation") then
  table.insert(out.asset.animations,{path=d:GetFullName(),id=d.AnimationId})
 elseif d:IsA("Humanoid") then
  table.insert(out.asset.humanoids,{path=d:GetFullName(),walk=d.WalkSpeed,jump=d.JumpPower,rig=tostring(d.RigType)})
 elseif d:IsA("NumberValue") or d:IsA("IntValue") then
  if #out.asset.values<80 then table.insert(out.asset.values,{path=d:GetFullName(),value=d.Value}) end
 end
end
asset:Destroy()

local ui=SG:FindFirstChild("NextbotsBrasilUI")
if ui then
 for _,d in ipairs(ui:GetDescendants()) do
  if d:IsA("GuiObject") and #out.ui<120 then
   table.insert(out.ui,{path=d:GetFullName(),class=d.ClassName,visible=d.Visible})
  end
 end
end
local mc=ui and ui:FindFirstChild("NextbotsMenuClient")
if mc then out.menuClient=string.sub(mc.Source,1,12000) end
local hud=SPS:FindFirstChild("NBReferenceHUDClient")
if hud then out.hudClient=string.sub(hud.Source,1,12000) end

return out
