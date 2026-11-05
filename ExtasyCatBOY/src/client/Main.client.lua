-- ExtasyCatBOY: interface local responsiva e resposta ao chat nativo quando disponivel.
-- Falas de NPC aparecem como bolhas de chat, sem fingir que sao mensagens da conta do amigo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ExtasyRemotes")
local request = remotes:WaitForChild("Request")
local event = remotes:WaitForChild("Event")

local theme = {
    base = Color3.fromRGB(249,244,240),
    panel = Color3.fromRGB(255,251,249),
    ink = Color3.fromRGB(72,61,69),
    muted = Color3.fromRGB(139,123,133),
    accent = Color3.fromRGB(227,161,181),
    accent2 = Color3.fromRGB(239,219,224),
    dog = Color3.fromRGB(204,177,147),
    white = Color3.fromRGB(255,255,255),
}
local gui = Instance.new("ScreenGui")
gui.Name = "ExtasyCatBOY"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local function make(class, properties, parent)
    local object = Instance.new(class)
    for k,v in pairs(properties or {}) do object[k]=v end
    object.Parent = parent
    return object
end
local function rounded(object, radius)
    make("UICorner",{CornerRadius=UDim.new(0,radius)},object)
end
local function pad(object,left,top,right,bottom)
    make("UIPadding",{
        PaddingLeft=UDim.new(0,left),PaddingTop=UDim.new(0,top),
        PaddingRight=UDim.new(0,right),PaddingBottom=UDim.new(0,bottom)
    },object)
end
local function button(parent,text,size,color)
    local b=make("TextButton",{
        Text=text,Size=size,BackgroundColor3=color or theme.accent2,
        BorderSizePixel=0,TextColor3=theme.ink,Font=Enum.Font.GothamMedium,
        TextSize=14,AutoButtonColor=true,
    },parent)
    rounded(b,13)
    return b
end
local function label(parent,text,pos,size,fontSize,color)
    return make("TextLabel",{
        Text=text,Position=pos,Size=size,BackgroundTransparency=1,
        TextColor3=color or theme.ink,Font=Enum.Font.GothamMedium,
        TextSize=fontSize or 14,TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true,
    },parent)
end

local toggle=button(gui,"=^.^=",UDim2.fromOffset(65,60),theme.accent2)
toggle.AnchorPoint=Vector2.new(1,0)
toggle.Position=UDim2.new(1,-14,0,15)
toggle.TextSize=23
make("UIStroke",{Color=theme.white,Thickness=2,Transparency=.17},toggle)
local panel=make("Frame",{
    Name="Creator",
    Size=UDim2.fromOffset(354,610),
    AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,384,0,16),
    BackgroundColor3=theme.panel,BorderSizePixel=0,ClipsDescendants=true,
},gui)
rounded(panel,23)
make("UIStroke",{Color=theme.accent2,Thickness=2,Transparency=.05},panel)
local header=make("Frame",{Size=UDim2.new(1,0,0,68),BackgroundColor3=theme.accent2,BorderSizePixel=0},panel)
label(header,"ExtasyCatBOY",UDim2.fromOffset(17,7),UDim2.new(1,-62,0,32),22)
label(header,"Seu companheiro virtual | NPC",UDim2.fromOffset(18,37),UDim2.new(1,-70,0,21),11,theme.muted)
local close=button(header,"×",UDim2.fromOffset(34,34),theme.panel)
close.Position=UDim2.new(1,-47,0,16)
close.TextSize=23

local message=label(panel,"Escolha um amigo da sua lista.",UDim2.fromOffset(17,75),UDim2.new(1,-34,0,30),12,theme.muted)
local friendHeader=label(panel,"Amigos do Roblox",UDim2.fromOffset(18,110),UDim2.new(1,-35,0,23),15)
local reload=button(panel,"↻",UDim2.fromOffset(31,28),theme.accent2)
reload.Position=UDim2.new(1,-45,0,108)
reload.TextSize=17
local search=make("TextBox",{
    PlaceholderText="Buscar nome do amigo...",
    Text="",TextColor3=theme.ink,PlaceholderColor3=theme.muted,
    BackgroundColor3=theme.base,TextSize=13,
    Font=Enum.Font.Gotham,ClearTextOnFocus=false,
    TextXAlignment=Enum.TextXAlignment.Left,
    Size=UDim2.new(1,-36,0,36),Position=UDim2.fromOffset(18,144),
},panel)
rounded(search,10)
pad(search,12,0,8,0)
local friendList=make("ScrollingFrame",{
    Name="Friends",
    Position=UDim2.fromOffset(18,188),Size=UDim2.new(1,-36,0,158),
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,
    ScrollBarThickness=3,BorderSizePixel=0,BackgroundTransparency=1,
    ScrollingDirection=Enum.ScrollingDirection.Y,
},panel)
local listLayout=make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},friendList)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    friendList.CanvasSize=UDim2.fromOffset(0,listLayout.AbsoluteContentSize.Y+6)
end)
local currentFriend=nil
local friends={}
local pickedKind="cat"
local pickedMood="timido"
local currentNPC=nil

