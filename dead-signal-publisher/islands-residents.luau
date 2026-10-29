local Players=game:GetService('Players')
local M={}
M.Definitions={
 {id='Tomas',name='Tomás',role='Reparador do cais',island='city',offset=Vector3.new(20,0,8),hair=62234425,shirt=144076358,pants=144076760,male=true,height=1.08,width=.95,skin=Color3.fromRGB(173,122,86),line='A maré voltou. O estranho é que as cordas continuam puxando para cima.'},
 {id='Helena',name='Helena',role='Dona da hospedaria',island='city',offset=Vector3.new(-24,0,12),hair=62724852,shirt=144076436,pants=398633812,male=false,height=.97,width=.83,skin=Color3.fromRGB(112,76,57),line='Se ouvir alguém na porta depois da meia-noite, olha pela janela primeiro.'},
 {id='Caio',name='Caio',role='Entregador',island='city',offset=Vector3.new(12,0,-30),hair=16630147,shirt=607785314,pants=398633812,male=true,height=1.02,width=.85,skin=Color3.fromRGB(222,174,135),line='Eu devia entregar uma carta aqui. O endereço existe, mas a pessoa diz que nunca morou lá.'},
 {id='Irene',name='Irene',role='Observadora do céu',island='city',offset=Vector3.new(-36,0,-22),hair=63690008,shirt=398633584,pants=144076760,male=false,height=1.04,width=.8,skin=Color3.fromRGB(229,194,162),line='Não é uma estrela. E ontem ele parecia menor.'},
 {id='Mara',name='Mara',role='Pesquisadora de campo',island='forestCurrent',offset=Vector3.new(26,0,18),hair=62724852,shirt=398633584,pants=144076760,male=false,height=1.01,width=.88,skin=Color3.fromRGB(145,98,69),line='As árvores ainda se inclinam com o vento. Pelo menos alguma coisa aqui continua normal.'},
 {id='Davi',name='Davi',role='Viajante',island='forest1',offset=Vector3.new(-20,0,-14),hair=16630147,shirt=144076436,pants=398633812,male=true,height=.99,width=.91,skin=Color3.fromRGB(197,145,106),line='Eu marquei a trilha antes de escurecer. Quando voltei, as marcas estavam do outro lado.'},
}
function M.Build(def)
 local d=Instance.new('HumanoidDescription')
 d.Head=86498048;d.Face=def.male and 86487700 or 86487766
 d.Torso=def.male and 86500008 or 86499666;d.RightArm=def.male and 86500036 or 86499698;d.LeftArm=def.male and 86500054 or 86499716
 d.LeftLeg=def.male and 86500064 or 86499753;d.RightLeg=def.male and 86500078 or 86499793
 d.HairAccessory=tostring(def.hair);d.Shirt=def.shirt;d.Pants=def.pants
 d.HeightScale=def.height;d.WidthScale=def.width;d.DepthScale=.94;d.HeadScale=.98;d.BodyTypeScale=.7;d.ProportionScale=.3
 for _,key in ipairs({'HeadColor','TorsoColor','LeftArmColor','RightArmColor','LeftLegColor','RightLegColor'}) do d[key]=def.skin end
 local rig=Players:CreateHumanoidModelFromDescriptionAsync(d,Enum.HumanoidRigType.R15);d:Destroy()
 rig.Name=def.id;rig:SetAttribute('ResidentId',def.id);rig:SetAttribute('ResidentName',def.name);rig:SetAttribute('ResidentRole',def.role)
 for _,v in ipairs(rig:GetDescendants()) do
  if v:IsA('LuaSourceContainer') then v:Destroy() end
  if v:IsA('BasePart') then v.CanCollide=false;v.CanTouch=false;v.CanQuery=false end
 end
 local hum=assert(rig:FindFirstChildOfClass('Humanoid'));hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.WalkSpeed=5;hum.BreakJointsOnDeath=false
 local root=assert(rig:FindFirstChild('HumanoidRootPart'));root.Anchored=true
 assert(rig:FindFirstChildOfClass('Shirt') and rig:FindFirstChildOfClass('Pants'),'Incomplete clothes: '..def.id)
 assert(rig:FindFirstChildWhichIsA('Accessory'),'Missing hair: '..def.id)
 local face=rig.Head:FindFirstChildWhichIsA('Decal');assert(face and face.Texture~='','Missing face: '..def.id)
 local desc=hum:GetAppliedDescription();assert(desc.Torso>0 and desc.LeftArm>0 and desc.RightLeg>0,'Missing authored body');desc:Destroy()
 return rig
end
return M
