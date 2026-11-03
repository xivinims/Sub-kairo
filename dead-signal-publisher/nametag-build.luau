local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local function instance(class,name,parent)
 local o=R.Instance.new(class);o.Name=name;o.Parent=parent;return o
end
local source=R.deserializeModel(fs.readFile('/tmp/nametag-source.rbxm'))[1]
local original=assert(source:FindFirstChild('Nametag',true))
assert(original:IsA('ModuleScript'))
local template=assert(original:FindFirstChild('Nametag',true)):Clone()
local name=template.Properties.Player.displaynamelabel:Clone()
local title=template.Properties.Player.namelabel:Clone()
local level=template.Properties.List.valueframe.valuelabel:Clone()
template:ClearAllChildren()
template.Name='FalloutNametagTemplate'
template.Enabled=false;template.Size=R.UDim2.fromScale(6,1.65)
template.StudsOffset=R.Vector3.new(0,2.55,0)
template.StudsOffsetWorldSpace=R.Vector3.zero
template.ExtentsOffset=R.Vector3.zero;template.ExtentsOffsetWorldSpace=R.Vector3.zero
template.AlwaysOnTop=false;template.MaxDistance=65;template.LightInfluence=0
template:SetAttribute('SourceAssetId','72094860266497')
template:SetAttribute('SourceCreator','Bconggs')
for index,label in ipairs({name,title,level}) do
 label.Name=({'DisplayName','TenureTitle','Level'})[index]
 label.Text=({'Jogador','Iniciante','Nível 1'})[index]
 label.AnchorPoint=R.Vector2.zero;label.Position=R.UDim2.fromScale(0,({0,.39,.67})[index])
 label.Size=R.UDim2.fromScale(1,({.4,.28,.27})[index]);label.BackgroundTransparency=1
 label.TextScaled=true;label.TextWrapped=false;label.RichText=false
 label.TextXAlignment=R.Enum.TextXAlignment.Center;label.TextYAlignment=R.Enum.TextYAlignment.Center
 label.Visible=true;label.TextColor3=R.Color3.fromRGB(242,244,247)
 for _,child in ipairs(label:GetChildren()) do
  if child:IsA('UIGradient') then child:Destroy()
  elseif child:IsA('UIStroke') then child.Thickness=1.3;child.Transparency=.22;child.Color=R.Color3.fromRGB(17,21,25) end
 end
 label.Parent=template
end
title.TextColor3=R.Color3.fromRGB(166,217,179)
level.TextColor3=R.Color3.fromRGB(202,209,220)
local bundle=instance('Model','NametagPatch')
template.Parent=bundle
for name,file in pairs({Progress='fallout-progress.luau',Profiles='fallout-profiles.luau',Nametags='fallout-nametags.luau'}) do
 local code=fs.readFile(file);luau.load(code,{debugName=file})
 local module=instance('ModuleScript',name,bundle);module.Source=code
end
local controller=instance('Script','NametagController',bundle)
controller.Source='require(script.Parent.Nametags).start()'
fs.writeFile('/tmp/nametag-bundle.rbxm',R.serializeModel({bundle}))
require('./nametag-tests')
print('NAMETAG_BUILD '..serde.encode('json',{source='72094860266497',instances=#bundle:GetDescendants(),scripts=4,tests=true}))
