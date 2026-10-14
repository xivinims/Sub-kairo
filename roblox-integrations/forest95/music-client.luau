local Players=game:GetService("Players")local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local player=Players.LocalPlayer
local Config=require(runtime:WaitForChild("MusicConfig"))local UI=require(runtime:WaitForChild("MusicUI"))local Player=require(runtime:WaitForChild("MusicPlayer"))
local remote=runtime:WaitForChild("MusicListening")local ui=UI.build(player:WaitForChild("PlayerGui"),Config.Tracks)
local music=Player.new(game:GetService("SoundService"),function(active)remote:FireServer(active)end,function(text)ui.status.Text=text end)
ui.open.Activated:Connect(function()ui.panel.Visible=not ui.panel.Visible end)
for _,entry in ipairs(ui.tracks)do entry.button.Activated:Connect(function()task.spawn(music.play,entry.track.id,entry.track.title)end)end
ui.play.Activated:Connect(function()local id=Config.parse(ui.input.Text)if not id then ui.status.Text="Digite um ID de áudio válido."return end task.spawn(music.play,id,"Sua música")end)
ui.pause.Activated:Connect(music.pause)ui.stop.Activated:Connect(function()music.stop()ui.status.Text="Parado"end)
ui.lower.Activated:Connect(function()music.setVolume(music.volume-.05)end)ui.louder.Activated:Connect(function()music.setVolume(music.volume+.05)end)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt,who)if prompt.Name=="OpenPersonalMusic"and who==player then ui.panel.Visible=true end end)
script.Destroying:Connect(function()music.stop()ui.gui:Destroy()end)
