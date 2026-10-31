local Players=game:GetService('Players')
local PianoGame={}
local remote,piano,anchor
local sounds={}
local joined=setmetatable({},{__mode='k'})
local lastNote=setmetatable({},{__mode='k'})
local songId=setmetatable({},{__mode='k'})
local songs={
 VALSA={title='VALSA DO HOTEL',step=.34,notes={0,4,7,9,7,4,2,5,9,7,4,0}},
 CAIXA={title='CAIXINHA',step=.27,notes={12,7,9,7,4,7,9,7,12,11,9,7}},
 LUAR={title='CANÇÃO DO LUAR',step=.39,notes={0,2,4,7,9,7,4,2,0,4,7,12}},
 MISTERIO={title='MISTÉRIO',step=.31,notes={0,3,7,10,9,7,3,0,2,5,9,12}},
}
local function rootOf(player)
 local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local root=c and c:FindFirstChild('HumanoidRootPart')
 return h and h.Health>0 and root or nil
end
local function nearby(player,maxDistance)
 local root=rootOf(player);return root and anchor and (root.Position-anchor.Position).Magnitude<=(maxDistance or 13)
end
local function play(index)
 local sound=sounds[index];if not sound then return end
 sound.TimePosition=0;sound:Play();remote:FireAllClients('piano_note_visual',{index=index})
end
function PianoGame.Initialize(map,actionRemote)
 assert(not piano,'Piano already initialized')
 piano=assert(map:FindFirstChild('Piano',true),'Hotel piano not found');remote=actionRemote
 local candidates={}
 for _,object in ipairs(piano:GetDescendants()) do if object:IsA('BasePart') then table.insert(candidates,object) end end
 table.sort(candidates,function(a,b) return a.Size.X*a.Size.Z>b.Size.X*b.Size.Z end)
 anchor=assert(candidates[1],'Piano anchor missing');piano.PrimaryPart=piano.PrimaryPart or anchor;piano:SetAttribute('InteractionKind','Piano')
 for index=0,12 do
  local sound=Instance.new('Sound');sound.Name='HotelPianoNote'..index;sound.SoundId='rbxassetid://122098201042601';sound.PlaybackSpeed=2^((index-7)/12);sound.Volume=.48;sound.RollOffMode=Enum.RollOffMode.InverseTapered;sound.RollOffMinDistance=8;sound.RollOffMaxDistance=64;sound:SetAttribute('SoundCategory','Music')
  local reverb=Instance.new('ReverbSoundEffect');reverb.DecayTime=2.25;reverb.Density=.82;reverb.Diffusion=.78;reverb.DryLevel=-2;reverb.WetLevel=-9;reverb.Parent=sound;sound.Parent=anchor;sounds[index]=sound
 end
end
function PianoGame.Join(player)
 if not piano or not nearby(player,11) then return false end
 joined[player]=true;remote:FireClient(player,'piano_open',{piano=piano,surface=anchor});return true
end
function PianoGame.Note(player,data)
 local index=typeof(data)=='table' and tonumber(data.index)
 if not joined[player] or not nearby(player,14) or not index or index%1~=0 or index<0 or index>12 then return false end
 local now=os.clock();if now-(lastNote[player] or 0)<.085 then return false end;lastNote[player]=now;play(index);return true
end
function PianoGame.Song(player,data)
 local id=typeof(data)=='table' and data.id;local song=songs[id]
 if not joined[player] or not nearby(player,14) or not song then return false end
 songId[player]=(songId[player] or 0)+1;local token=songId[player]
 task.spawn(function()
  for _,index in ipairs(song.notes) do
   if not joined[player] or songId[player]~=token or not nearby(player,14) then break end
   play(index);task.wait(song.step)
  end
 end)
 return true
end
function PianoGame.Exit(player)
 if not joined[player] then return false end
 joined[player]=nil;songId[player]=(songId[player] or 0)+1;remote:FireClient(player,'piano_close');return true
end
Players.PlayerRemoving:Connect(function(player) joined[player]=nil;lastNote[player]=nil;songId[player]=nil end)
return PianoGame