label(panel,"Tipo",UDim2.fromOffset(18,356),UDim2.fromOffset(310,22),15)
local catButton=button(panel,"Gatinho :3",UDim2.new(.5,-24,0,35),theme.accent)
catButton.Position=UDim2.fromOffset(18,382)
local dogButton=button(panel,"Cachorrinho",UDim2.new(.5,-24,0,35),theme.accent2)
dogButton.Position=UDim2.new(.5,5,0,382)
label(panel,"Personalidade",UDim2.fromOffset(18,425),UDim2.fromOffset(310,22),15)
local moodArea=make("Frame",{Position=UDim2.fromOffset(18,453),Size=UDim2.new(1,-36,0,80),BackgroundTransparency=1},panel)
local grid=make("UIGridLayout",{
    CellSize=UDim2.new(1/3,-5,0,34),
    CellPadding=UDim2.fromOffset(6,6),SortOrder=Enum.SortOrder.LayoutOrder,
},moodArea)
local moods={
    {"timido","Tímido"}, {"tsundere","Tsundere"}, {"brincalhao","Brincalhão"},
    {"sonolento","Sonolento"}, {"bravo","Bravinho"}, {"gentil","Gentil"},
}
local moodButtons={}
for i,item in ipairs(moods) do
    local b=button(moodArea,item[2],UDim2.new(1,0,0,34),theme.accent2)
    b.LayoutOrder=i
    b.TextSize=11
    moodButtons[item[1]]=b
    b.MouseButton1Click:Connect(function()
        pickedMood=item[1]
        for key,btn in pairs(moodButtons) do
            btn.BackgroundColor3 = key==pickedMood and theme.accent or theme.accent2
        end
    end)
end
moodButtons.timido.BackgroundColor3=theme.accent
local createButton=button(panel,"Adicionar companheiro",UDim2.new(1,-36,0,44),theme.accent)
createButton.Position=UDim2.fromOffset(18,543)
createButton.TextSize=15

local chatPane=make("Frame",{
    Name="Chat",BackgroundColor3=theme.panel,Position=UDim2.new(1,384,0,16),
    AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(354,166),BorderSizePixel=0,
},gui)
rounded(chatPane,20)
make("UIStroke",{Color=theme.accent2,Thickness=2},chatPane)
label(chatPane,"Conversar com seu NPC",UDim2.fromOffset(16,9),UDim2.new(1,-70,0,28),16)
local closeChat=button(chatPane,"×",UDim2.fromOffset(34,32),theme.accent2)
closeChat.Position=UDim2.new(1,-46,0,9)
closeChat.TextSize=22
local talk=make("TextBox",{
    Position=UDim2.fromOffset(14,50),Size=UDim2.new(1,-28,0,58),
    ClearTextOnFocus=false,Text="",
    PlaceholderText="Diga oi, faça uma pergunta...",
    TextColor3=theme.ink,PlaceholderColor3=theme.muted,
    TextSize=13,TextWrapped=true,MultiLine=false,
    Font=Enum.Font.Gotham,BackgroundColor3=theme.base,BorderSizePixel=0,
},chatPane)
rounded(talk,12)
pad(talk,9,5,9,5)
local send=button(chatPane,"Enviar",UDim2.fromOffset(130,35),theme.accent)
send.Position=UDim2.new(1,-144,0,119)
local remove=button(chatPane,"Guardar",UDim2.fromOffset(116,35),theme.accent2)
remove.Position=UDim2.fromOffset(14,119)

