local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local Settings={}
function Settings.new(layer,send,onVisibility)
    local self={values={masterVolume=1,sfxVolume=0.85,dialogueVolume=1,reducedMotion=false,shadows=true,fov=75,
        sensitivity=1,brightness=0,subtitles=true,graphics="Médio"},controls={},visible=false}
    local bg=Instance.new("Frame"); bg.Name="SettingsOverlay"; bg.Size=UDim2.fromScale(1,1)
    bg.BackgroundColor3=Color3.fromRGB(9,12,13); bg.BackgroundTransparency=0.08; bg.Visible=false; bg.ZIndex=10; bg.Parent=layer
    local panel=Instance.new("Frame"); panel.Size=UDim2.fromScale(0.9,0.86); panel.Position=UDim2.fromScale(0.05,0.07)
    panel.BackgroundTransparency=1; panel.ZIndex=11; panel.Parent=bg
    local function text(parent,t,pos,size,font)
        local l=Instance.new("TextLabel"); l.Text=t; l.Position=pos; l.Size=size; l.BackgroundTransparency=1
        l.TextColor3=Color3.fromRGB(225,219,199); l.Font=font or Enum.Font.GothamMedium
        l.TextSize=18; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=12; l.Parent=parent; return l
    end
    local function button(parent,t,pos,size,fn)
        local b=Instance.new("TextButton"); b.Text=t; b.Position=pos; b.Size=size; b.BackgroundTransparency=1
        b.TextColor3=Color3.fromRGB(219,213,191); b.Font=Enum.Font.GothamBold; b.TextSize=18
        b.ZIndex=13; b.Modal=true; b.Parent=parent; b.Activated:Connect(fn); return b
    end
    text(panel,"CONFIGURAÇÕES",UDim2.fromScale(0,0),UDim2.fromScale(0.8,0.09),Enum.Font.GothamBlack).TextSize=30
    local rule=Instance.new("Frame"); rule.BackgroundColor3=Color3.fromRGB(131,116,79); rule.BorderSizePixel=0
    rule.Position=UDim2.fromScale(0,0.12); rule.Size=UDim2.new(1,0,0,2); rule.ZIndex=12; rule.Parent=panel
    local pages,tabs={},{}
    local function select(name)
        for id,p in pairs(pages) do p.Visible=id==name; tabs[id].TextColor3=id==name and Color3.fromRGB(229,181,89) or Color3.fromRGB(170,168,155) end
    end
    for i,name in ipairs({"JOGO","VÍDEO","ÁUDIO","CONTROLES"}) do
        tabs[name]=button(panel,name,UDim2.fromScale((i-1)*0.25,0.15),UDim2.fromScale(0.25,0.09),function() select(name) end)
        local p=Instance.new("ScrollingFrame"); p.Name=name; p.BackgroundTransparency=1
        p.Position=UDim2.fromScale(0,0.28); p.Size=UDim2.fromScale(1,0.58); p.CanvasSize=UDim2.new()
        p.AutomaticCanvasSize=Enum.AutomaticSize.Y; p.ScrollBarThickness=4; p.ScrollingDirection=Enum.ScrollingDirection.Y; p.ZIndex=12; p.Parent=panel
        local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,12); layout.Parent=p; pages[name]=p
    end
    local function apply()
        local v=self.values
        Lighting.GlobalShadows=v.shadows and v.graphics~="Baixo"
        UIS.MouseDeltaSensitivity=v.sensitivity
        if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=v.fov end
        local cc=Lighting:FindFirstChild("PlayerBrightness")
        if not cc then cc=Instance.new("ColorCorrectionEffect"); cc.Name="PlayerBrightness"; cc.Parent=Lighting end
        cc.Brightness=v.brightness
        layer:SetAttribute("Graphics",v.graphics)
        layer:SetAttribute("Subtitles",v.subtitles)
        layer:SetAttribute("ReducedMotion",v.reducedMotion)
        for _,s in ipairs(SoundService:GetChildren()) do
            if s:IsA("Sound") and s:GetAttribute("BaseVolume") then s.Volume=s:GetAttribute("BaseVolume")*v.masterVolume*v.sfxVolume end
        end
    end
    function self:Update() apply(); for _,fn in ipairs(self.controls) do fn() end end
    function self:SetVisible(show)
        self.visible=show; bg.Visible=show; onVisibility(show)
    end
    local function row(page,title)
        local r=Instance.new("Frame"); r.BackgroundColor3=Color3.fromRGB(35,39,38); r.BackgroundTransparency=0.25
        r.Size=UDim2.new(1,-10,0,58); r.ZIndex=12; r.Parent=pages[page]
        local l=text(r,title,UDim2.new(0,12,0,0),UDim2.new(0.52,-12,1,0)); l.TextWrapped=true
        return r
    end
    local function changed() self:Update(); send(self.values) end
    local function toggle(page,title,key)
        local r=row(page,title); local b
        b=button(r,"",UDim2.fromScale(0.58,0),UDim2.fromScale(0.4,1),function() self.values[key]=not self.values[key]; changed() end)
        table.insert(self.controls,function() b.Text=self.values[key] and "LIGADO" or "DESLIGADO" end)
    end
    local function slider(page,title,key,min,max,step,suffix)
        local r=row(page,title); local value=text(r,"",UDim2.fromScale(0.66,0),UDim2.fromScale(0.2,1))
        button(r,"−",UDim2.fromScale(0.53,0),UDim2.fromScale(0.12,1),function() self.values[key]=math.clamp(self.values[key]-step,min,max); changed() end)
        button(r,"+",UDim2.fromScale(0.86,0),UDim2.fromScale(0.12,1),function() self.values[key]=math.clamp(self.values[key]+step,min,max); changed() end)
        table.insert(self.controls,function() value.Text=tostring(suffix=="×" and self.values[key] or math.floor(self.values[key]*(suffix=="%" and 100 or 1)+0.5))..(suffix or "") end)
    end
    toggle("JOGO","Legendas", "subtitles")
    toggle("JOGO","Movimento reduzido", "reducedMotion")
    local cameraRow=row("JOGO","Câmera")
    text(cameraRow,"PRIMEIRA PESSOA",UDim2.fromScale(0.56,0),UDim2.fromScale(0.43,1)).TextSize=15
    slider("VÍDEO","Campo de visão","fov",60,100,5,"°")
    slider("VÍDEO","Brilho","brightness",-0.1,0.25,0.05,"%")
    toggle("VÍDEO","Sombras", "shadows")
    local gr=row("VÍDEO","Qualidade de efeitos"); local gb
    gb=button(gr,"",UDim2.fromScale(0.55,0),UDim2.fromScale(0.43,1),function()
        self.values.graphics=self.values.graphics=="Baixo" and "Médio" or self.values.graphics=="Médio" and "Alto" or "Baixo"; changed()
    end)
    table.insert(self.controls,function() gb.Text=self.values.graphics end)
    slider("ÁUDIO","Volume geral","masterVolume",0,1,0.1,"%")
    slider("ÁUDIO","Efeitos sonoros","sfxVolume",0,1,0.1,"%")
    slider("ÁUDIO","Diálogos","dialogueVolume",0,1,0.1,"%")
    slider("CONTROLES","Sensibilidade (mouse)","sensitivity",0.25,2,0.25,"×")
    for _,t in ipairs({"WASD / analógico — andar","SHIFT / CORRER — correr","C / AGACHAR — agachar","F / toque na interação — usar","E / USAR — mirar cabo","Q / SOLTAR — largar item","T / LUZ — lanterna","P / PAUSA — configurações"}) do
        local r=row("CONTROLES",t); r:FindFirstChildOfClass("TextLabel").Size=UDim2.new(1,-24,1,0)
    end
    button(panel,"VOLTAR",UDim2.fromScale(0,0.89),UDim2.fromScale(0.3,0.1),function() self:SetVisible(false) end)
    button(panel,"RESTAURAR PADRÃO",UDim2.fromScale(0.6,0.89),UDim2.fromScale(0.4,0.1),function()
        self.values={masterVolume=1,sfxVolume=0.85,dialogueVolume=1,reducedMotion=false,shadows=true,fov=75,sensitivity=1,brightness=0,subtitles=true,graphics="Médio"}; changed()
    end)
    UIS.InputBegan:Connect(function(i,processed) if not processed and i.KeyCode==Enum.KeyCode.P then self:SetVisible(not self.visible) end end)
    select("JOGO"); self:Update(); return self
end
return Settings
