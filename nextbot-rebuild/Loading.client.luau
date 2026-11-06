local Players=game:GetService('Players');local Content=game:GetService('ContentProvider')
local First=game:GetService('ReplicatedFirst');local Http=game:GetService('HttpService')
local player=Players.LocalPlayer;local playerGui=player:WaitForChild('PlayerGui')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local policy=require(package:WaitForChild('LoadingPolicy'));local View=require(First:WaitForChild('LoadingView'))
local generation=0;local view
local function current(token)return generation==token end
local function addAsset(assets,seen,id)
 if type(id)=='string'and id~=''and id~='rbxassetid://0'and not seen[id]then seen[id]=true;table.insert(assets,id)end
end
local function mapAssets(map)
 local assets,seen={},{}
 for _,v in ipairs(map:GetDescendants())do
  local properties=v:IsA('MeshPart')and {'MeshId','TextureID'}or v:IsA('SpecialMesh')and {'MeshId','TextureId'}or v:IsA('Decal')and {'Texture'}or v:IsA('ImageLabel')and {'Image'}or v:IsA('ImageButton')and {'Image'}or v:IsA('Sound')and {'SoundId'}or v:IsA('Animation')and {'AnimationId'}or v:IsA('ParticleEmitter')and {'Texture'}or v:IsA('Beam')and {'Texture'}or v:IsA('Trail')and {'Texture'}or v:IsA('SurfaceAppearance')and {'ColorMap','MetalnessMap','NormalMap','RoughnessMap'}or v:IsA('Sky')and {'SkyboxBk','SkyboxDn','SkyboxFt','SkyboxLf','SkyboxRt','SkyboxUp','SunTextureId','MoonTextureId'}or {}
  for _,property in ipairs(properties)do local ok,id=pcall(function()return v[property]end);if ok then addAsset(assets,seen,id)end end
 end
 local atlas=package:GetAttribute('MenuAtlas');addAsset(assets,seen,atlas)
 local manifest=package:FindFirstChild('GameplayPreload')
 local encoded=manifest and manifest:IsA('StringValue')and manifest.Value or package:GetAttribute('GameplayPreload')
 if type(encoded)=='string'then
  local ok,ids=pcall(Http.JSONDecode,Http,encoded)
  if ok and type(ids)=='table'then for _,id in ipairs(ids)do addAsset(assets,seen,id)end end
 end
 for _,v in ipairs(playerGui:GetDescendants())do if v:IsA('ImageLabel')or v:IsA('ImageButton')then addAsset(assets,seen,v.Image)end end
 return assets
end
local function clientsReady()
 if not playerGui:GetAttribute('NBInterfaceReady')then return false end
 local encoded=package:GetAttribute('NBClientScripts')
 if type(encoded)=='string'then
  local ok,names=pcall(Http.JSONDecode,Http,encoded)
  if not ok or type(names)~='table'then return false end
  for _,name in ipairs(names)do if playerGui:GetAttribute('NBReady_'..name)~=true then return false end end
 end
 return true
end
local function loadMap()
 generation+=1;local token=generation
 playerGui:SetAttribute('NBLoadComplete',false);playerGui:SetAttribute('NBLoadedMapRevision',0)
 if view and view.gui.Parent then view.gui:Destroy()end
 while not playerGui:GetAttribute('NBBootComplete')do task.wait(.05);if not current(token)then return end end
 view=View.Create(playerGui,'MapLoading',1001);local screen=view
 screen:Set('CARREGANDO MAPA SELECIONADO',0,package:GetAttribute('SelectedMap')or 'Aguardando a arena…')
 playerGui:SetAttribute('NBMapLoadingVisible',true)
 while not package:GetAttribute('MapReady')or package:GetAttribute('MapReadyRevision')~=package:GetAttribute('MapRevision')or package:GetAttribute('MapContentRevision')~=package:GetAttribute('MapRevision')do task.wait(.1);if not current(token)then return end end
 local revision=package:GetAttribute('MapRevision')or 0;local name=package:GetAttribute('MapName')or ''
 local map
 repeat
  map=workspace:FindFirstChild('ActiveMap')
  if map and map:GetAttribute('MapRevision')==revision and policy.MapReplicated(map:GetAttribute('ExpectedDescendants'),#map:GetDescendants())then break end
  screen:Set('CARREGANDO MODELOS',.1,name)
  task.wait(.1);if not current(token)then return end
 until false
 screen:Set('INICIANDO SCRIPTS',.12,name)
 while not clientsReady()do task.wait(.1);if not current(token)then return end end
 local assets=mapAssets(map)
 local completed=0;local failed={};local attempts=0
 repeat
  attempts+=1;local pending=attempts==1 and assets or failed;failed={}
  local ok=pcall(function()Content:PreloadAsync(pending,function(id,status)
   completed+=1
   if status~=Enum.AssetFetchStatus.Success then table.insert(failed,id)end
   if current(token)then screen:Set('CARREGANDO RECURSOS',.15+.65*math.min(completed/math.max(#assets,1),1),name)end
  end)end)
  if not ok and #failed==0 then failed=pending end
  if not current(token)or revision~=(package:GetAttribute('MapRevision')or 0)then return end
 until #failed==0 or attempts>=3
 if #failed>0 then
  -- A failed fetch is not a completed load. Keep the player behind the readiness gate.
  screen:Set('NÃO FOI POSSÍVEL CARREGAR',.8,'Toque em TENTAR NOVAMENTE para carregar os recursos do mapa.')
  screen:Retry(function()if current(token)then task.spawn(loadMap)end end)
  return
 end
 screen:Set('INICIANDO SCRIPTS E PERSONAGEM',.9,name)
 while not clientsReady()or not player.Character or not player.Character:FindFirstChild('HumanoidRootPart')or package:GetAttribute('MapChanging')do task.wait(.1);if not current(token)then return end end
 if not current(token)or not policy.CanReveal(playerGui:GetAttribute('NBBootComplete'),package:GetAttribute('MapReady'),package:GetAttribute('MapRevision')or 0,revision,playerGui:GetAttribute('NBInterfaceReady'))then return end
 screen:Set('PRONTO',1,name)
 package.MatchAction:FireServer('ClientReady',revision)
 -- The server owns this acknowledgment, and alone permits arena admission.
 while player:GetAttribute('NBClientReadyRevision')~=revision do task.wait(.05);if not current(token)then return end end
 playerGui:SetAttribute('NBLoadedMapRevision',revision);playerGui:SetAttribute('NBLoadComplete',true)
 screen:Close()
end
package:GetAttributeChangedSignal('MapRevision'):Connect(function()task.spawn(loadMap)end)
package:GetAttributeChangedSignal('MapChanging'):Connect(function()if package:GetAttribute('MapChanging')then task.spawn(loadMap)end end)
task.spawn(loadMap)
