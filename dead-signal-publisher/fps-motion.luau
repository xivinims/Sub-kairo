-- Reads the source's saved pose data; does not load external animation scripts or asset IDs.
local M={};M.__index=M
function M.new(rig)
 local self=setmetatable({rig=rig,joints={},clips={},clock=0},M)
 for _,joint in ipairs(rig:GetDescendants()) do if joint:IsA('Motor6D') and joint.Part1 then self.joints[joint.Part1.Name]=joint end end
 local weapon=rig:FindFirstChild('Weapon');local joint=rig:FindFirstChild('ViewmodelJoint',true);if weapon and joint then self.joints[weapon:GetAttribute('SourceModelName') or 'Weapon']=joint end
 local folder=rig:FindFirstChild('OriginalSequences')
 if folder then for _,seq in ipairs(folder:GetChildren()) do if seq:IsA('KeyframeSequence') then
  local frames=seq:GetKeyframes();table.sort(frames,function(a,b) return a.Time<b.Time end)
  self.clips[seq.Name:lower()]={frames=frames,length=frames[#frames] and frames[#frames].Time or 0}
 end end end
 self:Play('idle');return self
end
function M:Play(name)
 if name=='fire' then name='shoot' end
 if self.clips[name] then self.current=self.clips[name];self.name=name;self.clock=0 end
end
local function poses(frame)
 local result={};for _,pose in ipairs(frame:GetDescendants()) do if pose:IsA('Pose') then result[pose.Name]=pose.CFrame end end;return result
end
function M:Step(dt)
 local clip=self.current;if not clip or #clip.frames==0 then return end
 self.clock+=dt
 if self.clock>clip.length and clip.length>0 then if self.name=='idle' then self.clock%=clip.length else self:Play('idle');return end end
 local a,b=clip.frames[1],clip.frames[#clip.frames]
 for i=1,#clip.frames-1 do if self.clock>=clip.frames[i].Time and self.clock<=clip.frames[i+1].Time then a=clip.frames[i];b=clip.frames[i+1];break end end
 local alpha=b.Time>a.Time and math.clamp((self.clock-a.Time)/(b.Time-a.Time),0,1) or 0
 local pa,pb=poses(a),poses(b)
 for name,joint in pairs(self.joints) do if joint.Parent then joint.Transform=(pa[name] or CFrame.identity):Lerp(pb[name] or pa[name] or CFrame.identity,alpha) end end
end
return M
