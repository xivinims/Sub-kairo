import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';
console.log(JSON.stringify(first(await execute(fs.readFileSync('mage-duel-v2/probe.luau','utf8')))));
