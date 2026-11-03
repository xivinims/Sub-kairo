assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")assert(game.PlaceVersion==80,"Wrong published version")
local w=workspace.IlhaSerena assert(w:GetAttribute("UpgradeVersion")==80,"Upgrade missing")
local runtime=game.ReplicatedStorage.SerenaRuntime local Climate=require(runtime.Climate)local Personal=require(runtime.PersonalClimate)
assert(Climate.DayLength==600 and Climate.TransitionSeconds==8 and w:GetAttribute("DayLength")==600,"Fast cycle missing")
local h,r,c=Personal.resolve("Noite","Chuva",12,0,1)assert(h==23 and r==1 and c==0,"Personal choices missing")
local SPS=game.StarterPlayer.StarterPlayerScripts assert(SPS.SerenaWeatherMenu and SPS.SerenaBridgeAnimation,"Client sources missing")
assert(SPS.SerenaWeatherMenu.Source:find("AutomaticCanvasSize=Enum.AutomaticSize.Y",1,true),"Scrolling not saved")
assert(SPS.SerenaAmbienceClient.Source:find("Personal.resolve",1,true),"Personal ambience missing")
local bridges={}local parts=0
for _,z in ipairs({70,124})do
 local m=w.TrilhasEMirante["Ponte"..z]assert(m:GetAttribute("SuspensionBridge")and m:GetAttribute("AnimateConstruction"),"Bridge config missing")
 local towers,orbs,fixed=0,0,0
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
  assert(p.Anchored,"Unanchored bridge")if p.Name=="Torre"then towers+=1 end if p:GetAttribute("BridgeOrb")then orbs+=1 assert(p.PointLight:GetAttribute("AlwaysOn"),"Orb illumination not persistent")end
  if p.CanCollide then assert(not p:GetAttribute("BridgeRestCF")and p.Transparency==1,"Moving or visible collider")fixed+=1 end
  if p:GetAttribute("BridgeRestCF")then assert((p.Position-p:GetAttribute("BridgeRestCF").Position).Magnitude<.01 and p.Transparency<1,"Incomplete saved construction")end
 end end
 assert(towers==4 and orbs==4 and fixed>=80,"Bridge geometry lost")table.insert(bridges,{name=m.Name,towers=towers,orbs=orbs,fixedColliders=fixed})
end
for _,p in ipairs(w:GetDescendants())do if p:IsA("BasePart")then parts+=1 assert(p.Anchored,"Unanchored scenery")end end assert(parts==5956,"Scene changed")
assert(workspace.StreamingEnabled and w:GetAttribute("InteractiveGrass"),"Existing map config changed")
local Rules=require(runtime.ItemRules)assert(Rules.Duration==3 and Rules.Cooldown==60 and Rules.Price==30,"Apple rules changed")
assert(game.ServerStorage.SerenaItems["Maçã da Névoa"] and game.ServerScriptService.SerenaShopServer,"Shop missing")
local nativeSky=game.Lighting.SerenaSky assert(nativeSky.SkyboxBk=="rbxassetid://1084532042","HD sky changed")
local compiled=0
for _,parent in ipairs({game.ServerScriptService,SPS})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,result=pcall(require,m)m:Destroy()assert(ok,tostring(result))compiled+=1
end end end
local scenes={}
for _,m in ipairs(workspace:GetChildren())do assert(m==w or m==workspace.Terrain or m:IsA("Camera"),"Extra scene")table.insert(scenes,m.Name)end
return {ok=true,version=game.PlaceVersion,parts=parts,bridges=bridges,daySeconds=Climate.DayLength,transitionSeconds=Climate.TransitionSeconds,scrollingMenu=true,personalNightRain=true,applePreserved=true,hdSkyPreserved=true,compiledScripts=compiled,singleScene=scenes}
