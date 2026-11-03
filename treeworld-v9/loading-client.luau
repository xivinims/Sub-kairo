local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local TeleportService=game:GetService("TeleportService")
local View=require(ReplicatedFirst:WaitForChild("OveryardLoadingView"))
local player=Players.LocalPlayer
local data=nil
pcall(function()data=TeleportService:GetLocalPlayerTeleportData()end)
local updating=type(data)=="table"and data.overyardUpdate
local view=View.create("MapLoadingScreen","Olá, "..player.DisplayName,updating and "Aplicando atualização..."or "Seja bem-vindo",10000)
-- Install the dark screen BEFORE removing Roblox's default screen.
ReplicatedFirst:RemoveDefaultLoadingScreen()
pcall(function()
 local arriving=TeleportService:GetArrivingTeleportGui()
 if arriving then arriving:Destroy()end
end)
local start=os.clock()
local MIN_SECONDS=3
local MAX_LOGO_WAIT=12
while view.gui.Parent do
 local elapsed=os.clock()-start
 local character=player.Character
 local ready=game:IsLoaded()and character and character:FindFirstChild("HumanoidRootPart")
 local logoSettled=(view.ready and os.clock()-view.visibleAt>=.7)or elapsed>=MAX_LOGO_WAIT
 if elapsed>=MIN_SECONDS and ready and logoSettled then break end
 if elapsed>1.15 then
  view.status.Text=not game:IsLoaded()and "Carregando ambiente..."or(not character and "Preparando sua chegada..."or(not logoSettled and "Preparando Overyard..."or "Quase pronto..."))
 end
 view:setProgress(math.min(.9,elapsed/MIN_SECONDS*.65)+(ready and .04 or 0))
 if elapsed>25 then
  -- Asset/network trouble must never leave a permanent input-blocking overlay.
  view.status.Text="Entrando no mundo...";break
 end
 task.wait(.1)
end
view:setProgress(1)
view.status.Text=updating and "Atualização aplicada. Seja bem-vindo!"or "Seja bem-vindo ao Overyard"
task.wait(.25)
view:close()
