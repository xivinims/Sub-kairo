local Players=game:GetService('Players');local Content=game:GetService('ContentProvider')
local Tween=game:GetService('TweenService');local First=game:GetService('ReplicatedFirst')
local player=Players.LocalPlayer;local playerGui=player:WaitForChild('PlayerGui')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local policy=require(package:WaitForChild('LoadingPolicy'));local View=require(First:WaitForChild('LoadingView'))
local generation=0;local view;local blur
local function current(token)return generation==token end
local function loadMap()
 generation+=1;local token=generation
 playerGui:SetAttribute('NBLoadComplete',false)
 if view and view.gui.Parent then view.gui:Destroy()end
 if blur then blur:Destroy()end
 while not playerGui:GetAttribute('NBBootComplete')do task.wait(.05);if not current(token)then return end end
 view=View.Create(playerGui,'MapLoading',1001);local screen=view
 screen:Set('CARREGANDO MAPA',0,'Aguardando a arena…')
 playerGui:SetAttribute('NBMapLoadingVisible',true)
 local began=os.clock()
 while not package:GetAttribute('MapReady')do task.wait(.1);if not current(token)then return end end
 local revision=package:GetAttribute('MapRevision')or 0
 local name=package:GetAttribute('MapName')or ''
 screen:Set('CARREGANDO MAPA',.1,name)
 local cameras=workspace:WaitForChild('MenuCameras');local anchor=cameras:WaitForChild('Home')
 local point=anchor.Position
 pcall(function()player:RequestStreamAroundAsync(point,15)end)
 if not current(token)or revision~=(package:GetAttribute('MapRevision')or 0)then return end
 local map=workspace:WaitForChild('ActiveMap');local assets={};local seen={}
 -- Preload the visible menu area, not every map or thousands of distant meshes on mobile.
 for _,v in ipairs(map:GetDescendants())do
  if #assets>=200 then break end
  local part=v:IsA('BasePart')and v or v:FindFirstAncestorWhichIsA('BasePart')
  if part and (part.Position-point).Magnitude<192 then
   for _,property in ipairs(v:IsA('MeshPart')and {'MeshId','TextureID'}or v:IsA('Decal')and {'Texture'}or {})do
    local ok,id=pcall(function()return v[property]end)
    if ok and type(id)=='string'and id~=''and not seen[id]then seen[id]=true;table.insert(assets,id)end
   end
  end
 end
 local count=0
 pcall(function()Content:PreloadAsync(assets,function()
  count+=1;if current(token)then screen:Set('CARREGANDO MAPA',.15+.7*math.min(count/math.max(#assets,1),1),name)end
 end)end)
 if not current(token)or revision~=(package:GetAttribute('MapRevision')or 0)then return end
 blur=Instance.new('BlurEffect');blur.Name='LoadingBlur';blur.Size=15;blur.Parent=game:GetService('Lighting')
 Tween:Create(screen.cover,TweenInfo.new(.4),{BackgroundTransparency=.4}):Play()
 screen:Set('CARREGANDO INTERFACE',.9,name)
 task.wait(.6);if not current(token)then return end
 while not playerGui:GetAttribute('NBInterfaceReady')or not player.Character do task.wait(.1);if not current(token)then return end end
 if os.clock()-began<1.2 then task.wait(1.2-(os.clock()-began))end
 if not current(token)then return end
 if not policy.CanReveal(playerGui:GetAttribute('NBBootComplete'),package:GetAttribute('MapReady'),package:GetAttribute('MapRevision')or 0,revision,playerGui:GetAttribute('NBInterfaceReady'))then return end
 screen:Set('CARREGANDO INTERFACE',1,name)
 playerGui:SetAttribute('NBLoadedMapRevision',revision);playerGui:SetAttribute('NBLoadComplete',true)
 local ownBlur=blur;Tween:Create(ownBlur,TweenInfo.new(.35),{Size=0}):Play()
 screen:Close();ownBlur:Destroy()
end
package:GetAttributeChangedSignal('MapRevision'):Connect(function()task.spawn(loadMap)end)
task.spawn(loadMap)
