local Maze={}
function Maze.generate(width,height,seed)
 local cells={};for y=1,height do cells[y]={};for x=1,width do cells[y][x]={true,true,true,true} end end
 local random=seed or 58817
 local function nextInt(n) random=(random*48271)%2147483647;return random%n+1 end
 local visited={["1:1"]=true};local stack={{1,1}};local dirs={{0,-1},{1,0},{0,1},{-1,0}}
 while #stack>0 do
  local p=stack[#stack];local choices={}
  for d,v in ipairs(dirs) do local x,y=p[1]+v[1],p[2]+v[2];if x>=1 and x<=width and y>=1 and y<=height and not visited[x..":"..y] then table.insert(choices,d) end end
  if #choices==0 then table.remove(stack) else
   local d=choices[nextInt(#choices)];local x,y=p[1]+dirs[d][1],p[2]+dirs[d][2]
   cells[p[2]][p[1]][d]=false;cells[y][x][(d+1)%4+1]=false;visited[x..":"..y]=true;table.insert(stack,{x,y})
  end
 end
 local leaves={};for y=2,height do for x=1,width do local walls=0;for _,v in ipairs(cells[y][x]) do if v then walls+=1 end end;if walls==3 then table.insert(leaves,{x,y}) end end end
 return cells,leaves
end
return Maze
