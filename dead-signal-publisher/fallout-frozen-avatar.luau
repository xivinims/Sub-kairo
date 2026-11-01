-- Frozen from the owner avatar audit at 2026-11-01T14:36:42Z.
-- Never query the user's live outfit when spawning or refreshing the NPC.
local FrozenAvatar={}
function FrozenAvatar.create()
 local d=Instance.new('HumanoidDescription')
 d.BodyTypeScale=0
 d.ClimbAnimation=123695349157584
 d.DepthScale=0.8500000238418579
 d.Face=0
 d.FallAnimation=1090132063
 d.GraphicTShirt=0
 d.Head=114768729606879
 d.HeadScale=0.949999988079071
 d.HeightScale=0.8999999761581421
 d.IdleAnimation=126354114956642
 d.JumpAnimation=115715495289805
 d.LeftArm=0
 d.LeftLeg=0
 d.MoodAnimation=14618207727
 d.Pants=12900240938
 d.ProportionScale=0
 d.RightArm=0
 d.RightLeg=100234186631845
 d.RunAnimation=126640806116840
 d.Shirt=123193711263166
 d.SwimAnimation=18538158932
 d.Torso=0
 d.WalkAnimation=18538146480
 d.WidthScale=0.699999988079071
 d.HeadColor=Color3.new(0.9725490212440491,0.9686274528503418,0.8823529481887817)
 d.LeftArmColor=Color3.new(0.9725490212440491,0.9686274528503418,0.8823529481887817)
 d.LeftLegColor=Color3.new(0.9725490212440491,0.9686274528503418,0.8823529481887817)
 d.RightArmColor=Color3.new(0.9725490212440491,0.9686274528503418,0.8823529481887817)
 d.RightLegColor=Color3.new(0.9725490212440491,0.9686274528503418,0.8823529481887817)
 d.TorsoColor=Color3.new(0.9725490212440491,0.9686274528503418,0.8823529481887817)
 d:SetAccessories({
  {AssetId=17604156527,AccessoryType=Enum.AccessoryType.Hat,IsLayered=false,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(1,1,1)},
  {AssetId=73342945001153,AccessoryType=Enum.AccessoryType.Hair,IsLayered=true,Order=13,Puffiness=1,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(1,1,1)},
  {AssetId=90774383444285,AccessoryType=Enum.AccessoryType.RightShoe,IsLayered=true,Order=5,Puffiness=1,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(1,1,1)},
  {AssetId=95317110336842,AccessoryType=Enum.AccessoryType.Hair,IsLayered=true,Order=13,Puffiness=1,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(1,1,1)},
  {AssetId=108292858869352,AccessoryType=Enum.AccessoryType.Neck,IsLayered=false,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(0.949999988079071,0.949999988079071,0.949999988079071)},
  {AssetId=118533085553626,AccessoryType=Enum.AccessoryType.Hair,IsLayered=true,Order=13,Puffiness=1,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(1,1,1)},
  {AssetId=126558719604070,AccessoryType=Enum.AccessoryType.Hair,IsLayered=true,Order=13,Puffiness=1,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(1,1,1)},
  {AssetId=134721172715164,AccessoryType=Enum.AccessoryType.Face,IsLayered=false,Position=Vector3.new(0,0,0),Rotation=Vector3.new(0,0,0),Scale=Vector3.new(1,1,1)},
 },true)
 return d
end
return FrozenAvatar
