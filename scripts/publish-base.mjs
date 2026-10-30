// Release: original-scene menu settings, mission markers, GrabPack pickup and touch controls.
import {readFile, writeFile} from 'node:fs/promises';

// Verified from the owner's Dead Signal share link. Never fall back to another place.
const universe = '9421311218';
const place = '118064584465155';
const key = process.env.ROBLOX_API_KEY;
if (!key) throw new Error('ROBLOX_API_KEY is not configured in repository secrets.');
const lookup = await fetch(`https://apis.roblox.com/universes/v1/places/${place}/universe`);
if (!lookup.ok || String((await lookup.json()).universeId) !== universe) {
  throw new Error('Destination verification failed; no place was uploaded.');
}
const bytes = await readFile('dist/Brambles-Sprout.rbxlx');
const response = await fetch(`https://apis.roblox.com/universes/v1/${universe}/places/${place}/versions?versionType=Published`, {
  method: 'POST', headers: {'x-api-key': key, 'Content-Type': 'application/xml'},
  body: bytes, signal: AbortSignal.timeout(120000),
});
if (!response.ok) {
  // Do not log credentials, request headers, or arbitrary remote response bodies.
  throw new Error(`Roblox rejected publication: HTTP ${response.status}. Check the key's place-publishing permission for universe ${universe}.`);
}
const result = await response.json();
if (!Number.isSafeInteger(result.versionNumber) || result.versionNumber < 1) throw new Error('Roblox did not confirm a published version number.');
const release = 'Cinematic settings over the existing menu scene; visible missions; working GrabPack pickup and mobile controls.';
const receipt = {published:true, release, engineVerified:true, universeId:universe, placeId:place, versionNumber:result.versionNumber, commit:process.env.GITHUB_SHA, publishedAt:new Date().toISOString(), studioPlaytested:false};
await writeFile('dist/publication.json', JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt,null,2));
