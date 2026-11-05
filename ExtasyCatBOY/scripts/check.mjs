import fs from "node:fs";
import assert from "node:assert/strict";
const root = new URL("../", import.meta.url);
const read = name => fs.readFileSync(new URL(name,root),"utf8");
const src = read("src/shared/Dialogue.lua");
function stringArray(name) {
  const m = src.match(new RegExp("local "+name+" = \\\{([\\s\\S]*?)\\\}"));
  assert(m, "Array not found: "+name);
  return (m[1].match(/"(?:[^"\\]|\\.)*"/g) || []).length;
}
const greetings=stringArray("hello");
const helloEndings=stringArray("helloEndings");
const endings=stringArray("endings");
const replyBlock=src.match(/local replies = \{([\s\S]*?)\n\}\nlocal order/);
assert(replyBlock,"replies block missing");
const groups=[...replyBlock[1].matchAll(/^\s{4}([a-z]+) = \{([\s\S]*?)^\s{4}\},/gm)];
assert.equal(groups.length,16,"Expected 16 intent categories");
let total=greetings*helloEndings;
for(const g of groups) {
  const count=(g[2].match(/"(?:[^"\\]|\\.)*"/g)||[]).length;
  assert.equal(count,10, "Expected 10 bases in "+g[1]);
  total+=count*endings;
}
assert(greetings>=100,"Need at least 100 unique, authored greetings");
assert(new Set([...src.matchAll(/^\s{4}"(.*)",?$/gm)].map(m=>m[1])).size>100,"Greetings must not all repeat");
assert(total>2462,"Need at least 2463 reply possibilities");
assert(src.includes("Hmm, não sei.")&&src.includes("Eu sou um gato ou cachorro"),"Unknown fallback missing");
const server=read("src/server/Main.server.lua");
const client=read("src/client/Main.client.lua");
for(const marker of ["IsFriendsWithAsync","GetFriendsAsync","CreateHumanoidModelFromDescriptionAsync","Motor6D","DataStoreService"]) {
  assert(server.includes(marker),"Missing server system: "+marker);
}
assert(client.includes("TextChatService:DisplayBubble"),"NPC bubble UI missing");
const config=read("src/shared/Config.lua");
assert(config.includes("MaxCompanionsPerPlayer = 4"),"Expected multiple NPCs per player");
assert(server.includes("table.insert(companions,rec)"),"Expected group spawn");
assert(server.includes("table.insert(payload,{"),"Expected array persistence");
assert(server.includes("companion.friendId == tonumber(friendId)"),"Expected selected NPC chat routing");
assert(client.includes("selectedFriendId()"),"Client must select NPC conversation target");
const tree=JSON.parse(read("default.project.json"));
assert(tree.tree.ServerScriptService && tree.tree.StarterPlayer,"Rojo service map missing");
console.log("ExtasyCatBOY source checks: PASS");
console.log("Original greetings:",greetings);
console.log("Greeting variations:",greetings*helloEndings);
console.log("Dialogue variations:",total);
console.log("Note: source checks do not replace in-Studio gameplay testing.");
