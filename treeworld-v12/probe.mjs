import fs from 'node:fs';
import {execute,first} from './cloud.mjs';
// Read-only inspection: no SavePlaceAsync call.
console.log(JSON.stringify(first(await execute(fs.readFileSync('treeworld-v12/probe.luau','utf8')))));
