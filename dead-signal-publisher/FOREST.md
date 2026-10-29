# Still Here — native grass meadow

Exclusive universe 9421311218 / place 118064584465155 and branch dead-signal-publisher.

Published build: still-here-native-grass-v7, PlaceVersion 171. The downloaded published file was independently deserialized and checked: Terrain.Decoration=true, Terrain.GrassLength=0.85, zero geometry grass models. 99,490 old grass models were removed; 2,917 trees and 7,562 flower models remain. The file size fell from 23,101,448 bytes to 3,250,516 bytes.

The meadow has no roads, creek, props, menu, custom loading screen or storm system. Terrain materials were converted to Grass over the full 2,048 × 2,048 stud field. Native blades use Roblox terrain decoration, not imported grass geometry. Trees and flowers remain audited geometry selections.

The lighting now has a pale gold Atmosphere decay/color, lower haze and density, brighter ambient fill, reduced contrast, and a normal sky. This removes the former dark horizon treatment.

## Publishing

Terrain.Decoration and GrassLength are NotScriptable. The publisher first performs its normal source assembly, then native-grass.mjs downloads the place using the authorized Asset Delivery API, edits the serialized place with pinned Lune 0.11.1 (SHA-256 checked), verifies those two properties survive serialization, and uploads the edited binary using the official Place Publishing API. A bounded Luau pass converts terrain materials to Grass and saves it. Fresh engine validation confirms trees, flowers and zero grass models; a second download of that exact saved version confirms native terrain properties. Servers restart after these checks.

The downloader requires legacy-asset:manage. Native grass rendering also follows Roblox client graphics quality. No rendered client screenshot was available during this verification.
