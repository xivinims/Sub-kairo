local Players=game:GetService('Players')
local player=Players.LocalPlayer
local event=game.ReplicatedStorage:WaitForChild('LivingForest'):WaitForChild('ReportEvent')
local M={};local active=nil
local words={
 pt={'Reportar','Quem você quer reportar?','O que aconteceu?','Mensagens repetidas ou inadequadas','Assédio ou perseguição','Movimento anormal','Outros','Descreva o que aconteceu (até 200 caracteres)','Enviar relato','Cancelar','Analisamos ações e chat público desta sessão. Relatos sem evidência ficam para revisão.','Relato recebido. Seu nome não será mostrado à pessoa.','Aguarde um pouco para enviar novamente.','Não foi possível enviar. Tente novamente.','Escolha uma pessoa e pelo menos um motivo. Em “Outros”, descreva o ocorrido.','A pessoa saiu do servidor.','Aproxime-se do Caio para enviar.','Enviando…'},
 en={'Report','Who would you like to report?','What happened?','Spam or inappropriate messages','Harassment','Abnormal movement','Other','Describe what happened (up to 200 characters)','Send report','Cancel','We check this session’s actions and public chat. Unsupported reports await review.','Report received. Your name will not be shown to the player.','Please wait before sending again.','Could not send. Please try again.','Choose a player and a reason. Describe the issue when choosing Other.','The player left the server.','Move closer to Caio to send.','Sending…'},
 es={'Reportar','¿A quién quieres reportar?','¿Qué ocurrió?','Spam o mensajes inapropiados','Acoso','Movimiento anormal','Otros','Describe lo ocurrido (hasta 200 caracteres)','Enviar reporte','Cancelar','Revisamos acciones y chat público de esta sesión. Los reportes sin evidencia quedan pendientes.','Reporte recibido. Tu nombre no se mostrará a la persona.','Espera antes de enviar de nuevo.','No se pudo enviar. Inténtalo otra vez.','Elige persona y motivo. Describe lo ocurrido si eliges Otros.','La persona salió del servidor.','Acércate a Caio para enviar.','Enviando…'}}
