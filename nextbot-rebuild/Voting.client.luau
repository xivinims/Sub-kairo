local Players=game:GetService('Players');local Http=game:GetService('HttpService');local Run=game:GetService('RunService')
local player=Players.LocalPlayer;local playerGui=player:WaitForChild('PlayerGui')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local function new(class,parent,props)local v=Instance.new(class);for k,val in pairs(props or {})do v[k]=val end;v.Parent=parent;return v end
local gui=new('ScreenGui',playerGui,{Name='MapVoting',Enabled=false,ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,DisplayOrder=90})
local shade=new('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(10,13,20),BackgroundTransparency=.05,Active=true})
local panel=new('Frame',shade,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundTransparency=1})
local function text(value,y,h,size)
 return new('TextLabel',panel,{Text=value,Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,h),Font=Enum.Font.GothamBold,TextSize=size,TextColor3=Color3.new(1,1,1),TextWrapped=true,BackgroundTransparency=1})
end
text('ESCOLHA O PRÓXIMO MAPA',0,38,21)
local countdown=text('',40,32,14)
local list=new('ScrollingFrame',panel,{Position=UDim2.fromOffset(0,82),Size=UDim2.new(1,0,1,-82),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
new('UIListLayout',list,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
local buttons={};local previous=''
local function decode(raw)local ok,v=pcall(Http.JSONDecode,Http,raw or '{}');return ok and type(v)=='table'and v or {}end
local function refresh()
 local raw=package:GetAttribute('VoteOptions')or '[]'
 if raw~=previous then
  previous=raw;for _,b in pairs(buttons)do b:Destroy()end;buttons={}
  for i,name in ipairs(decode(raw))do
   local b=new('TextButton',list,{Name='Vote'..i,Text='',Size=UDim2.new(1,-8,0,70),BackgroundColor3=Color3.fromRGB(35,43,60),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=18,TextWrapped=true,LayoutOrder=i})
   new('UICorner',b,{CornerRadius=UDim.new(0,12)});b.Activated:Connect(function()package.MatchAction:FireServer('Vote',name)end);buttons[name]=b
  end
 end
 local counts=decode(package:GetAttribute('MapVotes'));local selected=player:GetAttribute('NBVotedMap')
 for name,b in pairs(buttons)do b.Text=name..'  •  '..tostring(counts[name]or 0)..' voto(s)'..(name==selected and '  ✓'or '');b.BackgroundColor3=name==selected and Color3.fromRGB(46,91,74)or Color3.fromRGB(35,43,60)end
end
local function fit()panel.Size=UDim2.fromOffset(math.min(540,gui.AbsoluteSize.X-32),math.min(390,gui.AbsoluteSize.Y-24))end
fit();gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
for _,key in ipairs({'VoteOptions','MapVotes'})do package:GetAttributeChangedSignal(key):Connect(refresh)end
player:GetAttributeChangedSignal('NBVotedMap'):Connect(refresh);refresh()
Run.Heartbeat:Connect(function()
 local active=playerGui:GetAttribute('NBLoadComplete')==true and package:GetAttribute('VotingOpen')==true
 if active and not gui.Enabled then player:SetAttribute('NBOverlay','Voting')elseif not active and gui.Enabled and player:GetAttribute('NBOverlay')=='Voting'then player:SetAttribute('NBOverlay','')end
 gui.Enabled=active
 local seconds=math.max(0,math.ceil((package:GetAttribute('Deadline')or 0)-workspace:GetServerTimeNow()))
 countdown.Text=seconds..'s • Toque em um mapa para votar ou trocar seu voto'
end)
