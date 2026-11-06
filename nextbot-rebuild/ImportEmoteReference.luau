-- Build-time import only: deserialize the user reference, never execute its scripts.
local fs=require('@lune/fs')
local R=require('@lune/roblox')
local M={}
local function decode64(encoded)
 local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
 local values={};for i=1,#alphabet do values[alphabet:sub(i,i)]=i-1 end
 local out={};local bits,value=0,0
 for i=1,#encoded do
  local n=values[encoded:sub(i,i)]
  if n then
   value=value*64+n;bits+=6
   if bits>=8 then bits-=8;table.insert(out,string.char(math.floor(value/2^bits)%256));value%=2^bits end
  end
 end
 return table.concat(out)
end
function M.Import(package)
 local bytes=decode64(fs.readFile('assets/emote-wheel-reference.b64'))
 assert(#bytes==189838,'emote wheel reference size mismatch')
 local source=R.deserializePlace(bytes)
 local original=source:GetService('StarterGui'):FindFirstChild('EmotesUI')
 assert(original and original:IsA('ScreenGui'),'reference EmotesUI missing')
 local template=original:Clone();template.Name='EmoteWheelTemplate';template.Enabled=false
 for _,v in ipairs(template:GetDescendants())do
  if v:IsA('LuaSourceContainer')or v:IsA('RemoteEvent')or v:IsA('RemoteFunction')or v:IsA('Sound')or v:IsA('WorldModel')or v:IsA('Camera')then v:Destroy()end
 end
 for i=1,4 do
  local slot=template.EmoteWheel:FindFirstChild('Slot'..i)
  assert(slot and slot:FindFirstChild('EmoteViewport')and slot:FindFirstChild('EmoteName'),'reference slot structure changed')
 end
 assert(template.EmoteMenu.EmoteList:FindFirstChild('EmoteTemplate'),'reference list missing')
 template.Parent=package
 return template
end
return M
