import fs from 'node:fs';
import { execute, first } from '../../treeworld-v12/cloud.mjs';

const read = (name) => fs.readFileSync(`roblox-integrations/sakura97/${name}.luau`, 'utf8');
const quote = (text) => {
  if (text.includes(']====]')) throw new Error('Source delimiter collision');
  return '[====[' + text + ']====]';
};

// Strip the final return from install so we can continue with verify + save
let installBody = read('install');
installBody = installBody.replace(/\nreturn\s*\{[\s\S]*\}\s*$/, '\n-- install finished');

const verifySource = read('verify');

const patch = `
assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, "Wrong target place")
local sourceVersion = game.PlaceVersion
print("[Sakura97] Starting clean install from version " .. tostring(sourceVersion))

do
${installBody}
end

-- verify
local function runVerify()
${verifySource}
end
local checks = runVerify()
assert(checks and checks.ok, "Verify failed: " .. tostring(checks))

game:GetService("AssetService"):SavePlaceAsync()
return {
  ok = true,
  sourceVersion = sourceVersion,
  trees = checks.trees,
  message = "Sakura island v97 published"
}
`;

console.log("[Sakura97] Dispatching Luau install to place...");
const applied = first(await execute(patch));
if (!applied?.ok) {
  console.error(JSON.stringify(applied, null, 2));
  throw new Error("Sakura97 install failed");
}
console.log(JSON.stringify({ stage: "installed-and-saved", ...applied }));

// wait for place version to advance
let persisted, last;
for (let i = 0; i < 12; i++) {
  if (i) await new Promise((r) => setTimeout(r, 4500));
  try {
    const check = first(await execute(`
      assert(game.GameId==9421311218 and game.PlaceId==118064584465155)
      local runtime = game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
      local trees = workspace:FindFirstChild("SakuraTrees")
      return {
        ok = runtime ~= nil and trees ~= nil,
        placeVersion = game.PlaceVersion,
        trees = trees and #trees:GetChildren() or 0,
        version = runtime and runtime:GetAttribute("Version")
      }
    `));
    if (!check?.ok || check.placeVersion <= applied.sourceVersion) {
      throw new Error("Saved version not visible yet (got " .. tostring(check and check.placeVersion) .. ")");
    }
    persisted = check;
    last = null;
    break;
  } catch (e) {
    last = e;
    console.log(JSON.stringify({ waiting: true, attempt: i + 1, error: String(e) }));
  }
}
if (last) throw last;

console.log(JSON.stringify({ stage: "verified-persisted", ...persisted }));
console.log("[Sakura97] Done! Place updated with cherry blossom island.");
