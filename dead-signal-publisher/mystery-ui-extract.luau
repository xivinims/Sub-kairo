-- The original Mystery UI is a reusable package, with no map or campaign code.
local R=require('@lune/roblox')
return function(source)
 local package=R.Instance.new('Folder')
 package.Name='MysteryInterface'
 package:SetAttribute('SourceAsset','7902470429')
 package:SetAttribute('InterfaceVersion','mystery-independent-v1')
 for _,screen in ipairs(source:GetService('StarterGui'):GetChildren()) do
  if screen:IsA('ScreenGui') then
   local copy=screen:Clone()
   copy.Enabled=false
   copy.ResetOnSpawn=false
   copy:SetAttribute('SourceScreen',screen.Name)
   for _,d in ipairs(copy:GetDescendants()) do
    if d:IsA('LuaSourceContainer') or d.Name=='Credits_01' then d:Destroy() end
   end
   copy.Parent=package
  end
 end
 assert(package:FindFirstChild('HUD'),'Original Mystery HUD missing')
 local frame=assert(package.HUD:FindFirstChild('Frame'))
 assert(frame:FindFirstChild('HeadlampButton') and frame:FindFirstChild('GrabReleaseButton'),'Original Mystery buttons missing')
 assert(#package:GetChildren()==7,'Original Mystery screen package changed')
 return package
end
