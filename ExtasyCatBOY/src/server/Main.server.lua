-- ExtasyCatBOY: authoritative server (R6). Nao modifica os NPCs nem o mapa de outros jogos.
-- Cada personagem representa apenas um avatar inspirado em um amigo, nunca a conta real.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Config = require(ReplicatedStorage:WaitForChild("ExtasyShared"):WaitForChild("Config"))
local Dialogue = require(ReplicatedStorage.ExtasyShared:WaitForChild("Dialogue"))

local remotes = Instance.new("Folder")
remotes.Name = "ExtasyRemotes"
remotes.Parent = ReplicatedStorage
local request = Instance.new("RemoteFunction")
request.Name = "Request"
request.Parent = remotes
local event = Instance.new("RemoteEvent")
event.Name = "Event"
event.Parent = remotes

local companionsFolder = Instance.new("Folder")
companionsFolder.Name = "ExtasyCompanions"
companionsFolder.Parent = workspace
local byPlayer = {}
local lastAction = {}
local lastChat = {}
local profileStore = DataStoreService:GetDataStore("ExtasyCatBOY_profiles_v1")
local moods = {timido=true,tsundere=true,brincalhao=true,sonolento=true,bravo=true,gentil=true}

local function allowed(player, bucket, seconds)
    local now = os.clock()
    local previous = bucket[player.UserId] or -999
    if now - previous < seconds then return false end
    bucket[player.UserId] = now
    return true
end

local function safeFriend(player, id)
    if type(id) ~= "number" or id < 1 or id == player.UserId or id ~= math.floor(id) then return false end
    local ok, result = pcall(function() return player:IsFriendsWithAsync(id) end)
    return ok and result == true
end

local function isOnline(player)
    return player.Parent == Players
end

local function notify(player, kind, ...)
    if isOnline(player) then event:FireClient(player,kind,...) end
end

local function getFriends(player)
    local friends = {}
    local ok, pages = pcall(function() return Players:GetFriendsAsync(player.UserId) end)
    if not ok then return {}, "A lista de amigos não está disponível agora." end
    repeat
        for _, item in ipairs(pages:GetCurrentPage()) do
            if type(item.Id) == "number" then
                table.insert(friends, {
                    id = item.Id,
                    username = tostring(item.Username or ""),
                    displayName = tostring(item.DisplayName or item.Username or "Amigo"),
                })
            end
            if #friends >= 300 then break end
        end
        if pages.IsFinished or #friends >= 300 then break end
        local advanced = pcall(function() pages:AdvanceToNextPageAsync() end)
        if not advanced then break end
    until false
    table.sort(friends, function(a,b) return string.lower(a.displayName) < string.lower(b.displayName) end)
    return friends
end

