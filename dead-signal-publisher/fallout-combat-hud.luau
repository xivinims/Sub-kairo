local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local HUD={}
local white=Color3.fromRGB(235,239,238)
local muted=Color3.fromRGB(159,171,175)
local blue=Color3.fromRGB(67,176,216)
local red=Color3.fromRGB(228,80,77)
local function make(class,parent,props)
 local item=Instance.new(class);for key,value in pairs(props) do item[key]=value end;item.Parent=parent;return item
end
local function text(parent,name,value,size,position,fontSize)
 return make('TextLabel',parent,{Name=name,Text=value,Size=size,Position=position,TextSize=fontSize,Font=Enum.Font.GothamMedium,TextColor3=white,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=false})
end
local function line(parent,name,size,position,color,transparency)
 return make('Frame',parent,{Name=name,Size=size,Position=position,BackgroundColor3=color or white,BackgroundTransparency=transparency or 0,BorderSizePixel=0})
end
local function brackets(parent,length,color)
 for _,side in ipairs({0,1}) do for _,edge in ipairs({0,1}) do
  local h=line(parent,'CornerH',UDim2.fromOffset(length,1),UDim2.new(side,side==1 and -length or 0,edge,edge==1 and -1 or 0),color,.25)
  local v=line(parent,'CornerV',UDim2.fromOffset(1,length),UDim2.new(side,side==1 and -1 or 0,edge,edge==1 and -length or 0),color,.25)
 end end
end
local function panel(parent,name,size,position,anchor)
 return make('Frame',parent,{Name=name,Size=size,Position=position,AnchorPoint=anchor or Vector2.zero,BackgroundColor3=Color3.fromRGB(13,19,23),BackgroundTransparency=.66,BorderSizePixel=0})
