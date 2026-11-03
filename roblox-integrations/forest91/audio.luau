local B={}
function B.install()
 local folder=Instance.new("Folder")folder.Name="GardenSounds"folder.Parent=game.ReplicatedStorage.ForestRuntime
 local report={}
 for name,id in pairs({Forest=9116971475,Wind=9114518779,River=9120552550,Rain=9112854613,GrassStep=135037154891351,WoodStep=9083826864,StoneStep=178190837})do
  local s=Instance.new("Sound")s.Name=name s.SoundId="rbxassetid://"..id s.Looped=true s.Volume=.15 s.RollOffMinDistance=4 s.RollOffMaxDistance=35 s.Parent=folder
  game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Sound unavailable: "..name)
  report[name]={id=id,length=s.TimeLength}
 end return report
end
return B
