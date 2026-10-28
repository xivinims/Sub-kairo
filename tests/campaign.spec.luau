local Campaign=require("../src/shared/Campaign")
local Maze=require("../src/shared/Maze")
local checks=0
local function check(ok,message) assert(ok,message);checks+=1 end
local s=Campaign.new()
local function act(id,right) local nextState,msg,changed=Campaign.act(s,id,right==true);s=nextState;return changed,msg end
check(not act("socket1"),"power required")
check(not act("arbitrary"),"unknown targets rejected")
for _,id in ipairs({"card","fuse","power","socket1"}) do check(act(id),id) end
check(not act("socket2"),"red hand enforced")
check(act("socket2",true),"socket2")
check(not act("socket3"),"pruning required")
for i=1,3 do check(act("bloom"..i),"prune") end
check(not act("bloom1"),"duplicate collectible rejected")
check(act("socket3"),"socket3");check(Campaign.danger(s),"pursuer wakes")
check(act("release",true),"release");check(Campaign.complete(s),"sector1 complete")
check(act("exit") and s.sector==2,"archive transition")
check(not act("safe"),"safe rejects missing pages")
for i=1,3 do act("page"..i) end
for i,n in ipairs({1,7,8,4}) do for _=1,n do act("digit"..i) end end
check(act("safe"),"safe opens");act("exit")
for _,i in ipairs({1,3,4}) do act("valve"..i) end
for _=1,6 do act("pressure") end
for i=1,3 do act("cell"..i) end
check(not act("start"),"start requires red");check(act("start",true),"machines complete");act("exit")
for i=1,6 do act("seed"..i);if i==4 then check(Campaign.danger(s),"fourth seed wakes enemy") end end
check(Campaign.complete(s),"all seeds");act("exit")
check(not Campaign.complete(s),"echoes initially unsolved")
act("tone1");check(s.tones==0,"wrong note resets")
for _,n in ipairs({2,4,1,3,2,1}) do act("tone"..n) end
for _,n in ipairs({8,5,3,1}) do act("lamp"..n) end
check(Campaign.complete(s),"tones and matrix solved")
local restored=Campaign.restore(s);check(Campaign.complete(restored),"restore puzzle state");act("exit")
check(not act("cut1",true),"isolation required")
check(not act("isolate1",true),"blue required")
for i=1,4 do act("isolate"..i);check(act("cut"..i,true),"root cut") end
check(not Campaign.danger(s),"last root silences pursuer");act("exit")
for i=1,4 do act("fuse"..i) end
for i,n in ipairs({3,1,4}) do for _=1,n do act("angle"..i) end end
check(not act("master"),"master requires red");check(act("master",true),"transmission off")
check(act("exit") and s.finished,"chapter ending")
check(not act("exit"),"finished chapter cannot advance")
local bad=Campaign.restore({sector=999,pressure=-20,digits={999,-9},matrix={true},finished=true});check(bad.sector==7 and bad.pressure==0 and bad.digits[1]==9,"bounded saves")
local cells,leaves=Maze.generate(10,16,58817)
local visited={};local queue={{1,1}};local directions={{0,-1},{1,0},{0,1},{-1,0}};local total=0
while #queue>0 do
 local p=table.remove(queue);local key=p[1]..":"..p[2]
 if not visited[key] then visited[key]=true;total+=1
  for i,dir in ipairs(directions) do if not cells[p[2]][p[1]][i] then table.insert(queue,{p[1]+dir[1],p[2]+dir[2]}) end end
 end
end
check(total==160,"all maze rooms connected")
local picks={};for i=1,6 do local cell=leaves[math.floor((i-1)*#leaves/6)+1];local key=cell[1]..":"..cell[2];check(not picks[key],"unique seed locations");picks[key]=true end
print("PASS: "..checks.." campaign, save and maze assertions")
