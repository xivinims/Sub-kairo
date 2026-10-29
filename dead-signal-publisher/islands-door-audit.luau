local function get(o,k) local ok,v=pcall(function() return o[k] end);return ok and tostring(v) or '' end
local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
for _,id in ipairs({'15864801103','14817965191','13037825880','9426919197'}) do
 local file='/tmp/asset-'..id..'.rbxl'
 if fs.isFile(file) then
 local ok,dm=pcall(R.deserializePlace,fs.readFile(file))
 if not ok then print('AUDIT FAILED '..id..' '..tostring(dm));continue end
 local result={id=id,counts={},objects={},sources={},animations={},sounds={}}
 for _,d in ipairs(dm:GetDescendants()) do
  result.counts[d.ClassName]=(result.counts[d.ClassName] or 0)+1
  if d:IsA('LuaSourceContainer') then table.insert(result.sources,{path=d:GetFullName(),source=d.Source:sub(1,22000)}) end
  if d:IsA('Animation') then table.insert(result.animations,{path=d:GetFullName(),id=get(d,'AnimationId')}) end
  if d:IsA('Sound') then table.insert(result.sounds,{path=d:GetFullName(),id=get(d,'SoundId')}) end
  if d:IsA('Tool') or (d:IsA('Model') and (d.Name:lower():find('gun') or d.Name:lower():find('view') or d.Name:lower():find('rifle') or d.Name:lower():find('pistol') or d.Name:lower():find('blaster'))) then
   local names={};for _,c in ipairs(d:GetChildren()) do table.insert(names,c.Name..':'..c.ClassName) end
   table.insert(result.objects,{path=d:GetFullName(),class=d.ClassName,count=#d:GetDescendants(),children=names})
  end
 end
 local L=dm:GetService('Lighting');result.lighting={clock=get(L,'ClockTime'),time=get(L,'TimeOfDay'),brightness=get(L,'Brightness'),exposure=get(L,'ExposureCompensation'),ambient=get(L,'Ambient'),outdoor=get(L,'OutdoorAmbient')}
 print('WEAPON HORROR AUDIT '..J.encode('json',result))
 end
end