words.fr={'Signaler','Qui veux-tu signaler ?','Que s’est-il passé ?','Messages répétés ou inappropriés','Harcèlement','Mouvement anormal','Autre','Décris les faits (200 caractères maximum)','Envoyer','Annuler','Nous vérifions les actions et le chat public de cette session. Les signalements sans preuve restent à examiner.','Signalement reçu. Ton nom ne sera pas montré à la personne.','Attends avant de renvoyer.','Échec de l’envoi. Réessaie.','Choisis une personne et un motif. Décris les faits pour Autre.','La personne a quitté le serveur.','Rapproche-toi de Caio.','Envoi…'}
words.de={'Melden','Wen möchtest du melden?','Was ist passiert?','Spam oder unangemessene Nachrichten','Belästigung','Ungewöhnliche Bewegung','Sonstiges','Beschreibe den Vorfall (maximal 200 Zeichen)','Meldung senden','Abbrechen','Wir prüfen Aktionen und öffentlichen Chat dieser Sitzung. Unbelegte Meldungen warten auf Prüfung.','Meldung erhalten. Dein Name wird der Person nicht gezeigt.','Warte vor einer weiteren Meldung.','Senden fehlgeschlagen. Versuche es erneut.','Wähle Person und Grund. Beschreibe Sonstiges genauer.','Die Person hat den Server verlassen.','Komm näher zu Caio.','Wird gesendet…'}
words.it={'Segnala','Chi vuoi segnalare?','Cosa è successo?','Spam o messaggi inappropriati','Molestie','Movimento anomalo','Altro','Descrivi i fatti (massimo 200 caratteri)','Invia','Annulla','Controlliamo azioni e chat pubblica di questa sessione. Le segnalazioni senza prove attendono revisione.','Segnalazione ricevuta. Il tuo nome non verrà mostrato.','Attendi prima di inviare di nuovo.','Invio non riuscito. Riprova.','Scegli persona e motivo. Descrivi i fatti per Altro.','La persona ha lasciato il server.','Avvicinati a Caio.','Invio…'}
words.ja={'報告','誰を報告しますか？','何がありましたか？','連投や不適切なメッセージ','嫌がらせ','不自然な移動','その他','状況を説明してください（200文字以内）','送信','キャンセル','このセッションの行動と公開チャットを確認します。証拠のない報告は審査待ちになります。','報告を受け付けました。名前は相手に表示されません。','しばらく待ってから再送信してください。','送信できませんでした。再試行してください。','相手と理由を選んでください。その他の場合は説明してください。','相手はサーバーを退出しました。','カイオに近づいてください。','送信中…'}
words.ko={'신고','누구를 신고할까요?','무슨 일이 있었나요?','도배 또는 부적절한 메시지','괴롭힘','비정상적인 이동','기타','상황을 설명해 주세요 (최대 200자)','신고 보내기','취소','이번 세션의 행동과 공개 채팅을 확인합니다. 증거 없는 신고는 검토 대기 상태로 남습니다.','신고를 받았습니다. 이름은 상대에게 표시되지 않습니다.','다시 보내기 전에 잠시 기다려 주세요.','보내지 못했습니다. 다시 시도하세요.','사람과 이유를 선택하세요. 기타는 설명이 필요합니다.','상대가 서버를 떠났습니다.','카이우에게 가까이 가세요.','보내는 중…'}
words.zh={'举报','你想举报谁？','发生了什么？','刷屏或不当消息','骚扰','异常移动','其他','请描述情况（最多200字）','发送举报','取消','我们会检查本次会话的行为和公开聊天。缺少证据的举报将等待审核。','举报已收到。对方不会看到你的名字。','请稍候再发送。','发送失败，请重试。','请选择玩家和原因。选择其他时请描述情况。','该玩家已离开服务器。','请靠近卡约再发送。','发送中…'}
words.ar={'إبلاغ','من تريد الإبلاغ عنه؟','ماذا حدث؟','رسائل مكررة أو غير مناسبة','مضايقة','حركة غير طبيعية','غير ذلك','صف ما حدث (حتى 200 حرف)','إرسال البلاغ','إلغاء','نفحص الأفعال والدردشة العامة لهذه الجلسة. البلاغات دون دليل تنتظر المراجعة.','تم استلام البلاغ. لن يظهر اسمك للشخص.','انتظر قبل الإرسال مجدداً.','تعذر الإرسال. حاول مجدداً.','اختر شخصاً وسبباً. صف ما حدث عند اختيار غير ذلك.','غادر الشخص الخادم.','اقترب من كايو للإرسال.','جارٍ الإرسال…'}
words.hi={'रिपोर्ट','किसकी रिपोर्ट करना चाहते हो?','क्या हुआ?','स्पैम या अनुचित संदेश','परेशान करना','असामान्य गति','अन्य','घटना बताएँ (अधिकतम 200 अक्षर)','रिपोर्ट भेजें','रद्द करें','हम इस सत्र की गतिविधियाँ और सार्वजनिक चैट जाँचते हैं। बिना प्रमाण की रिपोर्ट समीक्षा की प्रतीक्षा करती है।','रिपोर्ट मिल गई। आपका नाम उस खिलाड़ी को नहीं दिखेगा।','दोबारा भेजने से पहले प्रतीक्षा करें।','भेज नहीं सके। फिर कोशिश करें।','खिलाड़ी और कारण चुनें। अन्य चुनने पर विवरण दें।','खिलाड़ी सर्वर छोड़ चुका है।','भेजने के लिए कायो के पास जाएँ।','भेज रहे हैं…'}
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
  if not target or #reasons==0 or (#details.Text>700 or (utf8.len(details.Text)or 201)>200) or selected.other and #details.Text:gsub('%s','')<8 then status.Text=w[15];return end
  pending=true;submit.Active=false;submit.Text=w[18];status.Text='';event:FireServer(target,reasons,details.Text)
  task.delay(18,function()if active==panel and pending then pending=false;submit.Active=true;submit.Text=w[9];status.Text=w[14]end end)
 end)
end
return M
