local M={}
M.Tracks={
 {id=96332574400847,title="When You Said Goodbye",category="Em inglês"},
 {id=140033922950767,title="Why Do You Leave Me to Suffer Alone",category="Em inglês"},
 {id=1836416985,title="Gone Fishing · instrumental",category="Natureza"},
 {id=109647250911986,title="Nature Chill · reggae",category="Natureza"},
 {id=105504604402949,title="Sumidero Echo · instrumental",category="Natureza"},
 {id=9116971475,title="Floresta e pássaros",category="Natureza"},
 {id=9120552550,title="Riacho",category="Natureza"},
}
function M.parse(text)
 if type(text)~="string"or #text>32 then return nil end
 local digits=text:match("^%s*(%d+)%s*$")or text:match("^rbxassetid://(%d+)$")
 if not digits or #digits>16 then return nil end
 local id=tonumber(digits)if not id or id<1 or id>=9007199254740992 or id%1~=0 then return nil end return id
end
return M