local function addPart(parent, name, size, cframe, color, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.CFrame = cframe
    p.Shape = shape or Enum.PartType.Block
    p.CanCollide = false
    p.CanTouch = false
    p.Massless = true
    p.Material = Enum.Material.SmoothPlastic
    p.Parent = parent
    return p
end

local function decorate(model, kind)
    local head = model:FindFirstChild("Head")
    local torso = model:FindFirstChild("Torso")
    if not head or not torso then return end
    local shell = Instance.new("Folder")
    shell.Name = "CuteDetails"
    shell.Parent = model
    local outer = kind == "cat" and Color3.fromRGB(222,177,171) or Color3.fromRGB(201,154,119)
    local inner = Color3.fromRGB(244,176,196)
    local function weldPart(p, root)
        local joint = Instance.new("WeldConstraint")
        joint.Part0 = root
        joint.Part1 = p
        joint.Parent = p
    end
    for _, side in ipairs({-1, 1}) do
        if kind == "cat" then
            local ear = Instance.new("WedgePart")
            ear.Name = "Orelhinha"
            ear.Size = Vector3.new(.48,.62,.28)
            ear.Color = outer
            ear.Material = Enum.Material.SmoothPlastic
            ear.CanCollide = false
            ear.Massless = true
            ear.CFrame = head.CFrame * CFrame.new(.52 * side,.65,-.02) * CFrame.Angles(0,side*math.rad(12),0)
            ear.Parent = shell
            weldPart(ear,head)
            local pink = addPart(shell,"DetalheOrelha",Vector3.new(.28,.35,.05),head.CFrame * CFrame.new(.52*side,.70,-.19),inner)
            weldPart(pink,head)
        else
            local ear = addPart(shell,"OrelhaCaida",Vector3.new(.43,.8,.35),head.CFrame * CFrame.new(1.03*side,.1,0),outer)
            ear.Orientation = ear.Orientation + Vector3.new(0,0,12 * side)
            weldPart(ear,head)
        end
    end
    local tail = addPart(shell, kind == "cat" and "CaudinhaDeGato" or "CaudinhaDeCachorro",
        Vector3.new(.33,1.35,.33),torso.CFrame * CFrame.new(0,-.28,.75) * CFrame.Angles(math.rad(55),0,0),outer,Enum.PartType.Cylinder)
    local motor = Instance.new("Motor6D")
    motor.Name = "CuteTailMotor"
    motor.Part0 = torso
    motor.Part1 = tail
    motor.C0 = torso.CFrame:ToObjectSpace(tail.CFrame)
    motor.C1 = CFrame.new()
    motor.Parent = torso
end

local function nameTag(model, displayName, kind, personality)
    local head = model:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ExtasyName"
    bb.Size = UDim2.fromOffset(260,67)
    bb.StudsOffsetWorldSpace = Vector3.new(0,2.3,0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 55
    bb.Parent = head
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1,1)
    bg.BackgroundColor3 = Color3.fromRGB(42,43,49)
    bg.BackgroundTransparency = .18
    bg.Parent = bb
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,16)
    c.Parent = bg
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1,1)
    text.TextColor3 = Color3.fromRGB(255,240,244)
    text.Font = Enum.Font.GothamMedium
    text.TextScaled = true
    text.Text = string.format("%s %s\nNPC inspirado em amigo • %s",kind == "cat" and "Gatinho" or "Cachorrinho",displayName,personality)
    text.Parent = bg
end

local function spawn(player, friendId, kind, personality, displayName)
    local okDesc, description = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(friendId) end)
    if not okDesc then return false, "Não consegui carregar o avatar desse amigo." end
    local okModel, model = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
    end)
    if not okModel or not model then return false, "Falha ao criar o personagem R6." end
    local old = byPlayer[player.UserId]
    if old and old.model then old.model:Destroy() end
    model.Name = "Companion_" .. tostring(player.UserId)
    model:SetAttribute("ExtasyNPC",true)
    model:SetAttribute("OwnerId",player.UserId)
    model:SetAttribute("InspiredByUserId",friendId)
    model:SetAttribute("Kind",kind)
    model:SetAttribute("Personality",personality)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then model:Destroy() return false,"Avatar incompleto." end
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.WalkSpeed = personality == "sonolento" and 8 or 11
    humanoid.JumpPower = 30
    humanoid.AutoRotate = true
    humanoid.BreakJointsOnDeath = false
    local avatar = player.Character
    local playerRoot = avatar and avatar:FindFirstChild("HumanoidRootPart")
    local targetCF = playerRoot and (playerRoot.CFrame * CFrame.new(4,1,4)) or CFrame.new(4,6,4)
    model.Parent = companionsFolder
    model:PivotTo(targetCF)
    root:SetNetworkOwner(nil)
    decorate(model,kind)
    nameTag(model,displayName,kind,personality)
    local head = model:FindFirstChild("Head")
    if head then
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "Conversar"
        prompt.ObjectText = "Companheiro virtual"
        prompt.ActionText = "Conversar"
        prompt.MaxActivationDistance = 10
        prompt.HoldDuration = 0
        prompt.Parent = head
        prompt.Triggered:Connect(function(who)
            if who == player then notify(player,"openTalk") end
        end)
    end
    byPlayer[player.UserId] = {
        model=model,friendId=friendId,kind=kind,personality=personality,
        displayName=displayName,phase=math.random()*6,lastFollow=0,
    }
    notify(player,"spawned",model,kind,personality)
    notify(player,"bubble",model,Dialogue.Respond("oi",kind,personality,tostring(player.UserId)))
    return true,"Companheiro criado!"
