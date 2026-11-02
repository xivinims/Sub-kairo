assert(workspace:GetAttribute('WaterRPGBuild')=='water-rpg-v1-assets','Unexpected game')
local mod=assert(game.ReplicatedStorage.WaterRPG:FindFirstChild('MenuScene'),'3D scene module missing')
local M=require(mod)
local base=require(game.ReplicatedStorage.WaterRPG.Config).MenuCamera
local main,mainPlane=M.route(base,'Main');local settings,settingsPlane=M.route(base,'Settings');local credits=M.route(base,'Credits')
assert((settings.Position-main.Position):Dot(base.RightVector)>8,'Settings camera does not travel right')
assert((credits.Position-main.Position):Dot(base.RightVector)<-8,'Credits camera does not travel left')
local part=Instance.new('Part');part.Anchored=true;part.CanCollide=false;part.CanQuery=true;part.Transparency=1;part.Size=Vector3.new(12,10,.04);part.CFrame=settingsPlane;part.Parent=workspace
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={part}
local hit=workspace:Raycast(settings.Position,(settingsPlane.Position-settings.Position)*1.1,params)
assert(hit and hit.Instance==part,'3D menu plane cannot receive ray queries');part:Destroy()
local ui=game.StarterPlayer.StarterPlayerScripts.WaterRPGClient.Source
for _,text in ipairs({'menuPlane.CanQuery=true','modalPlane.CanQuery=true','WaterMenuSection3D','Enum.EasingStyle.Quart',"travel('Main')",'displayedSection=kind'}) do assert(ui:find(text,1,true),'Missing menu feature '..text) end
assert(workspace:GetAttribute('MenuRevision')=='reference-3d-transitions-v2','Menu revision not saved')
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,revision=workspace:GetAttribute('MenuRevision'),cameraRight=true,cameraLeft=true,worldPanel=true,clickQueries=true,residents=#workspace.Residents:GetChildren()})
