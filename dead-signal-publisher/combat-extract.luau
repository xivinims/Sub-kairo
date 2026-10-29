local fs=require('@lune/fs');local R=require('@lune/roblox')
local allowed={Model=true,Folder=true,Part=true,MeshPart=true,UnionOperation=true,WedgePart=true,Attachment=true,Motor6D=true,Weld=true,WeldConstraint=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,SurfaceAppearance=true,Decal=true,Texture=true,AnimationController=true,Animator=true,Animation=true,KeyframeSequence=true,Keyframe=true,Pose=true,KeyframeMarker=true,Bone=true,Sound=true,SoundGroup=true}
local function sanitize(source)
 local clone=source:Clone();local list=clone:GetDescendants()
 for i=#list,1,-1 do local d=list[i];if not allowed[d.ClassName] then d:Destroy() end end
 for _,p in ipairs(clone:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.CastShadow=false end end
 return clone
end
return function(dm)
 local fps=R.deserializePlace(fs.readFile('/tmp/asset-15864801103.rbxl'));local RS=fps:GetService('ReplicatedStorage')
 local assets=R.Instance.new('Folder');assets.Name='CombatAssets';assets.Parent=dm:GetService('ReplicatedStorage')
 local weapons=R.Instance.new('Folder');weapons.Name='PlayerWeapons';weapons.Parent=assets
 for _,spec in ipairs({{name='M4A1',model='M4',mag=30,damage=23,interval=.0885,reload=2.6,sequence='M4a1vm'},{name='Deagle',model='Deagle',mag=10,damage=30,interval=.42,reload=2.2,sequence='Deagle'}}) do
  local vm=sanitize(RS.Assets.Models.Viewmodels.Tactical);vm.Name=spec.name
  local root=assert(vm:FindFirstChild('HumanoidRootPart'));vm.PrimaryPart=root;vm:PivotTo(R.CFrame.new())
  local gun=sanitize(RS.Game.Weapons[spec.name][spec.model]);gun.Name='Weapon';gun:SetAttribute('SourceModelName',spec.model);gun.PrimaryPart=assert(gun:FindFirstChild('Handle'));gun:PivotTo(R.CFrame.new(.45,-.8,-1.25));gun.Parent=vm
  local joint=R.Instance.new('Motor6D');joint.Name='ViewmodelJoint';joint.Part0=root;joint.Part1=gun.PrimaryPart;joint.C0=R.CFrame.new(.45,-.8,-1.25);joint.Parent=root
  for _,p in ipairs(vm:GetDescendants()) do if p:IsA('BasePart') then p.Anchored=p==root end end
  local sequences=R.Instance.new('Folder');sequences.Name='OriginalSequences';sequences.Parent=vm
  local cache=fps:GetService('ServerStorage').RBX_ANIMSAVES[spec.sequence]
  for _,names in ipairs({{'Idle','idle'},{'Shoot','shoot'},{'Reload','reload'},{'Equip','equip'}}) do
   local chosen
   for _,candidate in ipairs(cache:GetChildren()) do if candidate:IsA('KeyframeSequence') and candidate.Name:lower()==names[2] and #candidate:GetChildren()>0 then chosen=candidate;break end end
   if chosen then local clip=sanitize(chosen);clip.Name=names[1];clip.Parent=sequences end
  end
  for _,pose in ipairs(sequences:GetDescendants()) do if pose:IsA('Pose') and (pose.Name=='Handle' or pose.Name==spec.model) then joint.C0=R.CFrame.new();break end end
  assert(sequences:FindFirstChild('Shoot') and sequences:FindFirstChild('Reload'),'Missing original animations: '..spec.name)
  local soundRoot=fps:GetService('SoundService'):FindFirstChild('ClientSounds')
  local sourceSounds=soundRoot and soundRoot:FindFirstChild('Weapons') and soundRoot.Weapons:FindFirstChild(spec.name)
  if sourceSounds then local sounds=sanitize(sourceSounds);sounds.Name='WeaponSounds';sounds.Parent=vm;for _,s in ipairs(sounds:GetDescendants()) do if s:IsA('Sound') then s.PlayOnRemove=false;s.Volume=math.min(s.Volume,.65) end end end
  vm:SetAttribute('SourceAsset','15864801103');vm:SetAttribute('FireInterval',spec.interval);vm:SetAttribute('Damage',spec.damage);vm:SetAttribute('Magazine',spec.mag);vm:SetAttribute('ReloadTime',spec.reload);vm.Parent=weapons
 end
 local laser=R.deserializePlace(fs.readFile('/tmp/asset-14817965191.rbxl'))
 local alien=sanitize(laser:GetService('ReplicatedStorage').Instances.LaserBlastersFolder.SingleBlaster.ViewModel);alien.Name='AlienBlaster';alien.PrimaryPart=alien:FindFirstChild('Root');alien:SetAttribute('SourceAsset','14817965191');alien.Parent=assets
 local horror=R.deserializePlace(fs.readFile('/tmp/asset-13037825880.rbxl'))
 local entrance=horror:GetService('StarterGui').Entrance:Clone();entrance.Name='HorrorEntrance'
 local ui={Frame=true,TextLabel=true,TextButton=true,ImageLabel=true,UIAspectRatioConstraint=true,UICorner=true,UIGradient=true,UIStroke=true,UITextSizeConstraint=true,UIPadding=true}
 local list=entrance:GetDescendants();for i=#list,1,-1 do if not ui[list[i].ClassName] then list[i]:Destroy() end end
 entrance.Enabled=false;entrance.DisplayOrder=3000;entrance.IgnoreGuiInset=true
 local logo=entrance.LogoFrame.Logo;logo.Image='';logo.BackgroundTransparency=1;logo.LogoText.Text='STILL HERE\nBy Ch_ckz2n'
 entrance.WarningFrame.Warning.Text='STILL HERE';entrance.WarningFrame.Warning.Description.Text='A floresta não está vazia.\nUse fones de ouvido e observe o céu.';entrance.WarningFrame.Warning.Continue.Text='TOQUE PARA CONTINUAR'
 entrance:SetAttribute('LayoutSource','13037825880');entrance.Parent=assets
 for _,d in ipairs(assets:GetDescendants()) do assert(not d:IsA('LuaSourceContainer'),'Unsafe weapon code') end
 print('COMBAT EXTRACTED: two original FPS rigs + original saved keyframes, official laser blaster, entrance layout; no foreign code/maps')
end