end

local function save(player)
    local rec = byPlayer[player.UserId]
    if not rec then return end
    local payload = {
        friendId=rec.friendId, kind=rec.kind,
        personality=rec.personality, displayName=rec.displayName,
    }
    pcall(function()
        profileStore:UpdateAsync(Config.SaveKeyPrefix .. player.UserId,function() return payload end)
    end)
end

request.OnServerInvoke = function(player,operation,payload)
    if not isOnline(player) or type(operation)~="string" then return false,"Pedido inválido." end
    if operation == "friends" then
        if not allowed(player,lastAction,2) then return false,"Espere um instante." end
        local friends,err = getFriends(player)
        if err then return false,err end
        return true,friends
    end
    if operation == "create" then
        if not allowed(player,lastAction,3) then return false,"Espere um instante para criar de novo." end
        if type(payload) ~= "table" then return false,"Dados inválidos." end
        local id=tonumber(payload.friendId)
        local kind=payload.kind
        local personality=payload.personality
        if not Config.AllowedKinds[kind] or not moods[personality] or not safeFriend(player,id) then
            return false,"Escolha um usuário que esteja na sua lista de amizades."
        end
        local safeName = "Amigo"
        local okName, name = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
        if okName then safeName=tostring(name) end
        local ok,msg=spawn(player,id,kind,personality,safeName)
        if ok then task.defer(save,player) end
        return ok,msg
    end
    if operation == "remove" then
        if not allowed(player,lastAction,2) then return false,"Espere um instante." end
        local rec=byPlayer[player.UserId]
        if rec and rec.model then rec.model:Destroy() end
        byPlayer[player.UserId]=nil
        pcall(function() profileStore:RemoveAsync(Config.SaveKeyPrefix..player.UserId) end)
        notify(player,"removed")
        return true,"Companheiro guardado."
    end
    return false,"Operação desconhecida."
end

event.OnServerEvent:Connect(function(player,operation,message)
    if operation ~= "talk" or not allowed(player,lastChat,Config.ChatReplyCooldown) then return end
    local rec=byPlayer[player.UserId]
    if not rec or not rec.model or not rec.model.Parent then return end
    if type(message)~="string" or #message<1 or #message>220 then return end
    local avatarRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local npcRoot=rec.model:FindFirstChild("HumanoidRootPart")
    if not avatarRoot or not npcRoot or (avatarRoot.Position-npcRoot.Position).Magnitude>70 then return end
    local answer,context=Dialogue.Respond(message,rec.kind,rec.personality,tostring(player.UserId))
    notify(player,"bubble",rec.model,answer,context)
end)

-- Animacoes dos joints acontecem nos clientes em Animations.client.lua:
-- Motor6D.Transform nao replica a partir do servidor.

local accumulated=0
RunService.Heartbeat:Connect(function(dt)
    accumulated += dt
    if accumulated<.10 then return end
    accumulated=0
    local now=os.clock()
    for userId,rec in pairs(byPlayer) do
        local player=Players:GetPlayerByUserId(userId)
        local model=rec.model
        if not player or not model or not model.Parent then continue end
        local avatar=player.Character
        local charRoot=avatar and avatar:FindFirstChild("HumanoidRootPart")
        local npcRoot=model:FindFirstChild("HumanoidRootPart")
        local humanoid=model:FindFirstChildOfClass("Humanoid")
        if charRoot and npcRoot and humanoid and humanoid.Health>0 then
            local dist=(charRoot.Position-npcRoot.Position).Magnitude
            if dist>85 then
                model:PivotTo(charRoot.CFrame*CFrame.new(4,1,4))
            elseif dist>Config.FollowDistance and now-rec.lastFollow>Config.FollowUpdateInterval then
                rec.lastFollow=now
                local target=charRoot.Position-charRoot.CFrame.LookVector*4+charRoot.CFrame.RightVector*2
                humanoid:MoveTo(target)
            end
        end
    end
end)