end
function HUD.create(parent,UI,onEquip)
 local screen=make('ScreenGui',parent,{Name='FalloutCombatHUD',ResetOnSpawn=false,Enabled=false,DisplayOrder=32,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,SafeAreaCompatibility=Enum.SafeAreaCompatibility.None})
 local root=make('Frame',screen,{Name='Combat',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
 local reticleScreen=make('ScreenGui',parent,{Name='FalloutCombatReticle',ResetOnSpawn=false,Enabled=false,DisplayOrder=33,ScreenInsets=Enum.ScreenInsets.None,SafeAreaCompatibility=Enum.SafeAreaCompatibility.None})
 local cross=make('Frame',reticleScreen,{Name='Reticle',Size=UDim2.fromOffset(32,32),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1})
 local dot=line(cross,'Dot',UDim2.fromOffset(2,2),UDim2.fromOffset(15,15),white,.08)
 local arms={}
 for i=1,4 do arms[i]=line(cross,'Arm'..i,UDim2.fromOffset(i<=2 and 5 or 1,i<=2 and 1 or 5),UDim2.new(),white,.14) end
 local hit=make('Frame',cross,{Name='HitMarker',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
 for i,offset in ipairs({Vector2.new(7,7),Vector2.new(24,7),Vector2.new(7,24),Vector2.new(24,24)}) do
  local stroke=line(hit,'Hit'..i,UDim2.fromOffset(7,1),UDim2.fromOffset(offset.X,offset.Y));stroke.AnchorPoint=Vector2.new(.5,.5);stroke.Rotation=(i==1 or i==4) and 45 or -45
 end
 local health=panel(root,'Vital',UDim2.fromOffset(160,24),UDim2.new(.5,0,1,-14),Vector2.new(.5,1));health.BackgroundTransparency=1
 local hp=text(health,'Value','100',UDim2.fromOffset(32,14),UDim2.new(),10)
 local hpTitle=text(health,'Label','SAÚDE',UDim2.new(1,-34,0,14),UDim2.fromOffset(34,0),8);hpTitle.TextColor3=muted;hpTitle.TextXAlignment=Enum.TextXAlignment.Right
 local track=line(health,'Track',UDim2.new(1,-4,0,4),UDim2.fromOffset(2,18),white,.8)
 local fill=line(track,'Fill',UDim2.fromScale(1,1),UDim2.new(),white,.15)
 line(health,'LeftCap',UDim2.fromOffset(1,8),UDim2.fromOffset(0,16),white,.35)
 line(health,'RightCap',UDim2.fromOffset(1,8),UDim2.new(1,-1,0,16),white,.35)
 local ammo=panel(root,'Ammo',UDim2.fromOffset(180,54),UDim2.new(1,-16,1,-14),Vector2.new(1,1));brackets(ammo,7)
 local count=text(ammo,'Magazine','—',UDim2.fromOffset(58,30),UDim2.fromOffset(8,2),25);count.Font=Enum.Font.Gotham
 local reserve=text(ammo,'Reserve','',UDim2.fromOffset(58,14),UDim2.fromOffset(10,31),9);reserve.TextColor3=muted
 local weapon=text(ammo,'Weapon','',UDim2.new(1,-77,0,13),UDim2.fromOffset(68,37),8);weapon.TextTruncate=Enum.TextTruncate.AtEnd
 local preview=make('Frame',ammo,{Name='WeaponPreview',Size=UDim2.new(1,-76,0,36),Position=UDim2.fromOffset(68,1),BackgroundTransparency=1})
 local reloadTrack=line(ammo,'ReloadTrack',UDim2.new(1,-16,0,1),UDim2.fromOffset(8,52),white,.82)
 local reloadFill=line(reloadTrack,'Reload',UDim2.fromScale(0,1),UDim2.new(),white,.1)
 local hotbar=make('Frame',root,{Name='Equipment',AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-74),Size=UDim2.fromOffset(180,32),BackgroundTransparency=1})
 local slots={}
 for i=1,4 do
  local b=make('TextButton',hotbar,{Name='Slot'..i,Text='',Size=UDim2.new(.25,-4,1,0),Position=UDim2.new((i-1)/4,0,0,0),BackgroundTransparency=.82,BackgroundColor3=Color3.fromRGB(13,19,23),BorderSizePixel=0,AutoButtonColor=false})
  local key=text(b,'Key',tostring(i),UDim2.fromOffset(10,11),UDim2.fromOffset(3,1),8)
  local icon=make('Frame',b,{Name='Icon',Size=UDim2.new(1,-12,1,-4),Position=UDim2.fromOffset(10,2),BackgroundTransparency=1})
  local selected=line(b,'Selected',UDim2.new(1,-4,0,1),UDim2.new(0,2,1,-1),white);selected.Visible=false
  local slot={button=b,icon=icon,key=key,selected=selected};slots[i]=slot
  b.Activated:Connect(function()if slot.id and onEquip then onEquip(slot.id) end end)
 end
 local feed=make('Frame',root,{Name='Eliminations',AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(244,66),Position=UDim2.new(1,-12,0,40),BackgroundTransparency=1})
 local feedRows={};for i=1,3 do local row=text(feed,'Entry'..i,'',UDim2.new(1,0,0,18),UDim2.fromOffset(0,(i-1)*20),10);row.TextXAlignment=Enum.TextXAlignment.Right;row.TextTruncate=Enum.TextTruncate.AtEnd;feedRows[i]=row end
 local radar=panel(root,'Radar',UDim2.fromOffset(106,96),UDim2.new(0,12,1,-14),Vector2.new(0,1));brackets(radar,9)
 local map=make('Frame',radar,{Name='Map',ClipsDescendants=true,Size=UDim2.new(1,-8,1,-8),Position=UDim2.fromOffset(4,4),BackgroundTransparency=1})
 local data=require(game.ReplicatedStorage:WaitForChild('FalloutRadarData'))
 for _,p in ipairs(data.rects) do
  local r=line(map,'Structure',UDim2.fromScale(p[3],p[4]),UDim2.fromScale(p[1],p[2]),Color3.fromRGB(157,173,178),.79);r.AnchorPoint=Vector2.new(.5,.5);r.Rotation=p[5]
 end
 local north=text(radar,'North','N',UDim2.fromOffset(12,12),UDim2.fromOffset(5,3),7);north.TextColor3=muted
 local own=text(map,'Player','▲',UDim2.fromOffset(12,12),UDim2.fromScale(.5,.5),12);own.AnchorPoint=Vector2.new(.5,.5);own.TextXAlignment=Enum.TextXAlignment.Center;own.ZIndex=4
 local allies={};for i=1,4 do local marker=line(map,'Ally'..i,UDim2.fromOffset(4,4),UDim2.new(),blue);marker.AnchorPoint=Vector2.new(.5,.5);marker.Visible=false;marker.ZIndex=3;make('UICorner',marker,{CornerRadius=UDim.new(1,0)});allies[i]=marker end
 return {screen=screen,reticleScreen=reticleScreen,root=root,cross=cross,arms=arms,hit=hit,health=health,hp=hp,hpTitle=hpTitle,fill=fill,ammo=ammo,count=count,reserve=reserve,weapon=weapon,preview=preview,reloadFill=reloadFill,hotbar=hotbar,slots=slots,feed=feed,feedRows=feedRows,kills={},radar=radar,map=map,own=own,allies=allies,data=data,UI=UI,onEquip=onEquip,lastSlow=0}
end
function HUD.hit(view,headshot)
 view.hitSerial=(view.hitSerial or 0)+1;local serial=view.hitSerial
 for _,line in ipairs(view.hit:GetChildren()) do line.BackgroundColor3=headshot and red or white end
 view.hit.Visible=true
 task.delay(.14,function()if view.hit.Parent and view.hitSerial==serial then view.hit.Visible=false end end)
end
function HUD.addKill(view,info)
 table.insert(view.kills,1,{text=info.killer..(info.headshot and '  ◎  ' or '  ›  ')..info.victim,expires=os.clock()+5})
 while #view.kills>3 do table.remove(view.kills) end
end
function HUD.equipSlot(view,index)
 local slot=view.slots[index];if slot and slot.id and view.onEquip then view.onEquip(slot.id) end
end
function HUD.cycleEquipment(view,direction)
 local current=1;for i,slot in ipairs(view.slots) do if slot.selected.Visible then current=i;break end end
 for step=1,4 do local index=(current-1+step*direction)%4+1;if view.slots[index].id then HUD.equipSlot(view,index);return end end
end
function HUD.styleControl(button,kind)
 button.Text='';button.BackgroundColor3=Color3.fromRGB(12,18,22);button.BackgroundTransparency=.72
 make('UIStroke',button,{Thickness=1,Transparency=.4,Color=white})
 if kind=='fire' or kind=='aim' then
  local ring=make('Frame',button,{Size=UDim2.fromOffset(18,18),Position=UDim2.fromScale(.5,.44),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1})
  make('UICorner',ring,{CornerRadius=UDim.new(1,0)});make('UIStroke',ring,{Thickness=1,Color=white,Transparency=.1})
  if kind=='fire' then local dot=line(ring,'Dot',UDim2.fromOffset(4,4),UDim2.fromScale(.5,.5));dot.AnchorPoint=Vector2.new(.5,.5);make('UICorner',dot,{CornerRadius=UDim.new(1,0)})
  else line(ring,'H',UDim2.fromOffset(26,1),UDim2.fromOffset(-4,8));line(ring,'V',UDim2.fromOffset(1,26),UDim2.fromOffset(8,-4)) end
 elseif kind=='heal' then
  line(button,'CrossV',UDim2.fromOffset(3,16),UDim2.new(.5,-1,.4,-8));line(button,'CrossH',UDim2.fromOffset(16,3),UDim2.new(.5,-8,.4,-1))
 else local glyph=text(button,'Reload','↻',UDim2.new(1,0,0,27),UDim2.fromOffset(0,0),24);glyph.Font=Enum.Font.SourceSans;glyph.TextXAlignment=Enum.TextXAlignment.Center end
 local caption=text(button,'Caption',({fire='TIRO',aim='MIRA',heal='CURAR',reload='R'})[kind],UDim2.new(1,0,0,10),UDim2.new(0,0,1,-12),7);caption.TextXAlignment=Enum.TextXAlignment.Center
end
local function mapPoint(data,position)
 return UDim2.fromScale(math.clamp((position.X-data.minX)/data.width,.025,.975),math.clamp((position.Z-data.minZ)/data.depth,.025,.975))
end
function HUD.update(view,context)
 local active=context.phase=='Match' and not context.menuOpen
 view.screen.Enabled=active;view.reticleScreen.Enabled=active and not context.downed and context.reticleEnabled~=false
 view.radar.Visible=context.radarEnabled~=false;view.feed.Visible=context.killfeedEnabled~=false
 if not active then view.kills={};return end
 local touch=context.touch
 view.health.Size=UDim2.fromOffset(touch and 124 or 160,24)
 view.health.Position=UDim2.new(.5,0,1,touch and -8 or -14)
 view.ammo.Size=UDim2.fromOffset(touch and 138 or 180,54)
 view.ammo.Position=UDim2.new(1,touch and -100 or -16,1,touch and -38 or -14)
 view.hotbar.Position=UDim2.new(1,touch and -100 or -16,1,touch and -98 or -74)
 view.hotbar.Size=UDim2.fromOffset(180,32)
 view.radar.Size=UDim2.fromOffset(touch and 76 or 106,touch and 72 or 96)
 view.radar.Position=UDim2.new(0,touch and 8 or 12,1,touch and -152 or -14)
 local hp=context.humanoid and math.max(0,context.humanoid.Health) or 0
 local max=context.humanoid and context.humanoid.MaxHealth or 100
 local ratio=max>0 and math.clamp(hp/max,0,1) or 0
 if ratio~=ratio then ratio=1 end
 view.hp.Text=tostring(math.ceil(hp));view.fill.Size=UDim2.fromScale(ratio,1);view.fill.BackgroundColor3=ratio<=.25 and red or white
 view.hpTitle.Text=context.downed and 'CAÍDO' or 'SAÚDE';view.hp.TextColor3=ratio<=.25 and red or white
 local gap=context.aiming and 2 or 5+math.min(context.recoil or 0,.18)*24
 view.arms[1].Position=UDim2.fromOffset(15-gap-5,15);view.arms[2].Position=UDim2.fromOffset(17+gap,15)
 view.arms[3].Position=UDim2.fromOffset(15,15-gap-5);view.arms[4].Position=UDim2.fromOffset(15,17+gap)
 local tool,def=context.tool,context.def
 local ammo=tool and tool:GetAttribute('Ammo')
 local reserve=tool and tool:GetAttribute('Reserve') or 0
 local reloading=tool and tool:GetAttribute('Reloading')==true
 view.count.Text=type(ammo)=='number' and ammo>=0 and string.format('%03d',ammo) or '—'
 view.count.TextColor3=ammo==0 and red or white
 view.reserve.Text=reloading and 'RECARGA' or (def and def.kind=='Gun' and '/ '..string.format('%03d',reserve) or def and def.kind=='Melee' and 'CORPO A CORPO' or def and 'CARGAS' or '')
 if reloading and not view.reloading then view.reloadStart=os.clock() end
 view.reloading=reloading
 view.reloadFill.Size=UDim2.fromScale(reloading and math.clamp((os.clock()-(view.reloadStart or os.clock()))/(def and def.reload or 2),0,1) or 0,1)
 if view.weaponId~=(def and def.id or '') then
  view.weaponId=def and def.id or '';view.weapon.Text=def and string.upper(def.name) or 'SEM ARMA'
  view.preview:ClearAllChildren();local model=def and game.ReplicatedStorage.FalloutItemVisuals:FindFirstChild(def.id)
  if model then view.UI.catalogPreview(view.preview,model,def) end
 end
 local now=os.clock();if now-view.lastSlow<.1 then return end;view.lastSlow=now
 local gear={}
 for _,container in ipairs({context.character,context.backpack}) do
  if container then for _,item in ipairs(container:GetChildren()) do if item:IsA('Tool') then
   local id=item:GetAttribute('FalloutItem');local entry=context.catalog[id]
   if entry then local slot=entry.kind=='Gun' and 1 or entry.kind=='Melee' and 2 or entry.kind=='Heal' and 3 or 4;gear[slot]=id end
  end end end
 end
 for i,slot in ipairs(view.slots) do
  local id=gear[i]
  if slot.id~=id then slot.id=id;slot.icon:ClearAllChildren();if id then view.UI.itemIcon(slot.icon,context.catalog[id]) end end
  slot.button.Active=id~=nil;slot.selected.Visible=id~=nil and def~=nil and def.id==id;slot.button.BackgroundTransparency=slot.selected.Visible and .4 or .82;slot.key.TextTransparency=id and .15 or .7
 end
 for i=#view.kills,1,-1 do if view.kills[i].expires<=now then table.remove(view.kills,i) end end
 for i,row in ipairs(view.feedRows) do row.Text=view.kills[i] and view.kills[i].text or '';row.TextTransparency=view.kills[i] and math.clamp(1-(view.kills[i].expires-now),0,1) or 0 end
 local root=context.character and context.character:FindFirstChild('HumanoidRootPart')
 if root then view.own.Position=mapPoint(view.data,root.Position);local look=root.CFrame.LookVector;view.own.Rotation=math.deg(math.atan2(look.X,-look.Z)) end
 local ownPlayer=context.player;local index=0
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=ownPlayer and ownPlayer and p.Team==ownPlayer.Team and p:GetAttribute('InMatch') then
   local character=p.Character;local r=character and character:FindFirstChild('HumanoidRootPart');local h=character and character:FindFirstChildOfClass('Humanoid')
   if r and h and h.Health>0 and index<4 then index+=1;view.allies[index].Visible=true;view.allies[index].Position=mapPoint(view.data,r.Position) end
  end
 end
 for i=index+1,4 do view.allies[i].Visible=false end
end
return HUD
