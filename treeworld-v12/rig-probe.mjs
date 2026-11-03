import {execute,first} from './cloud.mjs';
console.log(JSON.stringify(first(await execute(`
local d=Instance.new('HumanoidDescription');d.RightLeg=139607718
local n=game.Players:CreateHumanoidModelFromDescriptionAsync(d,Enum.HumanoidRigType.R15)
local function inspect()
 local a={};local m={}
 for _,p in ipairs(n:GetDescendants())do
  if p:IsA('Attachment')then table.insert(a,{name=p.Name,parent=p.Parent.Name,pos=tostring(p.Position)})
  elseif p:IsA('Motor6D')then table.insert(m,{name=p.Name,parent=p.Parent.Name,p0=p.Part0 and p.Part0.Name,p1=p.Part1 and p.Part1.Name})end
 end
 return {attachments=a,motors=m,root=n.Humanoid.RootPart and n.Humanoid.RootPart.Name}
end
local before=inspect();n.Parent=workspace;n.Humanoid:BuildRigFromAttachments();task.wait(.5);local after=inspect()
return {before=before,after=after,rig=tostring(n.Humanoid.RigType)}
`))));