local window="none"
local function fit()
    local cam=workspace.CurrentCamera
    local view=cam and cam.ViewportSize or Vector2.new(800,680)
    local width=math.clamp(view.X-20,230,354)
    local height=math.clamp(view.Y-95,430,610)
    panel.Size=UDim2.fromOffset(width,height)
    -- Em telas compactas, escala o conteudo vertical sem invadir o chat.
    local scale=panel:FindFirstChild("MobileScale")
    if not scale then scale=make("UIScale",{Name="MobileScale"},panel) end
    scale.Scale=math.min(1,height/610,width/354)
    panel.Size=UDim2.fromOffset(width,math.min(height,610))
    local chatWidth=math.clamp(view.X-20,230,354)
    chatPane.Size=UDim2.fromOffset(chatWidth,166)
end
local cam=workspace.CurrentCamera
if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
fit()
local function showWindow(which)
    window=which
    local creatorPos=which=="creator" and UDim2.new(1,-14,0,16) or UDim2.new(1,384,0,16)
    local chatPos=which=="chat" and UDim2.new(1,-14,0,16) or UDim2.new(1,384,0,16)
    TweenService:Create(panel,TweenInfo.new(.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=creatorPos}):Play()
    TweenService:Create(chatPane,TweenInfo.new(.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=chatPos}):Play()
