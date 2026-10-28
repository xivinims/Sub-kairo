-- Run once from Studio's Command Bar in EDIT mode. This does not publish the place.
-- Creator Store access is controlled by Roblox and the asset owner's permissions.
local InsertService=game:GetService("InsertService")
local ServerStorage=game:GetService("ServerStorage")
local ok,result=pcall(function() return InsertService:LoadAsset(77713813527653) end)
if not ok then warn("Roblox não autorizou a importação de Bramble: "..tostring(result));return end
-- Container remains unparented while all executable scripts are removed.
for _,item in ipairs(result:GetDescendants()) do if item:IsA("LuaSourceContainer") then item:Destroy() end end
local model=result:FindFirstChildWhichIsA("Model")
if not model then result:Destroy();warn("O asset não contém um Model.");return end
model.Parent=nil;result:Destroy()
local part=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
if not part then model:Destroy();warn("Modelo sem geometria.");return end
model.PrimaryPart=part;model.Name="BrambleTemplate"
local old=ServerStorage:FindFirstChild(model.Name);if old then old:Destroy() end
model.Parent=ServerStorage
print("Bramble importado sem scripts. Confira orientação, escala e direitos de uso antes de publicar.")
