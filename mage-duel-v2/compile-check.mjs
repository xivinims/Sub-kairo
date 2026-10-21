import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';

for (const file of ['mage-duel-v2/magic-server.luau','mage-duel-v2/magic-client.luau']) {
  const src=fs.readFileSync(file,'utf8');
  const wrapped='local function __compile_probe()\n'+src+'\nend\nreturn {ok=true,file='+JSON.stringify(file)+'}';
  const out=first(await execute(wrapped));
  console.log(JSON.stringify(out));
}