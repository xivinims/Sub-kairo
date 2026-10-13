# Forest v88

Target: universe `9421311218`, place `118064584465155`, branch `roblox-publisher`.

The only world is the forest. This update corrects root placement and dense grass loading, replaces both old log crossings with wooden bridges, improves native terrain water and adds rest points and the owner's seated NPC.

## Assets

| Asset | Use |
| --- | --- |
| `6432306802` | Roblox Forest Pack: PBR trees, plants, rocks, fallen-log benches and wildlife |
| `87377915371959` | Existing SkinnedGrass, GrassCard variant, fitted to its bone-root footprint |
| `11946229834` | Existing Wind Effects; gentler foliage and grass motion |
| `1352279393` | Wooden bridge model, adapted to the two banks with continuous floors and railings |
| `3070634312` | Requested cut-trunk model, upright and fitted to dry terrain |
| `13557849262` | Wooden lantern model, with warm lights controlled by the day/night cycle |
| `8490242417` | Requested Extreme shaders preset: reviewed sky/effects, adapted for changing sunlight |
| `9059051593` | Requested Hi sound effect, verified playable in this universe |
| `125673289337492` | Creator Store yay voice effect, verified playable in this universe |
| Roblox user `8344738123` | Real avatar description of `ch_ckz2n`, including current clothes and accessories |

Imported map scripts are removed. The Extreme shaders script is inspected rather than executed; its original destructive Lighting reset, constant blur and heavy vignette are replaced with the game's own controlled lighting setup.

## Behavior

- Geometry contact profiles use native upward rays at the lower imported mesh, rather than the whole tree's bounding-box centre. Every placement samples the actual terrain beneath those contacts. Plants follow the surface normal; unsuitable slopes and excessively buried placements are rejected.
- Tree heights vary from roughly 31 to 103 studs across seven varieties.
- Grass cells are four studs apart. Their bone footprint overlaps by roughly 1.6 studs. Native terrain rays suppress blades on water, trails, rocks and furniture; each patch uses the sampled ground color. Nearest patches take priority when walking. Dense grass is generated locally throughout the forest as it streams into view, with limits of 432 patches on touch devices and 1,152 on desktop.
- Water uses separate solid/liquid voxel channels, one consistent six-stud water level, smaller waves and restrained reflectance. Outer water extends beyond the forest's shoreline.
- Two real wooden bridges have individual boards, railings, support piers and continuous collision floors. No old log crossings remain.
- Eight fallen-log benches have sixteen usable seats. Sit prompts validate the player's distance and use the native Humanoid seating behavior.
- Twenty-five cut trunks and twenty-two lanterns are distributed beside trails and rest points.
- One cycle lasts sixteen minutes: twelve minutes of daylight and four minutes of night. Clients derive time from the server epoch, so ClockTime's non-replicating behavior does not desynchronize them. Lantern brightness follows dusk/dawn gradually.
- The NPC uses the owner's R6 avatar, sits on an imported cut trunk beside the entrance, turns its head toward nearby players and waves smoothly while its body stays fixed. Greetings alternate between “Olá!” and “Oiii!”. Dialogue uses short fixed choices, distance checks, separate command/greeting throttles and quiet positional sounds with a twenty-second shared cooldown.
- Stock avatar controls remain available; character setup does not move players during ordinary walking.

## Validation and publishing

`assemble.py` combines the reviewed components into a temporary `stage.luau`, the guarded `install.luau`, and an independent `verify.luau`. Staging never calls SavePlaceAsync. Publication calls SavePlaceAsync only after all native checks pass, then the publisher opens a new execution session to verify the saved version.

`tests.luau` checks lower geometry contacts, burial limits, river continuity, wooden-floor continuity and dry bridge entrances, seating and lantern counts, dense grass coverage in separated green areas, nearest-patch replacement, stable animated grass roots, the actual owner clothes, playable greeting voices, smooth cycle boundaries and all script/module compilation.

See the saved stage/publication results for measurements. These checks run in Roblox's native execution environment; they are not screenshots or an FPS measurement on the user's phone. Final visual appearance still depends on device rendering quality and needs an in-game visual check.

The previous live version is 87. The intended saved release is 88. Join a new game server after publication to load the new version.
