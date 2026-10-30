local fs=require('@lune/fs');local luau=require('@lune/luau');local R=require('@lune/roblox')
local function signal() local s={};function s:Connect(f) self.fn=f end;return s end
local instances={};local clock=10;local door={attrs={},TargetR_Closed={Position=R.Vector3.zero}};local info={enabled=true,frontSideInfo={tween={Cancel=function() end}},backSideInfo={tween={Cancel=function() end}}}
local opened,closed,sounds=0,0,0
local manager={EnableDoor=function(_,on) if on then opened+=1 end end}
function door:SetAttribute(k,v) self.attrs[k]=v end
function door:GetAttributeChangedSignal() return signal() end
local sound={Volume=.8,IsA=function(_,c) return c=='Sound' end}
function sound:Clone() return {Stop=function() end,Play=function() sounds+=1 end} end
function door:FindFirstChild() return sound end
local env={DoorManager=manager,doorInfos={[door]=info},StartClosing=function() closed+=1 end,Instance={new=function(class) local o={Triggered=signal(),MouseClick=signal()};instances[class]=o;return o end},Enum=R.Enum,os={clock=function() return clock end},task={spawn=function(fn,...) fn(...) end}}
local install=luau.load(fs.readFile('door-lock-extension.luau')..'\nreturn InstallPlayerLock',{environment=env})();install(door,info)
local position=R.Vector3.new(0,0,2);local player={GetAttribute=function() return false end,Character={FindFirstChild=function() return {Position=position} end,FindFirstChildOfClass=function() return {Health=100} end}}
local click=instances.ClickDetector.MouseClick.fn
click(player);assert(not info.playerLocked,'Single click locked')
clock+=.2;click(player);assert(info.playerLocked and closed==1 and sounds==1,'Double click did not lock')
clock+=1;click(player);clock+=.2;click(player);assert(not info.playerLocked and opened==1,'Double click did not unlock')
clock+=1;position=R.Vector3.new(0,0,30);click(player);clock+=.2;click(player);assert(not info.playerLocked,'Remote lock accepted')
position=R.Vector3.new(0,0,2);info.enabled=false;clock+=1;click(player);clock+=.2;click(player);assert(not info.playerLocked,'Campaign lock bypassed')
info.enabled=true;clock+=1;click(player);clock+=.8;click(player);assert(not info.playerLocked,'Slow clicks accepted')
print('DOOR LOCK TEST PASS: double-click lock/unlock, single/slow/distant input rejected, campaign lock authoritative, quiet authored sound')
