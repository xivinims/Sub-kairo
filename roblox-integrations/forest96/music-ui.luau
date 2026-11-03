local M={}
local function create(class,parent,name)local obj=Instance.new(class)obj.Name=name obj.Parent=parent return obj end
local function round(obj)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,10)c.Parent=obj end
local function label(parent,name,text,height)
 local l=create("TextLabel",parent,name)l.Text=text l.Size=UDim2.new(1,0,0,height or 22)l.Font=Enum.Font.Gotham l.TextSize=13 l.TextColor3=Color3.fromRGB(240,240,240)l.BackgroundTransparency=1 l.TextWrapped=true l.TextXAlignment=Enum.TextXAlignment.Left return l
end
local function button(parent,name,text)
 local b=create("TextButton",parent,name)b.Size=UDim2.new(1,0,0,42)b.Text=text b.Font=Enum.Font.GothamMedium b.TextSize=13 b.BackgroundColor3=Color3.fromRGB(12,12,12)b.TextColor3=Color3.fromRGB(240,240,240)b.BorderSizePixel=0 b.BackgroundTransparency=.35 round(b)return b
end
function M.build(parent,tracks)
 local gui=create("ScreenGui",parent,"TreeWorldPersonalMusic")gui.ResetOnSpawn=false gui.DisplayOrder=25 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local open=button(gui,"Open","♫ Música")open.AnchorPoint=Vector2.new(1,0)open.Position=UDim2.new(1,-12,0,12)open.Size=UDim2.fromOffset(100,38)
 local panel=create("Frame",gui,"Panel")panel.AnchorPoint=Vector2.new(1,0)panel.Position=UDim2.new(1,-12,0,60)panel.Size=UDim2.new(.9,0,.72,0)panel.BackgroundColor3=Color3.fromRGB(12,12,12)panel.BackgroundTransparency=.22 panel.BorderSizePixel=0 panel.Visible=false round(panel)
 local limit=create("UISizeConstraint",panel,"SizeLimit")limit.MaxSize=Vector2.new(340,490)limit.MinSize=Vector2.new(210,150)
 local scroll=create("ScrollingFrame",panel,"Scroll")scroll.Size=UDim2.fromScale(1,1)scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=Color3.fromRGB(240,240,240)scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new()scroll.ScrollingDirection=Enum.ScrollingDirection.Y
 local pad=create("UIPadding",scroll,"Padding")pad.PaddingTop=UDim.new(0,14)pad.PaddingBottom=UDim.new(0,14)pad.PaddingLeft=UDim.new(0,14)pad.PaddingRight=UDim.new(0,14)
 local layout=create("UIListLayout",scroll,"Layout")layout.Padding=UDim.new(0,8)layout.SortOrder=Enum.SortOrder.LayoutOrder
 local refs={gui=gui,open=open,panel=panel,tracks={}}local order=0
 local function add(obj)order+=1 obj.LayoutOrder=order return obj end
 add(label(scroll,"Title","Seu rádio",24)).Font=Enum.Font.GothamBold
 add(label(scroll,"Privacy","Só você ouve. A nametag mostra quando está ouvindo.",36))
 refs.status=add(label(scroll,"Status","Escolha uma música",36))
 for _,category in ipairs({"Em inglês","Natureza"})do add(label(scroll,"Category",category,24)).Font=Enum.Font.GothamBold
  for _,track in ipairs(tracks)do if track.category==category then local b=add(button(scroll,"Track",track.title))b:SetAttribute("AssetId",track.id)refs.tracks[#refs.tracks+1]={button=b,track=track}end end
 end
 add(label(scroll,"CustomTitle","Sua música · ID do Roblox",24))
 refs.input=add(create("TextBox",scroll,"AudioId"))refs.input.Size=UDim2.new(1,0,0,42)refs.input.PlaceholderText="Cole o ID de áudio"refs.input.Text=""refs.input.ClearTextOnFocus=false refs.input.Font=Enum.Font.Gotham refs.input.TextSize=14 refs.input.BackgroundColor3=Color3.fromRGB(12,12,12)refs.input.TextColor3=Color3.fromRGB(240,240,240)refs.input.BorderSizePixel=0 refs.input.BackgroundTransparency=.35 round(refs.input)
 refs.play=add(button(scroll,"PlayId","Ouvir meu ID"))refs.pause=add(button(scroll,"Pause","Pausar / continuar"))refs.stop=add(button(scroll,"Stop","Parar"))
 add(label(scroll,"VolumeTitle","Volume",22))refs.lower=add(button(scroll,"Quieter","Diminuir volume"))refs.louder=add(button(scroll,"Louder","Aumentar volume"))
 return refs
end
return M
