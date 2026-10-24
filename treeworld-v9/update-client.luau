local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TeleportService=game:GetService("TeleportService")
local View=require(ReplicatedFirst:WaitForChild("OveryardLoadingView"))
local remote=ReplicatedStorage:WaitForChild("OveryardUpdateEvent")
local current=nil
local function begin(title,status)
 if current and current.gui.Parent then current.gui:Destroy()end
 current=View.create("OveryardUpdating",title,status,20000)
 current:setProgress(.25)
 return current
end
remote.OnClientEvent:Connect(function(data)
 if type(data)~="table"then return end
 if data.phase=="begin"then
  local v=begin(data.title or "Atualizando Overyard",data.subtitle or "Indo para o servidor atualizado...")
  local transfer=v.gui:Clone();transfer.Name="OveryardUpdateTeleport"
  local fallback=transfer:FindFirstChild("LogoFallback",true);if fallback then fallback.Visible=false end
  pcall(function()TeleportService:SetTeleportGui(transfer)end)
  task.delay(1.5,function()if current==v and v.gui.Parent then v:setProgress(.7)end end)
 elseif data.phase=="retry"then
  local v=current
  if not v or not v.gui.Parent then v=begin("Reconectando...","Tentando entrar no servidor atualizado...")end
  v.title.Text=data.title or "Reconectando..."
  v.status.Text=data.subtitle or "Tentando novamente..."
 elseif data.phase=="failed"then
  local v=begin(data.title or "A atualização demorou",data.subtitle or "Você pode continuar neste servidor.")
  task.delay(3,function()if current==v and v.gui.Parent then v:close();current=nil end end)
 end
end)
-- Arrival is owned by MapLoadingScreen, preventing two overlapping loaders.
