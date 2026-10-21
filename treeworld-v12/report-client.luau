local Players=game:GetService('Players')
local player=Players.LocalPlayer
local event=game.ReplicatedStorage:WaitForChild('LivingForest'):WaitForChild('ReportEvent')
local M={};local active=nil
local words={
 pt={'Reportar','Quem você quer reportar?','O que aconteceu?','Mensagens repetidas ou inadequadas','Assédio ou perseguição','Movimento anormal','Outros','Descreva o que aconteceu (até 700 bytes)','Enviar relato','Cancelar','Analisamos ações e chat público desta sessão. Relatos sem evidência ficam para revisão.','Relato recebido. Seu nome não será mostrado à pessoa.','Aguarde um pouco para enviar novamente.','Não foi possível enviar. Tente novamente.','Escolha uma pessoa e pelo menos um motivo. Em “Outros”, descreva o ocorrido.','A pessoa saiu do servidor.','Aproxime-se do Caio para enviar.','Enviando…'},
 en={'Report','Who would you like to report?','What happened?','Spam or inappropriate messages','Harassment','Abnormal movement','Other','Describe what happened (up to 700 bytes)','Send report','Cancel','We check this session’s actions and public chat. Unsupported reports await review.','Report received. Your name will not be shown to the player.','Please wait before sending again.','Could not send. Please try again.','Choose a player and a reason. Describe the issue when choosing Other.','The player left the server.','Move closer to Caio to send.','Sending…'},
 es={'Reportar','¿A quién quieres reportar?','¿Qué ocurrió?','Spam o mensajes inapropiados','Acoso','Movimiento anormal','Otros','Describe lo ocurrido (hasta 700 bytes)','Enviar reporte','Cancelar','Revisamos acciones y chat público de esta sesión. Los reportes sin evidencia quedan pendientes.','Reporte recibido. Tu nombre no se mostrará a la persona.','Espera antes de enviar de nuevo.','No se pudo enviar. Inténtalo otra vez.','Elige persona y motivo. Describe lo ocurrido si eliges Otros.','La persona salió del servidor.','Acércate a Caio para enviar.','Enviando…'}}
function M.close()if active then active:Destroy();active=nil end end
function M.open(screen,locale)
 M.close();local w=words[locale]or words.en
 local panel=Instance.new('ScrollingFrame');panel.Name='ReportConversation';panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.51);panel.Size=UDim2.fromScale(.92,.82);panel.BackgroundColor3=Color3.fromRGB(25,37,30);panel.BackgroundTransparency=.04;panel.BorderSizePixel=0;panel.ScrollBarThickness=4;panel.AutomaticCanvasSize=Enum.AutomaticSize.Y;panel.CanvasSize=UDim2.new();panel.Parent=screen;active=panel
 Instance.new('UICorner',panel).CornerRadius=UDim.new(0,14)
 local bounds=Instance.new('UISizeConstraint');bounds.MaxSize=Vector2.new(490,590);bounds.Parent=panel
 local list=Instance.new('UIListLayout');list.Padding=UDim.new(0,8);list.SortOrder=Enum.SortOrder.LayoutOrder;list.Parent=panel
 local padding=Instance.new('UIPadding');padding.PaddingLeft=UDim.new(0,18);padding.PaddingRight=UDim.new(0,18);padding.PaddingTop=UDim.new(0,16);padding.PaddingBottom=UDim.new(0,18);padding.Parent=panel
 local order=0
 local function element(class,text,height)
  order+=1;local e=Instance.new(class);e.LayoutOrder=order;e.Size=UDim2.new(1,0,0,height or 38);e.BackgroundColor3=Color3.fromRGB(44,59,47);e.TextColor3=Color3.fromRGB(244,240,222);e.TextSize=15;e.Font=Enum.Font.GothamMedium;e.TextWrapped=true;e.Text=text;e.Parent=panel
  if class=='TextLabel'then e.BackgroundTransparency=1 else Instance.new('UICorner',e).CornerRadius=UDim.new(0,7)end
  return e
 end
 element('TextLabel',w[1],28);element('TextLabel',w[2],30)
 local target=nil;local buttons={};local selected={};local pending=false
 for _,p in ipairs(Players:GetPlayers())do if p~=player then
  local b=element('TextButton',p.DisplayName..'  @'..p.Name,36);buttons[p.UserId]=b
  b.Activated:Connect(function()if pending then return end;target=p.UserId;for id,other in pairs(buttons)do other.BackgroundColor3=id==target and Color3.fromRGB(77,111,75)or Color3.fromRGB(44,59,47)end end)
 end end
 element('TextLabel',w[3],30)
 for i,key in ipairs({'speech','harassment','movement','other'})do local b=element('TextButton','○  '..w[i+3],36)
  b.Activated:Connect(function()if pending then return end;selected[key]=not selected[key];b.Text=(selected[key]and'✓  'or'○  ')..w[i+3]end)
 end
 local details=element('TextBox','',90);details.PlaceholderText=w[8];details.PlaceholderColor3=Color3.fromRGB(176,188,173);details.ClearTextOnFocus=false;details.MultiLine=true;details.TextXAlignment=Enum.TextXAlignment.Left;details.TextYAlignment=Enum.TextYAlignment.Top
 element('TextLabel',w[11],58)
 local status=element('TextLabel','',48);status.TextColor3=Color3.fromRGB(222,204,146)
 local submit=element('TextButton',w[9],40);local cancel=element('TextButton',w[10],36)
 cancel.Activated:Connect(M.close)
 local connection;connection=event.OnClientEvent:Connect(function(code)
  if active~=panel then return end;pending=false;submit.Active=true;submit.Text=w[9]
  local mapping={sent=12,wait=13,retry=14,invalid=15,details=15,missing=16,far=17};status.Text=w[mapping[code]or 14]
  if code=='sent'then submit.Visible=false;details.Text='';task.delay(4,function()if active==panel then M.close()end end)end
 end)
 panel.Destroying:Connect(function()connection:Disconnect()end)
 submit.Activated:Connect(function()
  if pending then return end;local reasons={};for key,value in pairs(selected)do if value then table.insert(reasons,key)end end
  if not target or #reasons==0 or #details.Text>700 or selected.other and #details.Text:gsub('%s','')<8 then status.Text=w[15];return end
  pending=true;submit.Active=false;submit.Text=w[18];status.Text='';event:FireServer(target,reasons,details.Text)
  task.delay(18,function()if active==panel and pending then pending=false;submit.Active=true;submit.Text=w[9];status.Text=w[14]end end)
 end)
end
return M