end
-- Seletor compacto de NPCs ativos. Cada botao abre a conversa daquele personagem.
local ownedNPCs = {}
local quickBar=make("Frame",{
    Name="MeusCompanheiros",Position=UDim2.fromOffset(12,85),
    Size=UDim2.fromOffset(77,248),BackgroundTransparency=1,
},gui)
local quickLayout=make("UIListLayout",{
    FillDirection=Enum.FillDirection.Vertical,
    Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder,
},quickBar)
local function redrawNPCs()
    for _,child in ipairs(quickBar:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local compact={}
    for _,model in ipairs(ownedNPCs) do
        if model and model.Parent then table.insert(compact,model) end
    end
    ownedNPCs=compact
    for i,model in ipairs(ownedNPCs) do
        local species=model:GetAttribute("Kind")=="dog" and "Au!" or "Miau!"
        local title=tostring(model:GetAttribute("CompanionDisplayName") or "Amigo")
        local b=button(quickBar,species.."\n"..string.sub(title,1,9),
            UDim2.fromOffset(75,52),model==currentNPC and theme.accent or theme.accent2)
        b.LayoutOrder=i
        b.TextSize=11
        b.TextWrapped=true
        b.MouseButton1Click:Connect(function()
            currentNPC=model
            showWindow("chat")
            redrawNPCs()
        end)
    end
end
toggle.MouseButton1Click:Connect(function()
    showWindow(window=="creator" and "none" or "creator")
end)
close.MouseButton1Click:Connect(function() showWindow("none") end)
closeChat.MouseButton1Click:Connect(function() showWindow("none") end)
catButton.MouseButton1Click:Connect(function()
    pickedKind="cat"
    catButton.BackgroundColor3=theme.accent
    dogButton.BackgroundColor3=theme.accent2
end)
dogButton.MouseButton1Click:Connect(function()
    pickedKind="dog"
    dogButton.BackgroundColor3=theme.dog
    catButton.BackgroundColor3=theme.accent2
end)

local function renderFriends()
    for _, child in ipairs(friendList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local needle=string.lower(search.Text)
    local shown=0
    for _,friend in ipairs(friends) do
        if needle=="" or string.find(string.lower(friend.displayName),needle,1,true) or string.find(string.lower(friend.username),needle,1,true) then
            shown+=1
            if shown>80 then break end
            local row=make("Frame",{
                Size=UDim2.new(1,-5,0,49),BackgroundColor3=theme.base,
                BorderSizePixel=0,
            },friendList)
            rounded(row,12)
            local photo=make("ImageLabel",{
                Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(38,38),
                BackgroundTransparency=1,
                Image="rbxthumb://type=AvatarHeadShot&id="..tostring(friend.id).."&w=150&h=150",
            },row)
            rounded(photo,11)
            local title=label(row,friend.displayName,UDim2.fromOffset(51,5),UDim2.new(1,-117,0,21),13)
            title.TextTruncate=Enum.TextTruncate.AtEnd
            local user=label(row,"@"..friend.username,UDim2.fromOffset(51,25),UDim2.new(1,-117,0,20),10,theme.muted)
            user.TextTruncate=Enum.TextTruncate.AtEnd
            local choose=button(row,"Usar",UDim2.fromOffset(57,31),theme.accent2)
            choose.Position=UDim2.new(1,-63,0,9)
            choose.TextSize=11
            choose.MouseButton1Click:Connect(function()
                currentFriend=friend
                message.Text="Selecionado: @"..friend.username
            end)
        end
    end
    if #friends==0 then
        message.Text="Nenhum amigo encontrado ou lista indisponível."
    elseif shown==0 then
        message.Text="Nenhum resultado nessa busca."
    end
end
search:GetPropertyChangedSignal("Text"):Connect(renderFriends)
local function loadFriends()
    message.Text="Carregando sua lista de amigos..."
    local ok,result,payload=pcall(function() return request:InvokeServer("friends") end)
    if not ok or not result then
        message.Text=ok and tostring(payload) or "Não consegui acessar a lista. Tente de novo."
        return
    end
    friends=payload
    renderFriends()
    message.Text="Escolha um amigo para criar seu NPC."
end
reload.MouseButton1Click:Connect(function() task.spawn(loadFriends) end)
createButton.MouseButton1Click:Connect(function()
    if not currentFriend then message.Text="Selecione um amigo primeiro."; return end
    createButton.Text="Criando..."
    createButton.Active=false
    local ok,success,answer=pcall(function()
        return request:InvokeServer("create",{friendId=currentFriend.id,kind=pickedKind,personality=pickedMood})
    end)
    message.Text=ok and tostring(answer) or "Erro na criação. Tente novamente."
    createButton.Text="Adicionar companheiro"
    createButton.Active=true
    if ok and success then showWindow("chat") end
end)
local function selectedFriendId()
    if currentNPC and currentNPC.Parent then
        return tonumber(currentNPC:GetAttribute("InspiredByUserId"))
    end
    return nil
end
local function sendTalk()
    local text=talk.Text
    talk.Text=""
    if type(text)~="string" or #text==0 then return end
    local friendId=selectedFriendId()
    if not friendId then
        message.Text="Escolha um NPC para conversar."
        showWindow("creator")
        return
    end
    event:FireServer("talk",string.sub(text,1,200),friendId)
end
send.MouseButton1Click:Connect(sendTalk)
talk.FocusLost:Connect(function(enter)
    if enter then sendTalk() end
end)
remove.MouseButton1Click:Connect(function()
    local friendId=selectedFriendId()
    if not friendId then showWindow("creator") return end
    local ok,success=pcall(function()
        return request:InvokeServer("remove",{friendId=friendId})
    end)
    if ok and success then
        currentNPC=nil
        showWindow("creator")
        message.Text="Companheiro guardado. Você pode criar outro."
    end
end)
event.OnClientEvent:Connect(function(kind,a,b,c)
    if kind=="spawned" then
        if typeof(a)=="Instance" then
            currentNPC=a
            table.insert(ownedNPCs,a)
            redrawNPCs()
        end
    elseif kind=="removed" then
        for i=#ownedNPCs,1,-1 do
            local model=ownedNPCs[i]
            if not model or not model.Parent
                or tonumber(model:GetAttribute("InspiredByUserId"))==tonumber(a) then
                table.remove(ownedNPCs,i)
            end
        end
        currentNPC=ownedNPCs[#ownedNPCs]
        redrawNPCs()
    elseif kind=="openTalk" then
        if typeof(a)=="Instance" then currentNPC=a end
        redrawNPCs()
        showWindow("chat")
    elseif kind=="bubble" then
        local model=a
        local head=model and model:FindFirstChild("Head")
        if head and type(b)=="string" then
            local ok=pcall(function() TextChatService:DisplayBubble(head,b) end)
            if not ok then
                -- Fallback: a mensagem ja veio de uma biblioteca fixa, nao do texto do usuario.
                message.Text=b
                showWindow("creator")
            end
        end
    end
end)
-- Chat nativo: somente texto ja entregue/filtrado ao proprio cliente, quando disponivel.
-- Nao confia nos textos recebidos pelo servidor: a resposta sempre vem de biblioteca segura.
local lastNativeText=""
local lastNativeTime=0
TextChatService.MessageReceived:Connect(function(msg)
    local source=msg.TextSource
    if not source or source.UserId~=player.UserId or not currentNPC then return end
    if typeof(msg.Text)~="string" or #msg.Text==0 then return end
    local now=os.clock()
    if msg.Text==lastNativeText and now-lastNativeTime<2 then return end
    lastNativeText=msg.Text
    lastNativeTime=now
    local friendId=selectedFriendId()
    if friendId then event:FireServer("talk",string.sub(msg.Text,1,200),friendId) end
end)
task.spawn(loadFriends)
