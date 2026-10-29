local fs=require('@lune/fs');local R=require('@lune/roblox')
return function(dm,original,orderly)
 local assets=R.Instance.new('Folder');assets.Name='MansionOriginalUI';assets.Parent=dm:GetService('ReplicatedStorage')
 local allowed={Frame=true,CanvasGroup=true,ImageLabel=true,ImageButton=true,TextLabel=true,TextButton=true,ScrollingFrame=true,ViewportFrame=true,UIGradient=true,UIStroke=true,UICorner=true,UIAspectRatioConstraint=true,UITextSizeConstraint=true,UIScale=true,UIPadding=true,UIListLayout=true,Sound=true}
 for _,gui in ipairs(original:GetService('StarterGui'):GetChildren()) do if gui:IsA('ScreenGui') then
  local clone=gui:Clone();local list=clone:GetDescendants();for i=#list,1,-1 do if not allowed[list[i].ClassName] then list[i]:Destroy() end end
  clone.ResetOnSpawn=false;clone.Enabled=clone.Name=='HUD' or clone.Name=='Screenspace_Vignette' or clone.Name=='OnItemIndicator2';clone:SetAttribute('OriginalSource','7902470429');clone.Parent=assets
 end end
 local source=original:GetService('StarterPlayer').StarterPlayerScripts.MissionsLogicClient.Source
 assert(not source:find('loadstring',1,true) and not source:find('HttpGet',1,true),'Unexpected mission controller')
 local script=R.Instance.new('LocalScript');script.Name='OriginalMissionsLogicClient';script.Source="while not workspace:GetAttribute('GameMode') do task.wait(.1) end\nif workspace:GetAttribute('GameMode')~='Match' then return end\n"..source;script.Parent=dm:GetService('StarterPlayer').StarterPlayerScripts
 local compat=R.Instance.new('ModuleScript');compat.Name='DemoConfig';compat.Source="return {MissionEvents={MissionCounterSetup=1,MissionCounterUpdate=2}}";compat.Parent=dm:GetService('ReplicatedFirst')
 local event=R.Instance.new('RemoteEvent');event.Name='MissionLogicEvent';event.Parent=dm:GetService('ReplicatedStorage')
 local rig=orderly:GetService('ReplicatedStorage').Dreams.EmmaDream.Sepulchar:Clone();rig.Name='OriginalForestMonster'
 local visual={Model=true,Folder=true,MeshPart=true,Part=true,Attachment=true,Bone=true,Motor6D=true,Weld=true,WeldConstraint=true,Humanoid=true,Animator=true,Animation=true,AnimationController=true,KeyframeSequence=true,Keyframe=true,Pose=true,KeyframeMarker=true,SpecialMesh=true,Decal=true,Texture=true,SurfaceAppearance=true}
 local list=rig:GetDescendants();for i=#list,1,-1 do if not visual[list[i].ClassName] then list[i]:Destroy() end end
 for _,part in ipairs(rig:GetDescendants()) do if part:IsA('BasePart') then part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=true;part.Massless=true end end
 rig.PrimaryPart=assert(rig:FindFirstChild('HumanoidRootPart'));rig.PrimaryPart.Anchored=true;rig.PrimaryPart.CanCollide=true
 rig:SetAttribute('SourceAsset','13037825880');rig:SetAttribute('OriginalPath','ReplicatedStorage.Dreams.EmmaDream.Sepulchar');rig.Parent=dm:GetService('ReplicatedStorage')
end
