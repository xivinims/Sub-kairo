assert(game.GameId==9421311218 and game.PlaceId==118064584465155)
assert(game.PlaceVersion>75,"publish not visible")
local world=workspace:FindFirstChild("HangoutWorld") assert(world,"new world missing")
assert(not workspace:FindFirstChild("Lobby") and not workspace:FindFirstChild("ActiveNextbots"))
local net=game.ReplicatedStorage.HangoutNet
assert(#net.Locations:GetChildren()==5 and net.Travel:IsA("RemoteEvent") and net.Item:IsA("RemoteEvent"))
local expected={Praia={"11603671645",6284},Vila={"3371706192",2353},Parque={"139782479241283",1248}}
local maps={}
for name,def in pairs(expected) do
 local m=world:FindFirstChild(name) assert(m and m:GetAttribute("SourceAssetId")==def[1])
 local count=0 for _,d in ipairs(m:GetDescendants()) do
  assert(not d:IsA("LuaSourceContainer"),"imported script remained")
  if d:IsA("BasePart") then count+=1 assert(d.Anchored) end
 end
 assert(count==def[2]) maps[name]=count
end
local ids={}
for _,v in ipairs(net.Locations:GetChildren()) do
 assert(typeof(v:GetAttribute("Spawn"))=="CFrame")
 local pad=world:FindFirstChild("Landing_"..v.Name) assert(pad and pad.ModelStreamingMode==Enum.ModelStreamingMode.Persistent)
 assert(pad.SafeLanding.CanCollide and pad.SafeLanding.Anchored)
 table.insert(ids,v.Name)
end
local server=game.ServerScriptService.HangoutServer
local client=game.StarterPlayer.StarterPlayerScripts.HangoutClient
assert(server.Enabled and client.Enabled)
for _,d in ipairs(game.ServerScriptService:GetDescendants()) do if d:IsA("BaseScript") then assert(d==server or not d.Enabled,"old server script active") end end
local compiled={}
for _,s in ipairs({server,client}) do
 local m=Instance.new("ModuleScript") m.Source="return function()\n"..s.Source.."\nend" m.Parent=game.ServerStorage
 local ok,fn=pcall(require,m) m:Destroy() assert(ok and type(fn)=="function",s.Name) table.insert(compiled,s.Name)
end
assert(game.StarterPlayer.StarterCharacterScripts:GetChildren()[1]==nil)
assert(#game.ServerStorage.HangoutItems:GetChildren()==3)
local backup=game.ServerStorage:FindFirstChild("BeforeHangout_75") assert(backup)
assert(backup:FindFirstChild("RainCycleByNarrakin_Original"))
assert(server.Source:find("7095497839",1,true))
assert(game.Lighting.HangoutSky and game.Lighting.HangoutAtmosphere)
assert(workspace.StreamingEnabled and workspace:GetAttribute("HangoutVersion")==1)
return {ok=true,version=game.PlaceVersion,importedMaps=maps,destinations=ids,items={"Lanterna","Guarda-chuva","Bola"},weather="RainCycle sky + adapted rain",compiled=compiled,oldNextbotScriptsActive=false,streaming=true,backup=backup.Name}