local function buildCozyWorld()
    if not Config.AutoBuildCozyWorld then return end
    local existing=0
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and item.Parent~=companionsFolder then
            existing+=1
            if existing>12 then return end -- preserva um mapa existente
        end
    end
    local world=Instance.new("Folder")
    world.Name="ExtasyCozyVillage"
    world.Parent=workspace
    local function block(n,s,cf,col,mat)
        local p=addPart(world,n,s,cf,col)
        p.Anchored=true
        p.CanCollide=true
        p.Massless=false
        p.Material=mat or Enum.Material.SmoothPlastic
        return p
    end
    block("Jardim",Vector3.new(140,2,140),CFrame.new(0,-1.2,0),Color3.fromRGB(166,204,165),Enum.Material.Grass)
    block("Caminho",Vector3.new(14,.18,85),CFrame.new(0,.02,0),Color3.fromRGB(237,207,180))
    block("Praca",Vector3.new(39,.2,32),CFrame.new(0,.04,1),Color3.fromRGB(241,216,198))
    local spawnPad=Instance.new("SpawnLocation")
    spawnPad.Name="ExtasySpawn"
    spawnPad.Size=Vector3.new(10,1,10)
    spawnPad.CFrame=CFrame.new(0,.5,33)
    spawnPad.Anchored=true
    spawnPad.Neutral=true
    spawnPad.Transparency=1
    spawnPad.Parent=world
    for i=1,2 do
        local x=i==1 and -32 or 32
        block("Casa_Fachada",Vector3.new(22,12,18),CFrame.new(x,6,-20),Color3.fromRGB(249,230,222))
        block("Telhado",Vector3.new(26,1.5,21),CFrame.new(x,13,-20),Color3.fromRGB(188,131,144))
        block("Porta",Vector3.new(4,7,.3),CFrame.new(x,3.5,-10.82),Color3.fromRGB(164,127,113))
        for _,dx in ipairs({-6,6}) do
            block("Janela",Vector3.new(3.5,3.5,.35),CFrame.new(x+dx,7,-10.75),Color3.fromRGB(174,217,222),Enum.Material.Glass)
        end
    end
    for i=1,14 do
        local angle=i*math.pi*2/14
        local x,z=math.cos(angle)*54,math.sin(angle)*51
        block("ArvoreTronco",Vector3.new(2,8,2),CFrame.new(x,4,z),Color3.fromRGB(131,108,87),Enum.Material.Wood)
        local foliage=block("CopaRedonda",Vector3.new(10,10,10),CFrame.new(x,10,z),Color3.fromRGB(126,182,139),Enum.Material.Grass)
        foliage.Shape=Enum.PartType.Ball
    end
    for i=1,5 do
        local x=-18+i*6
        block("Almofada",Vector3.new(4,.45,3),CFrame.new(x,.45,14),Color3.fromRGB(242,184,202))
    end
    Lighting.ClockTime=15
    Lighting.Brightness=2
    Lighting.Ambient=Color3.fromRGB(177,170,180)
end
task.defer(buildCozyWorld)

Players.PlayerAdded:Connect(function(player)
    task.defer(function()
        local ok, data=pcall(function() return profileStore:GetAsync(Config.SaveKeyPrefix..player.UserId) end)
        if not ok or type(data)~="table" or not isOnline(player) then return end
        if not Config.AllowedKinds[data.kind] or not moods[data.personality] then return end
        if not safeFriend(player,tonumber(data.friendId)) then return end
        task.wait(4)
        if isOnline(player) then
            spawn(player,tonumber(data.friendId),data.kind,data.personality,tostring(data.displayName or "Amigo"))
        end
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    save(player)
    local rec=byPlayer[player.UserId]
    if rec and rec.model then rec.model:Destroy() end
    byPlayer[player.UserId]=nil
    lastAction[player.UserId]=nil
    lastChat[player.UserId]=nil
end)
game:BindToClose(function()
    for _,player in ipairs(Players:GetPlayers()) do save(player) end
end)
print("[ExtasyCatBOY] NPCs, amizade, salvamento e "..Dialogue.CountVariations().." variacoes de fala disponiveis")
