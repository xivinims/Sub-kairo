local fs=require('@lune/fs')
return function(dm)
 local module=dm:GetService('ServerScriptService').DoorManager
 local source=module.Source
 local function edit(old,new) local a,b=source:find(old,1,true);assert(a,'Door source changed: '..old);source=source:sub(1,a-1)..new..source:sub(b+1) end
 edit('local function StartOpening(info, sideInfo)','local function StartOpening(info, sideInfo)\n\tif info.playerLocked or not info.enabled then return end')
 edit('local function InitDoor(obj)','local function InitDoor(obj)\n\tif doorInfos[obj] then return end')
 edit('function DoorManager.EnableDoor(door, enable)','function DoorManager.EnableDoor(door, enable)\n\t-- Campaign locks remain authoritative and are never overwritten by player locks.')
 local extra=fs.readFile('door-lock-extension.luau')
 edit('local function InitDoor(obj)',extra..'\nlocal function InitDoor(obj)')
 edit('doorInfos[obj] = doorInfo','doorInfos[obj] = doorInfo\n\tInstallPlayerLock(obj, doorInfo)')
 module.Source=source;module:SetAttribute('CompatibilityChange','Original door tweens retained; proximity-validated double activation player lock, independent campaign lock')
 dm:GetService('Workspace'):SetAttribute('DoorLockVersion','double-tap-v1')
end
