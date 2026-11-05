-- ReplicatedFirst: visible before StarterPlayerScripts and the arena replicate.
local First=game:GetService('ReplicatedFirst');local Players=game:GetService('Players')
local Content=game:GetService('ContentProvider')
local player=Players.LocalPlayer;local playerGui=player:WaitForChild('PlayerGui')
playerGui:SetAttribute('NBBootComplete',false);playerGui:SetAttribute('NBLoadComplete',false)
local view=require(First:WaitForChild('LoadingView')).Create(playerGui,'GameLoading',1000)
view:Set('CARREGANDO JOGO',0,'Preparando os recursos…')
First:RemoveDefaultLoadingScreen()
local began=os.clock()
if not game:IsLoaded()then game.Loaded:Wait()end
view:Set('CARREGANDO JOGO',.25,'Carregando a interface…')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local atlas=package:GetAttribute('MenuAtlas')
if atlas and atlas~=''then pcall(function()Content:PreloadAsync({atlas})end)end
view:Set('CARREGANDO JOGO',1,'Recursos prontos')
if os.clock()-began<.8 then task.wait(.8-(os.clock()-began))end
playerGui:SetAttribute('NBBootComplete',true)
while not playerGui:GetAttribute('NBMapLoadingVisible')do playerGui:GetAttributeChangedSignal('NBMapLoadingVisible'):Wait()end
view.gui:Destroy()
