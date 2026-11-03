local runtime=game.ServerScriptService.FalloutRuntime
local P=require(runtime.Progress)
local N=require(runtime.Nametags)
local template=game.ServerStorage.FalloutNametagTemplate
assert(workspace:GetAttribute('FalloutNametagBuild')=='nametags-v1')
assert(template:GetAttribute('SourceAssetId')=='72094860266497')
assert(template:IsA('BillboardGui') and not template.AlwaysOnTop and template.MaxDistance==65)
assert(#template:GetChildren()==3 and template.DisplayName:IsA('TextLabel') and template.TenureTitle:IsA('TextLabel') and template.Level:IsA('TextLabel'))
assert(runtime.NametagController.Source=='require(script.Parent.Nametags).start()')
assert(P.BeginnerSeconds==7200 and P.VeteranSeconds==104400 and P.XPPerLevel==1000)
local before=protectedSnapshot()
local tag=template:Clone()
for _,test in ipairs({{0,'Iniciante'},{7199,'Iniciante'},{7200,''},{104399,''},{104400,'Veterano'}}) do
 N.update(tag,'Jogador de teste',test[1],2750,true)
 assert(tag.DisplayName.Text=='Jogador de teste' and tag.Level.Text=='Nível 3')
 assert(tag.TenureTitle.Text==test[2] and tag.TenureTitle.Visible==(test[2]~=''))
 assert(math.abs(tag.Level.Position.Y.Scale-(test[2]=='' and .47 or .67))<.001)
end
N.update(tag,'Jogador',nil,nil,false)
assert(not tag.TenureTitle.Visible and tag.Level.Text=='Nível —')
tag:Destroy()
N.start() -- No players: validates connections without reading or writing player data.
assert(protectedSnapshot()==before,'Nametag startup mutated game content')
local C=require(game.ReplicatedStorage.FalloutConfig)
assert(C.TeamSize==5 and C.MaxPlayers==10 and C.RoundSeconds==600 and C.IntermissionSeconds==90)
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=workspace:GetAttribute('FalloutNametagBuild'),baseBuild=workspace:GetAttribute('DeadSignalBuildId'),source='72094860266497',beginnerSeconds=P.BeginnerSeconds,veteranSeconds=P.VeteranSeconds,xpPerLevel=P.XPPerLevel,preserved=before,labels=3,nativeBoundaryChecks=5})
